import 'common.dart';

class Category {
  const Category({required this.id, required this.name, this.description, required this.isActive, required this.productCount});

  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final int productCount;

  factory Category.fromJson(Json json) => Category(
        id: toInt(json['id']),
        name: '${json['name']}',
        description: json['description'] as String?,
        isActive: json['isActive'] == true,
        productCount: toInt(json['productCount']),
      );
}

class Brand {
  const Brand({required this.id, required this.name, this.description, this.logoUrl, required this.isActive, required this.productCount});

  final int id;
  final String name;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final int productCount;

  factory Brand.fromJson(Json json) => Brand(
        id: toInt(json['id']),
        name: '${json['name']}',
        description: json['description'] as String?,
        logoUrl: json['logoUrl'] as String?,
        isActive: json['isActive'] == true,
        productCount: toInt(json['productCount']),
      );
}

class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.brandName,
    required this.price,
    this.imageUrl,
    required this.averageRating,
    required this.reviewCount,
    required this.inStock,
    required this.isActive,
  });

  final int id;
  final String name;
  final String categoryName;
  final String brandName;
  final double price;
  final String? imageUrl;
  final double averageRating;
  final int reviewCount;
  final bool inStock;
  final bool isActive;

  factory ProductSummary.fromJson(Json json) => ProductSummary(
        id: toInt(json['id']),
        name: '${json['name']}',
        categoryName: '${json['categoryName']}',
        brandName: '${json['brandName']}',
        price: toDouble(json['price']),
        imageUrl: json['imageUrl'] as String?,
        averageRating: toDouble(json['averageRating']),
        reviewCount: toInt(json['reviewCount']),
        inStock: json['inStock'] == true,
        isActive: json['isActive'] == true,
      );
}

class Variant {
  const Variant({
    required this.id,
    required this.productId,
    required this.sku,
    required this.size,
    required this.color,
    required this.price,
    required this.stockQuantity,
    required this.inStock,
    required this.isActive,
  });

  final int id;
  final int productId;
  final String sku;
  final String size;
  final String color;
  final double price;
  final int stockQuantity;
  final bool inStock;
  final bool isActive;

  String get label => '$color / $size';

  factory Variant.fromJson(Json json) => Variant(
        id: toInt(json['id']),
        productId: toInt(json['productId']),
        sku: '${json['sku']}',
        size: '${json['size']}',
        color: '${json['color']}',
        price: toDouble(json['price']),
        stockQuantity: toInt(json['stockQuantity']),
        inStock: json['inStock'] == true,
        isActive: json['isActive'] == true,
      );
}

class ProductImage {
  const ProductImage({required this.id, required this.productId, required this.url, this.altText, required this.displayOrder, required this.isPrimary});

  final int id;
  final int productId;
  final String url;
  final String? altText;
  final int displayOrder;
  final bool isPrimary;

  factory ProductImage.fromJson(Json json) => ProductImage(
        id: toInt(json['id']),
        productId: toInt(json['productId']),
        url: '${json['url']}',
        altText: json['altText'] as String?,
        displayOrder: toInt(json['displayOrder']),
        isPrimary: json['isPrimary'] == true,
      );
}

class ProductDetail {
  const ProductDetail({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    required this.categoryName,
    required this.brandId,
    required this.brandName,
    required this.basePrice,
    required this.price,
    required this.isActive,
    required this.averageRating,
    required this.reviewCount,
    required this.images,
    required this.variants,
  });

  final int id;
  final String name;
  final String? description;
  final int categoryId;
  final String categoryName;
  final int brandId;
  final String brandName;
  final double basePrice;
  final double price;
  final bool isActive;
  final double averageRating;
  final int reviewCount;
  final List<ProductImage> images;
  final List<Variant> variants;

  List<String> get colors => variants.map((v) => v.color).toSet().toList();

  factory ProductDetail.fromJson(Json json) => ProductDetail(
        id: toInt(json['id']),
        name: '${json['name']}',
        description: json['description'] as String?,
        categoryId: toInt(json['categoryId']),
        categoryName: '${json['categoryName']}',
        brandId: toInt(json['brandId']),
        brandName: '${json['brandName']}',
        basePrice: toDouble(json['basePrice']),
        price: toDouble(json['price']),
        isActive: json['isActive'] == true,
        averageRating: toDouble(json['averageRating']),
        reviewCount: toInt(json['reviewCount']),
        images: toList(json['images'], ProductImage.fromJson),
        variants: toList(json['variants'], Variant.fromJson),
      );
}

class FilterOptions {
  const FilterOptions({
    required this.categories,
    required this.brands,
    required this.sizes,
    required this.colors,
    required this.minPrice,
    required this.maxPrice,
  });

  final List<Category> categories;
  final List<Brand> brands;
  final List<String> sizes;
  final List<String> colors;
  final double minPrice;
  final double maxPrice;

  factory FilterOptions.fromJson(Json json) => FilterOptions(
        categories: toList(json['categories'], Category.fromJson),
        brands: toList(json['brands'], Brand.fromJson),
        sizes: (json['sizes'] as List? ?? []).map((e) => '$e').toList(),
        colors: (json['colors'] as List? ?? []).map((e) => '$e').toList(),
        minPrice: toDouble(json['minPrice']),
        maxPrice: toDouble(json['maxPrice']),
      );
}

enum ProductSort {
  newest('newest', 'desc', 'Newest'),
  priceLow('price', 'asc', 'Price: low to high'),
  priceHigh('price', 'desc', 'Price: high to low'),
  name('name', 'asc', 'Name A–Z'),
  rating('rating', 'desc', 'Top rated');

  const ProductSort(this.sortBy, this.sortOrder, this.label);

  final String sortBy;
  final String sortOrder;
  final String label;
}

/// Search, filter and sort criteria for the product list (UC-040 – UC-042).
class ProductFilter {
  const ProductFilter({
    this.keyword,
    this.categoryId,
    this.brandId,
    this.minPrice,
    this.maxPrice,
    this.size,
    this.color,
    this.sort = ProductSort.newest,
  });

  final String? keyword;
  final int? categoryId;
  final int? brandId;
  final double? minPrice;
  final double? maxPrice;
  final String? size;
  final String? color;
  final ProductSort sort;

  int get activeFilterCount =>
      [categoryId, brandId, minPrice, maxPrice, size, color].where((v) => v != null).length;

  ProductFilter copyWith({
    String? Function()? keyword,
    int? Function()? categoryId,
    int? Function()? brandId,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    String? Function()? size,
    String? Function()? color,
    ProductSort? sort,
  }) =>
      ProductFilter(
        keyword: keyword != null ? keyword() : this.keyword,
        categoryId: categoryId != null ? categoryId() : this.categoryId,
        brandId: brandId != null ? brandId() : this.brandId,
        minPrice: minPrice != null ? minPrice() : this.minPrice,
        maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
        size: size != null ? size() : this.size,
        color: color != null ? color() : this.color,
        sort: sort ?? this.sort,
      );

  ProductFilter clearFilters() => ProductFilter(keyword: keyword, sort: sort);

  Map<String, dynamic> toQuery() => {
        'keyword': keyword,
        'categoryId': categoryId,
        'brandId': brandId,
        'minPrice': minPrice?.round(),
        'maxPrice': maxPrice?.round(),
        'size': size,
        'color': color,
        'sortBy': sort.sortBy,
        'sortOrder': sort.sortOrder,
      };

  @override
  bool operator ==(Object other) =>
      other is ProductFilter &&
      other.keyword == keyword &&
      other.categoryId == categoryId &&
      other.brandId == brandId &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice &&
      other.size == size &&
      other.color == color &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(keyword, categoryId, brandId, minPrice, maxPrice, size, color, sort);
}
