import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<BluetoothInfo> _devices = [];
  String? _connectedMac;
  bool _previouslyConnected = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkConnection();
    await _loadDevices();
  }

  Future<void> _checkConnection() async {
    final connected = await PrintBluetoothThermal.connectionStatus;
    if (connected && mounted) setState(() => _previouslyConnected = true);
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);

    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final devices = await PrintBluetoothThermal.pairedBluetooths;
    if (mounted) setState(() { _devices = devices; _loading = false; });
  }

  Future<void> _connect(BluetoothInfo device) async {
    setState(() => _loading = true);
    final ok = await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _connectedMac = ok ? device.macAdress : _connectedMac;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Berjaya disambung ke ${device.name}' : 'Gagal sambung')),
    );
  }

  Future<void> _disconnect() async {
    await PrintBluetoothThermal.disconnect;
    if (!mounted) return;
    setState(() {
      _connectedMac = null;
      _previouslyConnected = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tetapan Printer Bluetooth')),
      body: RefreshIndicator(
        onRefresh: _init,
        child: ListView(
          children: [
            if (_connectedMac != null || _previouslyConnected)
              Card(
                margin: const EdgeInsets.all(12),
                color: Colors.green.shade50,
                child: ListTile(
                  leading: const Icon(Icons.print, color: Colors.green),
                  title: const Text('Printer disambung'),
                  subtitle: Text(_connectedMac ?? 'Sambungan aktif'),
                  trailing: TextButton(onPressed: _disconnect, child: const Text('Putuskan')),
                ),
              ),
            if (_loading) const LinearProgressIndicator(),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Peranti Bluetooth Berpasangan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Pasangkan printer thermal melalui Tetapan Bluetooth telefon dahulu, kemudian tarik untuk muat semula.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            if (_devices.isEmpty && !_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('Tiada peranti dijumpai', style: TextStyle(color: Colors.grey))),
              ),
            for (final device in _devices)
              ListTile(
                leading: Icon(
                  Icons.bluetooth,
                  color: device.macAdress == _connectedMac ? Colors.blue : Colors.grey,
                ),
                title: Text(device.name),
                subtitle: Text(device.macAdress),
                trailing: device.macAdress == _connectedMac
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : ElevatedButton(
                        onPressed: () => _connect(device),
                        child: const Text('Sambung'),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
