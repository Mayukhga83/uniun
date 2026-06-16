package `in`.uniun.app.ble

import java.security.SecureRandom

/**
 * One connected BLE peer's outbound side. The central and peripheral roles each
 * provide their own implementation (write vs notify); [BleController] routes a
 * `send(peerId, …)` to the matching channel.
 */
interface BlePeerChannel {
    fun sendMessage(message: ByteArray)
    fun close()
}

/** A fresh per-launch dial-arbitration token (advertised; never the pubkey). */
fun randomToken(): ByteArray = ByteArray(4).also { SecureRandom().nextBytes(it) }

/** Unsigned lexicographic comparison of two tokens. */
fun compareTokens(a: ByteArray, b: ByteArray): Int {
    val n = minOf(a.size, b.size)
    for (i in 0 until n) {
        val x = a[i].toInt() and 0xFF
        val y = b[i].toInt() and 0xFF
        if (x != y) return x - y
    }
    return a.size - b.size
}

/** Parses an even-length hex string to bytes (the form Apple peers advertise the
 *  token in, via the local name). Returns null on malformed input. */
fun hexToBytes(hex: String): ByteArray? {
    if (hex.length % 2 != 0) return null
    return try {
        ByteArray(hex.length / 2) { i ->
            hex.substring(i * 2, i * 2 + 2).toInt(16).toByte()
        }
    } catch (_: Exception) {
        null
    }
}
