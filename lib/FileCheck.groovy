import java.util.zip.GZIPInputStream

class FileCheck {
    static boolean isFileEmpty(File file) {
        if (!file.exists() || file.length() == 0) {
            return true
        }

        if (file.name.endsWith('.gz')) {
            // Check decompressed content
            file.withInputStream { fis ->
                new GZIPInputStream(fis).withStream { gis ->
                    return gis.read() != -1
                }
            }
        }
    }
}
