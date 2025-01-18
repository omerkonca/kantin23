import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';

class StudentForm extends StatefulWidget {
  final User? student;

  const StudentForm({super.key, this.student});

  @override
  State<StudentForm> createState() => _StudentFormState();
}

class _StudentFormState extends State<StudentForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _initApiService();
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _studentIdController.text = widget.student!.studentId;
    }
  }

  Future<void> _initApiService() async {
    _apiService = await ApiService.create(authToken: null);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _generateEmail(String name, String studentId) {
    // İsmi küçük harfe çevir ve boşlukları kaldır
    final cleanName = name.toLowerCase().replaceAll(' ', '');
    // Öğrenci numarasını ekle
    return '$cleanName$studentId@kantin23.com';
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final name = _nameController.text;
      final studentId = _studentIdController.text;
      final email = _generateEmail(name, studentId);
      final password = _passwordController.text;

      final student = User(
        id: widget.student?.id ?? '',
        name: name,
        email: email,
        studentId: studentId,
        role: 'student',
        balance: widget.student?.balance ?? 0,
      );

      if (widget.student == null) {
        // Yeni öğrenci oluştur
        await _apiService.createStudent(student);
        NotificationService.showSuccess('Öğrenci başarıyla oluşturuldu');
      } else {
        // Mevcut öğrenciyi güncelle
        await _apiService.updateStudent(student);
        NotificationService.showSuccess('Öğrenci başarıyla güncellendi');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      NotificationService.showError('Hata: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNewStudent = widget.student == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isNewStudent ? 'Yeni Öğrenci' : 'Öğrenci Düzenle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ad Soyad gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  labelText: 'Öğrenci Numarası',
                  prefixIcon: Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Öğrenci numarası gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (isNewStudent) ...[
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock),
                    helperText: 'En az 6 karakter',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Giriş Bilgileri',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'E-posta: ${_generateEmail(_nameController.text, _studentIdController.text)}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Şifre: ${_passwordController.text}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveStudent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isNewStudent ? 'Öğrenci Oluştur' : 'Değişiklikleri Kaydet',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
