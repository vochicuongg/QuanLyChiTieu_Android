import 'package:flutter/material.dart';

/// ============================================================================
/// EXPENSE CATEGORIES - Each main category with its own subcategories
/// Matches the existing ChiTieuMuc enum structure
/// ============================================================================

/// Subcategory model
class ExpenseSubCategory {
  final String id;
  final String nameVi;
  final String nameEn;
  final IconData icon;
  
  const ExpenseSubCategory({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.icon,
  });
  
  String getName(String language) => language == 'vi' ? nameVi : nameEn;
}

/// Main category with subcategories
class ExpenseCategory {
  final String id;
  final String nameVi;
  final String nameEn;
  final IconData icon;
  final Color color;
  final List<ExpenseSubCategory> subCategories;
  
  const ExpenseCategory({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    required this.icon,
    required this.color,
    required this.subCategories,
  });
  
  String getName(String language) => language == 'vi' ? nameVi : nameEn;
}

/// All expense categories matching existing ChiTieuMuc enum
final List<ExpenseCategory> expenseCategories = [
  // 🏠 My Housing (nhaTro)
  ExpenseCategory(
    id: 'nhaTro',
    nameVi: 'Nhà ở',
    nameEn: 'Housing',
    icon: Icons.home_rounded,
    color: Colors.blue,
    subCategories: [
      ExpenseSubCategory(id: 'tienNha', nameVi: 'Tiền nhà', nameEn: 'Rent', icon: Icons.house_rounded),
      ExpenseSubCategory(id: 'tienDien', nameVi: 'Tiền điện', nameEn: 'Electricity', icon: Icons.flash_on_rounded),
      ExpenseSubCategory(id: 'tienNuoc', nameVi: 'Tiền nước', nameEn: 'Water', icon: Icons.water_drop_rounded),
      ExpenseSubCategory(id: 'wifi', nameVi: 'Wi-Fi/Internet', nameEn: 'Wi-Fi/Internet', icon: Icons.wifi_rounded),
      ExpenseSubCategory(id: 'khacNhaO', nameVi: 'Khác', nameEn: 'Other', icon: Icons.more_horiz_rounded),
    ],
  ),
  
  // 🎓 My Education (hocPhi)
  ExpenseCategory(
    id: 'hocPhi',
    nameVi: 'Học tập',
    nameEn: 'Education',
    icon: Icons.school_rounded,
    color: Colors.purple,
    subCategories: [
      ExpenseSubCategory(id: 'hocPhiChinh', nameVi: 'Học phí', nameEn: 'Tuition', icon: Icons.attach_money_rounded),
      ExpenseSubCategory(id: 'sachVo', nameVi: 'Sách vở', nameEn: 'Books', icon: Icons.menu_book_rounded),
      ExpenseSubCategory(id: 'khoaHoc', nameVi: 'Khóa học', nameEn: 'Courses', icon: Icons.cast_for_education_rounded),
      ExpenseSubCategory(id: 'vanPhongPham', nameVi: 'Văn phòng phẩm', nameEn: 'Stationery', icon: Icons.edit_rounded),
      ExpenseSubCategory(id: 'khacHocTap', nameVi: 'Khác', nameEn: 'Other', icon: Icons.more_horiz_rounded),
    ],
  ),
  
  // 🍜 Food (thucAn)
  ExpenseCategory(
    id: 'thucAn',
    nameVi: 'Thức ăn',
    nameEn: 'Food',
    icon: Icons.restaurant_rounded,
    color: Colors.orange,
    subCategories: [
      ExpenseSubCategory(id: 'thucAnChinh', nameVi: 'Thức ăn chính', nameEn: 'Main Course', icon: Icons.restaurant_rounded),
      ExpenseSubCategory(id: 'anVat', nameVi: 'Ăn vặt', nameEn: 'Snacks', icon: Icons.fastfood_rounded),
      ExpenseSubCategory(id: 'nhaHang', nameVi: 'Nhà hàng', nameEn: 'Restaurant', icon: Icons.dinner_dining_rounded),
      ExpenseSubCategory(id: 'doAnNhanh', nameVi: 'Đồ ăn nhanh', nameEn: 'Fast Food', icon: Icons.local_pizza_rounded),
      ExpenseSubCategory(id: 'khacAn', nameVi: 'Khác', nameEn: 'Other', icon: Icons.more_horiz_rounded),
    ],
  ),
  
  // ☕ Drinks (doUong)
  ExpenseCategory(
    id: 'doUong',
    nameVi: 'Đồ uống',
    nameEn: 'Drinks',
    icon: Icons.local_cafe_rounded,
    color: const Color(0xFFAE7152), // Lighter brown (Brown 400)
    subCategories: [
      ExpenseSubCategory(id: 'caPhe', nameVi: 'Cà phê', nameEn: 'Coffee', icon: Icons.coffee_rounded),
      ExpenseSubCategory(id: 'tra', nameVi: 'Trà', nameEn: 'Tea', icon: Icons.emoji_food_beverage_rounded),
      ExpenseSubCategory(id: 'traSua', nameVi: 'Trà sữa', nameEn: 'Milk Tea', icon: Icons.bubble_chart_rounded),
      ExpenseSubCategory(id: 'nuocEp', nameVi: 'Nước ép', nameEn: 'Juice', icon: Icons.local_bar_rounded),
      ExpenseSubCategory(id: 'nuocNgot', nameVi: 'Nước ngọt', nameEn: 'Soft Drinks', icon: Icons.local_drink_rounded),
      ExpenseSubCategory(id: 'biaRuou', nameVi: 'Bia rượu', nameEn: 'Beverages', icon: Icons.local_bar_rounded),
      ExpenseSubCategory(id: 'khacUong', nameVi: 'Khác', nameEn: 'Other', icon: Icons.more_horiz_rounded),
    ],
  ),
  
  // ⛽ Transport (xang)
  ExpenseCategory(
    id: 'xang',
    nameVi: 'Di chuyển',
    nameEn: 'Transport',
    icon: Icons.local_gas_station_rounded,
    color: Colors.red,
    subCategories: [
      ExpenseSubCategory(id: 'xangDau', nameVi: 'Xăng/Dầu', nameEn: 'Gas', icon: Icons.local_gas_station_rounded),
      ExpenseSubCategory(id: 'guiXe', nameVi: 'Gửi xe', nameEn: 'Parking', icon: Icons.local_parking_rounded),
      ExpenseSubCategory(id: 'grabTaxi', nameVi: 'Grab/Taxi', nameEn: 'Taxi', icon: Icons.local_taxi_rounded),
      ExpenseSubCategory(id: 'xeBuyt', nameVi: 'Xe buýt', nameEn: 'Bus', icon: Icons.directions_bus_rounded),
      ExpenseSubCategory(id: 'khacDiChuyen', nameVi: 'Khác', nameEn: 'Other', icon: Icons.more_horiz_rounded),
    ],
  ),
  
  // 🛍️ Shopping (muaSam)
  ExpenseCategory(
    id: 'muaSam',
    nameVi: 'Mua sắm',
    nameEn: 'Shopping',
    icon: Icons.shopping_bag_rounded,
    color: Colors.pink,
    subCategories: [
      ExpenseSubCategory(id: 'quanAo', nameVi: 'Quần áo', nameEn: 'Clothes', icon: Icons.checkroom_rounded),
      ExpenseSubCategory(id: 'dienTu', nameVi: 'Đồ điện tử', nameEn: 'Electronics', icon: Icons.phone_android_rounded),
      ExpenseSubCategory(id: 'giaDung', nameVi: 'Đồ gia dụng', nameEn: 'Household', icon: Icons.weekend_rounded),
      ExpenseSubCategory(id: 'myPham', nameVi: 'Mỹ phẩm', nameEn: 'Cosmetics', icon: Icons.face_rounded),
      ExpenseSubCategory(id: 'khacMuaSam', nameVi: 'Khác', nameEn: 'Other', icon: Icons.more_horiz_rounded),
    ],
  ),
  
  // 🔧 Repair (suaXe)
  ExpenseCategory(
    id: 'suaXe',
    nameVi: 'Sửa chữa',
    nameEn: 'Repair',
    icon: Icons.build_rounded,
    color: Colors.teal,
    subCategories: [
      ExpenseSubCategory(id: 'suaXeMay', nameVi: 'Sửa xe máy', nameEn: 'Motorbike', icon: Icons.two_wheeler_rounded),
      ExpenseSubCategory(id: 'suaOto', nameVi: 'Sửa ô tô', nameEn: 'Car', icon: Icons.directions_car_rounded),
      ExpenseSubCategory(id: 'suaDienThoai', nameVi: 'Sửa điện thoại', nameEn: 'Phone', icon: Icons.phone_android_rounded),
      ExpenseSubCategory(id: 'suaMayTinh', nameVi: 'Sửa máy tính', nameEn: 'Computer', icon: Icons.computer_rounded),
      ExpenseSubCategory(id: 'khacSuaChua', nameVi: 'Khác', nameEn: 'Other', icon: Icons.more_horiz_rounded),
    ],
  ),
  
  // 💰 Other (khac)
  ExpenseCategory(
    id: 'khac',
    nameVi: 'Khoản khác',
    nameEn: 'Other',
    icon: Icons.more_horiz_rounded,
    color: Colors.grey,
    subCategories: [
      ExpenseSubCategory(id: 'giaiTri', nameVi: 'Giải trí', nameEn: 'Entertainment', icon: Icons.celebration_rounded),
      ExpenseSubCategory(id: 'sucKhoe', nameVi: 'Sức khỏe', nameEn: 'Health', icon: Icons.medical_services_rounded),
      ExpenseSubCategory(id: 'quaTang', nameVi: 'Quà tặng', nameEn: 'Gifts', icon: Icons.card_giftcard_rounded),
      ExpenseSubCategory(id: 'duLich', nameVi: 'Du lịch', nameEn: 'Travel', icon: Icons.flight_rounded),
      ExpenseSubCategory(id: 'khoanKhac', nameVi: 'Khác', nameEn: 'Other', icon: Icons.attach_money_rounded),
    ],
  ),
];

/// Helper to find category by ID
ExpenseCategory? findCategoryById(String id) {
  try {
    return expenseCategories.firstWhere((c) => c.id == id);
  } catch (e) {
    return null;
  }
}

/// Helper to find subcategory by parent.child ID
ExpenseSubCategory? findSubCategoryById(String parentId, String subId) {
  final parent = findCategoryById(parentId);
  if (parent == null) return null;
  try {
    return parent.subCategories.firstWhere((s) => s.id == subId);
  } catch (e) {
    return null;
  }
}

/// Get display name for a category path (e.g., "doUong.caPhe")
String getCategoryDisplayName(String categoryPath, String language) {
  final parts = categoryPath.split('.');
  if (parts.isEmpty) return '';
  
  final parent = findCategoryById(parts[0]);
  if (parent == null) return categoryPath;
  
  if (parts.length == 1) {
    return parent.getName(language);
  }
  
  final sub = findSubCategoryById(parts[0], parts[1]);
  if (sub == null) return parent.getName(language);
  
  return sub.getName(language);
}

/// Get icon for a category path
IconData getCategoryIcon(String categoryPath) {
  final parts = categoryPath.split('.');
  if (parts.isEmpty) return Icons.help_outline;
  
  final parent = findCategoryById(parts[0]);
  if (parent == null) return Icons.help_outline;
  
  if (parts.length == 1) {
    return parent.icon;
  }
  
  final sub = findSubCategoryById(parts[0], parts[1]);
  return sub?.icon ?? parent.icon;
}

/// Get color for a category path
Color getCategoryColor(String categoryPath) {
  final parts = categoryPath.split('.');
  if (parts.isEmpty) return Colors.grey;
  
  final parent = findCategoryById(parts[0]);
  return parent?.color ?? Colors.grey;
}

/// Get subcategories for a specific main category ID
List<ExpenseSubCategory> getSubCategoriesFor(String categoryId) {
  final category = findCategoryById(categoryId);
  return category?.subCategories ?? [];
}
