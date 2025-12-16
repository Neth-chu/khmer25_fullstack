import 'package:flutter/material.dart';
import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/cart/checkout_screen.dart';
import 'package:khmer25/l10n/lang_store.dart';
import 'package:khmer25/homePage.dart';
import 'package:khmer25/services/analytics_service.dart';
import 'package:khmer25/account/select_location_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String _lastCartSignature = '';
  final _remarkCtrl = TextEditingController();
  String _locationLabel = 'Not Specified';
  LatLng? _locationCoords;

  @override
  void initState() {
    super.initState();
    _loadSavedLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.trackScreen('Cart');
    });
  }

  @override
  void dispose() {
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _trackCartView(List<CartItem> items, double total) {
    final itemCount = items.fold<int>(0, (sum, it) => sum + it.quantity);
    final signature = '${itemCount}:${total.toStringAsFixed(2)}';
    if (_lastCartSignature == signature) return;
    _lastCartSignature = signature;
    AnalyticsService.trackCartViewed(itemCount: itemCount, total: total);
  }

  Future<void> _openMaps(BuildContext context) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=delivery+location',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(LangStore.t('map.error'))));
    }
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final label = prefs.getString('user_location_label');
    final lat = prefs.getDouble('user_location_lat');
    final lng = prefs.getDouble('user_location_lng');
    if (!mounted) return;
    setState(() {
      _locationLabel = label ?? 'Not Specified';
      if (lat != null && lng != null) {
        _locationCoords = LatLng(lat, lng);
      }
    });
  }

  Future<void> _openLocationPicker() async {
    final result = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => const SelectLocationScreen(),
        settings: const RouteSettings(name: '/select-location-cart'),
      ),
    );
    if (result == null) return;
    final label = (result['label'] ?? '').toString();
    final lat = result['lat'] is num ? (result['lat'] as num).toDouble() : null;
    final lng = result['lng'] is num ? (result['lng'] as num).toDouble() : null;
    if (lat == null || lng == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'user_location_label',
      label.isNotEmpty ? label : 'Pinned location',
    );
    await prefs.setDouble('user_location_lat', lat);
    await prefs.setDouble('user_location_lng', lng);

    if (!mounted) return;
    setState(() {
      _locationLabel = label.isNotEmpty ? label : 'Pinned location';
      _locationCoords = LatLng(lat, lng);
    });
  }

  void _handleCheckout(
    BuildContext context, {
    required List<CartItem> items,
    required double total,
  }) {
    final itemCount = items.fold<int>(0, (sum, it) => sum + it.quantity);
    AnalyticsService.trackCheckoutStarted(total: total, itemCount: itemCount);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(initialNote: _remarkCtrl.text.trim()),
        settings: const RouteSettings(name: '/checkout'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          LangStore.t('cart.title'),
          style: const TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<List<CartItem>>(
        valueListenable: CartStore.items,
        builder: (context, items, _) {
          final subtotal = CartStore.subtotal();
          final delivery = items.isEmpty ? 0.0 : 1.50;
          final total = subtotal + delivery;
          _trackCartView(items, total);

          if (items.isEmpty) {
            return Center(child: Text(LangStore.t('cart.empty')));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeaderSection(
                  onSelectLocation: _openLocationPicker,
                  locationLabel: _locationLabel,
                  locationCoords: _locationCoords,
                ),
                const SizedBox(height: 14),
                Text(
                  LangStore.t('cart.list'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CartItemTile(item: item),
                  ),
                ),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LangStore.t('cart.remarks'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.green.shade700),
                      ),
                      child: Text(LangStore.t('cart.buyMore')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _remarkCtrl,
                  decoration: InputDecoration(
                    hintText: LangStore.t('cart.remark.hint'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
                const Divider(height: 32),
                _SummaryRow(label: LangStore.t('cart.total'), value: subtotal),
                _SummaryRow(
                  label: LangStore.t('cart.delivery'),
                  value: delivery,
                ),
                const SizedBox(height: 6),
                _SummaryRow(
                  label: LangStore.t('cart.grandTotal'),
                  value: total,
                  isBold: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: items.isEmpty
                        ? null
                        : () => _handleCheckout(
                            context,
                            items: items,
                            total: total,
                          ),
                    child: Text(
                      LangStore.t('cart.checkout'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _CartBottomNav(currentIndex: 3),
    );
  }
}

class _CartBottomNav extends StatelessWidget {
  final int currentIndex;
  const _CartBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: LangStore.t('nav.home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.category),
          label: LangStore.t('nav.categories'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.local_offer),
          label: LangStore.t('nav.promotions'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_cart),
          label: LangStore.t('nav.products'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.favorite),
          label: LangStore.t('nav.favorite'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person),
          label: LangStore.t('nav.account'),
        ),
      ],
      onTap: (i) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(initialIndex: i),
            settings: RouteSettings(name: '/home/$i'),
          ),
        );
      },
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final VoidCallback onSelectLocation;
  final String locationLabel;
  final LatLng? locationCoords;
  const _HeaderSection({
    required this.onSelectLocation,
    required this.locationLabel,
    required this.locationCoords,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              LangStore.t('cart.shipping'),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            OutlinedButton(
              onPressed: onSelectLocation,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                side: BorderSide(color: Colors.green.shade700),
              ),
              child: Text(LangStore.t('cart.selectLocation')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: Colors.yellow.shade800),
                const SizedBox(width: 8),
                Text(
                  LangStore.t('cart.payment'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Icon(Icons.check_circle, color: Colors.blue.shade700),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LangStore.t('cart.payment.note')),
              const SizedBox(height: 4),
              Text(
                "Selected: $locationLabel",
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              if (locationCoords != null)
                Text(
                  "Pin: ${locationCoords!.latitude.toStringAsFixed(5)}, ${locationCoords!.longitude.toStringAsFixed(5)}",
                  style: const TextStyle(color: Colors.black45, fontSize: 11),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: _CartItemImage(imagePath: item.img),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${item.price.toStringAsFixed(2)} / ${item.unit}',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: () =>
                          CartStore.updateQuantity(item.id, item.quantity - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: () =>
                          CartStore.updateQuantity(item.id, item.quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                onPressed: () => CartStore.remove(item.id),
                icon: const Icon(Icons.delete, color: Colors.red),
              ),
              Text('\$${(item.price * item.quantity).toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartItemImage extends StatelessWidget {
  final String imagePath;

  const _CartItemImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final path = imagePath.trim();
    if (path.isEmpty) {
      return _placeholder();
    }

    final resolved = path.startsWith('/') ? 'http://127.0.0.1:8000$path' : path;
    final isNetwork = resolved.startsWith('http');
    final ImageProvider<Object> provider = isNetwork
        ? NetworkImage(resolved)
        : AssetImage(resolved);

    return Image(
      image: provider,
      width: 82,
      height: 82,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 82,
      height: 82,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
      fontSize: isBold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
