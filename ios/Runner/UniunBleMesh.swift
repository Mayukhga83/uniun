import CoreBluetooth
#if canImport(Flutter)
import Flutter
#else
import FlutterMacOS
#endif

// MARK: - BLE mesh (dual-role CoreBluetooth)
//
// The CoreBluetooth analogue of Android's BleController: a custom byte pipe over our
// own service/characteristic UUIDs, registered on the mesh engine. Dual-role
// (central + peripheral); fragmentation header byte-identical to Android so fragments
// interoperate cross-platform. CoreBluetooth peripherals cannot advertise manufacturer
// data, so the dial-arbitration token rides the local name on Apple and the manufacturer
// data on Android — each central reads whichever is present.
//
// SINGLE SOURCE: this one file is compiled into BOTH the iOS Runner target (where it
// imports `Flutter`) and the macOS Runner target (where it imports `FlutterMacOS`) via
// the conditional import above. Do not re-fork it per platform — that's exactly the
// drift this consolidation removes.
final class UniunBleMesh: NSObject {
  private static let serviceUUID = CBUUID(string: "6E9D1B00-7A2E-4C91-9B35-0C1F5A7E9D10")
  private static let charUUID = CBUUID(string: "6E9D1B01-7A2E-4C91-9B35-0C1F5A7E9D10")
  private static let header = 6

  private let methodChannel: FlutterMethodChannel
  private let eventChannel: FlutterEventChannel
  private var sink: FlutterEventSink?

  private let token: [UInt8] = (0..<4).map { _ in UInt8.random(in: 0...255) }
  private lazy var tokenHex: String = token.map { String(format: "%02x", $0) }.joined()

  private var central: CBCentralManager?
  private var peripheralMgr: CBPeripheralManager?
  private var characteristic: CBMutableCharacteristic?
  private var started = false
  // CoreBluetooth callbacks (scan/advertise/notify/reassembly) and all state access
  // run on this serial queue — NOT the main thread — so BLE never janks the UI. Only
  // the Flutter event sink is marshaled back to main.
  private let bleQueue = DispatchQueue(label: "in.uniun.ble")

  // Central side (we dialed out): peerId = peripheral.identifier.uuidString
  private var peripherals: [String: CBPeripheral] = [:]
  private var writeChars: [String: CBCharacteristic] = [:]
  private var centralOut: [String: [[UInt8]]] = [:]
  private var centralSending: Set<String> = []
  private var centralMsgId: [String: Int] = [:]
  private var centralReasm: [String: BleReassembler] = [:]

  // Peripheral side (they dialed in): peerId = central.identifier.uuidString
  private var centrals: [String: CBCentral] = [:]
  private var peripheralMsgId: [String: Int] = [:]
  private var peripheralReasm: [String: BleReassembler] = [:]
  private var notifyQueue: [(CBCentral, [UInt8])] = []
  private var notifying = false

  init(messenger: FlutterBinaryMessenger) {
    methodChannel = FlutterMethodChannel(name: "in.uniun.app/ble", binaryMessenger: messenger)
    eventChannel = FlutterEventChannel(name: "in.uniun.app/ble/events", binaryMessenger: messenger)
    super.init()
    methodChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(nil); return }
      switch call.method {
      case "start": self.bleQueue.async { self.start() }; result(nil)
      case "stop": self.bleQueue.async { self.stop() }; result(nil)
      case "send":
        if let args = call.arguments as? [String: Any],
          let peerId = args["peerId"] as? String,
          let data = (args["bytes"] as? FlutterStandardTypedData)?.data {
          self.bleQueue.async { self.routeSend(peerId, [UInt8](data)) }
        }
        result(nil)
      case "disconnect":
        if let args = call.arguments as? [String: Any],
          let peerId = args["peerId"] as? String {
          self.bleQueue.async { self.disconnect(peerId) }
        }
        result(nil)
      default: result(FlutterMethodNotImplemented)
      }
    }
    eventChannel.setStreamHandler(self)
  }

  func dispose() {
    stop()
    methodChannel.setMethodCallHandler(nil)
    eventChannel.setStreamHandler(nil)
  }

  private func start() {
    if started { return }
    started = true
    NSLog("MESH/BLE: start: dual-role BLE, token=\(tokenHex)")
    central = CBCentralManager(delegate: self, queue: bleQueue)
    peripheralMgr = CBPeripheralManager(delegate: self, queue: bleQueue)
  }

  private func stop() {
    if !started { return }
    started = false
    NSLog("MESH/BLE: stop")
    central?.stopScan()
    for (_, p) in peripherals { central?.cancelPeripheralConnection(p) }
    peripherals.removeAll(); writeChars.removeAll(); centralOut.removeAll()
    centralSending.removeAll(); centralReasm.removeAll(); centralMsgId.removeAll()
    if peripheralMgr?.isAdvertising == true { peripheralMgr?.stopAdvertising() }
    peripheralMgr?.removeAllServices()
    centrals.removeAll(); peripheralReasm.removeAll(); peripheralMsgId.removeAll()
    notifyQueue.removeAll(); notifying = false
    central = nil; peripheralMgr = nil; characteristic = nil
  }

  // MARK: send routing
  private func routeSend(_ peerId: String, _ message: [UInt8]) {
    if peripherals[peerId] != nil {
      centralSend(peerId, message)
    } else if let c = centrals[peerId] {
      peripheralSend(c, message)
    }
  }

  private func disconnect(_ peerId: String) {
    if let p = peripherals[peerId] {
      central?.cancelPeripheralConnection(p)
    } else if centrals[peerId] != nil {
      dropCentral(peerId)
    }
  }

  // MARK: Dart events (main queue — the sink is main-thread only)
  private func emit(_ event: [String: Any]) {
    DispatchQueue.main.async { self.sink?(event) }
  }
  private func onPeerUp(_ peerId: String) {
    NSLog("MESH/BLE: peerUp \(peerId)")
    emit(["type": "peerUp", "peerId": peerId])
  }
  private func onPeerDown(_ peerId: String) {
    NSLog("MESH/BLE: peerDown \(peerId)")
    emit(["type": "peerDown", "peerId": peerId])
  }
  private func onMessage(_ peerId: String, _ data: [UInt8]) {
    emit([
      "type": "message", "peerId": peerId,
      "bytes": FlutterStandardTypedData(bytes: Data(data)),
    ])
  }

  // MARK: dial arbitration
  private func extractToken(_ adv: [String: Any]) -> [UInt8]? {
    if let mfr = adv[CBAdvertisementDataManufacturerDataKey] as? Data, mfr.count >= 6 {
      return Array(mfr[2..<6]) // skip the 2-byte company id (Android peers)
    }
    if let name = adv[CBAdvertisementDataLocalNameKey] as? String, name.count == 8 {
      return hexToBytes(name) // Apple peers carry the token in the local name
    }
    return nil
  }
  private func shouldDial(_ adv: [String: Any]) -> Bool {
    guard let peer = extractToken(adv) else { return false }
    // Only the strictly-higher token dials; the other side accepts. (Matches the
    // Android `>` so an Apple↔Apple token tie can't have both sides dial.)
    return compareTokens(token, peer) > 0
  }

  // MARK: central send
  private func centralSend(_ id: String, _ message: [UInt8]) {
    guard let p = peripherals[id] else { return }
    let mtu = max(p.maximumWriteValueLength(for: .withResponse), 23)
    let msgId = (centralMsgId[id] ?? 0) & 0xFFFF
    centralMsgId[id] = msgId + 1
    centralOut[id, default: []].append(contentsOf: fragment(message, msgId, mtu))
    pumpCentral(id)
  }
  private func pumpCentral(_ id: String) {
    if centralSending.contains(id) { return }
    guard var q = centralOut[id], !q.isEmpty,
      let p = peripherals[id], let ch = writeChars[id] else { return }
    let chunk = q.removeFirst()
    centralOut[id] = q
    centralSending.insert(id)
    p.writeValue(Data(chunk), for: ch, type: .withResponse)
  }

  // MARK: peripheral send (notifications, serialized globally)
  private func peripheralSend(_ central: CBCentral, _ message: [UInt8]) {
    let id = central.identifier.uuidString
    let mtu = max(central.maximumUpdateValueLength, 23)
    let msgId = (peripheralMsgId[id] ?? 0) & 0xFFFF
    peripheralMsgId[id] = msgId + 1
    for chunk in fragment(message, msgId, mtu) { notifyQueue.append((central, chunk)) }
    pumpNotify()
  }
  private func pumpNotify() {
    if notifying { return }
    guard let ch = characteristic, let mgr = peripheralMgr else { return }
    while let (central, chunk) = notifyQueue.first {
      let ok = mgr.updateValue(Data(chunk), for: ch, onSubscribedCentrals: [central])
      if ok { notifyQueue.removeFirst() } else { notifying = true; return }
    }
  }

  // MARK: cleanup
  private func dropPeripheral(_ id: String) {
    let wasReady = writeChars[id] != nil
    peripherals.removeValue(forKey: id)
    writeChars.removeValue(forKey: id)
    centralOut.removeValue(forKey: id)
    centralSending.remove(id)
    centralReasm.removeValue(forKey: id)
    centralMsgId.removeValue(forKey: id)
    if wasReady { onPeerDown(id) }
  }
  private func dropCentral(_ id: String) {
    let was = centrals[id] != nil
    centrals.removeValue(forKey: id)
    peripheralReasm.removeValue(forKey: id)
    peripheralMsgId.removeValue(forKey: id)
    notifyQueue.removeAll { $0.0.identifier.uuidString == id }
    if was { onPeerDown(id) }
  }

  // MARK: fragmentation (header matches Android: [msgId u16][idx u16][count u16] BE)
  private func fragment(_ message: [UInt8], _ msgId: Int, _ mtu: Int) -> [[UInt8]] {
    // [mtu] here is CoreBluetooth's usable write/notify length
    // (maximumWriteValueLength / maximumUpdateValueLength), which ALREADY nets the
    // 3-byte ATT header — so we subtract only our 6-byte fragment HEADER. The Android
    // side subtracts `3 + HEADER` because its onMtuChanged reports the raw ATT_MTU.
    // Both arrive at the same usable payload; don't "unify" the two formulas.
    let payloadSize = max(mtu - Self.header, 20)
    let count = max((message.count + payloadSize - 1) / payloadSize, 1)
    var out: [[UInt8]] = []
    var offset = 0
    for i in 0..<count {
      let end = min(offset + payloadSize, message.count)
      var chunk = [UInt8](repeating: 0, count: Self.header + (end - offset))
      chunk[0] = UInt8((msgId >> 8) & 0xFF); chunk[1] = UInt8(msgId & 0xFF)
      chunk[2] = UInt8((i >> 8) & 0xFF); chunk[3] = UInt8(i & 0xFF)
      chunk[4] = UInt8((count >> 8) & 0xFF); chunk[5] = UInt8(count & 0xFF)
      if end > offset {
        for j in offset..<end { chunk[Self.header + (j - offset)] = message[j] }
      }
      out.append(chunk)
      offset = end
    }
    return out
  }

  private func compareTokens(_ a: [UInt8], _ b: [UInt8]) -> Int {
    let n = min(a.count, b.count)
    for i in 0..<n where a[i] != b[i] { return Int(a[i]) - Int(b[i]) }
    return a.count - b.count
  }
  private func hexToBytes(_ hex: String) -> [UInt8]? {
    let chars = Array(hex)
    if chars.count % 2 != 0 { return nil }
    var out: [UInt8] = []
    var i = 0
    while i < chars.count {
      guard let b = UInt8(String(chars[i...i + 1]), radix: 16) else { return nil }
      out.append(b); i += 2
    }
    return out
  }
}

// MARK: central role
extension UniunBleMesh: CBCentralManagerDelegate {
  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    if central.state == .poweredOn {
      NSLog("MESH/BLE: central: scanning")
      central.scanForPeripherals(withServices: [Self.serviceUUID], options: nil)
    }
  }
  func centralManager(
    _ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
    advertisementData: [String: Any], rssi RSSI: NSNumber
  ) {
    let id = peripheral.identifier.uuidString
    if peripherals[id] != nil { return }
    if !shouldDial(advertisementData) { return }
    NSLog("MESH/BLE: central: dialing \(id)")
    peripherals[id] = peripheral // retain through the connection
    peripheral.delegate = self
    central.connect(peripheral, options: nil)
  }
  func centralManager(
    _ central: CBCentralManager, didConnect peripheral: CBPeripheral
  ) {
    peripheral.discoverServices([Self.serviceUUID])
  }
  func centralManager(
    _ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?
  ) {
    dropPeripheral(peripheral.identifier.uuidString)
  }
  func centralManager(
    _ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?
  ) {
    dropPeripheral(peripheral.identifier.uuidString)
  }
}

// MARK: central → peripheral connection (CBPeripheralDelegate)
extension UniunBleMesh: CBPeripheralDelegate {
  func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
    guard let svc = peripheral.services?.first(where: { $0.uuid == Self.serviceUUID }) else {
      central?.cancelPeripheralConnection(peripheral); return
    }
    peripheral.discoverCharacteristics([Self.charUUID], for: svc)
  }
  func peripheral(
    _ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?
  ) {
    guard let ch = service.characteristics?.first(where: { $0.uuid == Self.charUUID }) else {
      central?.cancelPeripheralConnection(peripheral); return
    }
    writeChars[peripheral.identifier.uuidString] = ch
    peripheral.setNotifyValue(true, for: ch)
  }
  func peripheral(
    _ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic,
    error: Error?
  ) {
    if characteristic.isNotifying {
      let id = peripheral.identifier.uuidString
      centralReasm[id] = BleReassembler()
      onPeerUp(id)
    }
  }
  func peripheral(
    _ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?
  ) {
    guard let value = characteristic.value else { return }
    let id = peripheral.identifier.uuidString
    if let whole = centralReasm[id]?.receive([UInt8](value)) { onMessage(id, whole) }
  }
  func peripheral(
    _ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?
  ) {
    let id = peripheral.identifier.uuidString
    centralSending.remove(id)
    pumpCentral(id)
  }
}

// MARK: peripheral role
extension UniunBleMesh: CBPeripheralManagerDelegate {
  func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
    if peripheral.state == .poweredOn {
      let ch = CBMutableCharacteristic(
        type: Self.charUUID,
        properties: [.write, .writeWithoutResponse, .notify],
        value: nil, permissions: [.writeable])
      let svc = CBMutableService(type: Self.serviceUUID, primary: true)
      svc.characteristics = [ch]
      characteristic = ch
      peripheral.add(svc)
    }
  }
  func peripheralManager(
    _ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?
  ) {
    NSLog("MESH/BLE: peripheral: advertising")
    peripheral.startAdvertising([
      CBAdvertisementDataServiceUUIDsKey: [Self.serviceUUID],
      CBAdvertisementDataLocalNameKey: tokenHex,
    ])
  }
  func peripheralManager(
    _ peripheral: CBPeripheralManager, central: CBCentral,
    didSubscribeTo characteristic: CBCharacteristic
  ) {
    let id = central.identifier.uuidString
    centrals[id] = central
    peripheralReasm[id] = BleReassembler()
    onPeerUp(id)
  }
  func peripheralManager(
    _ peripheral: CBPeripheralManager, central: CBCentral,
    didUnsubscribeFrom characteristic: CBCharacteristic
  ) {
    dropCentral(central.identifier.uuidString)
  }
  func peripheralManager(
    _ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]
  ) {
    for req in requests {
      guard let value = req.value else { continue }
      let id = req.central.identifier.uuidString
      if centrals[id] == nil {
        centrals[id] = req.central
        peripheralReasm[id] = BleReassembler()
      }
      if let whole = peripheralReasm[id]?.receive([UInt8](value)) { onMessage(id, whole) }
    }
    if let first = requests.first { peripheral.respond(to: first, withResult: .success) }
  }
  func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
    notifying = false
    pumpNotify()
  }
}

// MARK: Flutter event stream
extension UniunBleMesh: FlutterStreamHandler {
  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    sink = events
    return nil
  }
  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }
}

/// Per-peer reassembly — mirrors the Android `BleFragmenter.Reassembler`, including the
/// 8 MB safety cap so a peer can't drive unbounded reassembly with a huge fragment count.
final class BleReassembler {
  private static let maxMessage = 8 * 1024 * 1024 // 8 MB (mirrors kMeshMaxMessageBytes)
  private var msgId = -1
  private var count = 0
  private var received = 0
  private var total = 0
  private var parts: [[UInt8]?] = []

  func receive(_ frag: [UInt8]) -> [UInt8]? {
    if frag.count < 6 { return nil }
    let id = u16(frag, 0)
    let index = u16(frag, 2)
    let cnt = u16(frag, 4)
    if cnt == 0 || index >= cnt { return nil }
    if id != msgId || cnt != count {
      msgId = id; count = cnt; received = 0; total = 0
      parts = Array(repeating: nil, count: cnt)
    }
    if parts[index] == nil {
      let payload = frag.count > 6 ? Array(frag[6...]) : []
      parts[index] = payload
      received += 1
      total += payload.count
      if total > Self.maxMessage { reset(); return nil }
    }
    if received != count { return nil }
    var out = [UInt8]()
    out.reserveCapacity(total)
    for p in parts {
      guard let pp = p else { return nil }
      out.append(contentsOf: pp)
    }
    reset()
    return out
  }

  private func reset() {
    msgId = -1; count = 0; received = 0; total = 0; parts = []
  }

  private func u16(_ b: [UInt8], _ at: Int) -> Int { (Int(b[at]) << 8) | Int(b[at + 1]) }
}
