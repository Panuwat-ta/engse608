import 'package:flutter/material.dart';

class ActionsPage extends StatelessWidget {
  const ActionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Actions')),
      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              'Example: ElevatedButton',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            ElevatedButton(
              onPressed: () {},
              child: const Text('Click Me'),
            ),

            const SizedBox(height: 20),

            const Text('Code Example:'),

            const SelectableText(
'''
ElevatedButton(
  onPressed: () {},
  child: Text('Click Me'),
)
''',
            ),
          ],
        ),
      ),
    );
  }
}
