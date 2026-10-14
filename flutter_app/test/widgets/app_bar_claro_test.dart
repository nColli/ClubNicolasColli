import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/src/theme/theme.dart';
import 'package:flutter_app/src/widgets/widgets.dart';

void main() {
  testWidgets('la flecha de volver es oscura aunque el tema sea oscuro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const Scaffold(appBar: AppBarClaro(titulo: 'Tu reserva')),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    final flecha = find.byType(BackButtonIcon);
    expect(flecha, findsOneWidget);
    expect(
      IconTheme.of(tester.element(flecha)).color,
      AppColors.lightTextPrimary,
    );
  });
}
