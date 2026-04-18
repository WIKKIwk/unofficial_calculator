import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notif_hub/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const NotifRoot());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
