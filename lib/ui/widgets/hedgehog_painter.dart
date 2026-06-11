import 'package:flutter/material.dart';

/// The different hedgehog poses available as image assets.
enum HedgehogActivity {
  /// Hedgehog waving/cheering — used for greetings, general empty states
  waving,

  /// Hedgehog wiping a window/mirror — used for cleaning-related contexts
  cleaning,

  /// Hedgehog scrubbing a toilet — used for deep-clean or overdue states
  scrubbing,

  /// Hedgehog mopping with a bucket — used for "all done" or active chore states
  mopping,

  /// Hedgehog washing dishes — used for chore list, kitchen tasks
  washing,
}

/// A widget that displays the hedgehog mascot image based on an activity.
///
/// Each [HedgehogActivity] maps to a different hedgehog illustration.
/// The PNG assets have transparent backgrounds so they blend cleanly
/// into any parent widget.
class HedgehogWidget extends StatelessWidget {
  final double size;
  final HedgehogActivity activity;

  const HedgehogWidget({
    super.key,
    this.size = 80.0,
    this.activity = HedgehogActivity.waving,
  });

  String get _assetPath {
    switch (activity) {
      case HedgehogActivity.waving:
        return 'assets/images/hedgehog_waving.png';
      case HedgehogActivity.cleaning:
        return 'assets/images/hedgehog_cleaning.png';
      case HedgehogActivity.scrubbing:
        return 'assets/images/hedgehog_scrubbing.png';
      case HedgehogActivity.mopping:
        return 'assets/images/hedgehog_mopping.png';
      case HedgehogActivity.washing:
        return 'assets/images/hedgehog_washing.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        _assetPath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback: show a hedgehog emoji if image fails to load
          return Center(
            child: Text(
              '🦔',
              style: TextStyle(fontSize: size * 0.5),
            ),
          );
        },
      ),
    );
  }
}
