import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Exact SVG icons from the Moshn/Shina24 design system (moshn-icons.jsx)
// Stroke icons: strokeWidth=1.8, round caps/joins, 24x24 viewBox
class MoshnIcon extends StatelessWidget {
  const MoshnIcon({super.key, required this.name, this.size = 24, this.color});

  final String name;
  final double size;
  final Color? color;

  // SVG path bodies; stroke color is injected at render time.
  // Fill icons use fill="C"; stroke icons use stroke="C".
  static const Map<String, String> _icons = {
    'snow': '''
      <path d="M12 3v18M5 7.5l14 9M19 7.5l-14 9" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M9.5 4.5L12 6l2.5-1.5M9.5 19.5L12 18l2.5 1.5" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'gauge': '''
      <path d="M4 18a8 8 0 1116 0" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M12 18l4-5" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
      <circle cx="12" cy="18" r="1.2" fill="C" stroke="none"/>
    ''',
    'wrench': '''
      <path d="M15 6.5a3.5 3.5 0 00-4.6 4.3l-5.6 5.6a1.5 1.5 0 002.1 2.1l5.6-5.6A3.5 3.5 0 0017.5 9l-2 2-2-2 2-2z" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'disc': '''
      <circle cx="12" cy="12" r="8.5" stroke="C" stroke-width="1.8" fill="none"/>
      <circle cx="12" cy="12" r="3" stroke="C" stroke-width="1.8" fill="none"/>
      <path d="M12 3.5v3M12 17.5v3M3.5 12h3M17.5 12h3" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
    ''',
    'layers': '''
      <path d="M12 3l9 5-9 5-9-5 9-5z" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M3 13l9 5 9-5" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'home': '''
      <path d="M3 11l9-7 9 7" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M5 10v9a1 1 0 001 1h12a1 1 0 001-1v-9" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'calendar': '''
      <rect x="3.5" y="5" width="17" height="16" rx="3" stroke="C" stroke-width="1.8" fill="none"/>
      <path d="M3.5 9.5h17M8 3v4M16 3v4" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
    ''',
    'car': '''
      <path d="M5 11l1.6-4.2A2 2 0 018.5 5.5h7a2 2 0 011.9 1.3L19 11" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M4 11h16a1 1 0 011 1v4a1 1 0 01-1 1h-1v1.5a1 1 0 01-1 1h-1a1 1 0 01-1-1V17H9v1.5a1 1 0 01-1 1H7a1 1 0 01-1-1V17H5a1 1 0 01-1-1v-4a1 1 0 011-1z" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <circle cx="7.5" cy="14" r="1" fill="C" stroke="none"/>
      <circle cx="16.5" cy="14" r="1" fill="C" stroke="none"/>
    ''',
    'user': '''
      <circle cx="12" cy="8" r="4" stroke="C" stroke-width="1.8" fill="none"/>
      <path d="M4 20c0-3.5 3.5-6 8-6s8 2.5 8 6" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
    ''',
    'pin': '''
      <path d="M12 21s7-5.5 7-11a7 7 0 10-14 0c0 5.5 7 11 7 11z" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <circle cx="12" cy="10" r="2.5" stroke="C" stroke-width="1.8" fill="none"/>
    ''',
    'chevD': '''
      <path d="M5 9l7 7 7-7" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'chevR': '''
      <path d="M9 5l7 7-7 7" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'chevL': '''
      <path d="M15 5l-7 7 7 7" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'bell': '''
      <path d="M18 9a6 6 0 10-12 0c0 6-2.5 7-2.5 7h17S18 15 18 9z" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M10.5 20a2 2 0 003 0" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
    ''',
    'search': '''
      <circle cx="11" cy="11" r="7" stroke="C" stroke-width="1.8" fill="none"/>
      <path d="M21 21l-4.3-4.3" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
    ''',
    'starFill': '''
      <path d="M12 3.5l2.6 5.3 5.9.9-4.3 4.1 1 5.8-5.2-2.7-5.2 2.7 1-5.8L3.5 9.7l5.9-.9z" fill="C" stroke="none"/>
    ''',
    'crown': '''
      <path d="M4 18h16M4 18l-1.5-9 5 4 4.5-7 4.5 7 5-4L20 18" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'location': '''
      <circle cx="12" cy="12" r="3" stroke="C" stroke-width="1.8" fill="none"/>
      <path d="M12 2v3M12 19v3M2 12h3M19 12h3" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
    ''',
  };

  String _toHex(Color c) {
    final r = c.red.toRadixString(16).padLeft(2, '0');
    final g = c.green.toRadixString(16).padLeft(2, '0');
    final b = c.blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFFFFFFF);
    final hex = _toHex(c);
    final body = (_icons[name] ?? '').replaceAll('"C"', '"$hex"');
    final svg =
        '<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">$body</svg>';

    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
