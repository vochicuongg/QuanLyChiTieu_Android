import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../services/auth_service.dart';

/// Budget Screen - Set spending limits and track progress per category
class BudgetScreen extends StatefulWidget {
  final Map<ChiTieuMuc, List<ChiTieuItem>> chiTheoMuc;
  final Map<String, Map<String, List<HistoryEntry>>> lichSuThang;
  final DateTime currentDay;

  const BudgetScreen({
    super.key,
    required this.chiTheoMuc,
    required this.lichSuThang,
    required this.currentDay,
  });

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  Map<String, int> _budgets = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  /// Loads budgets from Firestore (per-user) for Cloud First architecture
  Future<void> _loadBudgets() async {
    final user = authService.currentUser;
    if (user == null) {
      // Guest mode: no budgets stored
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('budgets')
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _budgets = Map<String, int>.from(
            data.map((k, v) => MapEntry(k, (v as num).toInt())),
          );
        });
      }
    } catch (e) {
      debugPrint('[BudgetScreen] Error loading budgets: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Saves budgets to Firestore (per-user) for Cloud First architecture
  Future<void> _saveBudgets() async {
    final user = authService.currentUser;
    if (user == null) {
      // Guest mode: show message that login is required
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appLanguage == 'vi'
                ? 'Đăng nhập để lưu hạn mức ngân sách'
                : 'Sign in to save budget limits'),
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('budgets')
          .set(_budgets);
    } catch (e) {
      debugPrint('[BudgetScreen] Error saving budgets: $e');
    }
  }

  int _getMonthlySpending(ChiTieuMuc muc) {
    final currentMonthKey = getMonthKey(widget.currentDay);
    final todayDayKey = dinhDangNgayDayDu(widget.currentDay);
    
    // Today's spending
    int total = (widget.chiTheoMuc[muc] ?? []).fold(0, (sum, item) => sum + item.soTien);
    
    // History spending for current month
    final currentMonthData = widget.lichSuThang[currentMonthKey];
    if (currentMonthData != null) {
      for (final dayEntry in currentMonthData.entries) {
        if (dayEntry.key == todayDayKey) continue;
        for (final entry in dayEntry.value) {
          if (entry.muc == muc) {
            total += entry.item.soTien;
          }
        }
      }
    }
    return total;
  }

  void _showBudgetDialog(ChiTieuMuc muc) {
    final controller = TextEditingController(
      text: _budgets[muc.name]?.toString() ?? '',
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          appLanguage == 'vi' ? 'Đặt hạn mức cho ${muc.ten}' : 'Set budget for ${muc.ten}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: appLanguage == 'vi' ? 'Nhập hạn mức' : 'Enter budget',
            prefixIcon: const Icon(Icons.account_balance_wallet),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLanguage == 'vi' ? 'Hủy' : 'Cancel'),
          ),
          if (_budgets.containsKey(muc.name))
            TextButton(
              onPressed: () {
                setState(() => _budgets.remove(muc.name));
                _saveBudgets();
                Navigator.pop(context);
              },
              child: Text(
                appLanguage == 'vi' ? 'Xóa' : 'Remove',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                setState(() => _budgets[muc.name] = value);
                _saveBudgets();
              }
              Navigator.pop(context);
            },
            child: Text(appLanguage == 'vi' ? 'Lưu' : 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(appLanguage == 'vi' ? 'Ngân sách' : 'Budget', style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Categories that can have budgets (exclude soDu, lichSu, caiDat)
    final budgetableCategories = ChiTieuMuc.values.where((m) =>
      m != ChiTieuMuc.soDu && m != ChiTieuMuc.lichSu && m != ChiTieuMuc.caiDat
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(appLanguage == 'vi' ? 'Ngân sách' : 'Budget', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: primaryColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLanguage == 'vi' ? 'Quản lý ngân sách' : 'Budget Management',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appLanguage == 'vi'
                                  ? 'Đặt hạn mức chi tiêu cho từng danh mục'
                                  : 'Set spending limits for each category',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Budget categories with set limits
          if (_budgets.isNotEmpty) ...[
            Text(
              appLanguage == 'vi' ? 'Hạn mức đã đặt' : 'Active Budgets',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...budgetableCategories.where((m) => _budgets.containsKey(m.name)).map((muc) {
              final budget = _budgets[muc.name]!;
              final spent = _getMonthlySpending(muc);
              final progress = (spent / budget).clamp(0.0, 1.5);
              final isOverBudget = spent > budget;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _showBudgetDialog(muc),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: muc.color.withOpacity(0.2),
                              child: Icon(muc.icon, color: muc.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(muc.ten, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    '${formatAmountWithCurrency(spent)} / ${formatAmountWithCurrency(budget)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isOverBudget ? Colors.red : Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isOverBudget)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  appLanguage == 'vi' ? 'VƯỢT MỨC!' : 'OVER!',
                                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isOverBudget ? Colors.red : muc.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
          ],
          
          // Add budget section
          Text(
            appLanguage == 'vi' ? 'Thêm hạn mức' : 'Add Budget',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...budgetableCategories.where((m) => !_budgets.containsKey(m.name)).map((muc) {
            final spent = _getMonthlySpending(muc);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: muc.color.withOpacity(0.2),
                  child: Icon(muc.icon, color: muc.color, size: 20),
                ),
                title: Text(muc.ten, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: spent > 0
                    ? Text(
                        '${appLanguage == 'vi' ? 'Đã chi' : 'Spent'}: ${formatAmountWithCurrency(spent)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      )
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: primaryColor,
                  onPressed: () => _showBudgetDialog(muc),
                ),
                onTap: () => _showBudgetDialog(muc),
              ),
            );
          }),
        ],
      ),
    );
  }
}
