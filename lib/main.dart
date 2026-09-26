import 'package:flutter/material.dart';
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
  final _u = TextEditingController();
  final _p = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Nhập - PT78')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _u, decoration: const InputDecoration(labelText: 'Tên đăng nhập')),
            const SizedBox(height: 16),
            TextField(controller: _p, obscureText: true, decoration: const InputDecoration(labelText: 'Mật khẩu')),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_u.text == 'admin' && _p.text == 'admin123') {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sai tài khoản/mật khẩu!')));
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
      appBar: AppBar(title: const Text('Quản Lý PT78')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.table_chart),
              label: const Text('Xuất Excel'),
              onPressed: () => _xuatExcel(context),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Xuất PDF'),
              onPressed: () => _xuatPdf(context),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> _xuatExcel(BuildContext context) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Báo cáo'];

      // ✅ excel ^2.1.0: truyền trực tiếp giá trị, KHÔNG dùng TextCellValue
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
      final f = File('${dir.path}/BaoCao_PT78_${DateTime.now().millisecondsSinceEpoch}.xlsx');
      await f.writeAsBytes(excel.encode()!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Đã lưu: ${f.path}')));
      }
      await OpenFilex.open(f.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Lỗi Excel: $e')));
      }
    }
  }

  static Future<void> _xuatPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              children: [
                pw.Text('BÁO CÁO PT78', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Text('Ngày: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}'),
                pw.SizedBox(height: 16),
                // ✅ pdf ^3.10.7: dùng TableHelper thay vì Table.fromTextArray
                pw.TableHelper.fromTextArray(
                  headers: ['Mã', 'Tên', 'Ngày', 'Trạng thái'],
                  data: [
                    ['PT001', 'Nguyễn Văn A', DateFormat('dd/MM/yyyy').format(DateTime.now()), 'Đang xử lý'],
                    ['PT002', 'Trần Thị B', DateFormat('dd/MM/yyyy').format(DateTime.now()), 'Hoàn thành'],
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/BaoCao_PT78_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await f.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('✅ Đã lưu: ${f.path}')));
      }
      await OpenFilex.open(f.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Lỗi PDF: $e')));
      }
    }
  }
}
