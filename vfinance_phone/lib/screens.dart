import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'services/auth_service.dart';
import 'services/transaction_service.dart'; // Cloud First
import 'services/notification_service.dart'; // Budget notifications
import 'models/expense_categories.dart'; // Hierarchical categories
import 'widgets/category_picker.dart'; // Category picker dialog
import 'widgets/num_pad.dart'; // Custom numeric keypad
import 'widgets/custom_keyboard.dart'; // Custom alphabetic keypad
import 'package:firebase_core/firebase_core.dart';
import 'screens/login_screen.dart';

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
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const NhapSoDuScreen()),
    );

    if (result != null) {
      final soTien = result['soTien'] as int;
      final ten = result['ten'] as String?;
      
      if (soTien > 0) {
        final now = DateTime.now();
        final newItem = ChiTieuItem(soTien: soTien, thoiGian: now, tenChiTieu: ten);
        
        // Optimistic UI update for immediate feedback
        setState(() {
          danhSachThuNhap.add(newItem);
        });
        
        // Cloud First: When logged in, save to Firestore (main screen listens to stream)
        // When guest mode, also call the callback to update main screen
        if (transactionService.isLoggedIn) {
          transactionService.add(
            muc: ChiTieuMuc.soDu.name,
            soTien: soTien,
            thoiGian: now,
            ghiChu: ten,
          );
        } else {
          widget.onDataChanged?.call(danhSachThuNhap);
        }
      }
    }
  }

  Future<void> chinhSuaThuNhap(int index) async {
    if (dangChonXoa) return;
    final item = danhSachThuNhap[index];
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => NhapSoDuScreen(
          tenBanDau: item.tenChiTieu,
          soTienBanDau: item.soTien,
        ),
      ),
    );

    if (result != null) {
      final soTienMoi = result['soTien'] as int;
      final tenMoi = result['ten'] as String?;
      
      if (soTienMoi > 0) {
        final now = DateTime.now();
        final updatedItem = item.copyWith(soTien: soTienMoi, thoiGian: now, tenChiTieu: tenMoi);
        
        // Optimistic UI update for immediate feedback
        setState(() {
          danhSachThuNhap[index] = updatedItem;
        });
        
        // Cloud First: When logged in, update Firestore (main screen listens to stream)
        // When guest mode, use local callback
        if (transactionService.isLoggedIn) {
          if (item.id != null) {
            transactionService.update(
              item.id!,
              soTien: soTienMoi,
              thoiGian: now,
              ghiChu: tenMoi,
            );
          }
        } else {
          widget.onDataChanged?.call(danhSachThuNhap);
        }
      }
    }
  }

  Future<void> xoaThuNhap(int index) async {
    final item = danhSachThuNhap[index];
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLanguage == 'vi' ? 'Xác nhận' : 'Confirm', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(appLanguage == 'vi' 
          ? "Bạn có muốn xóa thu nhập ${formatAmountWithCurrency(item.soTien)} này không?"
          : "Do you want to delete this income ${formatAmountWithCurrency(item.soTien)}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appLanguage == 'vi' ? 'Hủy' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(appLanguage == 'vi' ? 'Xóa' : 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Optimistic UI update for immediate feedback
    setState(() {
      danhSachThuNhap.removeAt(index);
    });
    
    // Cloud First: When logged in, delete from Firestore (main screen listens to stream)
    // When guest mode, use local callback
    if (transactionService.isLoggedIn) {
      if (item.id != null) {
        transactionService.delete(item.id!);
      }
    } else {
      widget.onDataChanged?.call(danhSachThuNhap);
    }
  }

  @override
  Widget build(BuildContext context) {
    final remaining = tongThuNhap - widget.tongChiHomNay - widget.tongChiLichSu;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // Only use callback for guest mode; logged in users get data from Firestore stream
        if (didPop && !transactionService.isLoggedIn) {
          widget.onDataChanged?.call(danhSachThuNhap);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(ChiTieuMuc.soDu.ten),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Only use callback for guest mode
              if (!transactionService.isLoggedIn) {
                widget.onDataChanged?.call(danhSachThuNhap);
              }
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
                   
                        
                        Text(
                          appLanguage == 'vi' ? 'Tổng thu nhập' : 'Total Income',
                          style: const TextStyle(color: Colors.white),
                        ),
                      
                    const SizedBox(height: 12),
                    Text(
                      formatAmountWithCurrency(tongThuNhap),
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              Text(
                appLanguage == 'vi' ? 'Danh sách thu nhập' : 'Income list',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              if (danhSachThuNhap.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(appLanguage == 'vi' ? 'Chưa có thu nhập nào' : 'No income yet', 
                    style: const TextStyle(color: Colors.grey)),
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
                          child: Icon(Icons.add_rounded, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        title: Text(
                          item.tenChiTieu ?? formatAmountWithCurrency(item.soTien),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: item.tenChiTieu != null 
                            ? Text('${formatAmountWithCurrency(item.soTien)} • ${dinhDangGio(item.thoiGian)}')
                            : Text(dinhDangGio(item.thoiGian)),
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NhapSoTienScreen(
        parentCategoryId: widget.muc.name,
      )),
    );

    // Extract amount from result (can be Map or int)
    int? soTien;
    String? subCategory;
    String? tenChiTieu;
    if (result is Map) {
      soTien = result['amount'] as int?;
      subCategory = result['category'] as String?;
      tenChiTieu = result['name'] as String?;
    } else if (result is int) {
      soTien = result;
    }

    if (soTien != null && soTien > 0) {
      final now = DateTime.now();
      final newItem = ChiTieuItem(soTien: soTien, thoiGian: now, subCategory: subCategory, tenChiTieu: tenChiTieu);
      
      // Check budget thresholds before adding (only for logged-in users)
      if (transactionService.isLoggedIn) {
        await _checkBudgetAndNotify(widget.muc.name, soTien);
      }
      
      // Optimistic UI update for immediate feedback
      setState(() {
        danhSachChi.add(newItem);
      });
      
      // Cloud First: When logged in, save to Firestore (main screen listens to stream)
      if (transactionService.isLoggedIn) {
        transactionService.add(
          muc: widget.muc.name,
          soTien: soTien,
          thoiGian: now,
          subCategory: subCategory,
          ghiChu: tenChiTieu,
        );
      } else {
        widget.onDataChanged?.call(danhSachChi);
      }
    }
  }
  
  /// Check budget thresholds and trigger notifications
  Future<void> _checkBudgetAndNotify(String mucName, int newAmount) async {
    try {
      final user = authService.currentUser;
      if (user == null) return;
      
      // Get budget for this category
      final budgetDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('budgets')
          .get();
      
      if (!budgetDoc.exists) return;
      
      final budgets = budgetDoc.data() ?? {};
      final budgetLimit = (budgets[mucName] as num?)?.toInt() ?? 0;
      if (budgetLimit <= 0) return;
      
      // Calculate current total for this category (before adding new amount)
      final currentTotal = danhSachChi.fold(0, (sum, item) => sum + item.soTien);
      
      // Check thresholds
      await notificationService.checkBudgetThresholds(
        categoryName: widget.muc.ten,
        currentTotal: currentTotal,
        newAmount: newAmount,
        budgetLimit: budgetLimit,
      );
    } catch (e) {
      debugPrint('[BudgetNotification] Error: $e');
    }
  }

  Future<void> chinhSuaChiTieu(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NhapSoTienScreen(
          soTienBanDau: danhSachChi[index].soTien,
          initialCategory: danhSachChi[index].subCategory,
          parentCategoryId: widget.muc.name,
          tenBanDau: danhSachChi[index].tenChiTieu,
        ),
      ),
    );

    // Extract result (can be Map or int) - matched logic with themChiTieu
    int? soTienMoi;
    String? subCategoryMoi;
    String? tenChiTieuMoi;

    if (result is Map) {
      soTienMoi = result['amount'] as int?;
      subCategoryMoi = result['category'] as String?;
      tenChiTieuMoi = result['name'] as String?;
    } else if (result is int) {
      soTienMoi = result;
    }

    if (soTienMoi != null && soTienMoi > 0) {
      final item = danhSachChi[index];
      final now = DateTime.now();
      // Keep old values if not updated (though result usually has them if picker is used)
      // Actually if result is int, subCategory and name are null, but we should probably keep old ones?
      // Wait, if result is int (from simple input without picker changes?), it means user didn't change category.
      // usages of NhapSoTienScreen logic suggests if showCategoryPicker is true, it returns Map if category selected.
      
      // If user didn't change category (result is int), keep old subCategory/name
      final finalSubCategory = (result is Map) ? subCategoryMoi : item.subCategory;
      final finalTenChiTieu = (result is Map) ? tenChiTieuMoi : item.tenChiTieu;

      final updatedItem = item.copyWith(
        soTien: soTienMoi, 
        thoiGian: now,
        subCategory: finalSubCategory,
        tenChiTieu: finalTenChiTieu,
      );
      
      // Optimistic UI update for immediate feedback
      setState(() {
        danhSachChi[index] = updatedItem;
      });
      
      // Cloud First: When logged in, update Firestore (main screen listens to stream)
      if (transactionService.isLoggedIn) {
        if (item.id != null) {
          transactionService.update(
            item.id!,
            soTien: soTienMoi,
            thoiGian: now,
            subCategory: finalSubCategory,
            ghiChu: finalTenChiTieu,
          );
        }
      } else {
        widget.onDataChanged?.call(danhSachChi);
      }
    }
  }

  Future<void> xoaChiTieu(int index) async {
    final item = danhSachChi[index];
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLanguage == 'vi' ? 'Xác nhận' : 'Confirm', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(appLanguage == 'vi' 
          ? "Bạn có muốn xóa chi tiêu ${formatAmountWithCurrency(item.soTien)} này không?"
          : "Do you want to delete this expense ${formatAmountWithCurrency(item.soTien)}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appLanguage == 'vi' ? 'Hủy' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(appLanguage == 'vi' ? 'Xóa' : 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Optimistic UI update for immediate feedback
    setState(() {
      danhSachChi.removeAt(index);
    });
    
    // Cloud First: When logged in, delete from Firestore (main screen listens to stream)
    // When guest mode, use local callback
    if (transactionService.isLoggedIn) {
      if (item.id != null) {
        transactionService.delete(item.id!);
      }
    } else {
      widget.onDataChanged?.call(danhSachChi);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // Only use callback for guest mode; logged in users get data from Firestore stream
        if (didPop && !transactionService.isLoggedIn) {
          widget.onDataChanged?.call(danhSachChi);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.muc.ten),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Only use callback for guest mode
              if (!transactionService.isLoggedIn) {
                widget.onDataChanged?.call(danhSachChi);
              }
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
                  gradient: LinearGradient(
                    colors: [widget.muc.color, widget.muc.color.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appLanguage == 'vi' ? 'Tổng chi phí ${widget.muc.ten}' : 'Total cost ${widget.muc.ten}', style: const TextStyle(color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      formatAmountWithCurrency(tongChi),
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (danhSachChi.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(appLanguage == 'vi' ? 'Chưa có chi tiêu nào' : 'No expenses yet', style: const TextStyle(color: Colors.grey)),
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
                          child: Icon(
                            item.subCategory != null 
                                ? getCategoryIcon(item.subCategory!)
                                : widget.muc.icon, 
                            color: widget.muc.color, 
                            size: 20,
                          ),
                        ),
                        title: Text(formatAmountWithCurrency(item.soTien), 
                          style: const TextStyle(color: Color(0xFFF08080))),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.subCategory != null)
                              Text(
                                item.tenChiTieu ?? getCategoryDisplayName(item.subCategory!, appLanguage),
                                style: TextStyle(
                                  color: widget.muc.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Text(dinhDangGio(item.thoiGian)),
                          ],
                        ),
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
      final now = DateTime.now();
      final soTien = result['soTien'] as int;
      final tenChiTieu = result['ten'] as String;
      final newItem = ChiTieuItem(
        soTien: soTien,
        thoiGian: now,
        tenChiTieu: tenChiTieu,
      );
      
      // Optimistic UI update for immediate feedback
      setState(() {
        danhSachChi.add(newItem);
      });
      
      // Cloud First: When logged in, save to Firestore (main screen listens to stream)
      if (transactionService.isLoggedIn) {
        transactionService.add(
          muc: ChiTieuMuc.khac.name,
          soTien: soTien,
          thoiGian: now,
          ghiChu: tenChiTieu,
        );
      } else {
        widget.onDataChanged?.call(danhSachChi);
      }
    }
  }

  Future<void> chinhSuaChiTieu(int index) async {
    final item = danhSachChi[index];
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => NhapKhacScreen(
          tenBanDau: item.tenChiTieu,
          soTienBanDau: item.soTien,
        ),
      ),
    );

    if (result != null) {
      final ten = result['ten'] as String;
      final soTien = result['soTien'] as int;
      final now = DateTime.now();
      final updatedItem = item.copyWith(
        tenChiTieu: ten,
        soTien: soTien,
        thoiGian: now,
      );
      
      // Optimistic UI update for immediate feedback
      setState(() {
        danhSachChi[index] = updatedItem;
      });
      
      // Cloud First: When logged in, update Firestore (main screen listens to stream)
      // When guest mode, use local callback
      if (transactionService.isLoggedIn) {
        if (item.id != null) {
          transactionService.update(
            item.id!,
            muc: ChiTieuMuc.khac.name,
            soTien: soTien,
            ghiChu: ten,
            thoiGian: now,
          );
        }
      } else {
        widget.onDataChanged?.call(danhSachChi);
      }
    }
  }

  Future<void> xoaChiTieu(int index) async {
    final item = danhSachChi[index];
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(appLanguage == 'vi' ? 'Xác nhận' : 'Confirm', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(appLanguage == 'vi' 
          ? "Bạn có muốn xóa chi tiêu '${formatAmountWithCurrency(item.soTien)}' này không?"
          : "Do you want to delete this expense '${formatAmountWithCurrency(item.soTien)}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(appLanguage == 'vi' ? 'Hủy' : 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(appLanguage == 'vi' ? 'Xóa' : 'Delete', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Optimistic UI update for immediate feedback
    setState(() {
      danhSachChi.removeAt(index);
    });
    
    // Cloud First: When logged in, delete from Firestore (main screen listens to stream)
    // When guest mode, use local callback
    if (transactionService.isLoggedIn) {
      if (item.id != null) {
        transactionService.delete(item.id!);
      }
    } else {
      widget.onDataChanged?.call(danhSachChi);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        // Only use callback for guest mode; logged in users get data from Firestore stream
        if (didPop && !transactionService.isLoggedIn) {
          widget.onDataChanged?.call(danhSachChi);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(ChiTieuMuc.khac.ten),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Only use callback for guest mode
              if (!transactionService.isLoggedIn) {
                widget.onDataChanged?.call(danhSachChi);
              }
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
                  gradient: LinearGradient(
                    colors: [Colors.grey, Colors.grey.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appLanguage == 'vi' ? 'Tổng chi khác' : 'Total Other Expenses', 
                    style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      formatAmountWithCurrency(tongChi),
                      style: const TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              if (danhSachChi.isEmpty)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(appLanguage == 'vi' ? 'Chưa có chi tiêu nào' : 'No expenses yet', 
                    style: const TextStyle(color: Colors.grey)),
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
                        title: Text(item.tenChiTieu ?? 'Chi tiêu', style: TextStyle(backgroundColor: Theme.of(context).brightness == Brightness.dark
                                                                                    ? Color(0xFF2D2D3F) 
                                                                                    : Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('${formatAmountWithCurrency(item.soTien)} • ${dinhDangGio(item.thoiGian)}',
                        style: TextStyle(backgroundColor: Theme.of(context).brightness == Brightness.dark
                                                                                    ? Color(0xFF2D2D3F) 
                                                                                    : Colors.white)),
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

// =================== NHẬP SỐ TIỀN SCREEN ===================
class NhapSoTienScreen extends StatefulWidget {
  final int? soTienBanDau;
  final String? initialCategory; // Optional initial category path
  final String? parentCategoryId; // Parent category for subcategory picker
  final bool showCategoryPicker; // Whether to show category selector
  final String? tenBanDau; // Initial name/note
  
  const NhapSoTienScreen({
    super.key, 
    this.soTienBanDau,
    this.initialCategory,
    this.parentCategoryId,
    this.showCategoryPicker = true,
    this.tenBanDau,
  });

  @override
  State<NhapSoTienScreen> createState() => _NhapSoTienScreenState();
}

class _NhapSoTienScreenState extends State<NhapSoTienScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  String _activeField = 'amount'; // 'amount' or 'name'

  String? _selectedCategory;
  bool _isNavigating = false; // Prevent double navigation

  bool get _isOtherCategory {
    if (_selectedCategory == null) return false;
    final parts = _selectedCategory!.split('.');
    if (parts.length < 2) return false;
    // Check if subId contains "khac" (e.g. khacNhaO, khac...)
    return parts[1].toLowerCase().contains('khac');
  }

  @override
  void initState() {
    super.initState();
    if (widget.soTienBanDau != null) {
      _controller.text = formatNumberWithDots(widget.soTienBanDau!);
    }
    if (widget.tenBanDau != null) {
      _nameController.text = widget.tenBanDau!;
    }
    _selectedCategory = widget.initialCategory;
    
    // Listen for focus changes
    _amountFocus.addListener(() {
      if (_amountFocus.hasFocus) {
        setState(() => _activeField = 'amount');
      }
    });
    
    _nameFocus.addListener(() {
      if (_nameFocus.hasFocus) {
        setState(() => _activeField = 'name');
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _amountFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _xacNhan() {
    if (_isNavigating) return; // Prevent double tap
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final soTien = int.tryParse(text.replaceAll('.', '').replaceAll(',', ''));

    if (soTien != null && soTien > 0 && mounted) {
      _isNavigating = true;
      // Return both amount and category if category picker is enabled
      if (widget.showCategoryPicker && _selectedCategory != null) {
        String? name;
        if (_isOtherCategory) {
          name = _nameController.text.trim();
          if (name.isEmpty) name = null;
        }
        Navigator.pop(context, {'amount': soTien, 'category': _selectedCategory, 'name': name});
      } else {
        Navigator.pop(context, soTien);
      }
    }
  }

  Future<void> _pickCategory() async {
    if (_isNavigating) return; // Prevent double tap
    _isNavigating = true;
    
    String? result;
    if (widget.parentCategoryId != null) {
      // Show subcategory picker for specific parent
      result = await showSubCategoryPicker(context, widget.parentCategoryId!);
      if (result != null) {
        // Store full path: parentId.subId
        result = '${widget.parentCategoryId}.$result';
      }
    } else {
      // Show full category picker
      result = await showCategoryPicker(context);
    }
    
    _isNavigating = false;
    if (result != null && mounted) {
      setState(() => _selectedCategory = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVi = appLanguage == 'vi';
    
    return Scaffold(
      appBar: AppBar(title: Text(isVi ? 'Nhập số tiền' : 'Enter amount')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Category selector (if enabled)
                  if (widget.showCategoryPicker) ...[
                    InkWell(
                      onTap: _pickCategory,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark 
                              ? const Color(0xFF2D2D3F) 
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedCategory != null 
                                ? getCategoryColor(_selectedCategory!) 
                                : Colors.grey.shade400,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedCategory != null 
                                  ? getCategoryIcon(_selectedCategory!)
                                  : Icons.category_outlined,
                              color: _selectedCategory != null 
                                  ? getCategoryColor(_selectedCategory!)
                                  : Colors.grey,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedCategory != null 
                                    ? getCategoryDisplayName(_selectedCategory!, appLanguage)
                                    : (isVi ? 'Chọn danh mục' : 'Select category'),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedCategory != null 
                                      ? null 
                                      : Colors.grey,
                                ),
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Custom Name input for Other categories
                  if (widget.showCategoryPicker && _isOtherCategory) ...[
                     TextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      // readOnly: false, // Default is false, enable system keyboard
                      showCursor: true,
                      decoration: InputDecoration(
                        labelText: appLanguage == 'vi' ? 'Tên khoản chi' : 'Expense Name',
                        hintText: appLanguage == 'vi' ? 'Ví dụ: Mua quà sinh nhật' : 'Ex: Birthday gift',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF2D2D3F) 
                            : Colors.grey[200],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Amount input
                  TextField(
                    controller: _controller,
                    focusNode: _amountFocus,
                    readOnly: true, // Disable system keyboard
                    showCursor: true,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0',
                        suffixText: '₫',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF2D2D3F) 
                            : Colors.grey[200],
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
                      child: Text(isVi ? 'Xác nhận' : 'Confirm', 
                      style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Custom Keyboards
          // Only show NumPad if _activeField is 'amount'
          if (_activeField == 'amount')
            NumPad(
              onInput: (val) {
                String currentText = _controller.text.replaceAll('.', '');
                if (val == '000') {
                  if (currentText.isNotEmpty) currentText += '000';
                } else {
                  currentText += val;
                }
                
                if (currentText.length > 15) return;
                
                final number = int.tryParse(currentText);
                if (number != null) {
                  _controller.text = formatNumberWithDots(number);
                }
              },
              onDelete: () {
                String currentText = _controller.text.replaceAll('.', '');
                if (currentText.isEmpty) return;
                
                currentText = currentText.substring(0, currentText.length - 1);
                
                if (currentText.isEmpty) {
                  _controller.text = '';
                } else {
                  final number = int.tryParse(currentText);
                  if (number != null) {
                    _controller.text = formatNumberWithDots(number);
                  }
                }
              },
            ),
          // Removed the else block that contained CustomKeyboard for _nameController
        ],
      ),
    );
  }
}

// =================== NHẬP SỐ DƯ SCREEN (WITH NAME) ===================
class NhapSoDuScreen extends StatefulWidget {
  final String? tenBanDau;
  final int? soTienBanDau;

  const NhapSoDuScreen({super.key, this.tenBanDau, this.soTienBanDau});

  @override
  State<NhapSoDuScreen> createState() => _NhapSoDuScreenState();
}

class _NhapSoDuScreenState extends State<NhapSoDuScreen> {
  final TextEditingController _tenController = TextEditingController();
  final TextEditingController _soTienController = TextEditingController();
  final FocusNode _tenFocus = FocusNode();
  final FocusNode _soTienFocus = FocusNode();
  String _activeField = 'ten';

  @override
  void initState() {
    super.initState();
    if (widget.tenBanDau != null) {
      _tenController.text = widget.tenBanDau!;
    }
    if (widget.soTienBanDau != null) {
      _soTienController.text = formatNumberWithDots(widget.soTienBanDau!);
    }
    
    _tenFocus.addListener(() {
      if (_tenFocus.hasFocus) setState(() => _activeField = 'ten');
    });
    
    _soTienFocus.addListener(() {
      if (_soTienFocus.hasFocus) setState(() => _activeField = 'soTien');
    });
  }

  void _xacNhan() {
    final ten = _tenController.text.trim();
    final text = _soTienController.text.trim();
    
    final soTien = int.tryParse(text.replaceAll('.', '').replaceAll(',', ''));

    // Name is optional for balance, only amount is required
    if (soTien != null && soTien > 0) {
      Navigator.pop(context, {'ten': ten.isEmpty ? null : ten, 'soTien': soTien});
    }
  }

  @override
  void dispose() {
    _tenController.dispose();
    _soTienController.dispose();
    _tenFocus.dispose();
    _soTienFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appLanguage == 'vi' ? 'Thêm số dư' : 'Add Balance')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
              controller: _tenController,
              focusNode: _tenFocus,
              // readOnly: false, // Default is false, enable system keyboard
              showCursor: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: appLanguage == 'vi' ? 'Tên số dư (tùy chọn)' : 'Balance Name (optional)',
                hintText: appLanguage == 'vi' ? 'VD: Lương tháng 1' : 'E.g. January Salary',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF2D2D3F) 
                    : Colors.grey[200],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _soTienController,
              focusNode: _soTienFocus,
              keyboardType: TextInputType.number,
              readOnly: true,
              showCursor: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                      decoration: InputDecoration(
                        labelText: appLanguage == 'vi' ? 'Số tiền' : 'Amount',
                        suffixText: '₫',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF2D2D3F) 
                            : Colors.grey[200],
                      ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _xacNhan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF93),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(appLanguage == 'vi' ? 'Xác nhận' : 'Confirm', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_activeField == 'soTien')
            NumPad(
              onInput: (val) {
                String currentText = _soTienController.text.replaceAll('.', '');
                if (val == '000') {
                  if (currentText.isNotEmpty) currentText += '000';
                } else {
                  currentText += val;
                }
                
                if (currentText.length > 15) return;
                
                final number = int.tryParse(currentText);
                if (number != null) {
                  _soTienController.text = formatNumberWithDots(number);
                }
              },
              onDelete: () {
                String currentText = _soTienController.text.replaceAll('.', '');
                if (currentText.isEmpty) return;
                
                currentText = currentText.substring(0, currentText.length - 1);
                
                if (currentText.isEmpty) {
                  _soTienController.text = '';
                } else {
                  final number = int.tryParse(currentText);
                  if (number != null) {
                    _soTienController.text = formatNumberWithDots(number);
                  }
                }
              },
            )
          // Removed the else block that contained CustomKeyboard for _tenController
        ],
      ),
    );
  }
}

// =================== NHẬP CHI TIÊU KHÁC SCREEN ===================
class NhapKhacScreen extends StatefulWidget {
  final String? tenBanDau;
  final int? soTienBanDau;

  const NhapKhacScreen({super.key, this.tenBanDau, this.soTienBanDau});

  @override
  State<NhapKhacScreen> createState() => _NhapKhacScreenState();
}

class _NhapKhacScreenState extends State<NhapKhacScreen> {
  final TextEditingController _tenController = TextEditingController();
  final TextEditingController _soTienController = TextEditingController();
  final FocusNode _tenFocus = FocusNode();
  final FocusNode _soTienFocus = FocusNode();
  String _activeField = 'ten';

  @override
  void initState() {
    super.initState();
    if (widget.tenBanDau != null) {
      _tenController.text = widget.tenBanDau!;
    }
    if (widget.soTienBanDau != null) {
      _soTienController.text = formatNumberWithDots(widget.soTienBanDau!);
    }
    
    _tenFocus.addListener(() {
      if (_tenFocus.hasFocus) setState(() => _activeField = 'ten');
    });
    
    _soTienFocus.addListener(() {
      if (_soTienFocus.hasFocus) setState(() => _activeField = 'soTien');
    });
  }

  void _xacNhan() {
    final ten = _tenController.text.trim();
    final text = _soTienController.text.trim();
    
    final soTien = int.tryParse(text.replaceAll('.', '').replaceAll(',', ''));

    if (ten.isNotEmpty && soTien != null && soTien > 0) {
      Navigator.pop(context, {'ten': ten, 'soTien': soTien});
    }
  }



  @override
  void dispose() {
    _tenController.dispose();
    _soTienController.dispose();
    _tenFocus.dispose();
    _soTienFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(appLanguage == 'vi' ? 'Thêm chi tiêu khác' : 'Add Other Expense')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _tenController,
                    focusNode: _tenFocus,
                    // readOnly: false, // Default is false, enable system keyboard
                    showCursor: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: appLanguage == 'vi' ? 'Tên chi tiêu' : 'Expense Name',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF2D2D3F) 
                          : Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _soTienController,
                    focusNode: _soTienFocus,
                    keyboardType: TextInputType.number,
                    readOnly: true,
                    showCursor: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      ThousandsSeparatorInputFormatter(),
                    ],
                      decoration: InputDecoration(
                        labelText: appLanguage == 'vi' ? 'Số tiền' : 'Amount',
                        suffixText: '₫',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Theme.of(context).brightness == Brightness.dark 
                            ? const Color(0xFF2D2D3F) 
                            : Colors.grey[200],
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
                      child: Text(appLanguage == 'vi' ? 'Thêm' : 'Add', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_activeField == 'soTien')
            NumPad(
              onInput: (val) {
                String currentText = _soTienController.text.replaceAll('.', '');
                if (val == '000') {
                  if (currentText.isNotEmpty) currentText += '000';
                } else {
                  currentText += val;
                }
                
                if (currentText.length > 15) return;
                
                final number = int.tryParse(currentText);
                if (number != null) {
                  _soTienController.text = formatNumberWithDots(number);
                }
              },
              onDelete: () {
                String currentText = _soTienController.text.replaceAll('.', '');
                if (currentText.isEmpty) return;
                
                currentText = currentText.substring(0, currentText.length - 1);
                
                if (currentText.isEmpty) {
                  _soTienController.text = '';
                } else {
                  final number = int.tryParse(currentText);
                  if (number != null) {
                    _soTienController.text = formatNumberWithDots(number);
                  }
                }
              },
            )
        ],
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

                final totalMonthIncome = daysData.values
                    .expand((lst) => lst)
                    .where((e) => e.muc == ChiTieuMuc.soDu)
                    .fold(0, (s, e) => s + e.item.soTien);

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
                    title: Row(
                      children: [
                        Text(
                          appLanguage == 'vi' ? 'Tháng $monthKey' : '${getMonthName(int.parse(monthKey.split('/')[0]))} ${monthKey.split('/')[1]}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (totalMonth > 0)
                              Text(
                                formatAmountWithCurrency(totalMonth),
                                style: const TextStyle(color: Color(0xFFF08080), fontSize: 13.0, fontWeight: FontWeight.bold),
                              ),
                            if (totalMonthIncome > 0)
                              Text(
                                formatAmountWithCurrency(totalMonthIncome),
                                style: const TextStyle(color: Color(0xFF4CAF93), fontSize: 13.0, fontWeight: FontWeight.bold),
                              ),
                          ],
                        ),
                      ],
                    ),
                    children: sortedDays.map((dayKey) {
                      final itemsOnDay = daysData[dayKey]!;
                      final dayTotal = itemsOnDay
                          .where((e) => e.muc != ChiTieuMuc.soDu)
                          .fold(0, (sum, e) => sum + e.item.soTien);
                      final dayTotalIncome = itemsOnDay
                          .where((e) => e.muc == ChiTieuMuc.soDu)
                          .fold(0, (sum, e) => sum + e.item.soTien);

                      return ExpansionTile(
                        title: Row(
                          children: [
                            Text(appLanguage == 'vi' ? 'Ngày ${dayKey.split('/')[0]}' : '${getOrdinalSuffix(int.parse(dayKey.split('/')[0]))}'),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (dayTotal > 0)
                                  Text(
                                    formatAmountWithCurrency(dayTotal),
                                    style: const TextStyle(color: Color(0xFFF08080), fontSize: 12.0, fontWeight: FontWeight.bold),
                                  ),
                                if (dayTotalIncome > 0)
                                  Text(
                                    formatAmountWithCurrency(dayTotalIncome),
                                    style: const TextStyle(color: Color(0xFF4CAF93), fontSize: 12.0, fontWeight: FontWeight.bold),
                                  ),
                                if (dayTotalIncome == 0 && dayTotal == 0)
                                   Text(formatAmountWithCurrency(0), style: const TextStyle(color: Colors.white70, fontSize: 12.0)),
                              ],
                            ),
                          ],
                        ),
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
  final Map<ChiTieuMuc, List<ChiTieuItem>> chiTheoMuc;
  final Map<String, Map<String, List<HistoryEntry>>> lichSuThang;

  const SettingsScreen({
    super.key, 
    this.onLanguageChanged,
    required this.chiTheoMuc,
    required this.lichSuThang,
  });

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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                radius: 24,
                backgroundImage: authService.currentUser?.photoURL != null
                    ? NetworkImage(authService.currentUser!.photoURL!)
                    : null,
                child: authService.currentUser?.photoURL == null
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),
              title: Text(
                authService.currentUser?.displayName ?? (appLanguage == 'vi' ? 'Khách' : 'Guest'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
              subtitle: Text(
                authService.currentUser?.email ?? (appLanguage == 'vi' ? 'Chưa đăng nhập' : 'Not logged in'),
                style: const TextStyle(fontSize: 13.0),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(appLanguage == 'vi' ? 'Ngôn ngữ' : 'Language', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    title: Text(appLanguage == 'vi' ? 'Chọn ngôn ngữ' : 'Select Language', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          // Theme Toggle Card
          Card(
            child: ListTile(
              leading: const Icon(Icons.brightness_6),
              title: Text(appLanguage == 'vi' ? 'Giao diện' : 'Theme', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                    title: Text(appLanguage == 'vi' ? 'Chọn giao diện' : 'Select Theme', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              title: Text(appLanguage == 'vi' ? 'Phiên bản' : 'Version', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('1.0.0.adr-vochicuongg'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('VFinance', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('1.0.0.adr-vochicuongg', textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7))),
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
              title: Text(appLanguage == 'vi' ? 'Mã QR liên hệ' : 'Contact QR Code', style: const TextStyle(fontWeight: FontWeight.bold)),
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
          // Account Section
          if (authService.currentUser != null) ...[
            const SizedBox(height: 24),
            Text(
              appLanguage == 'vi' ? 'Sao lưu & Khôi phục' : 'Backup & Restore',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_upload, color: Colors.blue),
                title: Text(appLanguage == 'vi' ? 'Sao lưu dữ liệu' : 'Backup Data', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(appLanguage == 'vi' ? 'Lưu lên đám mây' : 'Save to cloud'),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLanguage == 'vi' ? 'Đang sao lưu...' : 'Backing up...')),
                  );
                  // Get all SharedPreferences data
                  final prefs = appPrefs ?? await SharedPreferences.getInstance();
                  final keys = prefs.getKeys();
                  final Map<String, dynamic> allData = {};
                  for (final key in keys) {
                    allData[key] = prefs.get(key);
                  }
                  await authService.backupData(allData);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(appLanguage == 'vi' ? ' Sao lưu thành công!' : 'Backup complete!')),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_download, color: Colors.green),
                title: Text(appLanguage == 'vi' ? 'Khôi phục dữ liệu' : 'Restore Data', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(appLanguage == 'vi' ? 'Tải từ đám mây' : 'Download from cloud'),
                onTap: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(appLanguage == 'vi' ? 'Đang khôi phục...' : 'Restoring...')),
                  );
                  final data = await authService.restoreData();
                  if (data != null) {
                    final prefs = appPrefs ?? await SharedPreferences.getInstance();
                    for (final entry in data.entries) {
                      if (entry.value is String) {
                        await prefs.setString(entry.key, entry.value);
                      } else if (entry.value is int) {
                        await prefs.setInt(entry.key, entry.value);
                      } else if (entry.value is double) {
                        await prefs.setDouble(entry.key, entry.value);
                      } else if (entry.value is bool) {
                        await prefs.setBool(entry.key, entry.value);
                      }
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(appLanguage == 'vi' ? 'Khôi phục thành công! Khởi động lại app để xem dữ liệu.' : 'Restored! Restart app to see data.')),
                      );
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(appLanguage == 'vi' ? 'Không có dữ liệu sao lưu' : 'No backup data found')),
                      );
                    }
                  }
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  appLanguage == 'vi' ? 'Đăng xuất' : 'Log Out',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(appLanguage == 'vi' ? 'Đăng xuất?' : 'Log Out?', style: const TextStyle(fontWeight: FontWeight.bold)),
                      content: Text(
                        appLanguage == 'vi'
                            ? 'Bạn có chắc muốn đăng xuất không?'
                            : 'Are you sure you want to log out?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(appLanguage == 'vi' ? 'Hủy' : 'Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            appLanguage == 'vi' ? 'Đăng xuất' : 'Log Out',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await authService.signOut();
                    final prefs = appPrefs ?? await SharedPreferences.getInstance();
                    await prefs.setBool('skipped_login', false);
                    if (mounted) {
                      // Restart app to show login screen
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        (route) => false,
                      );
                    }
                  }
                },
              ),
            ),
          ] else ...[
             const SizedBox(height: 24),
             Card(
               child: ListTile(
                 leading: const Icon(Icons.login, color: Colors.blue),
                 title: Text(
                   appLanguage == 'vi' ? 'Đăng nhập' : 'Sign In',
                   style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                 ),
                 subtitle: Text(
                   appLanguage == 'vi' ? 'Đăng nhập để đồng bộ dữ liệu' : 'Sign in to sync data',
                 ),
                 onTap: () {
                   // Capture Guest data before login for migration
                   final dataToMigrate = <Map<String, dynamic>>[];
                   final seenItems = <String>{}; // Track unique items to prevent duplicates
                   
                   // Helper to create unique key for an item
                   String itemKey(String muc, int soTien, String thoiGian) => '$muc|$soTien|$thoiGian';
                   
                   // Capture today's items
                   widget.chiTheoMuc.forEach((muc, items) {
                     for (var item in items) {
                       final key = itemKey(muc.name, item.soTien, item.thoiGian.toIso8601String());
                       if (!seenItems.contains(key)) {
                         seenItems.add(key);
                         dataToMigrate.add({
                           'muc': muc.name,
                           'soTien': item.soTien,
                           'thoiGian': item.thoiGian.toIso8601String(),
                           'ghiChu': item.tenChiTieu,
                         });
                       }
                     }
                   });
                   
                   // Capture history items (skip if already seen)
                   widget.lichSuThang.forEach((_, days) {
                     days.forEach((_, entries) {
                       for (var entry in entries) {
                         final key = itemKey(entry.muc.name, entry.item.soTien, entry.item.thoiGian.toIso8601String());
                         if (!seenItems.contains(key)) {
                           seenItems.add(key);
                           dataToMigrate.add({
                             'muc': entry.muc.name,
                             'soTien': entry.item.soTien,
                             'thoiGian': entry.item.thoiGian.toIso8601String(),
                             'ghiChu': entry.item.tenChiTieu,
                           });
                         }
                       }
                     });
                   });
                   
                   if (dataToMigrate.isNotEmpty) {
                     pendingMigrationData = dataToMigrate;
                     debugPrint('[SettingsScreen] Captured ${dataToMigrate.length} unique Guest items for migration.');
                   }
                   
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (_) => LoginScreen(
                         onLoginSuccess: () {
                           Navigator.pop(context);
                           // Refresh state to show user info
                           if (mounted) setState(() {});
                         },
                         onSkip: () {
                           // User skipped login, clear pending migration data
                           pendingMigrationData = null;
                           Navigator.pop(context);
                         },
                       ),
                     ),
                   );
                 },
               ),
             ),
          ],
        ],
      ),
    );
  }
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) return newValue.copyWith(text: '');
    
    // Parse to ensure valid number (remove leading zeros)
    int value = int.tryParse(newText) ?? 0;
    newText = value.toString();

    final buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      if (i > 0 && (newText.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(newText[i]);
    }
    
    final formattedText = buffer.toString();
    
    return newValue.copyWith(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length), // Keeps cursor at end
    );
  }
}

String formatNumberWithDots(int number) {
  final str = number.toString();
  final buffer = StringBuffer();
  for (int i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(str[i]);
  }
  return buffer.toString();
}
