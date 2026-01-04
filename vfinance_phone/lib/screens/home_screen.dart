import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../screens.dart' hide SettingsScreen, LichSuScreen;

/// Home Screen - Dashboard with balance card and category grid
class HomeScreen extends StatelessWidget {
  final Map<ChiTieuMuc, List<ChiTieuItem>> chiTheoMuc;
  final Map<String, Map<String, List<HistoryEntry>>> lichSuThang;
  final DateTime currentDay;
  final int allTimeIncome;
  final int allTimeExpenses;
  final int monthlyIncome;
  final int monthlyExpenses;
  final int tongHomNay;
  final Function(ChiTieuMuc) onCategoryTap;

  const HomeScreen({
    super.key,
    required this.chiTheoMuc,
    required this.lichSuThang,
    required this.currentDay,
    required this.allTimeIncome,
    required this.allTimeExpenses,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.tongHomNay,
    required this.onCategoryTap,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (appLanguage == 'vi') {
      if (hour >= 5 && hour < 11) return '🌞 Buổi sáng vui vẻ nho';
      if (hour >= 11 && hour < 13) return '☀️ Nghỉ trưa thư giãn nhen';
      if (hour >= 13 && hour < 18) return '⛅ Buổi chiều mát mẻ nha';
      if (hour >= 18 && hour < 22) return '🌙 Buổi tối ấm áp nhé';
      return '🌠 Nghỉ ngơi sớm đi nè';
    } else {
      if (hour >= 5 && hour < 11) return '🌞 Have a great morning';
      if (hour >= 11 && hour < 13) return '☀️ Have a relaxing lunch break';
      if (hour >= 13 && hour < 18) return '⛅ Have a lovely afternoon';
      if (hour >= 18 && hour < 22) return '🌙 Have a cozy evening';
      return '🌠 Have an early night';
    }
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  int _tongMuc(ChiTieuMuc muc) {
    final list = chiTheoMuc[muc] ?? <ChiTieuItem>[];
    return list.fold(0, (a, b) => _sameDay(b.thoiGian, currentDay) ? a + b.soTien : a);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = allTimeIncome - allTimeExpenses;
    final categories = ChiTieuMuc.values.where((m) =>
      m != ChiTieuMuc.lichSu && m != ChiTieuMuc.caiDat
    ).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card with Gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4355F0), Color(0xFF2BC0E4), Color(0xFF4FF2C6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, ${FirebaseAuth.instance.currentUser?.displayName ?? (appLanguage == 'vi' ? 'Khách' : 'User')}.',
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5), // Màu bóng (đen mờ 50%)
                        offset: const Offset(0, 1),           // Độ lệch (x: 2, y: 2) -> Bóng đổ xuống góc phải
                        blurRadius: 1,                        // Độ nhòe của bóng
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  appLanguage == 'vi' ? 'Số dư còn lại' : 'Remaining Balance',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  remaining >= 0
                      ? formatAmountWithCurrency(remaining)
                      : '-${formatAmountWithCurrency(remaining.abs())}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5), // Màu bóng (đen mờ 50%)
                        offset: const Offset(0, 1),           // Độ lệch (x: 2, y: 2) -> Bóng đổ xuống góc phải
                        blurRadius: 1,                        // Độ nhòe của bóng
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BalanceInfo(
                      label: appLanguage == 'vi' ? 'Thu nhập' : 'Income',
                      amount: formatAmountWithCurrency(monthlyIncome),
                      icon: Icons.add_circle_outline,
                      color: Colors.greenAccent,
                    ),
                    _BalanceInfo(
                      label: appLanguage == 'vi' ? 'Chi tiêu' : 'Expenses',
                      amount: formatAmountWithCurrency(monthlyExpenses),
                      icon: Icons.remove_circle_outline,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Today's spending
          Text(
            appLanguage == 'vi'
                ? 'Tổng chi tiêu ${currentDay.day}/${currentDay.month}:'
                : 'Spending ${getMonthName(currentDay.month)} ${getOrdinalSuffix(currentDay.day)}:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            formatAmountWithCurrency(tongHomNay),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: expenseColor,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.5), // Màu bóng (đen mờ 50%)
                  offset: const Offset(0, 0.5),           // Độ lệch (x: 2, y: 2) -> Bóng đổ xuống góc phải
                  blurRadius: 0.5,                        // Độ nhòe của bóng
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Categories Grid
          Text(
            appLanguage == 'vi' ? 'Danh mục' : 'Categories',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final muc = categories[index];
              int displayAmount;
              if (muc == ChiTieuMuc.soDu) {
                displayAmount = (chiTheoMuc[ChiTieuMuc.soDu] ?? <ChiTieuItem>[])
                    .where((item) => _sameDay(item.thoiGian, currentDay))
                    .fold(0, (sum, item) => sum + item.soTien);
              } else {
                displayAmount = _tongMuc(muc);
              }

              return _MobileCategoryCard(
                icon: muc.icon,
                label: muc.ten,
                amount: displayAmount,
                color: muc.color,
                isBalance: muc == ChiTieuMuc.soDu,
                onTap: () => onCategoryTap(muc),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BalanceInfo extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  const _BalanceInfo({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label, 
              style: TextStyle(
                color: Colors.white, 
                fontSize: 14, 
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              )
            ),
            Text(
              amount, 
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.w600, 
                fontSize: 14,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(0, 1),
                    blurRadius: 2,
                  ),
                ],
              )
            ),
          ],
        ),
      ],
    );
  }
}

class _MobileCategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int amount;
  final Color color;
  final bool isBalance;
  final VoidCallback onTap;

  const _MobileCategoryCard({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.onTap,
    this.isBalance = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (amount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  formatAmountWithCurrency(amount),
                  style: TextStyle(
                    color: isBalance ? incomeColor : expenseColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
