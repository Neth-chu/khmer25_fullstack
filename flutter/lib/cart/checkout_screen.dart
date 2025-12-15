import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:khmer25/cart/cart_store.dart';
import 'package:khmer25/login/api_service.dart';

enum PayMethod { cod, aba, acleda }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PayMethod method = PayMethod.cod;
  File? receipt;
  bool loading = false;

  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  bool get needReceipt => method != PayMethod.cod;

  String get qrAsset {
    switch (method) {
      case PayMethod.aba:
        return "assets/qr/aba_qr.png";
      case PayMethod.acleda:
        return "assets/qr/acleda_qr.png";
      case PayMethod.cod:
        return "";
    }
  }

  Future<void> pickReceipt() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) setState(() => receipt = File(x.path));
  }

  int get total {
    double sum = 0;
    for (final it in CartStore.items.value) {
      sum += it.price * it.quantity;
    }
    return sum.toInt();
  }

  Future<void> payNow() async {
    if (CartStore.items.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart is empty")),
      );
      return;
    }

    if (needReceipt && receipt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload receipt")),
      );
      return;
    }

    setState(() => loading = true);

    final payload = {
      "name": nameCtrl.text.trim(),
      "phone": phoneCtrl.text.trim(),
      "address": addressCtrl.text.trim(),
      "payment_method": method.name, // cod / aba / acleda
      "total": total,
      "items": CartStore.toPayloadItems(),
    };

    try {
      await ApiService.createOrderWithReceipt(payload, receipt: receipt);

      CartStore.clear();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Order placed successfully"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Checkout")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone")),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Address")),

            const SizedBox(height: 12),
            const Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold)),

            RadioListTile(
              value: PayMethod.cod,
              groupValue: method,
              onChanged: (v) => setState(() {
                method = v!;
                receipt = null;
              }),
              title: const Text("Cash on Delivery"),
            ),
            RadioListTile(
              value: PayMethod.aba,
              groupValue: method,
              onChanged: (v) => setState(() {
                method = v!;
                receipt = null;
              }),
              title: const Text("ABA QR"),
            ),
            RadioListTile(
              value: PayMethod.acleda,
              groupValue: method,
              onChanged: (v) => setState(() {
                method = v!;
                receipt = null;
              }),
              title: const Text("Acleda QR"),
            ),

            if (needReceipt) ...[
              const SizedBox(height: 8),
              Text("QR Path: $qrAsset"), // ✅ debug help

              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  qrAsset,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: Text(
                      "Cannot load QR:\n$qrAsset\n\nCheck pubspec.yaml + assets folder",
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: pickReceipt,
                icon: const Icon(Icons.upload),
                label: Text(receipt == null ? "Upload Receipt" : "Change Receipt"),
              ),

              if (receipt != null) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    receipt!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),
            Text("Total: $total", style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : payNow,
                child: loading
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Pay Now"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
