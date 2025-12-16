import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:khmer25/login/api_service.dart';
import 'package:khmer25/login/auth_store.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _orders = const [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final user = AuthStore.currentUser.value;
    if (user == null) {
      setState(() {
        _orders = const [];
        _error = 'Please login to view orders';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.fetchOrders(
        userId: user.id,
        phone: user.phone,
      );
      if (!mounted) return;
      setState(() {
        _orders = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _orders.isEmpty
          ? const Center(child: Text('No orders yet'))
          : RefreshIndicator(
              onRefresh: _fetch,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _orders.length,
                itemBuilder: (context, index) {
                  final o = _orders[index];
                  return _OrderTile(order: o);
                },
              ),
            ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final code = (order['order_code'] ?? 'Order').toString();
    final total = (order['total_amount'] ?? 0).toString();
    final status = (order['order_status'] ?? 'pending').toString();
    final payment = (order['payment_status'] ?? 'pending').toString();
    final method = (order['payment_method'] ?? '').toString();
    final created = (order['created_at'] ?? '').toString();
    final dateText = _formatDate(created);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(code, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Total: $total'),
            Text('Payment: $method • $payment'),
            Text('Status: $status'),
            Text('Created: $dateText'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // optional: navigate to detail in future
        },
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
