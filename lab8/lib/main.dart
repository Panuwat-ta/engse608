import 'package:flutter/material.dart';

import 'home_page.dart';
import 'pages/communication_page.dart';
import 'pages/containment_page.dart';
import 'pages/navigation_page.dart';
import 'pages/selection_page.dart';
import 'pages/textinput_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material Widgets Demo',
      theme: ThemeData(
        useMaterial3: true,
      ),

      initialRoute: '/',

      routes: {
        '/': (context) => const HomePage(),
        '/communication': (context) => const CommunicationPage(),
        '/containment': (context) => const ContainmentPage(),
        '/navigation': (context) => const NavigationPageDemo(),
        '/selection': (context) => const SelectionPage(),
        '/textinput': (context) => const TextInputPage(),
      },
    );
  }
}
