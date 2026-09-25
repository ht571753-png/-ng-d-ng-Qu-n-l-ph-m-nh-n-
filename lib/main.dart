import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border, TextSpan;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:intl/intl.dart';
import 'dart:io';

void main() => runApp(const MyApp());

// ==================== BẢO MẬT ====================
class SecureStorage {
  static String bamMatKhau(String mk) =>
      sha256.convert(utf8.encode(mk)).toString();
}

// ==================== CƠ SỞ DỮ LIỆU ====================
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _db;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _moCSDL();
    return _db!;
  }

  Future<Database> _moCSDL() async {
    final path = p.join(await getDatabasesPath(), 'pt78.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _taoBang,
    );
  }

  Future _taoBang(Database db, int v) async {
    await db.execute('''
CREATE TABLE pham_nhan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ma_pt78 TEXT UNIQUE, ho_ten TEXT NOT NULL, ngay_sinh TEXT, noi_dktt TEXT,
  que_quan TEXT, so_cccd TEXT, ngay_cap_cccd TEXT, noi_cap_cccd TEXT,
  dan_toc TEXT, quoc_tich TEXT, ton_giao TEXT, trinh_do_hoc_van TEXT,
  ngay_bat TEXT, toi_danh TEXT, an_phat TEXT, ban_an_so TEXT, ngay_ban_an TEXT,
  toa_ban_an TEXT, thoi_han TEXT, ngay_den_trai TEXT, doi TEXT, phan_trai TEXT,
  tien_an TEXT, tien_su TEXT, tien_su_ma_tuy TEXT, tien_su_benh TEXT,
  phat_tien TEXT, boi_thuong TEXT, an_phi TEXT, tom_tat_hanh_vi TEXT,
  xep_loai TEXT, trang_thai TEXT DEFAULT 'dang_chap_hanh', ghi_chu TEXT,
  ngay_tao TEXT DEFAULT (datetime('now'))
)''');

    await db.execute('''
CREATE TABLE qh_gia_dinh (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pham_nhan_id INTEGER, quan_he TEXT, ho_ten TEXT, nam_sinh TEXT,
  nghe_nghiep TEXT, noi_o TEXT,
  FOREIGN KEY (pham_nhan_id) REFERENCES pham_nhan(id) ON DELETE CASCADE
)''');

    await db.execute('''
CREATE TABLE qh_xa_hoi (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pham_nhan_id INTEGER, ho_ten TEXT, nam_sinh TEXT, moi_quan_he TEXT,
  nghe_nghiep TEXT, noi_o TEXT,
  FOREIGN KEY (pham_nhan_id) REFERENCES pham_nhan(id) ON DELETE CASCADE
)''');

    await db.execute('''
CREATE TABLE xep_loai_thang (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pham_nhan_id INTEGER, nam INTEGER, thang INTEGER, xep_loai TEXT, nhan_xet TEXT,
  FOREIGN KEY (pham_nhan_id) REFERENCES pham_nhan(id) ON DELETE CASCADE,
  UNIQUE(pham_nhan_id, nam, thang)
)''');

    await db.execute('''
CREATE TABLE giam_thoi_han (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pham_nhan_id INTEGER, so_quyet_dinh TEXT, ngay_quyet_dinh TEXT,
  muc_giam TEXT, noi_dung TEXT,
  FOREIGN KEY (pham_nhan_id) REFERENCES pham_nhan(id) ON DELETE CASCADE
)''');

    await db.execute('''
CREATE TABLE khen_thuong (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pham_nhan_id INTEGER, so_quyet_dinh TEXT, ngay_quyet_dinh TEXT,
  hinh_thuc TEXT, noi_dung TEXT,
  FOREIGN KEY (pham_nhan_id) REFERENCES pham_nhan(id) ON DELETE CASCADE
)''');

    await db.execute('''
CREATE TABLE ky_luat (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  pham_nhan_id INTEGER, so_quyet_dinh TEXT, ngay_quyet_dinh TEXT,
  loi_vi_pham TEXT, hinh_thuc TEXT,
  FOREIGN KEY (pham_nhan_id) REFERENCES pham_nhan(id) ON DELETE CASCADE
)''');

    await db.execute('''
CREATE TABLE tai_khoan (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ten_dang_nhap TEXT UNIQUE, mat_khau_bam TEXT, ho_ten TEXT, quyen TEXT
)''');

    final mk = SecureStorage.bamMatKhau('admin123');
    await db.insert('tai_khoan', {
      'ten_dang_nhap': 'admin',
      'mat_khau_bam': mk,
      'ho_ten': 'Quan tri vien',
      'quyen': 'admin'
    });
  }

  Future<int> themPhamNhan(Map<String, dynamic> d) async =>
      await (await database).insert('pham_nhan', d);

  Future<List<Map>> layTatCa() async =>
      await (await database).query('pham_nhan', orderBy: 'ho_ten');

  Future<Map?> layChiTiet(int id) async {
    final r = await (await database)
        .query('pham_nhan', where: 'id=?', whereArgs: [id]);
    return r.isNotEmpty ? r.first : null;
  }

  Future<int> xoa(int id) async =>
      await (await database).delete('pham_nhan', where: 'id=?', whereArgs: [id]);

  Future<int> themGiaDinh(int pid, Map d) async =>
      await (await database).insert('qh_gia_dinh', {...d, 'pham_nhan_id': pid});

  Future<List<Map>> layGiaDinh(int pid) async => await (await database)
      .query('qh_gia_dinh', where: 'pham_nhan_id=?', whereArgs: [pid]);

  Future<int> themXaHoi(int pid, Map d) async =>
      await (await database).insert('qh_xa_hoi', {...d, 'pham_nhan_id': pid});

  Future<List<Map>> layXaHoi(int pid) async => await (await database)
      .query('qh_xa_hoi', where: 'pham_nhan_id=?', whereArgs: [pid]);

  Future<int> themXepLoai(int pid, int nam, int thang, String xl, String? nx) async =>
      await (await database).insert(
        'xep_loai_thang',
        {'pham_nhan_id': pid, 'nam': nam, 'thang': thang, 'xep_loai': xl, 'nhan_xet': nx},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<List<Map>> layXepLoai(int pid, int nam) async => await (await database)
      .query('xep_loai_thang', where: 'pham_nhan_id=? AND nam=?', whereArgs: [pid, nam], orderBy: 'thang');

  Future<int> themGiamTH(int pid, Map d) async =>
      await (await database).insert('giam_thoi_han', {...d, 'pham_nhan_id': pid});

  Future<List<Map>> layGiamTH(int pid) async => await (await database)
      .query('giam_thoi_han', where: 'pham_nhan_id=?', whereArgs: [pid]);

  Future<int> themKT(int pid, Map d) async =>
      await (await database).insert('khen_thuong', {...d, 'pham_nhan_id': pid});

  Future<List<Map>> layKT(int pid) async => await (await database)
      .query('khen_thuong', where: 'pham_nhan_id=?', whereArgs: [pid]);

  Future<int> themKL(int pid, Map d) async =>
      await (await database).insert('ky_luat', {...d, 'pham_nhan_id': pid});

  Future<List<Map>> layKL(int pid) async => await (await database)
      .query('ky_luat', where: 'pham_nhan_id=?', whereArgs: [pid]);

  Future<Map?> dangNhap(String u, String p) async {
    final mb = SecureStorage.bamMatKhau(p);
    final r = await (await database).query(
      'tai_khoan',
      where: 'ten_dang_nhap=? AND mat_khau_bam=?',
      whereArgs: [u, mb],
    );
    return r.isNotEmpty ? r.first : null;
  }
}

// ==================== XUẤT PDF ====================
class XuatPDF {
  static Future<void> xuat(BuildContext ctx, Map pn) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (c) => pw.Column(children: [
          pw.Text('TRAI GIAM THU DUC',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.SizedBox(height: 8),
          pw.Text('PHIEU THEO DOI QUY TRINH CHAP HANH AN PT78',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.SizedBox(height: 12),
          pw.Divider()
        ]),
        build: (c) => [
          pw.Header(text: 'I. SO LICH'),
          _dong('Ma PT78', pn['ma_pt78']),
          _dong('Ho ten', pn['ho_ten'], dam: true),
          _dong('Ngay sinh', pn['ngay_sinh']),
          _dong('Noi DKTT', pn['noi_dktt']),
          _dong('Que quan', pn['que_quan']),
          _dong('So CCCD', pn['so_cccd']),
          _dong('Ngay den trai', pn['ngay_den_trai']),
          _dong('Toi danh', pn['toi_danh']),
          _dong('An phat', pn['an_phat']),
          pw.Header(text: 'II. TOM TAT HANH VI'),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Text(pn['tom_tat_hanh_vi'] ?? 'Chua co',
                style: const pw.TextStyle(lineSpacing: 1.5)),
          ),
          pw.SizedBox(height: 30),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(children: [
                  pw.Text('Nguoi lap'),
                  pw.SizedBox(height: 50),
                  pw.Text('(Ky, ho ten)')
                ]),
                pw.Column(children: [
                  pw.Text('Truong Phan trai'),
                  pw.SizedBox(height: 50),
                  pw.Text('(Ky, ho ten)')
                ]),
                pw.Column(children: [
                  pw.Text('Thu truong don vi'),
                  pw.SizedBox(height: 50),
                  pw.Text('(Ky, dong dau)')
                ])
              ])
        ],
      ));
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/PT78_${pn['ma_pt78']}.pdf');
      await f.writeAsBytes(await pdf.save());
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Da xuat PDF'), backgroundColor: Colors.green),
        );
      }
      await OpenFilex.open(f.path);
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Loi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _dong(String t, dynamic v, {bool dam = false}) =>
      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$t: ', style: pw.TextStyle(fontWeight: dam ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Expanded(child: pw.Text('${v ?? ""}'))
        ],
      ));
}

// ==================== XUẤT EXCEL ====================
class XuatExcel {
  static Future<void> xuatDanhSach(BuildContext ctx) async {
    final ds = await DatabaseHelper.instance.layTatCa();
    if (ds.isEmpty) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Chua co du lieu')),
        );
      }
      return;
    }
    final ex = Excel.createExcel();
    ex.delete('Sheet1');
    final sh = ex['Danh Sach PT78'];
    
    sh.appendRow([
      TextCellValue('STT'),
      TextCellValue('Ma PT78'),
      TextCellValue('Ho ten'),
      TextCellValue('Ngay sinh'),
      TextCellValue('Toi danh'),
      TextCellValue('Ngay den trai'),
      TextCellValue('Doi'),
      TextCellValue('Trang thai')
    ]);
    
    for (var i = 0; i < ds.length; i++) {
      final p = ds[i];
      sh.appendRow([
        IntCellValue(i + 1),
        TextCellValue('${p['ma_pt78']}'),
        TextCellValue('${p['ho_ten']}'),
        TextCellValue('${p['ngay_sinh'] ?? ""}'),
        TextCellValue('${p['toi_danh'] ?? ""}'),
        TextCellValue('${p['ngay_den_trai'] ?? ""}'),
        TextCellValue('${p['doi'] ?? ""}'),
        TextCellValue(p['trang_thai'] == 'dang_chap_hanh' ? 'Dang chap hanh' : 'Het an')
      ]);
    }
    
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/DanhSachPT78_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx');
    await f.writeAsBytes(ex.encode()!);
    
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Da xuat Excel'), backgroundColor: Colors.green),
      );
    }
    await OpenFilex.open(f.path);
  }
}

// ==================== MÀN HÌNH ĐĂNG NHẬP ====================
class ManHinhDangNhap extends StatefulWidget {
  const ManHinhDangNhap({super.key});
  @override
  State<ManHinhDangNhap> createState() => _ManHinhDangNhapState();
}

class _ManHinhDangNhapState extends State<ManHinhDangNhap> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _dang = false;

  Future<void> _dangNhap() async {
    setState(() => _dang = true);
    final tk = await DatabaseHelper.instance.dangNhap(_u.text.trim(), _p.text);
    setState(() => _dang = false);
    if (tk != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ManHinhDanhSach()),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sai ten dang nhap hoac mat khau!'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings, size: 64, color: Colors.blueGrey),
            const SizedBox(height: 16),
            const Text('QUAN LY PT78', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: _u,
              decoration: const InputDecoration(
                labelText: 'Ten dang nhap',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _p,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mat khau',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _dang ? null : _dangNhap,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: _dang
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('DANG NHAP', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ==================== MÀN HÌNH DANH SÁCH ====================
class ManHinhDanhSach extends StatefulWidget {
  const ManHinhDanhSach({super.key});
  @override
  State<ManHinhDanhSach> createState() => _ManHinhDanhSachState();
}

class _ManHinhDanhSachState extends State<ManHinhDanhSach> {
  List<Map> _ds = [];
  bool _dang = false;
  String _tk = '';

  Future<void> _tai() async {
    setState(() => _dang = true);
    _ds = await DatabaseHelper.instance.layTatCa();
    if (_tk.isNotEmpty) {
      _ds = _ds
          .where((p) =>
              p['ho_ten'].toString().toLowerCase().contains(_tk.toLowerCase()) ||
              p['ma_pt78'].toString().contains(_tk))
          .toList();
    }
    setState(() => _dang = false);
  }

  @override
  void initState() {
    super.initState();
    _tai();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Danh Sach Pham Nhan'),
      actions: [
        IconButton(
          icon: const Icon(Icons.table_chart),
          tooltip: 'Xuat Excel',
          onPressed: () => XuatExcel.xuatDanhSach(context),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ManHinhDangNhap()),
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ManHinhThem(_tai)),
      ).then((_) => _tai()),
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Tim theo ten, ma...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              _tk = v;
              _tai();
            },
          ),
        ),
        Expanded(
          child: _dang
              ? const Center(child: CircularProgressIndicator())
              : _ds.isEmpty
                  ? const Center(child: Text('Chua co phieu, nhan + de them'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _ds.length,
                      itemBuilder: (ctx, i) {
                        final p = _ds[i];
                        return Card(
                          child: ListTile(
                            title: Text('${p['ma_pt78']} — ${p['ho_ten']}'),
                            subtitle: Text(
                                '${p['ngay_den_trai'] ?? "Chua nhap"} | ${p['trang_thai'] == "dang_chap_hanh" ? "Dang chap hanh" : "Het an"}'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ManHinhChiTiet(p, _tai)),
                            ).then((_) => _tai()),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final xac = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Xac nhan xoa'),
                                    content: const Text('Xoa vinh vien?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, false),
                                        child: const Text('HUY'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('XOA', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (xac == true) {
                                  await DatabaseHelper.instance.xoa(p['id']);
                                  _tai();
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    ),
  );
}

// ==================== MÀN HÌNH THÊM ====================
class ManHinhThem extends StatefulWidget {
  final Function() cb;
  const ManHinhThem(this.cb, {super.key});
  @override
  State<ManHinhThem> createState() => _ManHinhThemState();
}

class _ManHinhThemState extends State<ManHinhThem> {
  final _f = GlobalKey<FormState>();
  final Map<String, dynamic> _d = {};

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Them Phieu PT78')),
    body: Form(
      key: _f,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Ma PT78'),
              onSaved: (v) => _d['ma_pt78'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Ho va ten *'),
              onSaved: (v) => _d['ho_ten'] = v,
              validator: (v) => v?.isEmpty == true ? 'Bat buoc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Ngay sinh'),
              onSaved: (v) => _d['ngay_sinh'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Noi DKTT'),
              onSaved: (v) => _d['noi_dktt'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'So CCCD'),
              onSaved: (v) => _d['so_cccd'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Ngay den trai'),
              onSaved: (v) => _d['ngay_den_trai'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Toi danh'),
              maxLines: 2,
              onSaved: (v) => _d['toi_danh'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'An phat'),
              onSaved: (v) => _d['an_phat'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Doi/Phan trai'),
              onSaved: (v) => _d['doi'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Tom tat hanh vi'),
              maxLines: 4,
              onSaved: (v) => _d['tom_tat_hanh_vi'] = v,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text('LUU PHIEU', style: TextStyle(fontSize: 16)),
                onPressed: () async {
                  if (_f.currentState!.validate()) {
                    _f.currentState!.save();
                    await DatabaseHelper.instance.themPhamNhan(_d);
                    widget.cb();
                    if (mounted) Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ==================== MÀN HÌNH CHI TIẾT ====================
class ManHinhChiTiet extends StatefulWidget {
  final Map pn;
  final Function() cb;
  const ManHinhChiTiet(this.pn, this.cb, {super.key});
  @override
  State<ManHinhChiTiet> createState() => _ManHinhChiTietState();
}

class _ManHinhChiTietState extends State<ManHinhChiTiet> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Map> _gd = [];
  List<Map> _xl = [];
  List<Map> _gth = [];
  List<Map> _kt = [];
  List<Map> _kl = [];
  int _nam = DateTime.now().year;
  bool _dang = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 5, vsync: this);
    _tai();
  }

  Future<void> _tai() async {
    setState(() => _dang = true);
    _gd = await DatabaseHelper.instance.layGiaDinh(widget.pn['id']);
    _xl = await DatabaseHelper.instance.layXepLoai(widget.pn['id'], _nam);
    _gth = await DatabaseHelper.instance.layGiamTH(widget.pn['id']);
    _kt = await DatabaseHelper.instance.layKT(widget.pn['id']);
    _kl = await DatabaseHelper.instance.layKL(widget.pn['id']);
    setState(() => _dang = false);
  }

  Color _mauXL(String? xl) => switch (xl) {
        'K' => Colors.green,
        'TB' => Colors.blue,
        'Kh' => Colors.orange,
        'G' => Colors.red,
        _ => Colors.grey
      };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.pn['ho_ten'] ?? '---'),
      bottom: TabBar(
        controller: _tab,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Ly lich'),
          Tab(text: 'Gia dinh'),
          Tab(text: 'Xep loai'),
          Tab(text: 'Khen/KL'),
          Tab(text: 'Xuat File')
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: 'Xuat PDF',
          onPressed: () => XuatPDF.xuat(context, widget.pn),
        )
      ],
    ),
    body: _dang
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tab,
            children: [
              // Tab 1: Lý lịch
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _dong('Ma PT78', widget.pn['ma_pt78']),
                    _dong('Ho ten', widget.pn['ho_ten'], dam: true),
                    _dong('Ngay sinh', widget.pn['ngay_sinh']),
                    _dong('Noi DKTT', widget.pn['noi_dktt']),
                    _dong('So CCCD', widget.pn['so_cccd']),
                    _dong('Ngay den trai', widget.pn['ngay_den_trai']),
                    _dong('Toi danh', widget.pn['toi_danh']),
                    _dong('An phat', widget.pn['an_phat']),
                    _dong('Doi', widget.pn['doi']),
                    _dong(
                      'Trang thai',
                      widget.pn['trang_thai'] == 'dang_chap_hanh' ? 'Dang chap hanh' : 'Da het an',
                    ),
                    const SizedBox(height: 16),
                    const Text('Tom tat hanh vi:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                      child: Text(widget.pn['tom_tat_hanh_vi'] ?? 'Chua cap nhat'),
                    ),
                  ],
                ),
              ),
              // Tab 2: Gia đình
              Column(
                children: [
                  Expanded(
                    child: _gd.isEmpty
                        ? const Center(child: Text('Chua co thong tin gia dinh'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: _gd.length,
                            itemBuilder: (c, i) => Card(
                              child: ListTile(
                                title: Text('${_gd[i]['quan_he']}: ${_gd[i]['ho_ten']}'),
                                subtitle: Text(_gd[i]['nghe_nghiep'] ?? ''),
                              ),
                            ),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Them thanh vien'),
                      onPressed: _themGiaDinh,
                    ),
                  ),
                ],
              ),
              // Tab 3: Xếp loại
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Text('Nam: '),
                        DropdownButton<int>(
                          value: _nam,
                          items: [
                            for (var n = DateTime.now().year - 2; n <= DateTime.now().year; n++)
                              DropdownMenuItem(value: n, child: Text('$n'))
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() => _nam = v!);
                              _tai();
                            }
                          },
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Them'),
                          onPressed: _themXepLoai,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _xl.isEmpty
                        ? const Center(child: Text('Chua co xep loai'))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(8),
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Thang')),
                                DataColumn(label: Text('Xep loai')),
                                DataColumn(label: Text('Nhan xet'))
                              ],
                              rows: _xl
                                  .map(
                                    (xl) => DataRow(cells: [
                                      DataCell(Text('${xl['thang']}/$_nam')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _mauXL(xl['xep_loai']).withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            xl['xep_loai'],
                                            style: TextStyle(
                                                color: _mauXL(xl['xep_loai']), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(xl['nhan_xet'] ?? ''))
                                    ]),
                                  )
                                  .toList(),
                            ),
                          ),
                  ),
                ],
              ),
              // Tab 4: Khen thưởng & Kỷ luật
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text('Khen thuong', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ..._kt.map((kt) => Card(
                          child: ListTile(
                            title: Text(kt['hinh_thuc'] ?? ''),
                            subtitle: Text('${kt['so_quyet_dinh']} • ${kt['ngay_quyet_dinh']}'),
                          ),
                        )),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Them Khen thuong'),
                      onPressed: _themKhenThuong,
                    ),
                    const SizedBox(height: 24),
                    const Text('Ky luat',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                    const SizedBox(height: 8),
                    ..._kl.map((kl) => Card(
                          color: Colors.red.shade50,
                          child: ListTile(
                            title: Text(kl['hinh_thuc'] ?? '', style: const TextStyle(color: Colors.red)),
                            subtitle: Text(
                                '${kl['so_quyet_dinh']} • ${kl['ngay_quyet_dinh']}\nLoi: ${kl['loi_vi_pham']}'),
                          ),
                        )),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Them Ky luat'),
                      onPressed: _themKyLuat,
                    ),
                    const SizedBox(height: 24),
                    const Text('Giam thoi han', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ..._gth.map((g) => Card(
                          child: ListTile(
                            title: Text(g['muc_giam'] ?? ''),
                            subtitle: Text('${g['so_quyet_dinh']} • ${g['ngay_quyet_dinh']}'),
                          ),
                        )),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Them Giam thoi han'),
                      onPressed: _themGiamThoiHan,
                    ),
                  ],
                ),
              ),
              // Tab 5: Xuất file
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf, size: 28),
                        label: const Text('XUAT PHIEU PDF', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                        onPressed: () => XuatPDF.xuat(context, widget.pn),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.table_chart, size: 28),
                        label: const Text('XUAT DANH SACH EXCEL', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                        onPressed: () => XuatExcel.xuatDanhSach(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
  );

  Widget _dong(String t, dynamic v, {bool dam = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Colors.black87),
            children: [
              TextSpan(
                  text: '$t: ',
                  style: TextStyle(fontWeight: dam ? FontWeight.bold : FontWeight.normal)),
              TextSpan(text: '${v ?? ""}')
            ],
          ),
        ),
      );

  Future<void> _themGiaDinh() async {
    final d = <String, dynamic>{};
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Them thanh vien gia dinh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Quan he'),
              items: ['Bo', 'Me', 'Vo', 'Chong', 'Con', 'Anh', 'Chi', 'Em', 'Khac']
                  .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                  .toList(),
              onChanged: (v) => d['quan_he'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Ho va ten'),
              onChanged: (v) => d['ho_ten'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Nam sinh'),
              onChanged: (v) => d['nam_sinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Nghe nghiep'),
              onChanged: (v) => d['nghe_nghiep'] = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('HUY')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.themGiaDinh(widget.pn['id'], d);
              if (mounted) Navigator.pop(c);
              _tai();
            },
            child: const Text('LUU'),
          ),
        ],
      ),
    );
  }

  Future<void> _themXepLoai() async {
    int t = DateTime.now().month;
    String xl = 'TB';
    String? nx;
    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setDl) => AlertDialog(
          title: const Text('Them xep loai thang'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: t,
                decoration: const InputDecoration(labelText: 'Thang'),
                items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text('Thang $i'))],
                onChanged: (v) => setDl(() => t = v!),
              ),
              DropdownButtonFormField<String>(
                value: xl,
                decoration: const InputDecoration(labelText: 'Xep loai'),
                items: const [
                  DropdownMenuItem(value: 'K', child: Text('Kha')),
                  DropdownMenuItem(value: 'TB', child: Text('Trung binh')),
                  DropdownMenuItem(value: 'Kh', child: Text('Kem')),
                  DropdownMenuItem(value: 'G', child: Text('Gay'))
                ],
                onChanged: (v) => setDl(() => xl = v!),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Nhan xet'),
                maxLines: 2,
                onChanged: (v) => nx = v,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('HUY')),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.instance.themXepLoai(widget.pn['id'], _nam, t, xl, nx);
                if (mounted) Navigator.pop(c);
                _tai();
              },
              child: const Text('LUU'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _themKhenThuong() async {
    final d = <String, dynamic>{};
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Them khen thuong'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'So quyet dinh'),
              onChanged: (v) => d['so_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Ngay quyet dinh'),
              onChanged: (v) => d['ngay_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Hinh thuc'),
              onChanged: (v) => d['hinh_thuc'] = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('HUY')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.themKT(widget.pn['id'], d);
              if (mounted) Navigator.pop(c);
              _tai();
            },
            child: const Text('LUU'),
          ),
        ],
      ),
    );
  }

  Future<void> _themKyLuat() async {
    final d = <String, dynamic>{};
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Them ky luat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'So quyet dinh'),
              onChanged: (v) => d['so_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Ngay quyet dinh'),
              onChanged: (v) => d['ngay_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Loi vi pham'),
              onChanged: (v) => d['loi_vi_pham'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Hinh thuc ky luat'),
              onChanged: (v) => d['hinh_thuc'] = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('HUY')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.themKL(widget.pn['id'], d);
              if (mounted) Navigator.pop(c);
              _tai();
            },
            child: const Text('LUU'),
          ),
        ],
      ),
    );
  }

  Future<void> _themGiamThoiHan() async {
    final d = <String, dynamic>{};
    await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Them giam thoi han'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'So quyet dinh'),
              onChanged: (v) => d['so_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Ngay quyet dinh'),
              onChanged: (v) => d['ngay_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Muc giam'),
              onChanged: (v) => d['muc_giam'] = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('HUY')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.themGiamTH(widget.pn['id'], d);
              if (mounted) Navigator.pop(c);
              _tai();
            },
            child: const Text('LUU'),
          ),
        ],
      ),
    );
  }
}

// ==================== ỨNG DỤNG CHÍNH ====================
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Quan Ly PT78',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const ManHinhDangNhap(),
      );
}
