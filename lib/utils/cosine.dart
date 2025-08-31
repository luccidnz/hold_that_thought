import 'dart:math' as math;

double cosine(List<double> a, List<double> b) {
  if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
  double dot = 0, na = 0, nb = 0;
  for (var i = 0; i < a.length; i++) { final x = a[i], y = b[i]; dot += x*y; na += x*x; nb += y*y; }
  final denom = math.sqrt(na) * math.sqrt(nb);
  return denom == 0 ? 0.0 : dot/denom;
}
