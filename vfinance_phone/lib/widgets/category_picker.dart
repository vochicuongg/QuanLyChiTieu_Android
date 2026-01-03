import 'package:flutter/material.dart';
import '../models/expense_categories.dart';
import '../main.dart';

/// ============================================================================
/// CATEGORY PICKER DIALOG
/// Shows subcategories for a specific main category
/// ============================================================================

/// Show subcategory picker for a specific parent category
/// Returns selected subcategory ID (e.g., "caPhe")
Future<String?> showSubCategoryPicker(BuildContext context, String parentCategoryId) async {
  final category = findCategoryById(parentCategoryId);
  if (category == null) return null;
  
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SubCategoryPickerSheet(category: category),
  );
}

/// Show full category picker (all categories with subcategories)
Future<String?> showCategoryPicker(BuildContext context) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const FullCategoryPickerSheet(),
  );
}

/// Subcategory picker for a single parent category
class SubCategoryPickerSheet extends StatelessWidget {
  final ExpenseCategory category;
  
  const SubCategoryPickerSheet({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final isVi = appLanguage == 'vi';
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title with category icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: category.color.withValues(alpha: 0.2),
                  child: Icon(category.icon, color: category.color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  category.getName(appLanguage),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Subcategory list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: category.subCategories.length,
            itemBuilder: (_, index) {
              final sub = category.subCategories[index];
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: category.color.withValues(alpha: 0.1),
                  child: Icon(sub.icon, color: category.color, size: 20),
                ),
                title: Text(
                  sub.getName(appLanguage),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => Navigator.pop(context, sub.id),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Full category picker with expandable sections
class FullCategoryPickerSheet extends StatefulWidget {
  const FullCategoryPickerSheet({super.key});

  @override
  State<FullCategoryPickerSheet> createState() => _FullCategoryPickerSheetState();
}

class _FullCategoryPickerSheetState extends State<FullCategoryPickerSheet> {
  String? _expandedCategoryId;

  @override
  Widget build(BuildContext context) {
    final isVi = appLanguage == 'vi';
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    isVi ? 'Chọn danh mục' : 'Select Category',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Category list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: expenseCategories.length,
                itemBuilder: (_, index) {
                  final category = expenseCategories[index];
                  final isExpanded = _expandedCategoryId == category.id;
                  
                  return Column(
                    children: [
                      // Main category
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: category.color.withValues(alpha: 0.2),
                          child: Icon(category.icon, color: category.color, size: 22),
                        ),
                        title: Text(
                          category.getName(appLanguage),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedCategoryId = null;
                            } else {
                              _expandedCategoryId = category.id;
                            }
                          });
                        },
                      ),
                      // Subcategories (animated)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: isExpanded ? category.subCategories.length * 56.0 : 0,
                        child: ClipRect(
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Column(
                              children: category.subCategories.map((sub) {
                                final path = '${category.id}.${sub.id}';
                                
                                return ListTile(
                                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                                  leading: Icon(sub.icon, color: category.color, size: 20),
                                  title: Text(
                                    sub.getName(appLanguage),
                                    style: const TextStyle(fontWeight: FontWeight.normal),
                                  ),
                                  onTap: () => Navigator.pop(context, path),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
