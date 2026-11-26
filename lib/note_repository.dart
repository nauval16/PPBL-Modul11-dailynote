import 'package:supabase_flutter/supabase_flutter.dart';

typedef Note = Map<String, dynamic>;

class NoteRepository {
  final _db = Supabase.instance.client;

  Future<List<Note>> list() async {
    return await _db
        .from('catatan')
        .select('id, judul, isi, tanggal')
        .order('created_at', ascending: false)
        .order('id', ascending: false);
  }

  Future<void> add(String title, String body) async {
    final now = DateTime.now();
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    await _db.from('catatan').insert({
      'judul': title,
      'isi': body,
      'tanggal': '$year-$month-$day',
    });
  }

  Future<void> edit(int id, String title, String body) async {
    final result = await _db
        .from('catatan')
        .update({'judul': title, 'isi': body})
        .eq('id', id)
        .select('id')
        .maybeSingle();
    if (result == null) throw StateError('Catatan tidak dapat diubah.');
  }

  Future<void> remove(int id) async {
    final result = await _db
        .from('catatan')
        .delete()
        .eq('id', id)
        .select('id')
        .maybeSingle();
    if (result == null) throw StateError('Catatan tidak dapat dihapus.');
  }
}
