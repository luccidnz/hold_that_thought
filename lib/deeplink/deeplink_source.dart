import 'dart:async';

abstract class DeepLinkSource {
  Future<Uri?> getInitialLink();
  Stream<Uri?> get linkStream;
}
