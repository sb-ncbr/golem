import 'package:flutter/material.dart';
import 'package:geneweb/api/api_service.dart';
import 'package:geneweb/api/auth.dart';
import 'package:geneweb/genes/gene_model.dart';
import 'package:dio/dio.dart';
import 'package:geneweb/screens/home_screen.dart';

class LockScreen extends StatelessWidget {
  const LockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo-golem.png', height: 72),
            const SizedBox(height: 40),
            const _Lock(),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.outline,
    );
  }
}

class _Lock extends StatefulWidget {
  const _Lock({super.key});

  @override
  State<_Lock> createState() => __LockState();
}

class __LockState extends State<_Lock> {
  late final _usernameController = TextEditingController();
  late final _passwordController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 60),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your username',
                  border: OutlineInputBorder(),
                ),
                obscureText: false,
                onEditingComplete: _handleLogin,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onEditingComplete: _handleLogin,
              ),
            ),
            const SizedBox(height: 20),
            IconButton.filled(onPressed: _handleLogin, icon: const Icon(Icons.arrow_forward)),
          ],
        ),
      ),
    );
  }

  Future _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty) {
      return _showMessage('Username is required');
    } else if (password.isEmpty) {
      return _showMessage('Password is required');
    }

    final formData =
        FormData.fromMap({'username': username, 'password': password});

    final loginResponse =
        await ApiService.instance.post('/auth/login', data: formData);

    if (!loginResponse.success) {
      return _showMessage(loginResponse.message);
    } else if (mounted) {
      final user = User.fromJson(loginResponse.data['user']);
      GeneModel.of(context).user = user;
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
