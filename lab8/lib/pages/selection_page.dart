import 'package:flutter/material.dart';

class SelectionPage extends StatefulWidget {
  const SelectionPage({super.key});

  @override
  State<SelectionPage> createState() => _SelectionPageState();
}

class _SelectionPageState extends State<SelectionPage> {

  bool isChecked = false;
  bool isSwitched = false;
  String gender = 'Male';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selection'),
      ),

      body: Column(
        children: [

          CheckboxListTile(
            title: const Text('Accept Terms'),
            value: isChecked,

            onChanged: (value) {
              setState(() {
                isChecked = value!;
              });
            },
          ),

          SwitchListTile(
            title: const Text('Enable Notification'),
            value: isSwitched,

            onChanged: (value) {
              setState(() {
                isSwitched = value;
              });
            },
          ),

          RadioListTile(
            title: const Text('Male'),
            value: 'Male',
            groupValue: gender,

            onChanged: (value) {
              setState(() {
                gender = value!;
              });
            },
          ),

          RadioListTile(
            title: const Text('Female'),
            value: 'Female',
            groupValue: gender,

            onChanged: (value) {
              setState(() {
                gender = value!;
              });
            },
          ),
        ],
      ),
    );
  }
}
