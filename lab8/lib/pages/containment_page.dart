import 'package:flutter/material.dart';

class ContainmentPage extends StatelessWidget {
  const ContainmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Containment'),
      ),

      body: Center(
        child: Card(
          elevation: 5,

          child: Container(
            width: 250,
            height: 150,
            padding: const EdgeInsets.all(16),

            child: const Center(
              child: Text(
                'This is inside Card',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
