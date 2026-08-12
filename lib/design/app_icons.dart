import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Single icon abstraction point for the template.
///
/// Screens reference semantic icon names through [AppIcons] instead of
/// scattering raw asset paths. Future custom icon sets can be swapped in
/// here without touching feature screens.
abstract final class AppIcons {
  static const String home = 'home';
  static const String profile = 'profile';
  static const String settings = 'settings';
  static const String search = 'search';
  static const String bell = 'bell';
  static const String calendar = 'calendar';
  static const String bookmark = 'bookmark';
  static const String history = 'history';
  static const String clock = 'clock';
  static const String more = 'more';
  static const String star = 'star';
  static const String heart = 'heart';
  static const String crown = 'crown';
  static const String rocket = 'rocket';
  static const String flash = 'flash';
  static const String target = 'target';
  static const String lock = 'lock';
  static const String unlock = 'unlock';
  static const String key = 'key';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String trash = 'trash';
  static const String edit = 'edit';
  static const String copy = 'copy';
  static const String share = 'share';
  static const String download = 'download';
  static const String upload = 'upload';
  static const String link = 'link';
  static const String send = 'send';
  static const String message = 'message';
  static const String chat = 'chat';
  static const String compose = 'compose';
  static const String note = 'note';
  static const String paperBlank = 'paper_blank';
  static const String paperNote = 'paper_note';
  static const String notebook = 'notebook';
  static const String checkAll = 'check_all';
  static const String tick = 'tick';
  static const String tickCircle = 'tick_circle';
  static const String x = 'x';
  static const String info = 'info';
  static const String warning = 'warning';
  static const String success = 'success';
  static const String emojiSmile = 'emoji_smile';
  static const String arrowLeft = 'arrow_left';
  static const String arrowRight = 'arrow_right';
}

/// Theme-aware SVG icon. The source SVGs use white strokes, so they are
/// recolored with [color] using srcIn blending.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.semanticsLabel,
  });

  final String icon;
  final double size;
  final Color? color;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      'lib/assets/icons/$icon.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      semanticsLabel: semanticsLabel ?? icon,
    );
  }
}
