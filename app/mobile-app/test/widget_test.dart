// Prueba de humo básica de FisuraScan.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/widgets/confidence_ring.dart';

void main() {
  testWidgets('El anillo de confianza muestra el porcentaje y la etiqueta',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ConfidenceRing(
              value: 0.97,
              hasCrack: true,
              label: 'Con grieta',
            ),
          ),
        ),
      ),
    );

    // Deja avanzar la animación del anillo.
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.textContaining('%'), findsOneWidget);
    expect(find.text('Con grieta'), findsOneWidget);
  });
}
