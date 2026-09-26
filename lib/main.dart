import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý PT78',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Nhập - PT78')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userController,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (_userController.text == 'admin' &&
                      _passController.text == 'admin123') {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sai tài khoản hoặc mật khẩu!')),
                    );
                  }
                },
                child: const Text('Đăng Nhập', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản Lý PT78')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                icon: const Icon(Icons.table_chart, size: 24),
                label: const Text('Xuất Báo Cáo Excel', style: TextStyle(fontSize: 16)),
                onPressed: () => xuatExcel(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 24),
                label: const Text('Xuất Báo Cáo PDF', style: TextStyle(fontSize: 16)),
                onPressed: () => xuatPdf(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> xuatExcel() async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Báo cáo'];

      sheet.appendRow(['Mã', 'Tên', 'Ngày', 'Trạng thái']);
      sheet.appendRow([
        'PT001',
        'Nguyễn Văn A',
        DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'Đang xử lý'
      ]);
      sheet.appendRow([
        'PT002',
        'Trần Thị B',
        DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'Hoàn thành'
      ]);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/BaoCao_PT78_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(excel.encode()!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Tạo thành công: ${file.path}')),
        );
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
      }
    }
  }

  Future<void> xuatPdf() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              children: [
                pw.Text(
                  'BÁO CÁO PT78',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                ),
                pw.SizedBox(height: 20),
                pw.Table.fromTextArray(
                  headers: ['Mã', 'Tên', 'Ngày', 'Trạng thái'],
                  data: [
                    [
                      'PT001',
                      'Nguyễn Văn A',
                      DateFormat('dd/MM/yyyy').format(DateTime.now()),
                      'Đang xử lý'
                    ],
                    [
                      'PT002',
                      'Trần Thị B',
                      DateFormat('dd/MM/yyyy').format(DateTime.now()),
                      'Hoàn thành'
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/BaoCao_PT78_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Tạo thành công: ${file.path}')),
        );
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e')),
        );
      }
    }
  }
}
