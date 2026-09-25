import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
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
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
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
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

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
              controller: _userCtrl,
              decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_userCtrl.text == 'admin' && _passCtrl.text == 'admin123') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sai thông tin đăng nhập!')),
                  );
                }
              },
              child: const Text('Đăng Nhập'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản Lý Quy Trình Chấp Hành Án')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.table_chart),
              label: const Text('Xuất Báo Cáo Excel'),
              onPressed: () => _xuatExcel(context),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Xuất Báo Cáo PDF'),
              onPressed: () => _xuatPdf(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _xuatExcel(BuildContext context) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Báo cáo PT78'];

      // Tiêu đề
      sheet.appendRow([
        TextCellValue('Mã'),
        TextCellValue('Tên'),
        TextCellValue('Ngày'),
        TextCellValue('Trạng thái'),
      ]);

      // Dữ liệu mẫu
      sheet.appendRow([
        TextCellValue('PT001'),
        TextCellValue('Nguyễn Văn A'),
        TextCellValue(DateFormat('dd/MM/yyyy').format(DateTime.now())),
        TextCellValue('Đang xử lý'),
      ]);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/BaoCao_PT78_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await file.writeAsBytes(excel.encode()!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã lưu: ${file.path}')),
        );
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất Excel: $e')),
        );
      }
    }
  }

  Future<void> _xuatPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BÁO CÁO QUY TRÌNH CHẤP HÀNH ÁN PT78',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 20),
                pw.Text('Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                pw.SizedBox(height: 16),
                pw.Table.fromTextArray(
                  headers: ['Mã', 'Tên', 'Ngày', 'Trạng thái'],
                  data: [
                    ['PT001', 'Nguyễn Văn A', DateFormat('dd/MM/yyyy').format(DateTime.now()), 'Đang xử lý'],
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã lưu: ${file.path}')),
        );
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất PDF: $e')),
        );
      }
    }
  }
}
