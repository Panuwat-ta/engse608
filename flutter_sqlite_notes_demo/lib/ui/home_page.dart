import 'package:flutter/material.dart';
import 'package:flutter_sqlite_notes_demo/ui/note_form_page.dart';
import 'package:flutter_sqlite_notes_demo/ui/state/note_store.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // โหลดครั้งแรกหลัง build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NoteStore>().loadNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<NoteStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes (SQLite)'),
        actions: [
          IconButton(
            tooltip: 'ล้างทั้งหมด',
            onPressed: store.loading
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('ยืนยัน'),
                        content: const Text('ต้องการลบโน้ตทั้งหมดใช่ไหม?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('ยกเลิก'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('ลบ'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      await context.read<NoteStore>().clearAll();
                    }
                  },
            icon: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: store.loading
            ? null
            : () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NoteFormPage()),
                );
              },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (store.error != null)
              MaterialBanner(
                content: Text(store.error!),
                actions: [
                  TextButton(
                    onPressed: () => context.read<NoteStore>().loadNotes(),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            Expanded(
              child: store.loading
                  ? const Center(child: CircularProgressIndicator())
                  : store.notes.isEmpty
                  ? const Center(child: Text('ยังไม่มีโน้ต'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: store.notes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final n = store.notes[i];
                        return Card(
                          child: ListTile(
                            title: Text(
                              '${n.title} (${n.updatedAt.day.toString().padLeft(2, '0')}/${n.updatedAt.month.toString().padLeft(2, '0')}/${n.updatedAt.year} ${n.updatedAt.hour.toString().padLeft(2, '0')}:${n.updatedAt.minute.toString().padLeft(2, '0')})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              n.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  context.read<NoteStore>().removeNote(n.id!),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NoteFormPage(
                                    noteId: n.id,
                                    initialTitle: n.title,
                                    initialContent: n.content,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
