import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

// =================== INCOME/BALANCE SCREEN ===================
class SoDuScreen extends StatefulWidget {
  final List<ChiTieuItem> danhSachThuNhap;
  final int tongChiHomNay;
  final int tongChiLichSu;
  final DateTime currentDay;
  final Function(List<ChiTieuItem>)? onDataChanged;

  const SoDuScreen({
    super.key,
    required this.danhSachThuNhap,
    required this.tongChiHomNay,
    required this.tongChiLichSu,
    required this.currentDay,
    this.onDataChanged,
  });

  @override
  State<SoDuScreen> createState() => _SoDuScreenState();
}

class _SoDuScreenState extends State<SoDuScreen> {
  late List<ChiTieuItem> danhSachThuNhap;
  bool dangChonXoa = false;

  int get tongThuNhap => danhSachThuNhap.fold(0, (a, b) => a + b.soTien);

  @override
  void initState() {
    super.initState();
    danhSachThuNhap = List<ChiTieuItem>.from(widget.danhSachThuNhap);
  }

  Future<void> themThuNhap() async {
    final soTien = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const NhapSoTienScreen()),
    );

    if (soTien != null && soTien > 0) {
      setState(() {
        danhSachThuNhap.add(ChiTieuItem(soTien: soTien, thoiGian: DateTime.now()));
        widget.onDataChanged?.call(danhSachThuNhap);
      });
    }
  }

  Future<void> chinhSuaThuNhap(int index) async {
    if (dangChonXoa) return;
    final soTienMoi = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => NhapSoTienScreen(soTienBanDau: danhSachThuNhap[index].soTien),
      ),
    );

    if (soTienMoi != null && soTienMoi > 0) {
      setState(() {
        danhSachThuNhap[index] = danhSachThuNhap[index].copyWith(soTien: soTienMoi, thoiGian: DateTime.now());
        widget.onDataChanged?.call(danhSachThuNhap);
      });
    }
  }

  void xoaThuNhap(int index) {
    setState(() {
      danhSachThuNhap.removeAt(index);
      widget.onDataChanged?.call(danhSachThuNhap);
    });
  }

  @override
  Widget build(BuildContext context) {
    final remaining = tongThuNhap - widget.tongChiHomNay - widget.tongChiLichSu;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) widget.onDataChanged?.call(danhSachThuNhap);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(ChiTieuMuc.soDu.ten),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.onDataChanged?.call(danhSachThuNhap);
              Navigator.pop(context, danhSachThuNhap);
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: themThuNhap,
          backgroundColor: const Color(0xFF4CAF93),
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF93), Color(0xFF81C784)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng thu nhập', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      formatAmountWithCurrency(tongThuNhap),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Còn lại: ${remaining >= 0 ? formatAmountWithCurrency(remaining) : '-${formatAmountWithCurrency(remaining.abs())}'}',
                      style: TextStyle(color: remaining >= 0 ? Colors.white : Colors.red[200], fontSize: 16),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              const Text('Danh sách thu nhập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              if (danhSachThuNhap.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Chưa có thu nhập nào', style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: danhSachThuNhap.length,
                  itemBuilder: (context, index) {
                    final item = danhSachThuNhap[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF4CAF93),
                          child: Icon(Icons.arrow_downward, color: Colors.white),
                        ),
                        title: Text(formatAmountWithCurrency(item.soTien)),
                        subtitle: Text(dinhDangGio(item.thoiGian)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => chinhSuaThuNhap(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => xoaThuNhap(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== CATEGORY DETAIL SCREEN ===================
class ChiTieuTheoMucScreen extends StatefulWidget {
  final ChiTieuMuc muc;
  final List<ChiTieuItem> danhSachChiBanDau;
  final DateTime currentDay;
  final Function(List<ChiTieuItem>)? onDataChanged;

  const ChiTieuTheoMucScreen({
    super.key,
    required this.muc,
    required this.danhSachChiBanDau,
    required this.currentDay,
    this.onDataChanged,
  });

  @override
  State<ChiTieuTheoMucScreen> createState() => _ChiTieuTheoMucScreenState();
}

class _ChiTieuTheoMucScreenState extends State<ChiTieuTheoMucScreen> {
  late List<ChiTieuItem> danhSachChi;

  int get tongChi => danhSachChi.fold(0, (a, b) => a + b.soTien);

  @override
  void initState() {
    super.initState();
    danhSachChi = List<ChiTieuItem>.from(widget.danhSachChiBanDau);
  }

  Future<void> themChiTieu() async {
    final soTien = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const NhapSoTienScreen()),
    );

    if (soTien != null && soTien > 0) {
      setState(() {
        danhSachChi.add(ChiTieuItem(soTien: soTien, thoiGian: DateTime.now()));
        widget.onDataChanged?.call(danhSachChi);
      });
    }
  }

  Future<void> chinhSuaChiTieu(int index) async {
    final soTienMoi = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => NhapSoTienScreen(soTienBanDau: danhSachChi[index].soTien),
      ),
    );

    if (soTienMoi != null && soTienMoi > 0) {
      setState(() {
        danhSachChi[index] = danhSachChi[index].copyWith(soTien: soTienMoi, thoiGian: DateTime.now());
        widget.onDataChanged?.call(danhSachChi);
      });
    }
  }

  void xoaChiTieu(int index) {
    setState(() {
      danhSachChi.removeAt(index);
      widget.onDataChanged?.call(danhSachChi);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) widget.onDataChanged?.call(danhSachChi);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.muc.ten),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.onDataChanged?.call(danhSachChi);
              Navigator.pop(context, danhSachChi);
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: themChiTieu,
          backgroundColor: widget.muc.color,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.muc.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: widget.muc.color.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(widget.muc.icon, color: widget.muc.color, size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tổng ${widget.muc.ten}', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Text(
                            formatAmountWithCurrency(tongChi),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF08080)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (danhSachChi.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Chưa có chi tiêu nào', style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: danhSachChi.length,
                  itemBuilder: (context, index) {
                    final item = danhSachChi[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: widget.muc.color.withOpacity(0.2),
                          child: Icon(widget.muc.icon, color: widget.muc.color, size: 20),
                        ),
                        title: Text(formatAmountWithCurrency(item.soTien), 
                          style: const TextStyle(color: Color(0xFFF08080))),
                        subtitle: Text(dinhDangGio(item.thoiGian)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => chinhSuaChiTieu(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                              onPressed: () => xoaChiTieu(index),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== OTHER EXPENSES SCREEN ===================
class KhacTheoMucScreen extends StatefulWidget {
  final List<ChiTieuItem> danhSachChiBanDau;
  final DateTime currentDay;
  final Function(List<ChiTieuItem>)? onDataChanged;

  const KhacTheoMucScreen({
    super.key,
    required this.danhSachChiBanDau,
    required this.currentDay,
    this.onDataChanged,
  });

  @override
  State<KhacTheoMucScreen> createState() => _KhacTheoMucScreenState();
}

class _KhacTheoMucScreenState extends State<KhacTheoMucScreen> {
  late List<ChiTieuItem> danhSachChi;

  int get tongChi => danhSachChi.fold(0, (a, b) => a + b.soTien);

  @override
  void initState() {
    super.initState();
    danhSachChi = List<ChiTieuItem>.from(widget.danhSachChiBanDau);
  }

  Future<void> themChiTieu() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const NhapKhacScreen()),
    );

    if (result != null) {
      setState(() {
        danhSachChi.add(ChiTieuItem(
          soTien: result['soTien'] as int,
          thoiGian: DateTime.now(),
          tenChiTieu: result['ten'] as String,
        ));
        widget.onDataChanged?.call(danhSachChi);
      });
    }
  }

  void xoaChiTieu(int index) {
    setState(() {
      danhSachChi.removeAt(index);
      widget.onDataChanged?.call(danhSachChi);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) widget.onDataChanged?.call(danhSachChi);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(ChiTieuMuc.khac.ten),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              widget.onDataChanged?.call(danhSachChi);
              Navigator.pop(context, danhSachChi);
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: themChiTieu,
          backgroundColor: Colors.grey,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tổng chi khác', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(
                      formatAmountWithCurrency(tongChi),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFF08080)),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (danhSachChi.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Chưa có chi tiêu nào', style: TextStyle(color: Colors.white54)),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: danhSachChi.length,
                  itemBuilder: (context, index) {
                    final item = danhSachChi[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.money_rounded, color: Colors.white, size: 20),
                        ),
                        title: Text(item.tenChiTieu ?? 'Chi tiêu', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text('${formatAmountWithCurrency(item.soTien)} • ${dinhDangGio(item.thoiGian)}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                          onPressed: () => xoaChiTieu(index),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// =================== NHẬP SỐ TIỀN SCREEN ===================
class NhapSoTienScreen extends StatefulWidget {
  final int? soTienBanDau;
  
  const NhapSoTienScreen({super.key, this.soTienBanDau});

  @override
  State<NhapSoTienScreen> createState() => _NhapSoTienScreenState();
}

class _NhapSoTienScreenState extends State<NhapSoTienScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.soTienBanDau != null) {
      _controller.text = widget.soTienBanDau.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _xacNhan() {
    final soTien = int.tryParse(_controller.text.replaceAll('.', '').replaceAll(',', ''));
    if (soTien != null && soTien > 0) {
      Navigator.pop(context, soTien);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhập số tiền')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                suffixText: 'đ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: const Color(0xFF2D2D3F),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _xacNhan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Xác nhận', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================== NHẬP CHI TIÊU KHÁC SCREEN ===================
class NhapKhacScreen extends StatefulWidget {
  const NhapKhacScreen({super.key});

  @override
  State<NhapKhacScreen> createState() => _NhapKhacScreenState();
}

class _NhapKhacScreenState extends State<NhapKhacScreen> {
  final TextEditingController _tenController = TextEditingController();
  final TextEditingController _soTienController = TextEditingController();

  void _xacNhan() {
    final ten = _tenController.text.trim();
    final soTien = int.tryParse(_soTienController.text.replaceAll('.', '').replaceAll(',', ''));
    if (ten.isNotEmpty && soTien != null && soTien > 0) {
      Navigator.pop(context, {'ten': ten, 'soTien': soTien});
    }
  }

  @override
  void dispose() {
    _tenController.dispose();
    _soTienController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm chi tiêu khác')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _tenController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Tên chi tiêu',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF2D2D3F),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _soTienController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền',
                suffixText: 'đ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFF2D2D3F),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _xacNhan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Thêm', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =================== LỊCH SỬ SCREEN ===================
class LichSuScreen extends StatefulWidget {
  final Map<String, Map<String, List<HistoryEntry>>> lichSuThang;
  final DateTime currentDay;
  final Map<ChiTieuMuc, List<ChiTieuItem>> currentData;

  const LichSuScreen({
    super.key,
    required this.lichSuThang,
    required this.currentDay,
    required this.currentData,
  });

  @override
  State<LichSuScreen> createState() => _LichSuScreenState();
}

class _LichSuScreenState extends State<LichSuScreen> {
  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, List<HistoryEntry>>> combined = {
      for (final e in widget.lichSuThang.entries)
        e.key: {for (final d in e.value.entries) d.key: List<HistoryEntry>.from(d.value)}
    };

    final monthKeyNow = getMonthKey(widget.currentDay);
    final dayKeyNow = dinhDangNgayDayDu(widget.currentDay);
    final List<HistoryEntry> currentDayEntries = [];
    widget.currentData.forEach((muc, items) {
      if (muc == ChiTieuMuc.lichSu) return;
      for (final it in items.where((item) => _sameDay(item.thoiGian, widget.currentDay))) {
        currentDayEntries.add(HistoryEntry(muc: muc, item: it));
      }
    });
    currentDayEntries.sort((a, b) => b.item.soTien.compareTo(a.item.soTien));
    if (currentDayEntries.isNotEmpty) {
      combined.putIfAbsent(monthKeyNow, () => {});
      combined[monthKeyNow]![dayKeyNow] = currentDayEntries;
    }

    final sortedMonths = combined.keys.toList()
      ..sort((a, b) {
        final pa = a.split('/');
        final pb = b.split('/');
        final da = DateTime(int.parse(pa[1]), int.parse(pa[0]));
        final db = DateTime(int.parse(pb[1]), int.parse(pb[0]));
        return db.compareTo(da);
      });

    return Scaffold(
      appBar: AppBar(title: Text(ChiTieuMuc.lichSu.ten)),
      body: sortedMonths.isEmpty
          ? const Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedMonths.length,
              itemBuilder: (context, monthIndex) {
                final monthKey = sortedMonths[monthIndex];
                final daysData = combined[monthKey]!;

                final totalMonth = daysData.values
                    .expand((lst) => lst)
                    .where((e) => e.muc != ChiTieuMuc.soDu)
                    .fold(0, (s, e) => s + e.item.soTien);

                final sortedDays = daysData.keys.toList()
                  ..sort((a, b) {
                    final pa = a.split('/');
                    final pb = b.split('/');
                    final da = DateTime(int.parse(pa[2]), int.parse(pa[1]), int.parse(pa[0]));
                    final db = DateTime(int.parse(pb[2]), int.parse(pb[1]), int.parse(pb[0]));
                    return db.compareTo(da);
                  });

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: Text(
                      appLanguage == 'vi' ? 'Tháng $monthKey' : '${getMonthName(int.parse(monthKey.split('/')[0]))} ${monthKey.split('/')[1]}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(formatAmountWithCurrency(totalMonth), style: const TextStyle(color: Color(0xFFF08080))),
                    children: sortedDays.map((dayKey) {
                      final itemsOnDay = daysData[dayKey]!;
                      final dayTotal = itemsOnDay
                          .where((e) => e.muc != ChiTieuMuc.soDu)
                          .fold(0, (sum, e) => sum + e.item.soTien);

                      return ExpansionTile(
                        title: Text(appLanguage == 'vi' ? 'Ngày ${dayKey.split('/')[0]}' : '${getOrdinalSuffix(int.parse(dayKey.split('/')[0]))}'),
                        subtitle: Text(formatAmountWithCurrency(dayTotal), style: const TextStyle(color: Color(0xFFF08080), fontSize: 12)),
                        children: itemsOnDay.map((entry) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: entry.muc.color.withOpacity(0.2),
                              child: Icon(entry.muc.icon, color: entry.muc.color, size: 20),
                            ),
                            title: Text(entry.item.tenChiTieu ?? entry.muc.ten),
                            subtitle: Text(dinhDangGio(entry.item.thoiGian)),
                            trailing: Text(
                              formatAmountWithCurrency(entry.item.soTien),
                              style: TextStyle(
                                color: entry.muc == ChiTieuMuc.soDu ? const Color(0xFF4CAF93) : const Color(0xFFF08080),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
    );
  }
}

// =================== SETTINGS SCREEN ===================
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onLanguageChanged;

  const SettingsScreen({super.key, this.onLanguageChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(ChiTieuMuc.caiDat.ten)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(appLanguage == 'vi' ? 'Ngôn ngữ' : 'Language'),
              subtitle: Text(
                appLanguageMode == 'auto'
                    ? (appLanguage == 'vi' ? '📱 Tự động (Tiếng Việt)' : '📱 Auto (English)')
                    : (appLanguageMode == 'vi' ? '🇻🇳 Tiếng Việt' : '🇺🇸 English'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final newLang = await showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text(appLanguage == 'vi' ? 'Chọn ngôn ngữ' : 'Select Language'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 'vi'),
                        child: const Text('🇻🇳 Tiếng Việt'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 'en'),
                        child: const Text('🇺🇸 English'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 'auto'),
                        child: Text(appLanguage == 'vi' ? '📱 Tự động theo thiết bị' : '📱 Auto (Device)'),
                      ),
                    ],
                  ),
                );
                if (newLang != null && newLang != appLanguageMode) {
                  setState(() {
                    appLanguageMode = newLang;
                    if (newLang == 'auto') {
                      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
                      appLanguage = deviceLocale == 'vi' ? 'vi' : 'en';
                    } else {
                      appLanguage = newLang;
                    }
                  });
                  final prefs = appPrefs ?? await SharedPreferences.getInstance();
                  await prefs.setString(keyLanguage, newLang);
                  widget.onLanguageChanged?.call();
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.attach_money),
              title: Text(appLanguage == 'vi' ? 'Đơn vị tiền tệ' : 'Currency'),
              subtitle: Text(appCurrency == 'đ' ? 'VND (đ)' : 'USD (\$)'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final newCurrency = await showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: const Text('Chọn đơn vị tiền tệ'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 'đ'),
                        child: const Text('VND (đ)'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, '\$'),
                        child: const Text('USD (\$)'),
                      ),
                    ],
                  ),
                );
                if (newCurrency != null && newCurrency != appCurrency) {
                  setState(() => appCurrency = newCurrency);
                  final prefs = appPrefs ?? await SharedPreferences.getInstance();
                  await prefs.setString(keyCurrency, newCurrency);
                  if (newCurrency == '\$') await fetchExchangeRate();
                  widget.onLanguageChanged?.call();
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          // Theme Toggle Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text(appLanguage == 'vi' ? 'Giao diện' : 'Theme'),
              subtitle: Text(
                appThemeMode == 'light' 
                    ? (appLanguage == 'vi' ? '🌕 Sáng' : '🌕 Light')
                    : appThemeMode == 'dark' 
                        ? (appLanguage == 'vi' ? '🌑 Tối' : '🌑 Dark')
                        : (appLanguage == 'vi' ? '🌗 Theo hệ thống' : '🌗 System'),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final newTheme = await showDialog<String>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    title: Text(appLanguage == 'vi' ? 'Chọn giao diện' : 'Select Theme'),
                    children: [
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 'light'),
                        child: Text(appLanguage == 'vi' ? '🌕 Sáng' : '🌕 Light'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 'dark'),
                        child: Text(appLanguage == 'vi' ? '🌑 Tối' : '🌑 Dark'),
                      ),
                      SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, 'system'),
                        child: Text(appLanguage == 'vi' ? '🌗 Theo hệ thống' : '🌗 System'),
                      ),
                    ],
                  ),
                );
                if (newTheme != null && newTheme != appThemeMode) {
                  setState(() {
                    setThemeMode(newTheme);
                  });
                }
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(appLanguage == 'vi' ? 'Phiên bản' : 'Version'),
              subtitle: const Text('1.0.0-vochicuongg'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('VFinance', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('1.0.0-vochicuongg', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
                        const SizedBox(height: 16),
                        Text(
                          appLanguage == 'vi'
                              ? 'Quản lý chi tiêu trên Android\nPhát triển bởi © 2025-vochicuongg.'
                              : 'Expense Manager on Android\nDeveloped by © 2025-vochicuongg.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(appLanguage == 'vi' ? 'Đóng' : 'Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code),
              title: Text(appLanguage == 'vi' ? 'Mã QR liên hệ' : 'Contact QR Code'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(appLanguage == 'vi' ? 'Mã QR' : 'QR Code')),
                      body: Center(
                        child: Image.asset('assets/images/qr_code.png', width: 250),
                      ),
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
}
