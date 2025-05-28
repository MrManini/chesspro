import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:chesspro_app/services/bluetooth_service.dart';
import 'package:logger/logger.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  BluetoothScreenState createState() => BluetoothScreenState();
}

class BluetoothScreenState extends State<BluetoothScreen> {
  final BluetoothService bluetoothService = BluetoothService();
  final Logger logger = Logger();

  List<BluetoothDevice> devices = [];
  bool isLoading = false;
  String connectionStatus = 'Not connected';

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => isLoading = true);
    devices = await bluetoothService.getDevices();
    setState(() => isLoading = false);
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      connectionStatus = 'Connecting...';
      isLoading = true;
    });

    bool success = await bluetoothService.connectToDevice(device);

    setState(() {
      connectionStatus =
          success ? 'Connected to ${device.name}' : 'Failed to connect';
      isLoading = false;
    });

    if (success && mounted) {
      // Navigate back or to chess screen
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connect to Raspberry Pi'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadDevices),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(connectionStatus),
            SizedBox(height: 16),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    BluetoothDevice device = devices[index];
                    return ListTile(
                      title: Text(device.name ?? 'Unknown Device'),
                      subtitle: Text(device.address),
                      trailing: Icon(Icons.bluetooth),
                      onTap: () => _connectToDevice(device),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    bluetoothService.disconnect();
    super.dispose();
  }
}
