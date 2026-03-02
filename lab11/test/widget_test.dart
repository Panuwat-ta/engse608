// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:provider/provider.dart';
import 'package:lab11/ui/state/category_provider.dart';
import 'package:lab11/ui/state/event_provider.dart';
import 'package:lab11/services/notification_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:lab11/main.dart';

void main() {
  setUpAll(() async {
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;

    WidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => EventProvider()),
        ],
        child: const EventReminderApp(),
      ),
    );

    // Verify that the title of the app appears
    expect(find.text('Events & Reminders'), findsOneWidget);
  });
}
