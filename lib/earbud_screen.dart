import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class EarbudScreen extends StatefulWidget {
  const EarbudScreen({super.key});

  @override
  State<EarbudScreen> createState() => _EarbudScreenState();
}

class _EarbudScreenState extends State<EarbudScreen> {
  static const platform = MethodChannel('bluetooth_devices');
  List<Map<String, String>> connectedDevices = [];
  Map<String, String>? selectedDevice;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _getConnectedDevices();
  }

  Future<void> _getConnectedDevices() async {
    setState(() => isLoading = true);
    try {
      final List<dynamic> devices =
      await platform.invokeMethod('getConnectedDevices');
      setState(() {
        connectedDevices = devices
            .map((d) => Map<String, String>.from(d))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Header
              const Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.headphones,
                      size: 80,
                      color: Color(0xFF10A37F),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Connect Earbuds',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Select your earbuds to continue',
                      style: TextStyle(
                        color: Color(0xFF8E8EA0),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Refresh Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _getConnectedDevices,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF10A37F)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF10A37F),
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(
                    Icons.refresh,
                    color: Color(0xFF10A37F),
                  ),
                  label: Text(
                    isLoading ? 'Loading...' : 'Refresh Devices',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Device count
              Text(
                'Found ${connectedDevices.length} connected device(s)',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // Device List
              Expanded(
                child: connectedDevices.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bluetooth_disabled,
                        size: 60,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Bluetooth devices connected!\nPlease connect your earbuds\nto your phone first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: connectedDevices.length,
                  itemBuilder: (context, index) {
                    final device = connectedDevices[index];
                    final isSelected =
                        selectedDevice?['address'] ==
                            device['address'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedDevice = device;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF10A37F)
                              .withOpacity(0.2)
                              : const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF10A37F)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.headphones,
                              color: Color(0xFF10A37F),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    device['name'] ?? 'Unknown Device',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    device['address'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF10A37F),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: selectedDevice != null
                      ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Connected to ${selectedDevice!['name']}'),
                        backgroundColor: const Color(0xFF10A37F),
                      ),
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10A37F),
                    disabledBackgroundColor:
                    Colors.grey.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}