import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/datasources/remote/auth_remote_ds.dart';
import '../../../data/repositories/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _loginForm  = GlobalKey<FormState>();
  final _signupForm = GlobalKey<FormState>();

  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _emailSCtrl   = TextEditingController();
  final _passSCtrl    = TextEditingController();
  final _userCtrl     = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    // rebuild เมื่อสลับแท็บ (เพราะ render ฟอร์มตาม index เอง ไม่ได้ใช้ TabBarView)
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailSCtrl.dispose();
    _passSCtrl.dispose();
    _userCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_loginForm.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(appUserProvider.notifier)
          .signIn(_emailCtrl.text.trim(), _passCtrl.text);
      if (mounted) context.go('/');
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signup() async {
    if (!_signupForm.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ref.read(appUserProvider.notifier).signUp(
            _emailSCtrl.text.trim(),
            _passSCtrl.text,
            _userCtrl.text.trim(),
          );
      if (mounted) context.go('/');
    } on EmailConfirmationRequired catch (e) {
      // ไม่ใช่ error — สมัครสำเร็จแล้ว แค่ต้องยืนยันอีเมล
      _showInfo(e.toString());
      _tab.animateTo(0); // สลับไปแท็บเข้าสู่ระบบให้เลย
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        // scroll ได้เมื่อคีย์บอร์ดเด้งขึ้น (กันจอล้น)
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // Logo / Title
              Icon(Icons.track_changes_rounded,
                  size: 64, color: theme.colorScheme.primary),
              const SizedBox(height: 12),
              Text('Habit Tracker',
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text('ติดตามนิสัย สร้างแต้ม แข่งกับเพื่อน',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              // Tabs
              TabBar(
                controller: _tab,
                tabs: const [Tab(text: 'เข้าสู่ระบบ'), Tab(text: 'สมัครสมาชิก')],
              ),
              const SizedBox(height: 24),
              // render เฉพาะฟอร์มที่เลือก (ไม่ใช้ TabBarView เพราะต้องการความสูงยืดหยุ่น)
              _tab.index == 0 ? _loginTab() : _signupTab(),
              const SizedBox(height: 8),
              // ข้ามไปใช้แบบ guest
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('ข้ามก่อน (ใช้แบบออฟไลน์)'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginTab() => Form(
        key: _loginForm,
        child: Column(children: [
          _emailField(_emailCtrl),
          const SizedBox(height: 12),
          _passwordField(_passCtrl),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Colors.white))
                  : const Text('เข้าสู่ระบบ'),
            ),
          ),
        ]),
      );

  Widget _signupTab() => Form(
        key: _signupForm,
        child: Column(children: [
          TextFormField(
            controller: _userCtrl,
            decoration: const InputDecoration(
              labelText: 'ชื่อผู้ใช้ *',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'กรุณากรอกชื่อผู้ใช้';
              if (v.trim().length < 3) return 'ต้องมีอย่างน้อย 3 ตัวอักษร';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _emailField(_emailSCtrl),
          const SizedBox(height: 12),
          _passwordField(_passSCtrl),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _signup,
              child: _loading
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Colors.white))
                  : const Text('สมัครสมาชิก'),
            ),
          ),
        ]),
      );

  Widget _emailField(TextEditingController ctrl) => TextFormField(
        controller: ctrl,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          labelText: 'อีเมล *',
          prefixIcon: Icon(Icons.email_outlined),
          border: OutlineInputBorder(),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'กรุณากรอกอีเมล';
          if (!v.contains('@')) return 'รูปแบบอีเมลไม่ถูกต้อง';
          return null;
        },
      );

  Widget _passwordField(TextEditingController ctrl) => TextFormField(
        controller: ctrl,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: 'รหัสผ่าน *',
          prefixIcon: const Icon(Icons.lock_outline),
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return 'กรุณากรอกรหัสผ่าน';
          if (v.length < 6) return 'ต้องมีอย่างน้อย 6 ตัวอักษร';
          return null;
        },
      );
}
