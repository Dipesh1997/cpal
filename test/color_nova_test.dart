import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paletteasian/color_detail_page.dart';
import 'package:paletteasian/main.dart';
import 'package:paletteasian/lightcolors.dart';
import 'package:paletteasian/mediumcolors.dart';
import 'package:paletteasian/darkcolors.dart';

void main() {
  group('Color Nova Page Number Tests', () {
    test('Verify LightColors matching color Nova pages', () {
      // 9436 has original page 1, Color Nova page 12
      final c9436 = LightColors.colors.firstWhere((c) => c['number'] == '9436');
      expect(c9436['page'], 1);
      expect(c9436['cNP'], 12);
      expect(c9436.containsKey('details'), isFalse);
      expect(c9436.containsKey('hex'), isFalse);

      // 8108 has original page 1, Color Nova page 116
      final c8108 = LightColors.colors.firstWhere((c) => c['number'] == '8108');
      expect(c8108['page'], 1);
      expect(c8108['cNP'], 116);
      expect(c8108.containsKey('details'), isFalse);
      expect(c8108.containsKey('hex'), isFalse);

      // L136 has page 8 in both, and has cNP 8
      final cL136 = LightColors.colors.firstWhere((c) => c['number'] == 'L136');
      expect(cL136['page'], 8);
      expect(cL136['cNP'], 8);
      expect(cL136.containsKey('details'), isFalse);
      expect(cL136.containsKey('hex'), isFalse);

      // L189 is not in colors.json, should NOT have cNP
      final cL189 = LightColors.colors.firstWhere((c) => c['number'] == 'L189');
      expect(cL189.containsKey('cNP'), isFalse);
      expect(cL189.containsKey('hex'), isFalse);
    });

    test('Verify MediumColors matching color Nova pages', () {
      // 9425 has page 26 in medium, 211 in Color Nova
      final c9425 = MediumColors.colors.firstWhere((c) => c['number'] == '9425');
      expect(c9425['page'], 26);
      expect(c9425['cNP'], 211);
      expect(c9425.containsKey('details'), isFalse);
      expect(c9425.containsKey('hex'), isFalse);

      // 0941 has page 171 in both, and has cNP 171
      final c0941 = MediumColors.colors.firstWhere((c) => c['number'] == '0941');
      expect(c0941['page'], 171);
      expect(c0941['cNP'], 171);
      expect(c0941.containsKey('details'), isFalse);
      expect(c0941.containsKey('hex'), isFalse);
    });

    test('Verify DarkColors matching color Nova pages', () {
      // 8093 has page 256 in dark, 115 in Color Nova
      final c8093 = DarkColors.colors.firstWhere((c) => c['number'] == '8093');
      expect(c8093['page'], 256);
      expect(c8093['cNP'], 115);
      expect(c8093.containsKey('details'), isFalse);
      expect(c8093.containsKey('hex'), isFalse);

      // X179 is not in colors.json, should not have cNP
      final cX179 = DarkColors.colors.firstWhere((c) => c['number'] == 'X179');
      expect(cX179.containsKey('cNP'), isFalse);
      expect(cX179.containsKey('hex'), isFalse);
    });

    testWidgets('ColorDetailPage shows Color Nova page number when present',
        (WidgetTester tester) async {
      final c9436 = LightColors.colors.firstWhere((c) => c['number'] == '9436');
      await tester.pumpWidget(
        MaterialApp(
          home: ColorDetailPage(
            color: {
              ...c9436,
              'tab': 'light',
            },
            allColors: const {},
            onFavoriteToggle: (_) {},
            isFavorite: false,
          ),
        ),
      );

      // Existing page in AppBar
      expect(find.text('Page 1'), findsOneWidget);

      // Color Nova page number in details card
      expect(find.text('Color Nova page number: 12'), findsOneWidget);
    });

    testWidgets(
        'ColorGridWithWheel shows Page and Color Nova in card when searching',
        (WidgetTester tester) async {
      final c9436 = LightColors.colors.firstWhere((c) => c['number'] == '9436');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorGridWithWheel(
              categoryColors: [c9436],
              category: 'light',
              onFavoriteToggle: (_) {},
              isFavorite: (_) => false,
              allColors: {
                'light': [c9436]
              },
              hexToColor: (hex) => const Color(0xFFF3EDE8),
              isSearchActive: true,
            ),
          ),
        ),
      );

      // Section header shows Page 1, but card does NOT display Page 1
      expect(find.text('Page 1'), findsOneWidget); // 1 header above grid, NOT inside card
      expect(find.text('Color Nova: 12'), findsOneWidget);
    });
  });
}
