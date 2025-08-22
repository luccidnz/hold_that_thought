import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/routing/uni_links_source.dart';

abstract class DeepLinkSource {
  Future<String?> getInitialLink();
  Stream<String?> get linkStream;
}

final deepLinkSourceProvider = Provider<DeepLinkSource>((ref) {
  // This can be swapped with a mock implementation in tests
  return UniLinksSource();
});
