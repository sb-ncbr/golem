/// Tools that work with a DNA/RNA sequences
class SequenceTools {
  static const reverseComplements = {
    'A': 'T',
    'G': 'C',
    'C': 'G',
    'T': 'A',
    'U': 'A',
    'R': 'Y',
    'Y': 'R',
    'N': 'N',
    'W': 'W',
    'S': 'S',
    'M': 'K',
    'K': 'M',
    'B': 'V',
    'H': 'D',
    'D': 'H',
    'V': 'B',
  };

  /// Reverse complement of a sequence
  String reverse(String sequence) {
    for (int i = sequence.length - 1; i >= 0; i--) {
      if (!reverseComplements.containsKey(sequence[i])) {
        throw StateError('No reverse complement for `${sequence[i]}`');
      }
    }
    final result = [
      for (int i = sequence.length - 1; i >= 0; i--) reverseComplements[sequence[i]]!,
    ].join();
    return result;
  }
}
