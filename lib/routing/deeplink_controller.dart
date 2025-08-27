sealed class DeepLinkAction {}

class NewThoughtAction extends DeepLinkAction {}

class ViewThoughtAction extends DeepLinkAction {
  final String id;
  ViewThoughtAction(this.id);
}

class DeepLinkNavigator {
  DeepLinkAction? parse(Uri uri) {
    if (uri.pathSegments.isEmpty) {
      return null;
    }

    if (uri.pathSegments.first == 'new') {
      return NewThoughtAction();
    }

    if (uri.pathSegments.length == 2 && uri.pathSegments.first == 't') {
      return ViewThoughtAction(uri.pathSegments[1]);
    }

    return null;
  }
}
