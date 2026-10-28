import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:locintel_shop/main.dart';

void main() {
  testWidgets('App LOCINTEL Shop starts', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('LOCINTEL Shop'))));
    expect(find.text('LOCINTEL Shop'), findsOneWidget);
  });
}
