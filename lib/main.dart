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
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Nhập - PT78')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản Lý Quy Trình PT78')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                icon: const Icon(Icons.table_chart, size: 24),
                label: const Text('Xuất Báo Cáo Excel', style: TextStyle(fontSize: 16)),
                onPressed: () => _xuatExcel(context),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                icon: const Icon(Icons.picture_as_pdf, size: 24),
                label: const Text('Xuất Báo Cáo PDF', style: TextStyle(fontSize: 16)),
                onPressed: () => _xuatPdf(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _xuatExcel(BuildContext context) async {
    try {
      final Excel excel = Excel.createExcel();
      excel.delete('Sheet1');
      final Sheet sheetObject = excel['Báo cáo PT78'];

      // ✅ Dùng đúng cú pháp excel ^2.1.0 — truyền trực tiếp giá trị
      sheetObject.appendRow(<dynamic>['Mã', 'Tên', 'Ngày', 'Trạng thái']);
      sheetObject.appendRow(<dynamic>[
        'PT001',
        'Nguyễn Văn A',
        DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'Đang xử lý'
      ]);
      sheetObject.appendRow(<dynamic>[
        'PT002',
        'Trần Thị B',
        DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'Hoàn thành'
      ]);

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'BaoCao_PT78_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(excel.encode()!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Tạo thành công: $fileName')),
        );
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi xuất Excel: $e')),
        );
      }
    }
  }

  Future<void> _xuatPdf(BuildContext context) async {
    try {
      final pw.Document pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context buildContext) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Center(
                    child: pw.Text(
                      'BÁO CÁO QUY TRÌNH CHẤP HÀNH ÁN PT78',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Text(
                      'Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
                      style: const pw.TextStyle(color: PdfColors.grey600),
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  // ✅ Dùng đúng TableHelper cho pdf ^3.10.7
                  pw.TableHelper.fromTextArray(
                    headers: <String>['Mã', 'Họ và Tên', 'Ngày', 'Trạng thái'],
                    data: <List<String>>[
                      <String>[
                        'PT001',
                        'Nguyễn Văn A',
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        'Đang xử lý'
                      ],
                      <String>[
                        'PT002',
                        'Trần Thị B',
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        'Hoàn thành'
                      ],
                    ],
                    headerStyle: pw.TextStyle(
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.blue700,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'BaoCao_PT78_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final File file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Tạo thành công: $fileName')),
        );
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi xuất PDF: $e')),
        );
      }
    }
  }
}
