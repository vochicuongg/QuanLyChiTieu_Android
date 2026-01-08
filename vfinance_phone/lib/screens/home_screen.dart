import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../screens.dart' hide SettingsScreen, LichSuScreen;
import '../widgets/animated_gradient_card.dart';

/// Home Screen - Dashboard with balance card and category grid
class HomeScreen extends StatefulWidget {
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

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {


  String _getGreeting({String? name}) {
    final hour = DateTime.now().hour;
    final displayName = name ?? '';
    final hasName = displayName.isNotEmpty;
    
    if (appLanguage == 'vi') {
      if (hour >= 5 && hour < 11) return hasName ? '🌞 Chào buổi sáng nha $displayName! Chi tiêu thật "chill" nha.' : '🌞 Chào buổi sáng! Chi tiêu thật "chill" nha.';
      if (hour >= 11 && hour < 13) return hasName ? '☀️ $displayName ơi, trưa ăn thật "feel" và nhớ ghi lại "bill" nha.' : '☀️ Ấy ơi, trưa ăn thật "feel" và nhớ ghi lại "bill" nha.';
      if (hour >= 13 && hour < 18) return hasName ? '⛅ Chiều vui vẻ $displayName ơi, và "Đừng để tiền rơi" nhé.' : '⛅ Chiều vui vẻ nhé ấy ơi, và "Đừng để tiền rơi" nhé.';
      if (hour >= 18 && hour < 22) return hasName ? '🌙 Tối lo "chốt sổ", sáng mai khỏi "khổ" nha $displayName ơi.' : '🌙 Tối lo "chốt sổ", để mai khỏi "khổ" nha.';
      return hasName ? '🌠 Ngủ sớm thôi $displayName ơi! Lãi quan trọng nhất vẫn là lãi sức khỏe.' : '🌠 Ngủ sớm thôi nào! Lãi quan trọng nhất vẫn là lãi sức khỏe.';
    } else {
      if (hour >= 5 && hour < 11) return hasName ? '🌞 Good morning, $displayName! Keep your spending "chill" today.' : '🌞 Good morning! Keep your spending "chill" today.';
      if (hour >= 11 && hour < 13) return hasName ? '☀️ Hey $displayName, enjoy your meal and remember to log the "bill".' : '☀️ Hey there, enjoy your meal and remember to log the "bill".';
      if (hour >= 13 && hour < 18) return hasName ? '⛅ Good afternoon, $displayName! Don\'t let your money slip away.' : '⛅ Good afternoon! Don\'t let your money slip away.';
      if (hour >= 18 && hour < 22)return hasName ? '🌙 Evening, $displayName! "Close the books" now for a worry-free tomorrow.' : '🌙 Evening! "Close the books" now for a worry-free tomorrow.';
}
return hasName 
    ? '🌠 Time to sleep, $displayName! Health is the best investment.' 
    : '🌠 Time to sleep! Health is the best investment.';
    }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  int _tongMuc(ChiTieuMuc muc) {
    final list = widget.chiTheoMuc[muc] ?? <ChiTieuItem>[];
    return list.fold(0, (a, b) => _sameDay(b.thoiGian, widget.currentDay) ? a + b.soTien : a);
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.allTimeIncome - widget.allTimeExpenses;
    final categories = ChiTieuMuc.values.where((m) =>
      m != ChiTieuMuc.lichSu && m != ChiTieuMuc.caiDat
    ).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card with Premium Animated Gradient
          AnimatedGradientCard(
            colors: const [
              Color(0xFF2010A1), // Deep Blue
              Color(0xDF42CFC4), // Teal
              Color(0xFF42CFC4), // Teal
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(name: FirebaseAuth.instance.currentUser?.displayName),
                  style: TextStyle(
                    color: Colors.white, 
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 1),
                        blurRadius: 1,
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
                    color: remaining >= 0 ? Colors.white : Colors.red,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: const Offset(0, 1),
                        blurRadius: 1,
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
                      amount: formatAmountWithCurrency(widget.monthlyIncome),
                      icon: Icons.add_circle_outline,
                      color: const Color(0xFF00D366),
                    ),
                    _BalanceInfo(
                      label: appLanguage == 'vi' ? 'Chi tiêu' : 'Expenses',
                      amount: formatAmountWithCurrency(widget.monthlyExpenses),
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
                ? 'Tổng chi tiêu ${widget.currentDay.day}/${widget.currentDay.month}:'
                : 'Spending ${getMonthName(widget.currentDay.month)} ${getOrdinalSuffix(widget.currentDay.day)}:',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            formatAmountWithCurrency(widget.tongHomNay),
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
                displayAmount = (widget.chiTheoMuc[ChiTieuMuc.soDu] ?? <ChiTieuItem>[])
                    .where((item) => _sameDay(item.thoiGian, widget.currentDay))
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
                onTap: () => widget.onCategoryTap(muc),
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
