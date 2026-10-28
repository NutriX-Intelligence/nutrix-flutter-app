import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../widgets/common/nx_segmented.dart';

enum HomelySection { build, custom, community }

const _routes = {
  HomelySection.build: '/homely-build',
  HomelySection.custom: '/homely-custom',
  HomelySection.community: '/homely-community',
};

/// Lets the three Homely destinations (Build / Custom / Community) switch
/// between each other directly, without bouncing back through the Log
/// chooser each time — they're lateral siblings, not a hierarchy. Uses
/// `pushReplacement` so switching between them doesn't pile up back-stack
/// entries.
class HomelySwitcher extends StatelessWidget {
  const HomelySwitcher({super.key, required this.current});

  final HomelySection current;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
      child: NxSegmented<HomelySection>(
        values: HomelySection.values,
        selected: current,
        labelBuilder: (v) => switch (v) {
          HomelySection.build => 'Build',
          HomelySection.custom => 'Custom',
          HomelySection.community => 'Community',
        },
        onChanged: (v) {
          if (v != current) context.pushReplacement(_routes[v]!);
        },
      ),
    );
  }
}
