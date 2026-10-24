import 'package:catequesis/design/borgona_theme.dart';
import 'package:catequesis/settings_screen.dart';
import 'package:catequesis/help_screen.dart';
import 'package:catequesis/user_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Borgona.darkMode.value = false;
  });
  tearDown(() {
    Borgona.darkMode.value = false;
  });
  testWidgets(
    'modo oscuro se aplica sin salir de ajustes y persiste al reiniciar',
    (tester) async {
      await tester.pumpWidget(
        ValueListenableBuilder<bool>(
          valueListenable: Borgona.darkMode,
          builder: (context, dark, child) =>
              MaterialApp(theme: Borgona.theme, home: const SettingsScreen()),
        ),
      );
      expect(Borgona.theme.brightness, Brightness.light);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(Borgona.theme.brightness, Brightness.dark);
      expect(find.text('Configuraciones'), findsOneWidget);
      expect(find.text('Proximamente'), findsNWidgets(2));
      expect(
        (await SharedPreferences.getInstance()).getBool('dark_mode'),
        true,
      );
      Borgona.darkMode.value = false;
      await Borgona.loadPreferences();
      expect(Borgona.darkMode.value, true);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('ayuda muestra los módulos correctos según el rol', (
    tester,
  ) async {
    for (final superior in [true, false]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: Borgona.theme,
          home: HelpScreen(superior: superior),
        ),
      );
      expect(
        find.text(
          superior ? 'Ayuda para el superior' : 'Ayuda para el catequista',
        ),
        findsOneWidget,
      );
      expect(find.text(superior ? 'Grupos' : 'Mis grupos'), findsOneWidget);
      expect(find.text(superior ? 'Mensajes' : 'Reportes'), findsNothing);
    }
  });
  testWidgets(
    'crear catequista valida antes de crear una cuenta y cabe en un teléfono pequeño',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: Borgona.theme,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showCatequistaForm(context),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Crear catequista'));
      await tester.pump();
      expect(find.text('Escribe el nombre'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
