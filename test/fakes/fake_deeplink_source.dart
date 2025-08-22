import 'dart:async';
import 'package:hold_that_thought/deeplink/deeplink_source.dart';

class FakeDeepLinkSource implements DeepLinkSource {
  final _controller = StreamController<Uri?>.broadcast();
  Uri? _initial;
  void setInitial(Uri? uri) => _initial = uri;
  void addLink(Uri? uri) => _controller.add(uri);
  @override
  Future<Uri?> getInitialLink() async => _initial;
  @override
  Stream<Uri?> get linkStream => _controller.stream;
  void dispose() => _controller.close();
}
