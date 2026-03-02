import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/note_store.dart';

class NoteFormPage extends StatefulWidget {
  const NoteFormPage({
    super.key,
    this.noteId,
    this.initialTitle,
    this.initialContent,
  });

  final int? noteId;
  final String? initialTitle;
  final String? initialContent;

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtl;
  late final TextEditingController _contentCtl;

  @override
  void initState() {
    super.initState();
    _titleCtl = TextEditingController(text: widget.initialTitle ?? '');
    _contentCtl = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  void dispose() {
    _titleCtl.dispose();
    _contentCtl.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.noteId != null;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NoteStore>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'แก้ไขโน้ต' : 'เพิ่มโน้ต')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _titleCtl,
                  decoration: const InputDecoration(
                    labelText: 'หัวข้อ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'กรุณากรอกหัวข้อ';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentCtl,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'รายละเอียด',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'กรุณากรอกรายละเอียด';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: store.loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;

                          final title = _titleCtl.text;
                          final content = _contentCtl.text;

                          if (_isEdit) {
                            await context.read<NoteStore>().editNote(
                              id: widget.noteId!,
                              title: title,
                              content: content,
                            );
                          } else {
                            await context.read<NoteStore>().addNote(
                              title: title,
                              content: content,
                            );
                          }

                          if (context.mounted) Navigator.pop(context);
                        },
                  icon: const Icon(Icons.save),
                  label: Text(_isEdit ? 'บันทึกการแก้ไข' : 'บันทึก'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
