import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Exact SVG icons from the PitGo design system
// Stroke icons: strokeWidth=1.8, round caps/joins, 24x24 viewBox
class PitGoIcon extends StatelessWidget {
  const PitGoIcon({super.key, required this.name, this.size = 24, this.color});

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
    // Балансировка
    'balance': '''
      <path d="M12 3v4M8 21h8M12 7v14" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
      <path d="M5 8h14" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
      <path d="M5 8l-2.5 5a2.5 2.5 0 005 0L5 8z" stroke="C" stroke-width="1.6" stroke-linejoin="round" fill="none"/>
      <path d="M19 8l-2.5 5a2.5 2.5 0 005 0L19 8z" stroke="C" stroke-width="1.6" stroke-linejoin="round" fill="none"/>
    ''',
    // Ремонт дисков
    'diskWrench': '''
      <circle cx="10" cy="14" r="6" stroke="C" stroke-width="1.8" fill="none"/>
      <circle cx="10" cy="14" r="2" stroke="C" stroke-width="1.8" fill="none"/>
      <path d="M15.5 4.5a3 3 0 00-3.9 3.9l-1 1 2 2 1-1a3 3 0 003.9-3.9l-1.5 1.5-2-2 1.5-1.5z" stroke="C" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    // Подкачка
    'pump': '''
      <rect x="5" y="4" width="6" height="10" rx="1.5" stroke="C" stroke-width="1.8" fill="none"/>
      <path d="M8 4V2.3M8 14v3M8 17h6a2 2 0 012 2v2" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <circle cx="18" cy="19.7" r="1.3" fill="C" stroke="none"/>
    ''',
    // Перезобувка
    'tireSwap': '''
      <circle cx="12" cy="12" r="7" stroke="C" stroke-width="1.8" fill="none"/>
      <circle cx="12" cy="12" r="2.5" stroke="C" stroke-width="1.8" fill="none"/>
      <path d="M12 3a9 9 0 018.5 6" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
      <path d="M18 6.5l2.5 2.5 1-3.3" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M12 21a9 9 0 01-8.5-6" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
      <path d="M6 17.5l-2.5-2.5-1 3.3" stroke="C" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    // Хранение шин
    'tireStack': '''
      <ellipse cx="12" cy="6" rx="7" ry="3" stroke="C" stroke-width="1.8" fill="none"/>
      <ellipse cx="12" cy="6" rx="2.5" ry="1.1" stroke="C" stroke-width="1.8" fill="none"/>
      <path d="M5 6v6c0 1.66 3.13 3 7 3s7-1.34 7-3V6" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
      <path d="M5 12v6c0 1.66 3.13 3 7 3s7-1.34 7-3v-6" stroke="C" stroke-width="1.8" stroke-linecap="round" fill="none"/>
    ''',
    // Вулканизация
    'flame': '''
      <path d="M12 3c3 3 5 6 5 9a5 5 0 11-10 0c0-1 .3-2 1-3 .2 1.2 1 2 1 2-.4-2.5.8-4.5 2-6-.3 1.3.2 2.2 1 2.6-.6-1.7 0-3.3 0-4.6z" stroke="C" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" fill="none"/>
    ''',
    // ── Quyidagilar admin panel (xizmat turlari) icon-tanlagichi bilan bir
    // xil nomlar — ServiceType.icon maydoni to'g'ridan-to'g'ri shu kalitlarga
    // mos kelishi kerak (Backend/admin/src/app/service-types/page.tsx).
    'wheel': '''
      <circle cx="12" cy="12" r="10" stroke="C" stroke-width="1.6" fill="none"/>
      <circle cx="12" cy="12" r="3" stroke="C" stroke-width="1.6" fill="none"/>
      <line x1="12" y1="2" x2="12" y2="9" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="12" y1="15" x2="22" y2="12" transform="rotate(60 12 12)" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="12" y1="15" x2="22" y2="12" transform="rotate(-60 12 12)" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
    ''',
    'alignment': '''
      <path d="M3 6h18M3 12h18M3 18h18" stroke="C" stroke-width="1.6" stroke-linecap="round" fill="none"/>
      <path d="M8 3l-5 3 5 3" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M16 15l5 3-5 3" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'snowflake': '''
      <line x1="12" y1="2" x2="12" y2="22" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <path d="M17 7l-5 5-5-5" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M17 17l-5-5-5 5" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <line x1="2" y1="12" x2="22" y2="12" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <path d="M7 7l5 5 5-5" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M7 17l5-5 5 5" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'sun': '''
      <circle cx="12" cy="12" r="5" stroke="C" stroke-width="1.6" fill="none"/>
      <line x1="12" y1="1" x2="12" y2="3" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="12" y1="21" x2="12" y2="23" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="4.22" y1="4.22" x2="5.64" y2="5.64" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="18.36" y1="18.36" x2="19.78" y2="19.78" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="1" y1="12" x2="3" y2="12" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="21" y1="12" x2="23" y2="12" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="4.22" y1="19.78" x2="5.64" y2="18.36" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="18.36" y1="5.64" x2="19.78" y2="4.22" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
    ''',
    'rim': '''
      <circle cx="12" cy="12" r="10" stroke="C" stroke-width="1.6" fill="none"/>
      <circle cx="12" cy="12" r="4" stroke="C" stroke-width="1.6" fill="none"/>
      <line x1="12" y1="2" x2="12" y2="8" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="12" y1="16" x2="12" y2="22" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="2" y1="12" x2="8" y2="12" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="16" y1="12" x2="22" y2="12" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="4.93" y1="4.93" x2="9.17" y2="9.17" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <line x1="14.83" y1="14.83" x2="19.07" y2="19.07" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
    ''',
    'shield': '''
      <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'check': '''
      <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" stroke="C" stroke-width="1.6" stroke-linecap="round" fill="none"/>
      <polyline points="22 4 12 14.01 9 11.01" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'clock': '''
      <circle cx="12" cy="12" r="10" stroke="C" stroke-width="1.6" fill="none"/>
      <polyline points="12 6 12 12 16 14" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'zap': '''
      <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'droplet': '''
      <path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'settings': '''
      <circle cx="12" cy="12" r="3" stroke="C" stroke-width="1.6" fill="none"/>
      <path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'tool': '''
      <path d="M3 3l7.07 16.97 2.51-7.39 7.39-2.51L3 3z" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <path d="M13 13l6 6" stroke="C" stroke-width="1.6" stroke-linecap="round" fill="none"/>
    ''',
    'star': '''
      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
    ''',
    'package': '''
      <line x1="16.5" y1="9.4" x2="7.5" y2="4.21" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
      <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <polyline points="3.27 6.96 12 12.01 20.73 6.96" stroke="C" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
      <line x1="12" y1="22.08" x2="12" y2="12" stroke="C" stroke-width="1.6" stroke-linecap="round"/>
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
    // Noma'lum/hali qo'shilmagan icon nomi kelsa (masalan admin yangi
    // xizmat turi qo'shganda) — bo'sh joy o'rniga umumiy "wrench" ko'rsatiladi.
    final body = (_icons[name] ?? _icons['wrench']!).replaceAll('"C"', '"$hex"');
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
