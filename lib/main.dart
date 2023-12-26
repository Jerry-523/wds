import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Device Scanner',
      theme: ThemeData.dark(useMaterial3: true),
      home: DeviceScanner(),
    );
  }
}

class DeviceScanner extends StatefulWidget {
  @override
  _DeviceScannerState createState() => _DeviceScannerState();
}

class _DeviceScannerState extends State<DeviceScanner> {
  final String networkRange = '192.168.1'; // Change this to your local network IP range
  List<MapEntry<String, String>> devices = [];
  bool scanning = false;

  Future<void> scanDevices() async {
    for (int i = 1; i <= 255; i++) {
      if (!scanning) break; // Break the loop if scanning is stopped
      final String ipAddress = '$networkRange.$i';
      final int port = 80; // You can change the port as needed for your use case

      try {
        final socket = await Socket.connect(ipAddress, port, timeout: Duration(milliseconds: 50));
        setState(() {
          devices.add(MapEntry(ipAddress, '...'));
        });
        String macAddress = await getMACAddress(ipAddress);
        setState(() {
          devices.removeWhere((entry) => entry.key == ipAddress);
          devices.add(MapEntry(ipAddress, macAddress));
        });
        socket.destroy();
      } catch (error) {
        print('Error connecting to $ipAddress: $error');
      }
    }
    setState(() {
      scanning = false; // Set scanning to false after completion
    });
  }

  Future<String> getMACAddress(String ipAddress) async {
    final ProcessResult result = await Process.run('arp', ['-a', ipAddress]);
    if (result.exitCode == 0) {
      final String output = result.stdout as String;
      final List<String> lines = output.split('\n');
      for (String line in lines) {
        if (line.contains(ipAddress)) {
          final List<String> parts = line.trim().split(' ');
          if (parts.length >= 2) {
            return parts[1]; // Assuming MAC address is the second part
          }
        }
      }
    }
    return 'MAC Address not found';
  }

  void startScanning() {
    setState(() {
      scanning = true;
      devices.clear(); // Clear the devices list when starting a new scan
    });
    scanDevices();
  }

  void stopScanning() {
    setState(() {
      scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: scanning ? null : startScanning,
              child: Text('Start Scanning'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: scanning ? stopScanning : null,
              child: Text('Stop Scanning'),
            ),
            SizedBox(height: 20),
            scanning
                ? CircularProgressIndicator()
                : devices.isEmpty
                ? Text('No devices found')
                : Expanded(
              child: ListView.builder(
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('IP: ${devices[index].key};\nMAC: ${devices[index].value};'),
                    trailing: Icon(Icons.device_hub),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
