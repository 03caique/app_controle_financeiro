import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_controle_financeiro/main.dart';

void main() {
  testWidgets('App inicia e mostra a tela de login', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Controle Financeiro'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}