/// Series of data points and some basic statistics on the series
class Series {
  final List<num> data;

  num get min => data.first;
  num get max => data.last;
  double get mean => sum / length;
  final int length;
  final double sum;

  Series(this.data)
      : sum = _sum(data),
        length = data.length {
    if (data.isEmpty) throw Exception('Empty data');
    data.sort();
  }

  static double _sum(List<num> values) {
    double sum = 0;
    for (final value in values) {
      sum += value;
    }
    return sum;
  }
}
