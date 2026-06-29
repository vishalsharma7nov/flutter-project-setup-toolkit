/// User-facing product name for the unified studio (hub, desktop, browser).
const studioProductName = 'Flutter Project Setup Toolkit';

String studioBannerCenterLine({int width = 58}) {
  final name = studioProductName;
  if (name.length >= width) {
    return '║ $name ║';
  }
  final pad = width - name.length;
  final left = pad ~/ 2;
  final right = pad - left;
  return '║${' ' * left}$name${' ' * right}║';
}
