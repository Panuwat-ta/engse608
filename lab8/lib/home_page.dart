import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Widgets'),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          _menu(context, 'Communication', '/communication'),
          _menu(context, 'Containment', '/containment'),
          _menu(context, 'Navigation', '/navigation'),
          _menu(context, 'Selection', '/selection'),
          _menu(context, 'Text Input', '/textinput'),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, String title, String route) {
    return Card(
      child: ListTile(
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.pushNamed(context, route);
        },
      ),
    );
  }
}
