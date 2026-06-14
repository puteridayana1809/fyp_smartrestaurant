import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/order_item.dart';
import '../models/restaurant_order.dart';
import '../models/restaurant_table.dart';
import '../services/constants.dart';
import '../services/printer_service.dart';
import 'login_screen.dart';
import 'printer_settings_screen.dart';

const kedahGreen = Color(0xFF2D5016);
const kedahLight = Color(0xFF4A7C23);
const kedahYellow = Color(0xFFF5C518);
const accentGreen = Color(0xFF22C55E);
const accentRed = Color(0xFFEF4444);
const accentBlue = Color(0xFF3B82F6);

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final _db = FirebaseFirestore.instance;

  RestaurantTable? _selectedTable;
  RestaurantOrder? _selectedOrder;
  String? _selectedPayment;
  bool _completing = false;
  bool _sidebarOpen = false;
  Map<int, int> _selectedQty = {};

  CollectionReference<Map<String, dynamic>> _col(String name) =>
      _db.collection('restaurants/$restaurantId/$name');

  List<RestaurantTable> _sortTables(List<RestaurantTable> tables) {
    int groupOf(String label) {
      if (RegExp(r'^T\d+$', caseSensitive: false).hasMatch(label)) return 0;
      if (RegExp(r'^\d+$').hasMatch(label)) return 1;
      if (RegExp(r'^B(ungkus)?\s*\d+$', caseSensitive: false).hasMatch(label)) return 2;
      return 3;
    }

    int numOf(String label) {
      final m = RegExp(r'(\d+)').firstMatch(label);
      return m != null ? int.parse(m.group(1)!) : 0;
    }

    final sorted = [...tables];
    sorted.sort((a, b) {
      final ga = groupOf(a.name), gb = groupOf(b.name);
      if (ga != gb) return ga - gb;
      final na = numOf(a.name), nb = numOf(b.name);
      if (na != nb) return na - nb;
      return a.name.toUpperCase().compareTo(b.name.toUpperCase());
    });
    return sorted;
  }

  Future<void> _selectTable(RestaurantTable table) async {
    setState(() {
      _selectedTable = table;
      _selectedOrder = null;
      _selectedPayment = null;
      _selectedQty = {};
    });

    if (table.hasOrder) {
      final snap = await _col('orders').doc(table.activeOrderId).get();
      if (snap.exists) {
        setState(() {
          _selectedOrder = RestaurantOrder.fromMap(snap.id, snap.data()!);
        });
      }
    }
  }

  ({double subtotal, double remainingTotal, double total}) _totals(RestaurantOrder order) {
    final subtotal = order.items.fold<double>(0, (total, item) => total + item.total);
    final remaining = order.items.fold<double>(
        0, (total, item) => total + item.remainingQty * item.unitPrice);
    return (subtotal: subtotal, remainingTotal: remaining, total: subtotal);
  }

  double _selectedTotal(RestaurantOrder order) {
    var total = 0.0;
    for (final entry in _selectedQty.entries) {
      if (entry.value <= 0) continue;
      total += order.items[entry.key].unitPrice * entry.value;
    }
    return total;
  }

  Future<void> _payForSelection() async {
    final order = _selectedOrder;
    final table = _selectedTable;
    final method = _selectedPayment;
    if (order == null || table == null || method == null) return;

    final selectedAmount = _selectedTotal(order);
    if (selectedAmount <= 0) return;

    setState(() => _completing = true);

    final updatedItems = <OrderItem>[];
    final paidNowItems = <OrderItem>[];
    for (var i = 0; i < order.items.length; i++) {
      final item = order.items[i];
      final selectedQty = _selectedQty[i] ?? 0;
      if (selectedQty > 0) {
        updatedItems.add(item.copyWith(paidQty: item.paidQty + selectedQty));
        paidNowItems.add(OrderItem(name: item.name, unitPrice: item.unitPrice, qty: selectedQty));
      } else {
        updatedItems.add(item);
      }
    }

    final isFullyPaid = updatedItems.every((item) => item.remainingQty == 0);
    final totals = _totals(order);

    try {
      await _col('orders').doc(order.id).update({
        'items': updatedItems.map((item) => item.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _col('orders').doc(order.id).collection('payments').add({
        'method': method,
        'amount': selectedAmount,
        'items': paidNowItems.map((item) => item.toMap()).toList(),
        'at': FieldValue.serverTimestamp(),
      });

      if (isFullyPaid) {
        final paymentsSnap = await _col('orders').doc(order.id).collection('payments').get();
        final methods = paymentsSnap.docs.map((d) => d.data()['method']?.toString()).toSet();
        final finalPayment = methods.length > 1 ? 'Split' : (methods.first ?? method);

        await _col('orders').doc(order.id).update({
          'status': 'completed',
          'payment': finalPayment,
          'total': totals.total,
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        await _col('tables').doc(table.id).update({
          'status': 'available',
          'activeOrderId': null,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      final shouldPrint = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pembayaran direkod'),
          content: const Text('Cetak resit melalui printer Bluetooth?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cetak')),
          ],
        ),
      );

      if (shouldPrint == true) {
        await _printReceipt(order, table.name, method, paidNowItems, selectedAmount);
      }

      if (isFullyPaid) {
        setState(() {
          _selectedOrder = null;
          _selectedTable = null;
          _selectedPayment = null;
          _selectedQty = {};
        });
      } else {
        setState(() {
          _selectedOrder = RestaurantOrder.fromMap(order.id, {
            'items': updatedItems.map((item) => item.toMap()).toList(),
            'status': order.status,
            'table': order.table,
          });
          _selectedPayment = null;
          _selectedQty = {};
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ralat: $e')));
      }
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }

  Future<void> _printReceipt(
    RestaurantOrder order,
    String tableName,
    String method,
    List<OrderItem> items,
    double total,
  ) async {
    final connected = await PrinterService.isConnected;
    if (!connected) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer tidak disambung. Sila sambung di Tetapan Printer.')),
      );
      return;
    }

    final ok = await PrinterService.printReceipt(
      orderId: order.id,
      tableName: tableName,
      items: items,
      subtotal: total,
      total: total,
      paymentMethod: method,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Resit dicetak' : 'Gagal mencetak resit')),
    );
  }

  void _showOrderDetailsDialog(RestaurantOrder order) {
    final totals = _totals(order);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Order ${order.id}'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in order.items)
                ListTile(
                  dense: true,
                  title: Text('${item.qty}x ${item.name}'),
                  trailing: Text('RM ${item.total.toStringAsFixed(2)}'),
                ),
              const Divider(),
              ListTile(
                dense: true,
                title: const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text('RM ${(order.total ?? totals.total).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _printReceipt(
              order,
              order.table ?? '-',
              order.payment ?? 'Cash',
              order.items,
              (order.total ?? totals.total).toDouble(),
            ),
            child: const Text('Cetak Resit'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _sidebarItem({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            if (_sidebarOpen) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Text(label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _sidebarOpen ? 220 : 0,
      color: kedahGreen,
      child: _sidebarOpen
          ? SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _sidebarItem(
                    icon: Icons.print,
                    label: 'Device Management',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
                    ),
                  ),
                  const Spacer(),
                  _sidebarItem(
                    icon: Icons.logout,
                    label: 'Sign Out',
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (!mounted) return;
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: kedahGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          tooltip: 'Menu',
          onPressed: () => setState(() => _sidebarOpen = !_sidebarOpen),
        ),
        title: const Text('Cashier - Payment System'),
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          final tablesSection = _buildTablesSection();
          final panel = _buildCashierPanel();

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: SingleChildScrollView(child: tablesSection)),
                SizedBox(width: 380, child: SingleChildScrollView(child: panel)),
              ],
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [tablesSection, panel],
            ),
          );
        },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [kedahGreen, kedahLight]),
              ),
              child: const Row(
                children: [
                  Icon(Icons.restaurant, color: kedahYellow),
                  SizedBox(width: 10),
                  Text('Tables & Orders',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _col('tables').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final tables = _sortTables(snapshot.data!.docs
                      .map((d) => RestaurantTable.fromMap(d.id, d.data()))
                      .toList());

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 100,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: tables.length,
                    itemBuilder: (context, index) {
                      final table = tables[index];
                      final isSelected = _selectedTable?.id == table.id;
                      final color = table.hasOrder ? accentRed : accentGreen;

                      return Material(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _selectTable(table),
                          child: Container(
                            decoration: isSelected
                                ? BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: kedahGreen, width: 4),
                                  )
                                : null,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(table.name,
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(
                                  table.hasOrder ? 'RECEIVED' : 'AVAILABLE',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCashierPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
      child: Column(
        children: [
          _buildOrderCard(),
          const SizedBox(height: 12),
          _buildRecentPaymentsCard(),
        ],
      ),
    );
  }

  Widget _buildOrderCard() {
    final order = _selectedOrder;
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEFF1F5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: order == null
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: kedahGreen.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.touch_app_outlined, size: 36, color: kedahLight),
                    ),
                    const SizedBox(height: 16),
                    const Text('Pilih meja yang mempunyai order',
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              )
            : _buildOrderContent(order),
      ),
    );
  }

  Widget _buildOrderContent(RestaurantOrder order) {
    final totals = _totals(order);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _infoBox('ORDER ID', order.id)),
            const SizedBox(width: 12),
            Expanded(child: _infoBox('TABLE', _selectedTable?.name ?? '-')),
          ],
        ),
        const SizedBox(height: 14),
        const Text('ORDER ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: order.items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: Text('No items', style: TextStyle(color: Colors.grey))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: order.items.length,
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    final remaining = item.remainingQty;
                    final selected = _selectedQty[index] ?? 0;
                    return Container(
                      margin: const EdgeInsets.all(5),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border(left: BorderSide(color: remaining == 0 ? Colors.grey : kedahYellow, width: 3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28, height: 24,
                                decoration: BoxDecoration(color: kedahGreen, borderRadius: BorderRadius.circular(6)),
                                alignment: Alignment.center,
                                child: Text('${item.qty}×', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: remaining == 0 ? Colors.grey : Colors.black,
                                    decoration: remaining == 0 ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                              ),
                              Text('RM ${item.total.toStringAsFixed(2)}', style: const TextStyle(color: accentGreen, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (item.paidQty > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 38),
                              child: Text('Dibayar: ${item.paidQty}/${item.qty}',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ),
                          if (remaining > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 6, left: 38),
                              child: Row(
                                children: [
                                  const Text('Bayar:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    onPressed: selected > 0
                                        ? () => setState(() => _selectedQty[index] = selected - 1)
                                        : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                  Text('$selected', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    onPressed: selected < remaining
                                        ? () => setState(() => _selectedQty[index] = selected + 1)
                                        : null,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                  Text('/ $remaining baki', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 14),
        _totalRow('Dipilih', _selectedTotal(order)),
        _totalRow('Baki', totals.remainingTotal),
        const Divider(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [kedahGreen, kedahLight]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('BAKI', style: TextStyle(color: Colors.white, fontSize: 13)),
              Text('RM ${totals.remainingTotal.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('PAYMENT METHOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _paymentButton('Cash', Icons.money)),
            const SizedBox(width: 10),
            Expanded(child: _paymentButton('QR', Icons.qr_code)),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_selectedPayment != null && !_completing && _selectedTotal(order) > 0)
                ? _payForSelection
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: _completing
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle),
            label: Text(_completing ? 'Processing...' : 'Bayar Item Dipilih'),
          ),
        ),
      ],
    );
  }

  Widget _infoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF8F9FC), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kedahGreen)),
        ],
      ),
    );
  }

  Widget _totalRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text('RM ${value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _paymentButton(String method, IconData icon) {
    final selected = _selectedPayment == method;
    return OutlinedButton.icon(
      onPressed: () => setState(() => _selectedPayment = method),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? kedahGreen : Colors.white,
        foregroundColor: selected ? Colors.white : Colors.black87,
        side: BorderSide(color: selected ? kedahGreen : const Color(0xFFE5E7EB), width: 2),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: Icon(icon),
      label: Text(method == 'QR' ? 'QR Code' : 'Cash'),
    );
  }

  Widget _buildRecentPaymentsCard() {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: kedahGreen.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.receipt_long, size: 15, color: kedahGreen),
                ),
                const SizedBox(width: 10),
                const Text('RECENT PAYMENTS',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kedahGreen, letterSpacing: 0.5)),
              ],
            ),
          ),
          const Divider(height: 1),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _col('orders')
                .orderBy('completedAt', descending: true)
                .limit(15)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              }
              final completed = snapshot.data!.docs
                  .map((d) => RestaurantOrder.fromMap(d.id, d.data()))
                  .where((o) => o.status == 'completed')
                  .toList();

              if (completed.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No recent payments', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
                );
              }

              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 280),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  itemCount: completed.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 8, endIndent: 8),
                  itemBuilder: (context, index) {
                    final order = completed[index];
                    final timestamp = order.completedAt;
                    String timeStr = '-';
                    if (timestamp is Timestamp) {
                      final dt = timestamp.toDate();
                      timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    }
                    final method = order.payment ?? 'Cash';
                    final badgeColor = switch (method) {
                      'QR' => accentBlue,
                      'Split' => kedahLight,
                      _ => accentGreen,
                    };

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showOrderDetailsDialog(order),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(order.table ?? '-',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kedahGreen)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.id.length > 8 ? order.id.substring(order.id.length - 8) : order.id,
                                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(timeStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(method,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor)),
                            ),
                            const SizedBox(width: 10),
                            Text('RM ${(order.total ?? 0).toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
