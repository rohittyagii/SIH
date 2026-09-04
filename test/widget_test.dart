import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sainik_saathi/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SainikSaathiApp()));
    await tester.pump();
    // App renders without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
