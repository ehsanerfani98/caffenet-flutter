/// مدل دسته‌بندی — Formatter::category بک‌اند.
class CategoryModel {
  const CategoryModel({
    required this.id,
    required this.title,
    this.iconName,
    this.iconColor = '',
    this.sortOrder = 0,
    this.description = '',
  });

  final String id;
  final String title;
  final String? iconName;
  final String iconColor;
  final int sortOrder;
  final String description;

  factory CategoryModel.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return CategoryModel(
      id: '${m['id'] ?? ''}',
      title: '${m['title'] ?? ''}',
      iconName: m['iconName']?.toString(),
      iconColor: '${m['iconColor'] ?? ''}',
      sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
      description: '${m['description'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'iconName': iconName,
        'iconColor': iconColor,
        'sortOrder': sortOrder,
        'description': description,
      };
}
