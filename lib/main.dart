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

// ===== MÀN HÌNH ĐĂNG NHẬP =====
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

// ===== MÀN HÌNH CHÍNH =====
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản Lý Quy Trình Chấp Hành Án PT78')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Chọn định dạng xuất báo cáo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                icon: const Icon(Icons.table_chart, size: 24),
                label: const Text('Xuất Báo Cáo Excel'),
                onPressed: () => _xuatExcel(context),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 24),
                label: const Text('Xuất Báo Cáo PDF'),
                onPressed: () => _xuatPdf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== XUẤT EXCEL =====
  Future<void> _xuatExcel(BuildContext context) async {
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Báo cáo PT78'];

      // Dùng CellValue thay vì TextCellValue
      sheet.appendRow([
        CellValue('Mã'),
        CellValue('Tên'),
        CellValue('Ngày'),
        CellValue('Trạng thái'),
      ]);

      sheet.appendRow([
        CellValue('PT001'),
        CellValue('Nguyễn Văn A'),
        CellValue(DateFormat('dd/MM/yyyy').format(DateTime.now())),
        CellValue('Đang xử lý'),
      ]);

      sheet.appendRow([
        CellValue('PT002'),
        CellValue('Trần Thị B'),
        CellValue(DateFormat('dd/MM/yyyy').format(DateTime.now())),
        CellValue('Hoàn thành'),
      ]);

      final dir = await getTemporaryDirectory();
      final tenFile = 'BaoCao_PT78_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final file = File('${dir.path}/$tenFile');
      await file.writeAsBytes(excel.encode()!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Đã tạo: $tenFile')),
        );
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi Excel: $e')),
        );
      }
    }
  }

  // ===== XUẤT PDF =====
  Future<void> _xuatPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'BÁO CÁO QUY TRÌNH CHẤP HÀNH ÁN PT78',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Center(
                  child: pw.Text(
                    'Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                  ),
                ),
                pw.SizedBox(height: 24),
                // Dùng TableHelper thay vì Table.fromTextArray
                pw.TableHelper.fromTextArray(
                  headers: ['Mã', 'Họ và Tên', 'Ngày', 'Trạng thái'],
                  data: [
                    ['PT001', 'Nguyễn Văn A', DateFormat('dd/MM/yyyy').format(DateTime.now()), 'Đang xử lý'],
                    ['PT002', 'Trần Thị B', DateFormat('dd/MM/yyyy').format(DateTime.now()), 'Hoàn thành'],
                  ],
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                  cellAlignment: pw.Alignment.center,
                ),
              ],
            ),
          ),
        ),
      );

      final dir = await getTemporaryDirectory();
      final tenFile = 'BaoCao_PT78_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$tenFile');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Đã tạo: $tenFile')),
        );
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi PDF: $e')),
        );
      }
    }
  }
}
