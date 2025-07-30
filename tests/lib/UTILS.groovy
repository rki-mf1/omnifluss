// Helper functions for pipeline tests

// found in: https://github.com/nf-core/ampliseq/blob/master/tests/pipeline/lib/UTILS.groovy
// re-written to work with nft-util's listToMD5() (see https://github.com/nf-core/nft-utils/blob/main/docs/usage.md#listtomd5)

class UTILS {

    // Function to filter certain lines from a file and return an ArrayList
    // Remember that the index starts at 0 in Groovy
    public static ArrayList excludeLines(String inFilePath, linesToExclude) {
        def inputLines = new File(inFilePath).readLines()
        if (linesToExclude.size() >= 0){
            Set<Integer> setOfLines = (0..inputLines.size()-1) as Set
            def newSetOfLines = setOfLines.minus(linesToExclude)
            return inputLines.getAt(newSetOfLines)
        }
        else {
            return inputLines
        }
    }
}
