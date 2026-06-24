import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum _Country { uzbekistan, russia, unknown }

/// Виджет, отображающий госномер в реалистичном виде.
/// По первому символу автоматически выбирается дизайн Узбекистана или России.
class MPlate extends StatelessWidget {
  final String plate;

  /// true = крупный (внутри карточки), false = мелкий (в списке)
  final bool large;

  const MPlate({super.key, required this.plate, this.large = false});

  static bool _isDigit(String c) {
    final code = c.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  _Country get _country {
    final raw = plate.trim();
    if (raw.isEmpty) return _Country.unknown;
    return _isDigit(raw[0]) ? _Country.uzbekistan : _Country.russia;
  }

  // "01A123EA" → ("01", "A 123 EA")
  (String, String) get _uzParts {
    final raw = plate.toUpperCase().trim();
    if (raw.length < 2) return (raw, '');
    final region = raw.substring(0, 2);
    final rest = raw.substring(2);
    if (rest.isEmpty) return (region, '');

    final buf = StringBuffer();
    int i = 0;
    while (i < rest.length && !_isDigit(rest[i]) && i < 3) {
      buf.write(rest[i++]);
    }
    if (i < rest.length) {
      buf.write(' ');
      int dc = 0;
      while (i < rest.length && _isDigit(rest[i]) && dc < 3) {
        buf.write(rest[i++]);
        dc++;
      }
    }
    if (i < rest.length) {
      buf.write(' ');
      while (i < rest.length) { buf.write(rest[i++]); }
    }
    return (region, buf.toString());
  }

  // "A000AA77" → ("A 000 AA", "77")
  (String, String) get _ruParts {
    final raw = plate.toUpperCase().trim();
    final buf = StringBuffer();
    int i = 0;
    if (i < raw.length && !_isDigit(raw[i])) buf.write(raw[i++]);
    if (i < raw.length) {
      buf.write(' ');
      int dc = 0;
      while (i < raw.length && _isDigit(raw[i]) && dc < 3) {
        buf.write(raw[i++]);
        dc++;
      }
    }
    if (i < raw.length && !_isDigit(raw[i])) {
      buf.write(' ');
      int lc = 0;
      while (i < raw.length && !_isDigit(raw[i]) && lc < 2) {
        buf.write(raw[i++]);
        lc++;
      }
    }
    final region = i < raw.length ? raw.substring(i) : '';
    return (buf.toString(), region);
  }

  @override
  Widget build(BuildContext context) {
    switch (_country) {
      case _Country.uzbekistan:
        final (region, main) = _uzParts;
        return _UzPlateDisplay(region: region, main: main, large: large);
      case _Country.russia:
        final (main, region) = _ruParts;
        return _RuPlateDisplay(main: main, region: region, large: large);
      case _Country.unknown:
        return _PlainPlate(text: plate.isEmpty ? '—' : plate.toUpperCase(), large: large);
    }
  }
}

// ─────────────────────────────────────────
//  УЗБЕКИСТАН  [ • 01 ║ A 123 EA  ≡ UZ ]
// ─────────────────────────────────────────
class _UzPlateDisplay extends StatelessWidget {
  final String region;
  final String main;
  final bool large;

  const _UzPlateDisplay({
    required this.region,
    required this.main,
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    final h = large ? 82.0 : 48.0;
    final mainFz = large ? 26.0 : 16.0;
    final regionFz = large ? 24.0 : 15.0;
    final badgeW = large ? 50.0 : 32.0;

    final textStyle = GoogleFonts.robotoMono(
      fontSize: mainFz,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF0D0D0D),
      letterSpacing: large ? 3 : 2,
      height: 1,
    );

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(large ? 10 : 7),
        border: Border.all(color: const Color(0xFF111111), width: large ? 2 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: large ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(large ? 9 : 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Слева: точка + код региона
            Container(
              padding: EdgeInsets.symmetric(horizontal: large ? 10 : 6),
              color: Colors.white,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: large ? 7 : 5,
                    height: large ? 7 : 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF555555),
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: large ? 6 : 4),
                  Text(
                    region.isEmpty ? '01' : region,
                    style: textStyle.copyWith(
                      fontSize: regionFz,
                      color: region.isEmpty
                          ? const Color(0xFFCCCCCC)
                          : const Color(0xFF0D0D0D),
                    ),
                  ),
                ],
              ),
            ),
            // Толстый разделитель
            Container(width: large ? 3.5 : 2.5, color: const Color(0xFF111111)),
            // Основной текст
            Padding(
              padding: EdgeInsets.symmetric(horizontal: large ? 14 : 8),
              child: Center(
                child: Text(
                  main.isEmpty ? 'A 123 EA' : main,
                  style: textStyle.copyWith(
                    color: main.isEmpty
                        ? const Color(0xFFCCCCCC)
                        : const Color(0xFF0D0D0D),
                  ),
                ),
              ),
            ),
            // Тонкая линия
            Container(width: 1, color: const Color(0xFFDDDDDD)),
            // UZ badge
            _UzBadgeDisplay(large: large, width: badgeW),
          ],
        ),
      ),
    );
  }
}

class _UzBadgeDisplay extends StatelessWidget {
  final bool large;
  final double width;

  const _UzBadgeDisplay({required this.large, required this.width});

  @override
  Widget build(BuildContext context) {
    final flagW = large ? 28.0 : 18.0;
    final flagH1 = large ? 7.0 : 4.5;
    final flagM = large ? 2.5 : 1.5;
    final uzFz = large ? 11.0 : 8.0;

    return Container(
      width: width,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: flagW,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: flagH1, color: const Color(0xFF1DAADF)),
                  Container(height: flagM, color: Colors.white),
                  Container(height: flagH1, color: const Color(0xFF1DB55E)),
                ],
              ),
            ),
          ),
          SizedBox(height: large ? 4 : 2),
          Text(
            'UZ',
            style: GoogleFonts.robotoMono(
              fontSize: uzFz,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D0D0D),
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  ROSSIYA  [ A 000 AA │ RUS flag │ 77 ]
// ─────────────────────────────────────────
class _RuPlateDisplay extends StatelessWidget {
  final String main;
  final String region;
  final bool large;

  const _RuPlateDisplay({
    required this.main,
    required this.region,
    required this.large,
  });

  @override
  Widget build(BuildContext context) {
    final h = large ? 82.0 : 48.0;
    final mainFz = large ? 26.0 : 16.0;
    final badgeW = large ? 56.0 : 38.0;

    final textStyle = GoogleFonts.robotoMono(
      fontSize: mainFz,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF0D0D0D),
      letterSpacing: large ? 3 : 2,
      height: 1,
    );

    return Container(
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(large ? 10 : 7),
        border: Border.all(color: const Color(0xFF111111), width: large ? 2 : 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: large ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(large ? 9 : 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Основной текст
            Padding(
              padding: EdgeInsets.symmetric(horizontal: large ? 16 : 10),
              child: Center(
                child: Text(
                  main.isEmpty ? 'A 000 AA' : main,
                  style: textStyle.copyWith(
                    color: main.isEmpty
                        ? const Color(0xFFCCCCCC)
                        : const Color(0xFF0D0D0D),
                  ),
                ),
              ),
            ),
            // Тонкая линия
            Container(width: 1, color: const Color(0xFFDDDDDD)),
            // RUS badge
            _RuBadgeDisplay(region: region, large: large, width: badgeW),
          ],
        ),
      ),
    );
  }
}

class _RuBadgeDisplay extends StatelessWidget {
  final String region;
  final bool large;
  final double width;

  const _RuBadgeDisplay({
    required this.region,
    required this.large,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final flagW = large ? 28.0 : 18.0;
    final bandH = large ? 6.0 : 4.0;
    final rusFz = large ? 10.0 : 7.0;
    final regFz = large ? 11.0 : 8.0;

    return Container(
      width: width,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: flagW,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: bandH,
                    color: Colors.white,
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDDDDDD), width: 0.5),
                    ),
                  ),
                  Container(height: bandH, color: const Color(0xFF0039A6)),
                  Container(height: bandH, color: const Color(0xFFD52B1E)),
                ],
              ),
            ),
          ),
          SizedBox(height: large ? 3 : 2),
          Text(
            'RUS',
            style: GoogleFonts.robotoMono(
              fontSize: rusFz,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D0D0D),
              letterSpacing: 0.5,
            ),
          ),
          if (region.isNotEmpty)
            Text(
              region,
              style: GoogleFonts.robotoMono(
                fontSize: regFz,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D0D0D),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
//  Неизвестный формат — простое отображение
// ─────────────────────────────────────────
class _PlainPlate extends StatelessWidget {
  final String text;
  final bool large;

  const _PlainPlate({required this.text, required this.large});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 9,
        vertical: large ? 7 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F2),
        borderRadius: BorderRadius.circular(large ? 8 : 6),
        border: Border.all(color: const Color(0x33000000)),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), offset: Offset(0, 1), blurRadius: 3),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.robotoMono(
          fontSize: large ? 18 : 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111111),
        ),
      ),
    );
  }
}
