import 'dart:async';

import 'package:hold_that_thought/routing/deeplink_source.dart';
import 'package:uni_links/uni_links.dart' as uni_links;

class UniLinksSource implements DeepLinkSource {
  final Stream<String?> _linkStream;

  UniLinksSource() : _linkStream = uni_links.linkStream;

  UniLinksSource.fromStream(this._linkStream);

  @override
  Future<Uri?> getInitialUri() async {
    final link = await uni_links.getInitialLink();
    if (link == null) return null;
    return Uri.tryParse(link);
  }

  @override
  Stream<Uri?> get uriStream {
    return _linkStream.map((link) {
      if (link == null) return null;
      return Uri.tryParse(link);
    });
  }
}
