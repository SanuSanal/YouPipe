import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:youpipe/ui/messenger.dart';
import 'package:youpipe/ui/widgets/common.dart';

void main() {
  // Flutter keeps a toast with an action up until it's tapped unless told otherwise; ours close by themselves.
  testWidgets('a global toast with an action (SponsorBlock Undo) closes by itself', (tester) async {
    await tester.pumpWidget(MaterialApp(scaffoldMessengerKey: scaffoldMessengerKey, home: const Scaffold()));
    showGlobalSnack('Skipped sponsor', action: 'Undo', onAction: () {});
    await tester.pumpAndSettle();
    expect(find.text('Skipped sponsor'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Skipped sponsor'), findsNothing);
  });

  testWidgets('a toast with an action raised from a widget closes by itself', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showSnack(context, 'Downloading…', action: 'View', onAction: () {}),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Downloading…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.text('Downloading…'), findsNothing);
  });
}
