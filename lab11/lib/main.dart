import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lab11/services/notification_service.dart';
import 'package:lab11/ui/state/category_provider.dart';
import 'package:lab11/ui/state/event_provider.dart';
import 'package:lab11/ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Notifications
  await NotificationService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => EventProvider()),
      ],
      child: const EventReminderApp(),
    ),
  );
}

class EventReminderApp extends StatelessWidget {
  const EventReminderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Event & Reminder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
