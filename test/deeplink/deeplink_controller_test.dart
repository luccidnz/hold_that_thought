import 'package:flutter_test/flutter_test.dart';
import 'package:hold_that_thought/deeplink/deeplink_controller.dart';
import '../fakes/fake_deeplink_source.dart';

void main() {
  test('navigates on initial link', () async {
    final fake = FakeDeepLinkSource()..setInitial(Uri.parse('myapp://note/abc'));
    Uri? got;
    final c = DeepLinkController(source: fake, onNavigate: (u) => got = u);
    await c.init();
   expect(got?.toString(), 'myapp://note/abc');
  });

  test('navigates on stream emission', () async {
    final fake = FakeDeepLinkSource();
    final seen = <String>[];
    final c = DeepLinkController(source: fake, onNavigate: (u) => seen.add(u.toString()));
    await c.init();
    fake.addLink(Uri.parse('myapp://note/xyz'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(seen, contains('myapp://note/xyz'));
  });
}
