import 'package:catequesis/design/borgona_theme.dart';
import 'package:catequesis/design/module_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness({bool reducedMotion = false}) => MaterialApp(
  theme: Borgona.theme,
  home: StatefulBuilder(
    builder: (context, setState) {
      // The host below owns the selected module independently of animation.
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
        child: const _Host(),
      );
    },
  ),
);

class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Text('Contenido $index')),
    bottomNavigationBar: ModuleNavigation(
      labels: const ['Perfil', 'Grupos', 'Lecciones', 'Clases', 'Reportes'],
      icons: const [
        Icons.person,
        Icons.groups,
        Icons.menu_book,
        Icons.event,
        Icons.assessment,
      ],
      selectedIndex: index,
      onChanged: (value) => setState(() => index = value),
    ),
  );
}

double lift(WidgetTester tester, int index) => tester
    .widget<Transform>(find.byKey(ValueKey('module-lift-$index')))
    .transform
    .storage[13];
void main() {
  testWidgets(
    'salto largo levanta los intermedios por orden y activa al llegar',
    (tester) async {
      await tester.pumpWidget(harness());
      await tester.tap(find.byKey(const ValueKey('module-tap-4')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(lift(tester, 1), lessThan(0));
      expect(lift(tester, 2), 0);
      expect(lift(tester, 3), 0);
      expect(find.text('Contenido 0'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 90));
      expect(lift(tester, 2), lessThan(0));
      expect(lift(tester, 3), 0);
      await tester.pump(const Duration(milliseconds: 90));
      expect(lift(tester, 3), lessThan(0));
      await tester.pumpAndSettle();
      expect(find.text('Contenido 4'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('module-tap-0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(lift(tester, 3), lessThan(0));
      expect(lift(tester, 2), 0);
      await tester.pumpAndSettle();
      expect(find.text('Contenido 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('toques durante la animación respetan el último destino', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.tap(find.byKey(const ValueKey('module-tap-4')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('module-tap-1')));
    await tester.pumpAndSettle();
    expect(find.text('Contenido 1'), findsOneWidget);
  });
  testWidgets(
    'movimiento reducido cambia de módulo de inmediato en ancho pequeño',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(harness(reducedMotion: true));
      await tester.tap(find.byKey(const ValueKey('module-tap-4')));
      await tester.pump();
      expect(find.text('Contenido 4'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
