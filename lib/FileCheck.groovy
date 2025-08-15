import java.util.zip.GZIPInputStream

class FileCheck {
    static boolean isFileEmpty(File file) {
        // true if the file doesn't exist or is empty (0 bytes)
        if (!file.exists() || file.length() == 0) {
            return true
        }

        // Check if decompressed content is empty
        if (file.name.endsWith('.gz')) {
            file.withInputStream { fis ->
                new GZIPInputStream(fis).withStream { gis ->
                    return gis.read() != -1
                }
            }
        }

        return false
    }
}
