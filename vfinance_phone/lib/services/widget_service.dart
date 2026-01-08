import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WidgetService {
  static const String _providerName = 'VFinanceWidgetProvider';
  static const String _keyBalance = 'widget_balance';
  static const String _keyIncome = 'widget_income';
  static const String _keyExpense = 'widget_expense';
  static const String _keyGreeting = 'widget_greeting';
  static const String _keyDailyExpense = 'widget_daily_expense';
  static const String _keyDate = 'widget_date';
  static const String _keyBalanceLabel = 'widget_balance_label';
  static const String _keyDailyLabel = 'widget_daily_label';

  Future<void> updateWidgetData({
    required int balance,
    required int income,
    required int expense,
    required String appLanguage,
    String? displayName,
    int? dailyExpense,
    String? dateString,
  }) async {
    // Format data
    final balanceStr = _formatMoney(balance);
    final incomeStr = _formatMoney(income);
    final expenseStr = _formatMoney(expense);
    final dailyExpenseStr = dailyExpense != null ? _formatMoney(dailyExpense) : '0 ₫';
    final greeting = _getGreeting(appLanguage, displayName);
    final date = dateString ?? '';

    // Localized Labels
    final isVi = appLanguage == 'vi';
    final balanceLabel = isVi ? 'Số dư hiện tại' : 'Current Balance';
    final dailyLabel = isVi ? 'Tổng chi tiêu $date:' : 'Total Expense $date:';

    // Save data to SharedPreferences (Compatible with native Kotlin code)
    // Note: Flutter's SharedPreferences automatically adds "flutter." prefix to keys in the XML file.
    // So we use keys WITHOUT "flutter." prefix here.
    // In Kotlin, we read "flutter.widget_balance", "flutter.widget_greeting", etc.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBalance, balanceStr);
    await prefs.setString(_keyIncome, incomeStr);
    await prefs.setString(_keyExpense, expenseStr);
    await prefs.setString(_keyGreeting, greeting);
    await prefs.setString(_keyDailyExpense, dailyExpenseStr);
    await prefs.setString(_keyDate, date);
    await prefs.setString(_keyBalanceLabel, balanceLabel);
    await prefs.setString(_keyDailyLabel, dailyLabel);

    // Trigger update
    await HomeWidget.updateWidget(
      name: _providerName,
      androidName: _providerName,
    );
  }

  String _formatMoney(int amount) {
    // Manual format to guarantee "1.234.567 ₫" style
    final numberStr = amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (m) => '${m[1]}.'
    );
    return '$numberStr ₫';
  }

  String _getGreeting(String appLanguage, String? name) {
    final hour = DateTime.now().hour;
    final displayName = name ?? '';
    final hasName = displayName.isNotEmpty;
    
    if (appLanguage == 'vi') {
      if (hour >= 5 && hour < 11) return hasName ? '🌞 Chào buổi sáng nha $displayName! Chi tiêu thật "chill" nha.' : '🌞 Chào buổi sáng! Chi tiêu thật "chill" nha.';
      if (hour >= 11 && hour < 13) return hasName ? '☀️ $displayName ơi, trưa ăn thật "feel" và nhớ ghi lại "bill" nha.' : '☀️ Ấy ơi, trưa ăn thật "feel" và nhớ ghi lại "bill" nha.';
      if (hour >= 13 && hour < 18) return hasName ? '⛅ Chiều vui vẻ $displayName ơi, và "Đừng để tiền rơi" nhé.' : '⛅ Chiều vui vẻ nhé ấy ơi, và "Đừng để tiền rơi" nhé.';
      if (hour >= 18 && hour < 22) return hasName ? '🌙 Tối lo "chốt sổ", sáng mai khỏi "khổ" nha $displayName ơi.' : '🌙 Tối lo "chốt sổ", sáng mai khỏi "khổ" nha.';
      return hasName ? '🌠 Ngủ sớm thôi $displayName ơi!\nLãi quan trọng nhất vẫn là lãi sức khỏe.' : '🌠 Ngủ sớm thôi nào!\nLãi quan trọng nhất vẫn là lãi sức khỏe.';
    } else {
      if (hour >= 5 && hour < 11) return hasName ? '🌞 Good morning, $displayName! Keep your spending "chill" today.' : '🌞 Good morning! Keep your spending "chill" today.';
      if (hour >= 11 && hour < 13) return hasName ? '☀️ Hey $displayName, enjoy your meal and remember to log the "bill".' : '☀️ Hey there, enjoy your meal and remember to log the "bill".';
      if (hour >= 13 && hour < 18) return hasName ? '⛅ Good afternoon, $displayName! Don\'t let your money slip away.' : '⛅ Good afternoon! Don\'t let your money slip away.';
      if (hour >= 18 && hour < 22)return hasName ? '🌙 Evening, $displayName! "Close the books" now for a worry-free tomorrow.' : '🌙 Evening! "Close the books" now for a worry-free tomorrow.';
      return hasName ? '🌠 Time to sleep, $displayName!\nHealth is the best investment.' : '🌠 Time to sleep!\nHealth is the best investment.';
    }
  }
}
