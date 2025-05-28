import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  static final Logger logger = Logger();
  BluetoothConnection? connection;
  bool isConnected = false;
  
  // Get available Bluetooth devices
  Future<List<BluetoothDevice>> getDevices() async {
    // Request permissions
    await _requestPermissions();
    
    try {
      List<BluetoothDevice> devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      return devices;
    } catch (e) {
      logger.e('Error getting devices: $e');
      return [];
    }
  }

  // Connect to a specific device
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      connection = await BluetoothConnection.toAddress(device.address);
      isConnected = true;
      logger.i('Connected to ${device.name}');
      
      // Listen for incoming data
      connection!.input!.listen((Uint8List data) {
        String message = String.fromCharCodes(data);
        logger.i('Received: $message');
        // Handle incoming messages here
      }).onDone(() {
        logger.i('Disconnected from device');
        isConnected = false;
      });
      
      return true;
    } catch (e) {
      logger.e('Failed to connect: $e');
      return false;
    }
  }

  // Send command to Raspberry Pi
  Future<bool> sendCommand(String command) async {
    if (!isConnected || connection == null) {
      logger.w('Not connected to device');
      return false;
    }

    try {
      connection!.output.add(Uint8List.fromList(utf8.encode('$command\n')));
      await connection!.output.allSent;
      logger.i('Sent command: $command');
      return true;
    } catch (e) {
      logger.e('Failed to send command: $e');
      return false;
    }
  }

  // Disconnect from device
  Future<void> disconnect() async {
    if (connection != null) {
      await connection!.close();
      connection = null;
      isConnected = false;
      logger.i('Disconnected from device');
    }
  }

  // Request necessary permissions
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetooth] != PermissionStatus.granted) {
      logger.w('Bluetooth permission not granted');
    }
  }
}