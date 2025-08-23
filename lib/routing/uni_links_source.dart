import 'dart:async';

import 'package:hold_that_thought/routing/deeplink_source.dart';
import 'package:uni_links/uni_links.dart' as uni_links;

class UniLinksSource implements DeepLinkSource {
  @override
  Future<Uri?> getInitialUri() async {
    final link = await uni_links.getInitialLink();
    if (link == null) return null;
    return Uri.tryParse(link);
  }

  @override
  Stream<Uri?> get uriStream {
    return uni_links.linkStream.map((link) {
      if (link == null) return null;
      return Uri.tryParse(link);
    });
  }
}
