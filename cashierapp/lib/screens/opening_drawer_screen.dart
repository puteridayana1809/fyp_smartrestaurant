import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/constants.dart';

const kedahGreen = Color(0xFF2D5016);
const kedahYellow = Color(0xFFF5C518);

class OpeningDrawerScreen extends StatefulWidget {
  const OpeningDrawerScreen({super.key});

  @override
  State<OpeningDrawerScreen> createState() => _OpeningDrawerScreenState();
}

class _OpeningDrawerScreenState extends State<OpeningDrawerScreen> {
  final _db = FirebaseFirestore.instance;
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _amountPrefilled = false;

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  DocumentReference<Map<String, dynamic>> get _drawerRef => _db
      .collection('restaurants')
      .doc(restaurantId)
      .collection('openingDrawers')
      .doc(_todayKey);

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double _readAmount(Map<String, dynamic>? data) {
    final raw = data?['amount'];
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  Future<void> _saveOpeningDrawer() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text.trim());
    final user = FirebaseAuth.instance.currentUser;

    setState(() => _saving = true);
    try {
      await _drawerRef.set({
        'amount': amount,
        'date': _todayKey,
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid,
        'updatedByEmail': user?.email,
      }, SetOptions(merge: true));

      if (!mounted) return;
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Opening drawer berjaya disimpan')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ralat simpan opening drawer: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: const Text('Opening Drawer'),
        backgroundColor: kedahGreen,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _drawerRef.snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final currentAmount = _readAmount(data);
          final updatedAt = data?['updatedAt'];

          if (snapshot.hasData && !_amountPrefilled) {
            _amountController.text = currentAmount.toStringAsFixed(2);
            _amountPrefilled = true;
          }

          String updatedText = 'Belum disimpan hari ini';
          if (updatedAt is Timestamp) {
            updatedText =
                'Updated ${DateFormat('h:mm a').format(updatedAt.toDate())}';
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Color(0xFFEFF1F5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: kedahGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.point_of_sale,
                              color: kedahGreen,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Opening Drawer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(DateTime.now()),
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: kedahYellow.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Opening',
                              style: TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'RM ${currentAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: kedahGreen,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              updatedText,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Opening amount',
                            prefixText: 'RM ',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final amount = double.tryParse(value?.trim() ?? '');
                            if (amount == null) {
                              return 'Masukkan jumlah yang sah';
                            }
                            if (amount < 0) return 'Jumlah tidak boleh negatif';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _saveOpeningDrawer,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kedahGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            _saving ? 'Saving...' : 'Save Opening Drawer',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Card(
                elevation: 0,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Nilai ini akan ditolak daripada jumlah pembayaran cash untuk kiraan Actual Cash di admin dashboard.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
