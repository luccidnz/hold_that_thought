import 'package:hold_that_thought/routing/deeplink_source.dart';
import 'package:uni_links/uni_links.dart' as uni_links;

class UniLinksSource implements DeepLinkSource {
  @override
  Future<String?> getInitialLink() {
    return uni_links.getInitialLink();
  }

  @override
  Stream<String?> get linkStream {
    return uni_links.linkStream;
  }
}
