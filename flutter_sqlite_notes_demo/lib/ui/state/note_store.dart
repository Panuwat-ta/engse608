import 'package:flutter/foundation.dart';
import '../../data/models/note.dart';
import '../../data/repositories/note_repository.dart';

class NoteStore extends ChangeNotifier {
  NoteStore(this._repo);

  final NoteRepository _repo;

  bool _loading = false;
  bool get loading => _loading;

  String? _error;
  String? get error => _error;

  List<Note> _notes = [];
  List<Note> get notes => List.unmodifiable(_notes);

  Future<void> loadNotes() async {
    _setLoading(true);
    try {
      _error = null;
      _notes = await _repo.getAllNotes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> addNote({required String title, required String content}) async {
    _setLoading(true);
    try {
      _error = null;
      final now = DateTime.now();
      final note = Note(
        title: title.trim(),
        content: content.trim(),
        createdAt: now,
        updatedAt: now,
      );
      await _repo.insertNote(note);
      _notes = await _repo.getAllNotes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> editNote({
    required int id,
    required String title,
    required String content,
  }) async {
    _setLoading(true);
    try {
      _error = null;
      final existing = await _repo.getNoteById(id);
      if (existing == null) {
        _error = 'ไม่พบโน้ตที่ต้องการแก้ไข';
        return;
      }
      final updated = existing.copyWith(
        title: title.trim(),
        content: content.trim(),
        updatedAt: DateTime.now(),
      );
      await _repo.updateNote(updated);
      _notes = await _repo.getAllNotes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeNote(int id) async {
    _setLoading(true);
    try {
      _error = null;
      await _repo.deleteNote(id);
      _notes = await _repo.getAllNotes();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> clearAll() async {
    _setLoading(true);
    try {
      _error = null;
      await _repo.deleteAll();
      _notes = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }
}
