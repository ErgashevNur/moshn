import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum _Country { unknown, uzbekistan, russia }

class PlateInput extends StatefulWidget {
  final TextEditingController controller;

  const PlateInput({super.key, required this.controller});

  @override
  State<PlateInput> createState() => _PlateInputState();
}

class _PlateInputState extends State<PlateInput> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_rebuild);
    _focusNode.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    _focusNode.removeListener(_rebuild);
    _focusNode.dispose();
    super.dispose();
  }

  _Country get _country {
    final raw = widget.controller.text;
    if (raw.isEmpty) return _Country.unknown;
    return _isDigit(raw[0]) ? _Country.uzbekistan : _Country.russia;
  }

  bool _isDigit(String c) {
    final code = c.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  // "01A123EA" → region:"01", main:"A 123 EA"
  (String region, String main) _splitUz(String raw) {
    if (raw.length < 2) return (raw, '');
    final region = raw.substring(0, 2);
    final rest = raw.substring(2);
    if (rest.isEmpty) return (region, '');

    final buf = StringBuffer();
    int i = 0;

    // Letters (1–3)
    while (i < rest.length && !_isDigit(rest[i]) && i < 3) {
      buf.write(rest[i++]);
    }
    // 3 digits
    if (i < rest.length) {
      buf.write(' ');
      int dc = 0;
      while (i < rest.length && _isDigit(rest[i]) && dc < 3) {
        buf.write(rest[i++]);
        dc++;
      }
    }
    // Final 2 letters
    if (i < rest.length) {
      buf.write(' ');
      while (i < rest.length) { buf.write(rest[i++]); }
    }
    return (region, buf.toString());
  }

  // "A000AA77" → main:"A 000 AA", region:"77"
  (String main, String region) _splitRu(String raw) {
    final buf = StringBuffer();
    int i = 0;

    // 1 letter
    if (i < raw.length && !_isDigit(raw[i])) buf.write(raw[i++]);

    // 3 digits
    if (i < raw.length) {
      buf.write(' ');
      int dc = 0;
      while (i < raw.length && _isDigit(raw[i]) && dc < 3) {
        buf.write(raw[i++]);
        dc++;
      }
    }

    // 2 letters
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
    final raw = widget.controller.text;
    final focused = _focusNode.hasFocus;

    Widget plate;
    switch (_country) {
      case _Country.uzbekistan:
        final (region, main) = _splitUz(raw);
        plate = _UzPlate(key: const ValueKey('uz'), region: region, main: main, focused: focused);
      case _Country.russia:
        final (main, region) = _splitRu(raw);
        plate = _RuPlate(key: const ValueKey('ru'), main: main, region: region, focused: focused);
      case _Country.unknown:
        plate = _EmptyPlate(key: const ValueKey('empty'), focused: focused);
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(_focusNode),
      child: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: plate,
          ),
          SizedBox(
            height: 0,
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              style: const TextStyle(fontSize: 0, color: Colors.transparent),
              decoration: const InputDecoration(border: InputBorder.none),
              cursorColor: Colors.transparent,
              cursorWidth: 0,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(9),
                _UpperCaseFormatter(),
              ],
              textCapitalization: TextCapitalization.characters,
              keyboardType: TextInputType.visiblePassword,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  O'ZBEKISTON raqami
//  [ • 01 ║ A 123 EA  ≡ UZ ]
// ──────────────────────────────────────────────
class _UzPlate extends StatelessWidget {
  final String region; // "01"
  final String main;   // "A 123 EA"
  final bool focused;

  const _UzPlate({
    super.key,
    required this.region,
    required this.main,
    required this.focused,
  });

  @override
  Widget build(BuildContext context) {
    final plateStyle = GoogleFonts.robotoMono(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF0D0D0D),
      letterSpacing: 3,
      height: 1,
    );
    final dimStyle = plateStyle.copyWith(color: const Color(0xFFCCCCCC));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? const Color(0xFF1A6ED4) : const Color(0xFF111111),
          width: focused ? 2.5 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Chap: bolt + hudud kodi ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              color: Colors.white,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF555555),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    region.isEmpty ? '01' : region,
                    style: region.isEmpty ? dimStyle : plateStyle,
                  ),
                ],
              ),
            ),
            // ── Qalin vertikal chiziq ──
            Container(width: 3.5, color: const Color(0xFF111111)),
            // ── Markaziy matn ──
            Expanded(
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  main.isEmpty ? 'A 123 EA' : main,
                  style: main.isEmpty ? dimStyle : plateStyle,
                ),
              ),
            ),
            // ── O'ng: UZ badge ──
            Container(width: 1.5, color: const Color(0xFFDDDDDD)),
            _UzBadge(),
          ],
        ),
      ),
    );
  }
}

class _UzBadge extends StatelessWidget {
  const _UzBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bayroq: ko'k / oq / yashil
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              width: 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 7, color: const Color(0xFF1DAADF)),
                  Container(height: 2.5, color: Colors.white),
                  Container(height: 7, color: const Color(0xFF1DB55E)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'UZ',
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D0D0D),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  ROSSIYA raqami
//  [ A 000 AA │ RU flag │ 77 ]
// ──────────────────────────────────────────────
class _RuPlate extends StatelessWidget {
  final String main;   // "A 000 AA"
  final String region; // "77"
  final bool focused;

  const _RuPlate({
    super.key,
    required this.main,
    required this.region,
    required this.focused,
  });

  @override
  Widget build(BuildContext context) {
    final plateStyle = GoogleFonts.robotoMono(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF0D0D0D),
      letterSpacing: 3,
      height: 1,
    );
    final dimStyle = plateStyle.copyWith(color: const Color(0xFFCCCCCC));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? const Color(0xFF1A6ED4) : const Color(0xFF111111),
          width: focused ? 2.5 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Asosiy matn ──
            Expanded(
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  main.isEmpty ? 'A 000 AA' : main,
                  style: main.isEmpty ? dimStyle : plateStyle,
                ),
              ),
            ),
            // ── O'ng: RU badge ──
            Container(width: 1.5, color: const Color(0xFFDDDDDD)),
            _RuBadge(region: region),
          ],
        ),
      ),
    );
  }
}

class _RuBadge extends StatelessWidget {
  final String region;

  const _RuBadge({required this.region});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bayroq: oq / ko'k / qizil
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              width: 30,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 6, color: Colors.white,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFCCCCCC), width: 0.5),
                    ),
                  ),
                  Container(height: 6, color: const Color(0xFF0039A6)),
                  Container(height: 6, color: const Color(0xFFD52B1E)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'RUS',
            style: GoogleFonts.robotoMono(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0D0D0D),
              letterSpacing: 1,
            ),
          ),
          if (region.isNotEmpty) ...[
            const SizedBox(height: 1),
            Text(
              region,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D0D0D),
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
//  Bo'sh holat — hali raqam kiritilmagan
// ──────────────────────────────────────────────
class _EmptyPlate extends StatelessWidget {
  final bool focused;

  const _EmptyPlate({super.key, required this.focused});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? const Color(0xFF1A6ED4) : const Color(0xFFCCCCCC),
          width: focused ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '_ _ _ _ _ _ _ _ _',
          style: GoogleFonts.robotoMono(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFDDDDDD),
            letterSpacing: 4,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
