import 'package:flutter/material.dart';

/// Shared spacing constants for consistent padding across the app.
class AppSpacing {
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Responsive layout helpers used across screens and widgets.
class ResponsiveUtils {
  static const double primaryButtonMinHeight = 52;
  static const double minTouchTarget = 48;

  static double screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => screenWidth(context) < 600;

  static bool isMedium(BuildContext context) {
    final w = screenWidth(context);
    return w >= 600 && w < 900;
  }

  static bool isExpanded(BuildContext context) => screenWidth(context) >= 900;

  static EdgeInsets screenPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 900) return const EdgeInsets.all(AppSpacing.xl);
    if (width >= 600) return const EdgeInsets.all(AppSpacing.lg);
    return const EdgeInsets.all(AppSpacing.md);
  }

  static double maxContentWidth(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 1200) return 1000;
    if (width >= 900) return 900;
    if (width >= 600) return 720;
    return double.infinity;
  }

  static int gridCrossAxisCount(
    BuildContext context, {
    int compact = 1,
    int medium = 2,
    int expanded = 4,
  }) {
    final width = screenWidth(context);
    if (width >= 900) return expanded;
    if (width >= 600) return medium;
    return compact;
  }

  static double chartHeight(BuildContext context, {double compact = 160, double expanded = 220}) {
    return isCompact(context) ? compact : expanded;
  }

  /// Wraps scrollable screen content with bottom safe-area and keyboard inset padding.
  static EdgeInsets scrollPadding(BuildContext context, {EdgeInsets? base}) {
    final padding = base ?? screenPadding(context);
    return padding.copyWith(
      bottom: padding.bottom + MediaQuery.viewInsetsOf(context).bottom,
    );
  }

  /// Standard body wrapper for screens with an [AppBar] (top inset handled by app bar).
  static Widget appBarBody({
    required BuildContext context,
    required Widget child,
    bool scrollable = false,
    ScrollPhysics? physics,
    EdgeInsets? padding,
  }) {
    final contentPadding = scrollPadding(context, base: padding);

    Widget content = child;
    if (scrollable) {
      content = SingleChildScrollView(
        physics: physics ?? const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: contentPadding,
        child: child,
      );
    } else if (padding != null) {
      content = Padding(padding: contentPadding, child: child);
    }

    return SafeArea(
      top: false,
      child: content,
    );
  }

  /// Centers content and constrains max width on tablets and web.
  static Widget constrainedContent(BuildContext context, Widget child) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth(context)),
        child: child,
      ),
    );
  }

  /// Full-width primary action button with consistent minimum height.
  static Widget primaryButton({
    required VoidCallback? onPressed,
    required Widget child,
    ButtonStyle? style,
  }) {
    return SizedBox(
      width: double.infinity,
      height: primaryButtonMinHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: style,
        child: child,
      ),
    );
  }
}
