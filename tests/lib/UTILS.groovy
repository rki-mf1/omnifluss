// Helper functions for pipeline tests

// found in: https://github.com/nf-core/ampliseq/blob/master/tests/pipeline/lib/UTILS.groovy

class UTILS {

    // Function to filter the first lines from a file and return a new file
    public static File filterFirstLines(String inFilePath, int linesToSkip) {
        if (linesToSkip >= 0) {
            File inputFile = new File(inFilePath)
            File outputFile = new File(inFilePath + ".filtered")
            // overwrite the output file
            outputFile.newWriter().withWriter{ w ->
                def lineCount = 0
                inputFile.eachLine { line ->
                    lineCount++
                    if (lineCount > linesToSkip) {
                        w << line + '\n'
                    }
                }
            }
            return outputFile
        } else {
            // not 100 % what this does
            // maybe it skips the last x lines of a file
            // for sure, the ouput will NOT be overwritten, but appended
            File inputFile = new File(inFilePath)
            File outputFile = new File(inFilePath + ".filtered")
            def lines = inputFile.readLines()
            def totalLines = lines.size()
            lines.take(totalLines + linesToSkip).each { line ->
                outputFile.append(line + '\n')
            }
            return outputFile
        }
    }

    // Function to filter certain lines from a file and return a new file
    public static File filterLines(String inFilePath, linesToSkip) {
        if (linesToSkip.size() >= 0){
            File inputFile = new File(inFilePath)
            File outputFile = new File(inFilePath + ".filtered")
            // overwrite the output file
            outputFile.newWriter().withWriter{ w ->
                def lineCount = 0
                inputFile.eachLine { line ->
                    lineCount++
                    if (! linesToSkip.contains(lineCount)) {
                        w << line + '\n'
                    }
                }
            }
            return outputFile
        } else {
            return new File(inFilePath)
        }
    }
}
