import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/routing/uni_links_source.dart';

abstract class DeepLinkSource {
  Future<Uri?> getInitialUri();
  Stream<Uri?> get uriStream;
}

final deepLinkSourceProvider = Provider<DeepLinkSource>((ref) {
  // This can be swapped with a mock implementation in tests
  return UniLinksSource();
});
