import 'package:flutter/foundation.dart';
import 'package:khmer25/services/analytics_service.dart';

class CartItem {
  final String id;
  final String title;
  final String img;
  final String unit;
  final double price;
  final int quantity;

  const CartItem({
    required this.id,
    required this.title,
    required this.img,
    required this.unit,
    required this.price,
    required this.quantity,
  });

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      title: title,
      img: img,
      unit: unit,
      price: price,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "img": img,
        "unit": unit,
        "price": price,
        "qty": quantity,
      };
}

class CartStore {
  static final ValueNotifier<List<CartItem>> items =
      ValueNotifier<List<CartItem>>([]);

  static void addItem(Map<String, dynamic> product, {int qty = 1}) {
    if (qty <= 0) return;

    final updated = List<CartItem>.from(items.value);
    final id = (product['id'] ?? product['title'] ?? '').toString();

    final price = _toPrice(product['price']);
    final title = (product['title'] ?? '').toString();
    final img = (product['img'] ?? '').toString();
    final unit = (product['unit'] ?? '').toString();

    final idx = updated.indexWhere((x) => x.id == id);

    if (idx >= 0) {
      final current = updated[idx];
      updated[idx] = current.copyWith(quantity: current.quantity + qty);
    } else {
      updated.add(
        CartItem(
          id: id,
          title: title,
          img: img,
          unit: unit,
          price: price,
          quantity: qty,
        ),
      );
    }

    items.value = updated;
    AnalyticsService.trackAddToCart(
      id: id,
      price: price,
      qty: qty,
      name: title,
    );
  }

  static void updateQuantity(String id, int quantity) {
    final updated = List<CartItem>.from(items.value);
    final idx = updated.indexWhere((x) => x.id == id);
    if (idx == -1) return;

    if (quantity <= 0) {
      updated.removeAt(idx);
    } else {
      updated[idx] = updated[idx].copyWith(quantity: quantity);
    }

    items.value = updated;
  }

  static void remove(String id) {
    items.value = List<CartItem>.from(items.value)
      ..removeWhere((x) => x.id == id);
  }

  static void clear() {
    items.value = [];
  }

  static double subtotal() {
    return items.value.fold(0, (t, x) => t + (x.price * x.quantity));
  }

  static List<Map<String, dynamic>> toPayloadItems() {
    return items.value.map((e) => e.toJson()).toList();
  }

  static double _toPrice(dynamic price) {
    if (price is num) return price.toDouble();
    final s = (price ?? '').toString();
    final cleaned = s.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
