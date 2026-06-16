package `in`.uniun.app.ble

/**
 * Splits whole app messages into GATT-sized fragments and reassembles them. This is
 * the one genuinely-hard transport bit (conceptually borrowed from bitchat): a GATT
 * write/notification can carry only `mtu - 3` bytes, but our messages are larger.
 *
 * Fragment layout: `[msgId u16][fragIndex u16][fragCount u16][payload…]` (big-endian
 * 6-byte header). Because each per-peer channel sends one message at a time with one
 * fragment in flight, fragments never interleave on a link; the reassembler still
 * keys by `msgId` and resets cleanly if a new message starts.
 */
object BleFragmenter {
    const val HEADER = 6
    private const val MAX_MESSAGE = 8 * 1024 * 1024 // 8 MB safety cap

    /** Splits [message] into fragments that fit the negotiated [mtu]. */
    fun fragment(message: ByteArray, msgId: Int, mtu: Int): List<ByteArray> {
        // [mtu] here is the RAW ATT_MTU from onMtuChanged, so we subtract the
        // 3-byte ATT write header (opcode + handle) AND our 6-byte fragment header.
        // NOTE: the Apple side (UniunBleMesh.swift) subtracts only HEADER, because
        // CoreBluetooth's maximumWriteValueLength/maximumUpdateValueLength already
        // net the ATT header — both arrive at the same usable payload. Don't
        // "unify" the two formulas; they're intentionally different per-platform.
        val payloadSize = (mtu - 3 - HEADER).coerceAtLeast(20)
        val count = ((message.size + payloadSize - 1) / payloadSize).coerceAtLeast(1)
        val out = ArrayList<ByteArray>(count)
        var offset = 0
        for (i in 0 until count) {
            val end = minOf(offset + payloadSize, message.size)
            val chunk = ByteArray(HEADER + (end - offset))
            putU16(chunk, 0, msgId)
            putU16(chunk, 2, i)
            putU16(chunk, 4, count)
            System.arraycopy(message, offset, chunk, HEADER, end - offset)
            out.add(chunk)
            offset = end
        }
        return out
    }

    /** Per-peer reassembly state. One in-flight message at a time. */
    class Reassembler {
        private var msgId = -1
        private var count = 0
        private var received = 0
        private var parts: Array<ByteArray?> = arrayOf()
        private var total = 0

        /** Feeds one inbound fragment; returns the whole message when complete. */
        fun receive(fragment: ByteArray): ByteArray? {
            if (fragment.size < HEADER) return null
            val id = u16(fragment, 0)
            val index = u16(fragment, 2)
            val cnt = u16(fragment, 4)
            if (cnt == 0 || index >= cnt) return null

            if (id != msgId || cnt != count) {
                // New message — reset.
                msgId = id
                count = cnt
                received = 0
                total = 0
                parts = arrayOfNulls(cnt)
            }
            if (parts[index] == null) {
                val payload = fragment.copyOfRange(HEADER, fragment.size)
                parts[index] = payload
                received++
                total += payload.size
                if (total > MAX_MESSAGE) {
                    reset()
                    return null
                }
            }
            if (received != count) return null

            val out = ByteArray(total)
            var offset = 0
            for (p in parts) {
                val part = p ?: return null
                System.arraycopy(part, 0, out, offset, part.size)
                offset += part.size
            }
            reset()
            return out
        }

        private fun reset() {
            msgId = -1
            count = 0
            received = 0
            total = 0
            parts = arrayOf()
        }
    }

    private fun putU16(buf: ByteArray, at: Int, value: Int) {
        buf[at] = ((value ushr 8) and 0xFF).toByte()
        buf[at + 1] = (value and 0xFF).toByte()
    }

    private fun u16(buf: ByteArray, at: Int): Int =
        ((buf[at].toInt() and 0xFF) shl 8) or (buf[at + 1].toInt() and 0xFF)
}
