import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'note_repository.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final repo = NoteRepository();
  final form = GlobalKey<FormState>();
  final title = TextEditingController();
  final body = TextEditingController();
  late Future<List<Note>> notes;
  int? editingId;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    notes = repo.list();
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  void refresh() => setState(() => notes = repo.list());

  void resetForm() {
    form.currentState?.reset();
    title.clear();
    body.clear();
    editingId = null;
  }

  void startEdit(Note note) {
    setState(() {
      form.currentState?.reset();
      editingId = note['id'] as int;
      title.text = note['judul'] as String;
      body.text = note['isi'] as String;
    });
  }

  Future<void> runAction(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      final text = switch (error) {
        PostgrestException e => e.message,
        AuthException e => e.message,
        StateError e => e.message.toString(),
        _ => 'Permintaan gagal. Periksa koneksi dan coba lagi.',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    final id = editingId;
    final judul = title.text.trim();
    final isi = body.text.trim();
    await runAction(() async {
      if (id == null) {
        await repo.add(judul, isi);
      } else {
        await repo.edit(id, judul, isi);
      }
      if (!mounted) return;
      resetForm();
      refresh();
    });
  }

  Future<void> confirmDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Hapus catatan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await runAction(() async {
      await repo.remove(id);
      if (!mounted) return;
      if (editingId == id) resetForm();
      refresh();
    });
  }

  String? requiredText(String? value) =>
      (value ?? '').trim().isEmpty ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('DailyNote'),
      actions: [
        IconButton(
          tooltip: 'Muat ulang',
          icon: const Icon(Icons.refresh),
          onPressed: busy ? null : refresh,
        ),
        TextButton(
          onPressed: busy
              ? null
              : () => runAction(() => Supabase.instance.client.auth.signOut()),
          child: const Text('Keluar'),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: form,
          child: Column(
            children: [
              Text(editingId == null ? 'Tambah catatan' : 'Edit catatan'),
              TextFormField(
                controller: title,
                enabled: !busy,
                maxLength: 100,
                validator: requiredText,
                decoration: const InputDecoration(labelText: 'Judul'),
              ),
              TextFormField(
                controller: body,
                enabled: !busy,
                maxLength: 2000,
                maxLines: 3,
                validator: requiredText,
                decoration: const InputDecoration(labelText: 'Isi catatan'),
              ),
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(busy ? 'Memproses...' : 'Simpan'),
              ),
              if (editingId != null)
                TextButton(
                  onPressed: busy ? null : () => setState(resetForm),
                  child: const Text('Batal edit'),
                ),
            ],
          ),
        ),
        const Divider(),
        FutureBuilder<List<Note>>(
          future: notes,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return const Text('Gagal memuat. Tekan ikon Muat ulang.');
            }
            final rows = snap.data ?? <Note>[];
            if (rows.isEmpty) return const Text('Belum ada catatan.');
            return Column(
              children: rows
                  .map(
                    (note) => ExpansionTile(
                      title: Text(note['judul'] as String),
                      subtitle: Text(note['tanggal'] as String),
                      children: [
                        ListTile(title: Text(note['isi'] as String)),
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: busy ? null : () => startEdit(note),
                              child: const Text('Edit'),
                            ),
                            TextButton(
                              onPressed: busy
                                  ? null
                                  : () => confirmDelete(note['id'] as int),
                              child: const Text('Hapus'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    ),
  );
}
