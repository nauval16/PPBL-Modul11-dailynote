import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;

  Future<void> submit({required bool register}) async {
    if (busy) return;
    final address = email.text.trim();
    final secret = password.text;
    if (!address.contains('@') || secret.length < 8) {
      message('Isi email dan kata sandi minimal 8 karakter.');
      return;
    }

    final auth = Supabase.instance.client.auth;
    setState(() => busy = true);
    try {
      if (register) {
        final result = await auth.signUp(email: address, password: secret);
        if (result.session == null) {
          message('Cek email verifikasi, lalu kembali dan tekan Masuk.');
        }
      } else {
        await auth.signInWithPassword(email: address, password: secret);
      }
    } on AuthException catch (error) {
      message(error.message);
    } catch (_) {
      message('Permintaan gagal. Periksa koneksi dan coba lagi.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('DailyNote')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Kata sandi'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy ? null : () => submit(register: false),
            child: Text(busy ? 'Memproses...' : 'Masuk'),
          ),
          OutlinedButton(
            onPressed: busy ? null : () => submit(register: true),
            child: const Text('Daftar'),
          ),
        ],
      ),
    );
  }
}
