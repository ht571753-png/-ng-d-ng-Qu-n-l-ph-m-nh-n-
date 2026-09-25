import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
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
  static const _KHOA_MA_HOA = 'PT78_KHOA_2026_AN_NINH_NEI_BO!@#XYZ';

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
      'ho_ten': 'Quản trị viên',
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
          pw.Text('TRẠI GIAM THỦ ĐỨC',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
          pw.SizedBox(height: 8),
          pw.Text('PHIẾU THEO DÕI QUÁ TRÌNH CHẤP HÀNH ÁN PT78',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.Divider()
        ]),
        build: (c) => [
          pw.Header(text: 'I. SƠ LƯỢC LÝ LỊCH'),
          _dong('Mã PT78', pn['ma_pt78']),
          _dong('Họ tên', pn['ho_ten'], dam: true),
          _dong('Ngày sinh', pn['ngay_sinh']),
          _dong('Nơi ĐKTT', pn['noi_dktt']),
          _dong('Quê quán', pn['que_quan']),
          _dong('Số CCCD', pn['so_cccd']),
          _dong('Ngày đến trại', pn['ngay_den_trai']),
          _dong('Tội danh', pn['toi_danh']),
          _dong('Án phạt', pn['an_phat']),
          pw.Header(text: 'II. TÓM TẮT HÀNH VI'),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Text(pn['tom_tat_hanh_vi'] ?? 'Chưa có',
                style: const pw.TextStyle(lineSpacing: 1.5)),
          ),
          pw.SizedBox(height: 20),
          pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(children: [
                  pw.Text('Người lập'),
                  pw.SizedBox(height: 40),
                  pw.Text('(Ký, họ tên)')
                ]),
                pw.Column(children: [
                  pw.Text('Trưởng Phân trại'),
                  pw.SizedBox(height: 40),
                  pw.Text('(Ký, họ tên)')
                ]),
                pw.Column(children: [
                  pw.Text('Thủ trưởng đơn vị'),
                  pw.SizedBox(height: 40),
                  pw.Text('(Ký, đóng dấu)')
                ])
              ])
        ],
      ));
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/PT78_${pn['ma_pt78']}.pdf');
      await f.writeAsBytes(await pdf.save());
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('✅ Đã xuất PDF'), backgroundColor: Colors.green),
        );
      }
      await OpenFilex.open(f.path);
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  static pw.Widget _dong(String t, dynamic v, {bool dam = false}) =>
      pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(
              text: '$t: ',
              style: pw.TextStyle(fontWeight: dam ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.TextSpan(text: '${v ?? ""}')
        ]),
      ));
}

// ==================== XUẤT EXCEL ====================
class XuatExcel {
  static Future<void> xuatDanhSach(BuildContext ctx) async {
    final ds = await DatabaseHelper.instance.layTatCa();
    if (ds.isEmpty) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Chưa có dữ liệu')),
        );
      }
      return;
    }
    final ex = Excel.createExcel();
    ex.delete('Sheet1');
    final sh = ex['DS Phạm Nhân'];
    sh.appendRow(['STT', 'Mã PT78', 'Họ tên', 'Ngày sinh', 'Tội danh', 'Ngày đến trại', 'Đội', 'Trạng thái']);
    for (var i = 0; i < ds.length; i++) {
      final p = ds[i];
      sh.appendRow([
        i + 1,
        p['ma_pt78'],
        p['ho_ten'],
        p['ngay_sinh'],
        p['toi_danh'],
        p['ngay_den_trai'],
        p['doi'],
        p['trang_thai'] == 'dang_chap_hanh' ? 'Đang chấp hành' : 'Hết án'
      ]);
    }
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/DanhSachPT78_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx');
    await f.writeAsBytes(ex.encode()!);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('✅ Đã xuất Excel'), backgroundColor: Colors.green),
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
          const SnackBar(content: Text('Sai tên đăng nhập hoặc mật khẩu!'), backgroundColor: Colors.red),
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
            const Text('QUẢN LÝ PT78', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            TextField(
              controller: _u,
              decoration: const InputDecoration(
                labelText: 'Tên đăng nhập',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _p,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mật khẩu',
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
                    : const Text('ĐĂNG NHẬP', style: TextStyle(fontSize: 16)),
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
      title: const Text('Danh Sách Phạm Nhân'),
      actions: [
        IconButton(
          icon: const Icon(Icons.table_chart),
          tooltip: 'Xuất Excel',
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
              hintText: 'Tìm theo tên, mã...',
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
                  ? const Center(child: Text('Chưa có phiếu, nhấn + để thêm'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: _ds.length,
                      itemBuilder: (ctx, i) {
                        final p = _ds[i];
                        return Card(
                          child: ListTile(
                            title: Text('${p['ma_pt78']} — ${p['ho_ten']}'),
                            subtitle: Text(
                                '${p['ngay_den_trai'] ?? "Chưa nhập"} | ${p['trang_thai'] == "dang_chap_hanh" ? "Đang chấp hành" : "Hết án"}'),
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
                                    title: const Text('Xác nhận xóa'),
                                    content: const Text('Xóa vĩnh viễn?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, false),
                                        child: const Text('HỦY'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(c, true),
                                        child: const Text('XÓA', style: TextStyle(color: Colors.red)),
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
    appBar: AppBar(title: const Text('Thêm Phiếu PT78')),
    body: Form(
      key: _f,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Mã PT78'),
              onSaved: (v) => _d['ma_pt78'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Họ và tên *'),
              onSaved: (v) => _d['ho_ten'] = v,
              validator: (v) => v?.isEmpty == true ? 'Bắt buộc' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Ngày sinh'),
              onSaved: (v) => _d['ngay_sinh'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Nơi ĐKTT'),
              onSaved: (v) => _d['noi_dktt'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Số CCCD'),
              onSaved: (v) => _d['so_cccd'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Ngày đến trại'),
              onSaved: (v) => _d['ngay_den_trai'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Tội danh'),
              maxLines: 2,
              onSaved: (v) => _d['toi_danh'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Án phạt'),
              onSaved: (v) => _d['an_phat'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Đội/Phân trại'),
              onSaved: (v) => _d['doi'] = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Tóm tắt hành vi'),
              maxLines: 4,
              onSaved: (v) => _d['tom_tat_hanh_vi'] = v,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text('LƯU PHIẾU', style: TextStyle(fontSize: 16)),
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
  List<Map> _xh = [];
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
    _xh = await DatabaseHelper.instance.layXaHoi(widget.pn['id']);
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
          Tab(text: 'Lý lịch'),
          Tab(text: 'Gia đình'),
          Tab(text: 'Xếp loại'),
          Tab(text: 'Khen/KL'),
          Tab(text: 'Xuất File')
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.picture_as_pdf),
          tooltip: 'Xuất PDF',
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
                    _dong('Mã PT78', widget.pn['ma_pt78']),
                    _dong('Họ tên', widget.pn['ho_ten'], dam: true),
                    _dong('Ngày sinh', widget.pn['ngay_sinh']),
                    _dong('Nơi ĐKTT', widget.pn['noi_dktt']),
                    _dong('Số CCCD', widget.pn['so_cccd']),
                    _dong('Ngày đến trại', widget.pn['ngay_den_trai']),
                    _dong('Tội danh', widget.pn['toi_danh']),
                    _dong('Án phạt', widget.pn['an_phat']),
                    _dong('Đội', widget.pn['doi']),
                    _dong(
                      'Trạng thái',
                      widget.pn['trang_thai'] == 'dang_chap_hanh' ? 'Đang chấp hành' : 'Đã hết án',
                    ),
                    const SizedBox(height: 16),
                    const Text('Tóm tắt hành vi:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300)),
                      child: Text(widget.pn['tom_tat_hanh_vi'] ?? 'Chưa cập nhật'),
                    ),
                  ],
                ),
              ),
              // Tab 2: Gia đình
              Column(
                children: [
                  Expanded(
                    child: _gd.isEmpty
                        ? const Center(child: Text('Chưa có thông tin gia đình'))
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
                      label: const Text('Thêm thành viên'),
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
                        const Text('Năm: '),
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
                          label: const Text('Thêm'),
                          onPressed: _themXepLoai,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _xl.isEmpty
                        ? const Center(child: Text('Chưa có xếp loại'))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(8),
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Tháng')),
                                DataColumn(label: Text('Xếp loại')),
                                DataColumn(label: Text('Nhận xét'))
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
                    const Text('🏆 Khen thưởng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ..._kt.map((kt) => Card(
                          child: ListTile(
                            title: Text(kt['hinh_thuc'] ?? ''),
                            subtitle: Text('${kt['so_quyet_dinh']} • ${kt['ngay_quyet_dinh']}'),
                          ),
                        )),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm Khen thưởng'),
                      onPressed: _themKhenThuong,
                    ),
                    const SizedBox(height: 24),
                    const Text('⚠️ Kỷ luật',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                    const SizedBox(height: 8),
                    ..._kl.map((kl) => Card(
                          color: Colors.red.shade50,
                          child: ListTile(
                            title: Text(kl['hinh_thuc'] ?? '', style: const TextStyle(color: Colors.red)),
                            subtitle: Text(
                                '${kl['so_quyet_dinh']} • ${kl['ngay_quyet_dinh']}\nLỗi: ${kl['loi_vi_pham']}'),
                          ),
                        )),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm Kỷ luật'),
                      onPressed: _themKyLuat,
                    ),
                    const SizedBox(height: 24),
                    const Text('📉 Giảm thời hạn', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    ..._gth.map((g) => Card(
                          child: ListTile(
                            title: Text(g['muc_giam'] ?? ''),
                            subtitle: Text('${g['so_quyet_dinh']} • ${g['ngay_quyet_dinh']}'),
                          ),
                        )),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm Giảm thời hạn'),
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
                        label: const Text('XUẤT PHIẾU PDF', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(20)),
                        onPressed: () => XuatPDF.xuat(context, widget.pn),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.table_chart, size: 28),
                        label: const Text('XUẤT DANH SÁCH EXCEL', style: TextStyle(fontSize: 16)),
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
        title: const Text('Thêm thành viên gia đình'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Quan hệ'),
              items: ['Bố', 'Mẹ', 'Vợ', 'Chồng', 'Con', 'Anh', 'Chị', 'Em', 'Khác']
                  .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                  .toList(),
              onChanged: (v) => d['quan_he'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Họ và tên'),
              onChanged: (v) => d['ho_ten'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Năm sinh'),
              onChanged: (v) => d['nam_sinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Nghề nghiệp'),
              onChanged: (v) => d['nghe_nghiep'] = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.themGiaDinh(widget.pn['id'], d);
              if (mounted) Navigator.pop(c);
              _tai();
            },
            child: const Text('LƯU'),
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
          title: const Text('Thêm xếp loại tháng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: t,
                decoration: const InputDecoration(labelText: 'Tháng'),
                items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text('Tháng $i'))],
                onChanged: (v) => setDl(() => t = v!),
              ),
              DropdownButtonFormField<String>(
                value: xl,
                decoration: const InputDecoration(labelText: 'Xếp loại'),
                items: const [
                  DropdownMenuItem(value: 'K', child: Text('Khá')),
                  DropdownMenuItem(value: 'TB', child: Text('Trung bình')),
                  DropdownMenuItem(value: 'Kh', child: Text('Kém')),
                  DropdownMenuItem(value: 'G', child: Text('Gây'))
                ],
                onChanged: (v) => setDl(() => xl = v!),
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Nhận xét'),
                maxLines: 2,
                onChanged: (v) => nx = v,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('HỦY')),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.instance.themXepLoai(widget.pn['id'], _nam, t, xl, nx);
                if (mounted) Navigator.pop(c);
                _tai();
              },
              child: const Text('LƯU'),
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
        title: const Text('Thêm khen thưởng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Số quyết định'),
              onChanged: (v) => d['so_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Ngày quyết định'),
              onChanged: (v) => d['ngay_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Hình thức'),
              onChanged: (v) => d['hinh_thuc'] = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.themKT(widget.pn['id'], d);
              if (mounted) Navigator.pop(c);
              _tai();
            },
            child: const Text('LƯU'),
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
        title: const Text('Thêm kỷ luật'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Số quyết định'),
              onChanged: (v) => d['so_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Ngày quyết định'),
              onChanged: (v) => d['ngay_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Lỗi vi phạm'),
              onChanged: (v) => d['loi_vi_pham'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Hình thức kỷ luật'),
              onChanged: (v) => d['hinh_thuc'] = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.themKL(widget.pn['id'], d);
              if (mounted) Navigator.pop(c);
              _tai();
            },
            child: const Text('LƯU'),
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
        title: const Text('Thêm giảm thời hạn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Số quyết định'),
              onChanged: (v) => d['so_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Ngày quyết định'),
              onChanged: (v) => d['ngay_quyet_dinh'] = v,
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Mức giảm'),
              onChanged: (v) => d['muc_giam'] = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('HỦY')),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.themGiamTH(widget.pn['id'], d);
              if (mounted) Navigator.pop(c);
              _tai();
            },
            child: const Text('LƯU'),
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
        title: 'Quản Lý PT78',
        theme: ThemeData(
          primarySwatch: Colors.blueGrey,
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const ManHinhDangNhap(),
      );
}
