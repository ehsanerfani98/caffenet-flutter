/// فیلد داینامیک فرم سفارش — fields_json مدل Service بک‌اند.
/// انواع حداقلی (T5.1): text/number/select/textarea/date/checkbox
/// نوع ناشناخته → text (ریسک «تغییر شکل fields» §9 پلن).
class ServiceField {
  const ServiceField({
    required this.id,
    required this.label,
    required this.type,
    this.required = false,
    this.options = const [],
    this.placeholder = '',
    this.min,
    this.max,
  });

  final String id;
  final String label;
  final String type;
  final bool required;
  final List<String> options;
  final String placeholder;
  final num? min;
  final num? max;

  factory ServiceField.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return ServiceField(
      id: '${m['id'] ?? m['name'] ?? ''}',
      label: '${m['label'] ?? m['id'] ?? ''}',
      type: switch ('${m['type'] ?? 'text'}') {
        'text' || 'number' || 'select' || 'textarea' || 'date' || 'checkbox' =>
          '${m['type']}',
        _ => 'text',
      },
      required: m['required'] == true || m['required'] == 1 || m['required'] == '1',
      options: (m['options'] as List?)?.map((e) => '$e').toList() ?? const [],
      placeholder: '${m['placeholder'] ?? ''}',
      min: m['min'] is num ? m['min'] as num : num.tryParse('${m['min'] ?? ''}'),
      max: m['max'] is num ? m['max'] as num : num.tryParse('${m['max'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'type': type,
        'required': required,
        'options': options,
        'placeholder': placeholder,
      };
}

/// مدل خدمت — Formatter::service بک‌اند.
class ServiceModel {
  const ServiceModel({
    required this.id,
    required this.categoryId,
    required this.title,
    this.description = '',
    required this.basePrice,
    this.estimatedTime = '',
    this.icon = '',
    this.iconColor = '',
    this.sortOrder = 0,
    this.isActive = true,
    this.isFeatured = false,
    this.fields = const [],
    this.pricingFormulaDescription = '',
  });

  final String id;
  final String categoryId;
  final String title;
  final String description;
  final int basePrice;
  final String estimatedTime;
  final String icon;
  final String iconColor;
  final int sortOrder;
  final bool isActive;
  final bool isFeatured;
  final List<ServiceField> fields;
  final String pricingFormulaDescription;

  factory ServiceModel.fromJson(dynamic raw) {
    final m = (raw as Map).cast<String, dynamic>();
    return ServiceModel(
      id: '${m['id'] ?? ''}',
      categoryId: '${m['categoryId'] ?? ''}',
      title: '${m['title'] ?? ''}',
      description: '${m['description'] ?? ''}',
      basePrice: (m['basePrice'] as num?)?.toInt() ?? 0,
      estimatedTime: '${m['estimatedTime'] ?? ''}',
      icon: '${m['icon'] ?? ''}',
      iconColor: '${m['iconColor'] ?? ''}',
      sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: m['isActive'] != false,
      isFeatured: m['isFeatured'] == true,
      fields: (m['fields'] as List?)?.map(ServiceField.fromJson).toList() ?? const [],
      pricingFormulaDescription: '${m['pricingFormulaDescription'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'categoryId': categoryId,
        'title': title,
        'description': description,
        'basePrice': basePrice,
        'estimatedTime': estimatedTime,
        'icon': icon,
        'iconColor': iconColor,
        'sortOrder': sortOrder,
        'isActive': isActive,
        'isFeatured': isFeatured,
        'fields': fields.map((f) => f.toJson()).toList(),
        'pricingFormulaDescription': pricingFormulaDescription,
      };
}
