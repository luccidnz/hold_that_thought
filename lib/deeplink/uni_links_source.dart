import 'package:uni_links/uni_links.dart' as ul;
import 'deeplink_source.dart';

class UniLinksSource implements DeepLinkSource {
  @override
  Future<Uri?> getInitialLink() => ul.getInitialUri();
  @override
  Stream<Uri?> get linkStream => ul.uriLinkStream;
}
