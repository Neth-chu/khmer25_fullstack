class ProductModel {
  final String id;
  final String title;
  final String price;
  final String unit;
  final String tag; // may be id or name
  final String subCategory; // may be id or name
  final String categoryName; // human-friendly name if provided
  final String subCategoryName; // human-friendly name if provided
  final String imageUrl;

  ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.unit,
    required this.tag,
    required this.subCategory,
    required this.categoryName,
    required this.subCategoryName,
    required this.imageUrl,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final rawPrice = json['price'];
    String displayPrice;
    if (rawPrice == null) {
      displayPrice = '';
    } else if (rawPrice is num) {
      displayPrice = rawPrice.toString();
    } else {
      displayPrice = rawPrice.toString();
    }

    return ProductModel(
      id: (json['id'] ?? json['pk'] ?? '').toString(),
      title: (json['name'] ?? json['title'] ?? '').toString(),
      price: displayPrice,
      unit: (json['unit'] ?? json['quantity']?.toString() ?? '').toString(),
      tag: (json['category'] ?? json['tag'] ?? '').toString(),
      subCategory: (json['subCategory'] ?? json['subcategory'] ?? '').toString(),
      categoryName: (json['category_name'] ?? json['categoryName'] ?? '').toString(),
      subCategoryName: (json['subcategory_name'] ?? json['subCategoryName'] ?? '').toString(),
      imageUrl: (json['image'] ?? json['image_url'] ?? '').toString(),
    );
  }

  String get displayPrice => price.isEmpty ? '' : '\$${price}';
  String get displayTag => categoryName.isNotEmpty ? categoryName : tag;
  String get displaySubCategory =>
      subCategoryName.isNotEmpty ? subCategoryName : subCategory;

  Map<String, dynamic> toCartMap() => {
        'id': id,
        'title': title,
        'img': imageUrl,
        'price': displayPrice,
        'unit': unit,
        'tag': tag,
        'subCategory': subCategory,
      };
}
