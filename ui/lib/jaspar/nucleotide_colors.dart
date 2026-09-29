import 'package:flutter/material.dart';

Color baseColor(String base) {
  switch (base) {
    case 'A':
      return const Color(0xFF16793A);
    case 'C':
      return const Color(0xFF1257A3);
    case 'G':
      return const Color(0xFF93720A);
    case 'T':
      return const Color(0xFFB3122B);
    default:
      return Colors.grey;
  }
}

Color iupacColor(String code) {
  if (code.length == 1 && code != 'N') return baseColor(code);
  if (code == 'N') return Colors.grey;
  if (code.length == 2) return const Color(0xFF5B2A9C); // R,Y,S,W,K,M
  return const Color(0xFFA05A00); // B,D,H,V
}

const _twoBaseCodes = {'R', 'Y', 'S', 'W', 'K', 'M'};
const _threeBaseCodes = {'B', 'D', 'H', 'V'};

double nucleotideFontSize(String code) {
  if (code == 'A' || code == 'C' || code == 'G' || code == 'T') return 42;
  if (_twoBaseCodes.contains(code)) return 32;
  if (_threeBaseCodes.contains(code)) return 26;
  return 20; // N (or anything unrecognized)
}
