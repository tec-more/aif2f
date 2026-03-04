/// 产品模型
/// 用于充值时长产品
class ProductModel {
  final int id;
  final String name;
  final String description;
  final double originalPrice;
  final double price;
  final int hours; // 充值时长（小时）
  final int? bonusHours; // 赠送时长（小时）
  final String? discount; // 优惠描述，如"限时9折"
  final bool isActive;
  final int? sortOrder; // 排序字段

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.price,
    required this.hours,
    this.bonusHours,
    this.discount,
    required this.isActive,
    this.sortOrder,
  });

  /// 计算折扣百分比
  double get discountPercent {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - price) / originalPrice * 100);
  }

  /// 计算总时长（包含赠送）
  int get totalHours => hours + (bonusHours ?? 0);

  /// 判断是否有优惠
  bool get hasDiscount => price < originalPrice || (bonusHours != null && bonusHours! > 0);

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      originalPrice: (json['original_price'] as num?)?.toDouble() ?? (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      hours: json['hours'] as int? ?? json['duration'] as int? ?? 0,
      bonusHours: json['bonus_hours'] as int? ?? json['bonusHours'] as int?,
      discount: json['discount'] as String?,
      isActive: json['is_active'] as bool? ?? json['isActive'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? json['sortOrder'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'original_price': originalPrice,
      'price': price,
      'hours': hours,
      'bonus_hours': bonusHours,
      'discount': discount,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, name: $name, price: $price, hours: $hours)';
  }
}
