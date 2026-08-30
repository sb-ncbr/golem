// nucleotide_colors.dart
//
// Shared color/size lookup for rendering bases and IUPAC codes. Pulled
// out into its own file because THREE widgets need the same palette
// (sequence logo, PFM table, consensus output) -- without this, each one
// would carry its own copy of the same switch-statement, and they'd
// eventually drift out of sync with each other.

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

// Every IUPAC code is a single CHARACTER regardless of how many bases it
// represents (e.g. "R" is one character but stands for A-or-G) -- so
// sizing by `code.length` (as an earlier version of this function did)
// never actually distinguished anything; every non-N code has length 1
// and got the same size. To size letters by how *ambiguous* they are
// (a clean single base drawn bigger/bolder than a 3-way toss-up), we
// need to know how many nucleotides the code stands for, which means
// checking against these small sets instead.
const _twoBaseCodes = {'R', 'Y', 'S', 'W', 'K', 'M'};
const _threeBaseCodes = {'B', 'D', 'H', 'V'};

double nucleotideFontSize(String code) {
  if (code == 'A' || code == 'C' || code == 'G' || code == 'T') return 42;
  if (_twoBaseCodes.contains(code)) return 32;
  if (_threeBaseCodes.contains(code)) return 26;
  return 20; // N (or anything unrecognized)
}
