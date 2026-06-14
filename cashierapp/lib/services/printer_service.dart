import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

import '../models/order_item.dart';

class PrinterService {
  /// Returns previously paired/bonded Bluetooth devices.
  static Future<List<BluetoothInfo>> getPairedDevices() async {
    return PrintBluetoothThermal.pairedBluetooths;
  }

  static Future<bool> connect(String macAddress) async {
    return PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
  }

  static Future<bool> disconnect() async {
    return PrintBluetoothThermal.disconnect;
  }

  static Future<bool> get isConnected => PrintBluetoothThermal.connectionStatus;

  /// Builds and prints a receipt for a completed order.
  static Future<bool> printReceipt({
    required String orderId,
    required String tableName,
    required List<OrderItem> items,
    required double subtotal,
    required double total,
    required String paymentMethod,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text(
      'Bihun Sup Daging Selambak',
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    );
    bytes += generator.text(
      'Cash Register Receipt',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    bytes += generator.text('Order : $orderId');
    bytes += generator.text('Table : $tableName');
    bytes += generator.text('Date  : ${DateTime.now()}');
    bytes += generator.hr();

    for (final item in items) {
      bytes += generator.row([
        PosColumn(text: '${item.qty}x ${item.name}', width: 8),
        PosColumn(
          text: item.total.toStringAsFixed(2),
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.hr();

    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 8),
      PosColumn(text: 'RM ${subtotal.toStringAsFixed(2)}', width: 4, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 8,
        styles: const PosStyles(bold: true, height: PosTextSize.size2),
      ),
      PosColumn(
        text: 'RM ${total.toStringAsFixed(2)}',
        width: 4,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2),
      ),
    ]);
    bytes += generator.hr();

    bytes += generator.text(
      'Payment: $paymentMethod',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.feed(1);
    bytes += generator.text(
      'Terima Kasih!',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.cut();

    return PrintBluetoothThermal.writeBytes(bytes);
  }
}
