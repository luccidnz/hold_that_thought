import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/routing/uni_links_source.dart';

class _FakeLinkStream {
  final _controller = StreamController<String?>();
  Stream<String?> get stream => _controller.stream;
  void add(String? v) => _controller.add(v);
  void close() => _controller.close();
}

void main() {
  test('parses valid link string into Uri', () async {
    final s = _FakeLinkStream();
    final source = UniLinksSource.fromStream(s.stream);
    s.add('myapp://note/abc123');

    final first = await source.uriStream.first;
    expect(first.toString(), 'myapp://note/abc123');
    s.close();
  });

  test('passes through invalid path', () async {
    final s = _FakeLinkStream();
    final source = UniLinksSource.fromStream(s.stream);
    s.add('myapp://noop/xyz');

    final first = await source.uriStream.first;
    expect(first.toString(), 'myapp://noop/xyz');
    s.close();
  });

  test('passes through link with empty path segment', () async {
    final s = _FakeLinkStream();
    final source = UniLinksSource.fromStream(s.stream);
    s.add('myapp://note/');

    final first = await source.uriStream.first;
    expect(first.toString(), 'myapp://note/');
    s.close();
  });

  test('passes through null value', () async {
    final s = _FakeLinkStream();
    final source = UniLinksSource.fromStream(s.stream);
    s.add(null);

    final first = await source.uriStream.first;
    expect(first, isNull);
    s.close();
  });
}
