import 'package:flutter/material.dart';
import 'expense_categories.dart';
import '../main.dart'; // For ChiTieuItem

/// Holds the comparison data for a single category
class CategoryComparisonData {
  final ChiTieuMuc category;
  final int baselineAmount;
  final int currentAmount;

  CategoryComparisonData({
    required this.category,
    required this.baselineAmount,
    required this.currentAmount,
  });

  /// Difference (Current - Baseline)
  int get delta => currentAmount - baselineAmount;

  /// Percentage Change: ((Current - Baseline) / Baseline) * 100
  double get percentageChange {
    if (baselineAmount == 0) {
      if (currentAmount == 0) return 0.0;
      return 100.0; // Infinite growth technically, but 100% simplifies UI
    }
    return ((currentAmount - baselineAmount) / baselineAmount) * 100;
  }
}

/// Holds the complete state of a comparison session
class ComparisonState {
  final DateTime baselineMonth;
  final DateTime currentMonth;
  final List<CategoryComparisonData> data;
  final int totalBaseline;
  final int totalCurrent;

  ComparisonState({
    required this.baselineMonth,
    required this.currentMonth,
    required this.data,
    required this.totalBaseline,
    required this.totalCurrent,
  });

  /// Delta of total expenses
  int get totalDelta => totalCurrent - totalBaseline;
  
  /// Total Percentage Change
  double get totalPercentageChange {
     if (totalBaseline == 0) {
      if (totalCurrent == 0) return 0.0;
      return 100.0;
    }
    return ((totalCurrent - totalBaseline) / totalBaseline) * 100;
  }
}

/// Logic to merge two datasets
class DataMerger {
  /// Merge two lists of transactions into a ComparisonState
  static ComparisonState mergeAndCompare({
    required DateTime baselineMonth,
    required DateTime currentMonth,
    required List<HistoryEntry> baselineItems,
    required List<HistoryEntry> currentItems,
  }) {
    // 1. Aggregate totals per month
    int baselineTotal = 0;
    int currentTotal = 0;
    
    // 2. Aggregate per category
    final Map<ChiTieuMuc, int> baselineMap = {};
    final Map<ChiTieuMuc, int> currentMap = {};

    for (var entry in baselineItems) {
      final item = entry.item;
      // Skip non-expense items if any (e.g. Income/Balance/Settings)
      if (entry.muc == ChiTieuMuc.soDu || entry.muc == ChiTieuMuc.lichSu || entry.muc == ChiTieuMuc.caiDat) continue;
      
      baselineTotal += item.soTien;
      baselineMap[entry.muc] = (baselineMap[entry.muc] ?? 0) + item.soTien;
    }

    for (var entry in currentItems) {
      final item = entry.item;
      if (entry.muc == ChiTieuMuc.soDu || entry.muc == ChiTieuMuc.lichSu || entry.muc == ChiTieuMuc.caiDat) continue;

      currentTotal += item.soTien;
      currentMap[entry.muc] = (currentMap[entry.muc] ?? 0) + item.soTien;
    }

    // 3. Union of all categories
    final allCategories = {...baselineMap.keys, ...currentMap.keys};
    
    // 4. Create comparison objects
    final List<CategoryComparisonData> comparisonList = [];
    
    for (var category in allCategories) {
      comparisonList.add(CategoryComparisonData(
        category: category,
        baselineAmount: baselineMap[category] ?? 0,
        currentAmount: currentMap[category] ?? 0,
      ));
    }

    // 5. Sort by Current Amount Descending (Meaningful for current month view)
    // Or maybe by Delta abs? Default to current spending impact.
    comparisonList.sort((a, b) => b.currentAmount.compareTo(a.currentAmount));

    return ComparisonState(
      baselineMonth: baselineMonth,
      currentMonth: currentMonth,
      data: comparisonList,
      totalBaseline: baselineTotal,
      totalCurrent: currentTotal,
    );
  }
}
