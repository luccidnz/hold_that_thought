import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hold_that_thought/flavor.dart';
import 'package:hold_that_thought/main.dart';

class FlavorBanner extends ConsumerWidget {
  const FlavorBanner({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flavor = ref.watch(flavorProvider);
    if (flavor == Flavor.prod) {
      return child;
    }
    return Banner(
      message: flavor.name.toUpperCase(),
      location: BannerLocation.topStart,
      child: child,
    );
  }
}
