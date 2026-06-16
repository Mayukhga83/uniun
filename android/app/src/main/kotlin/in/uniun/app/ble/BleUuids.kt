package `in`.uniun.app.ble

import java.util.UUID

/**
 * UNIUN's own GATT identifiers — deliberately NOT bitchat's — so UNIUN devices pair
 * only with UNIUN. One service with a single duplex characteristic:
 *  - central → peripheral via WRITE,
 *  - peripheral → central via NOTIFY.
 * The native layer fragments/reassembles whole app messages across it.
 */
object BleUuids {
    val SERVICE: UUID = UUID.fromString("6e9d1b00-7a2e-4c91-9b35-0c1f5a7e9d10")
    val CHARACTERISTIC: UUID = UUID.fromString("6e9d1b01-7a2e-4c91-9b35-0c1f5a7e9d10")
    // Standard Client Characteristic Configuration descriptor (notifications on/off).
    val CCC: UUID = UUID.fromString("00002902-0000-1000-8000-00805f9b34fb")

    // 16-bit "company id" carrying our per-launch dial-arbitration token in the
    // advertisement (0xFFFF is the reserved/testing id — never a real company).
    const val MANUFACTURER_ID = 0xFFFF
}
