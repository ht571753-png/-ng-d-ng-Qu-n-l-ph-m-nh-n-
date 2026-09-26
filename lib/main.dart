import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Khóa màn hình dọc — tránh lỗi khi xoay máy
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản Lý PT78',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _dangXuLy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Nhập')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tên đăng nhập',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  enabled: !_dangXuLy,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  enabled: !_dangXuLy,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _dangXuLy ? null : _xuLyDangNhap,
                    child: _dangXuLy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Đăng Nhập', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _xuLyDangNhap() {
    setState(() => _dangXuLy = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _dangXuLy = false);

      if (_userCtrl.text.trim() == 'admin' && _passCtrl.text == 'admin123') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TrangChinh()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sai tài khoản hoặc mật khẩu!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }
}

class TrangChinh extends StatefulWidget {
  const TrangChinh({super.key});
  @override
  State<TrangChinh> createState() => _TrangChinhState();
}

class _TrangChinhState extends State<TrangChinh> {
  bool _dangXuatExcel = false;
  bool _dangXuatPdf = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản Lý PT78'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_copy, size: 64, color: Colors.blue),
                const SizedBox(height: 32),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Xuất Báo Cáo Excel', style: TextStyle(fontSize: 16)),
                  onPressed: _dangXuatExcel ? null : _taoExcel,
                ),
                if (_dangXuatExcel)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Xuất Báo Cáo PDF', style: TextStyle(fontSize: 16)),
                  onPressed: _dangXuatPdf ? null : _taoPdf,
                ),
                if (_dangXuatPdf)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _taoExcel() async {
    if (mounted) setState(() => _dangXuatExcel = true);

    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final sheet = excel['Báo cáo'];

      sheet.appendRow(['Mã', 'Họ và Tên', 'Ngày', 'Trạng thái']);
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

      final thuMuc = await getTemporaryDirectory();
      final tenFile = 'BaoCao_PT78_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${thuMuc.path}/$tenFile');
      await file.writeAsBytes(excel.encode()!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Thành công: $tenFile')),
        );
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _dangXuatExcel = false);
    }
  }

  Future<void> _taoPdf() async {
    if (mounted) setState(() => _dangXuatPdf = true);

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context ctx) => pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'BÁO CÁO QUY TRÌNH PT78',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Ngày xuất: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey),
                ),
                pw.SizedBox(height: 24),
                pw.Table.fromTextArray(
                  headers: ['Mã', 'Họ và Tên', 'Ngày', 'Trạng thái'],
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
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.blue700),
                ),
              ],
            ),
          ),
        ),
      );

      final thuMuc = await getTemporaryDirectory();
      final tenFile = 'BaoCao_PT78_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${thuMuc.path}/$tenFile');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('✅ Thành công: $tenFile')),
        );
      }
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _dangXuatPdf = false);
    }
  }
}
