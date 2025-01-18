import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'student_form.dart';

class StudentManagement extends StatefulWidget {
  const StudentManagement({super.key});

  @override
  State<StudentManagement> createState() => _StudentManagementState();
}

class _StudentManagementState extends State<StudentManagement> {
  List<User>? _students;
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = await ApiService.create(authToken: authService.token);
      
      final students = await apiService.getStudents();
      setState(() {
        _students = students;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<User> get _filteredStudents {
    if (_students == null) return [];
    if (_searchQuery.isEmpty) return _students!;
    
    return _students!.where((student) {
      return student.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             student.studentId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             student.email.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Future<void> _deleteStudent(User student) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenciyi Sil'),
        content: Text('${student.name} öğrencisini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = await ApiService.create(authToken: authService.token);
      
      await apiService.deleteStudent(student.id);
      await _loadStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addBalance(User student) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bakiye Ekle'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Miktar',
              border: OutlineInputBorder(),
              prefixText: '₺',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Miktar gerekli';
              }
              if (double.tryParse(value) == null) {
                return 'Geçerli bir sayı girin';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, double.parse(controller.text));
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (amount == null) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final apiService = await ApiService.create(authToken: authService.token);
      
      await apiService.addStudentBalance(student.id, amount);
      await _loadStudents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editStudent(User student) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => StudentForm(student: student),
      ),
    );

    if (result == true) {
      await _loadStudents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğrenci Yönetimi'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Öğrenci ara...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadStudents,
                    child: _students == null
                        ? const Center(child: Text('Öğrenciler yüklenemedi'))
                        : _filteredStudents.isEmpty
                            ? const Center(child: Text('Öğrenci bulunamadı'))
                            : ListView.builder(
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final student = _filteredStudents[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        child: Icon(Icons.person),
                                      ),
                                      title: Text(student.name),
                                      subtitle: Text(
                                        '${student.studentId}\n${student.email}',
                                      ),
                                      isThreeLine: true,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                '₺${student.balance.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () => _addBalance(student),
                                                child: const Text('Bakiye Ekle'),
                                              ),
                                            ],
                                          ),
                                          PopupMenuButton(
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'edit',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.edit),
                                                    SizedBox(width: 8),
                                                    Text('Düzenle'),
                                                  ],
                                                ),
                                              ),
                                              const PopupMenuItem(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Sil',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            onSelected: (value) {
                                              switch (value) {
                                                case 'edit':
                                                  _editStudent(student);
                                                  break;
                                                case 'delete':
                                                  _deleteStudent(student);
                                                  break;
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => const StudentForm(),
            ),
          );

          if (result == true) {
            await _loadStudents();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
