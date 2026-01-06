import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../widgets/num_pad.dart';
import '../widgets/animated_progress_bar.dart';

/// Budget Screen - Set spending limits and track progress per category
class BudgetScreen extends StatefulWidget {
  final Map<ChiTieuMuc, List<ChiTieuItem>> chiTheoMuc;
  final Map<String, Map<String, List<HistoryEntry>>> lichSuThang;
  final DateTime currentDay;
  final bool isVisible;

  const BudgetScreen({
    super.key,
    required this.chiTheoMuc,
    required this.lichSuThang,
    required this.currentDay,
    this.isVisible = false,
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

  // Helper to format number with dots
  String _formatNumberWithDots(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.'
    );
  }

  void _showBudgetDialog(ChiTieuMuc muc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // Initialize state OUTSIDE StatefulBuilder to persist across rebuilds
        String currentText = _budgets[muc.name]?.toString() ?? '';
        if (currentText.isNotEmpty) {
           final initialVal = int.tryParse(currentText);
           if (initialVal != null) currentText = _formatNumberWithDots(initialVal);
        }

        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {

            void handleInput(String val) {
              String rawText = currentText.replaceAll('.', '');
              if (val == '000') {
                 if (rawText.isNotEmpty) rawText += '000';
              } else {
                 rawText += val;
              }
              
              if (rawText.length > 15) return;

              final number = int.tryParse(rawText);
              if (number != null) {
                setSheetState(() {
                  currentText = _formatNumberWithDots(number);
                });
              }
            }

            void handleDelete() {
              String rawText = currentText.replaceAll('.', '');
              if (rawText.isEmpty) return;
              
              rawText = rawText.substring(0, rawText.length - 1);
              
              setSheetState(() {
                if (rawText.isEmpty) {
                  currentText = '';
                } else {
                  final number = int.tryParse(rawText);
                  if (number != null) {
                    currentText = _formatNumberWithDots(number);
                  }
                }
              });
            }

            return Column(
              children: [
                // Handle bar
                Container(
                   margin: const EdgeInsets.only(top: 8, bottom: 20),
                   width: 40, 
                   height: 4, 
                   decoration: BoxDecoration(
                     color: Colors.grey.withOpacity(0.3), 
                     borderRadius: BorderRadius.circular(2)
                   )
                ),
                
                // Title
                Text(
                  appLanguage == 'vi' ? 'Đặt hạn mức cho ${muc.ten}' : 'Set budget for ${muc.ten}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                
                const SizedBox(height: 30),
                
                // Display Area
                Text(
                  appLanguage == 'vi' ? 'Nhập hạn mức' : 'Enter budget',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                     Icon(Icons.account_balance_wallet, size: 28, color: muc.color),
                     const SizedBox(width: 12),
                     Text(
                       currentText.isEmpty ? '0' : currentText,
                       style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                     ),
                  ],
                ),
                
                const Spacer(),
                
                // NumPad
                NumPad(
                  onInput: handleInput,
                  onDelete: handleDelete,
                  onLongDelete: () {
                    setSheetState(() {
                      currentText = '';
                    });
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          appLanguage == 'vi' ? 'Hủy' : 'Cancel',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ),
                      const Spacer(),
                      if (_budgets.containsKey(muc.name))
                         TextButton(
                          onPressed: () {
                            setState(() => _budgets.remove(muc.name));
                            _saveBudgets();
                            Navigator.pop(context);
                          },
                          child: Text(
                            appLanguage == 'vi' ? 'Xóa' : 'Delete',
                            style: const TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ),
                      const SizedBox(width: 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        onPressed: () {
                          final value = int.tryParse(currentText.replaceAll('.', ''));
                          if (value != null && value > 0) {
                            setState(() => _budgets[muc.name] = value);
                            _saveBudgets();
                          }
                          Navigator.pop(context);
                        },
                        child: Text(
                          appLanguage == 'vi' ? 'Lưu' : 'Save', 
                          style: const TextStyle(fontSize: 16)
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
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
        title: Text(appLanguage == 'vi' ? 'Hạn mức' : 'Budget', style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                color: Theme.of(context).cardColor,
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (isOverBudget) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      appLanguage == 'vi' ? 'VƯỢT MỨC!' : 'OVER!',
                                      style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${formatAmountWithCurrency(spent - budget)}',
                                    style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ]
                                else ...[
                                  Text(
                                    appLanguage == 'vi' ? 'Còn lại' : 'Remaining',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                  ),
                                  Text(
                                    formatAmountWithCurrency(budget - spent),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AnimatedBudgetProgressBar(
                          key: ValueKey('${muc.name}_${widget.isVisible}'),
                          progress: progress,
                          color: muc.color,
                          overBudgetColor: Colors.red,
                          height: 8,
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
              color: Theme.of(context).cardColor,
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
