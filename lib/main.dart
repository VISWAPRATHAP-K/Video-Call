import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';


import 'features/call/providers/call_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register the CallController globally
  Get.put(CallController());

  runApp(const AgoraCallKitDemoApp());
}

class AgoraCallKitDemoApp extends StatelessWidget {
  const AgoraCallKitDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Agora CallKit Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blueAccent,
        scaffoldBackgroundColor: const Color(0xFF121214),
        cardColor: const Color(0xFF1C1C1E),
        colorScheme: const ColorScheme.dark(
          primary: Colors.blueAccent,
          secondary: Colors.blueGrey,
          surface: Color(0xFF1C1C1E),
        ),
        useMaterial3: true,
      ),
      home: const MainDashboardScreen(),
    );
  }
}

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  late final TextEditingController _channelController;
  final CallController _callController = Get.find<CallController>();

  bool _cameraGranted = false;
  bool _micGranted = false;
  bool _notificationGranted = false;

  @override
  void initState() {
    super.initState();
    _channelController = TextEditingController(text: 'demo123');
    _checkPermissionsStatus();
    
    // Automatically request permissions when the app opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissions();
    });
  }

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsStatus() async {
    final camera = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    final notification = await Permission.notification.status;

    setState(() {
      _cameraGranted = camera.isGranted;
      _micGranted = mic.isGranted;
      _notificationGranted = notification.isGranted;
    });
  }

  Future<void> _requestPermissions() async {
    await _callController.requestPermissions();
    await _checkPermissionsStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Demo App',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Permissions Status Card
              _buildPermissionsCard(),
              const SizedBox(height: 24.0),

              // Call Actions Title
              const Text(
                'CALL TESTING CONTROLS',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12.0),

              // Testing Buttons Grid
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildPermissionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Text(
                      'System Permissions',
                      style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: _requestPermissions,
                  child: const Text('Request All'),
                )
              ],
            ),
            const Divider(height: 16.0, color: Colors.white12),
            _buildPermissionItem('Camera', _cameraGranted, Icons.videocam),
            const SizedBox(height: 10.0),
            _buildPermissionItem('Microphone', _micGranted, Icons.mic),
            const SizedBox(height: 10.0),
            _buildPermissionItem('Notifications', _notificationGranted, Icons.notifications_active),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(String name, bool isGranted, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18.0, color: Colors.white60),
            const SizedBox(width: 10.0),
            Text(name, style: const TextStyle(fontSize: 14.0, color: Colors.white70)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: isGranted ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            isGranted ? 'Granted' : 'Missing',
            style: TextStyle(
              color: isGranted ? Colors.greenAccent : Colors.redAccent,
              fontSize: 11.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Outgoing Caller Controls
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _callController.startOutgoingCall(_channelController.text, true),
                icon: const Icon(Icons.videocam, color: Colors.white),
                label: const Text('Start Video Call', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _callController.startOutgoingCall(_channelController.text, false),
                icon: const Icon(Icons.call, color: Colors.white),
                label: const Text('Start Audio Call', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C2C2E),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Incoming Call Simulators (CallKit Verification)
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callController.simulateIncomingCall(_channelController.text, true),
                icon: const Icon(Icons.add_to_home_screen, color: Colors.greenAccent),
                label: const Text('Simulate Incoming Video', style: TextStyle(color: Colors.greenAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.greenAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _callController.simulateIncomingCall(_channelController.text, false),
                icon: const Icon(Icons.phone_callback, color: Colors.greenAccent),
                label: const Text('Simulate Incoming Audio', style: TextStyle(color: Colors.greenAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.greenAccent),
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


}
