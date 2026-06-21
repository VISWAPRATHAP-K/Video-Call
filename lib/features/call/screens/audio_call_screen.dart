import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/call_provider.dart';
import '../widgets/call_controls.dart';
import '../../../core/models/call_state.dart';

class AudioCallScreen extends ConsumerWidget {
  const AudioCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callProvider);

    String statusText = 'Connecting...';
    if (call.callState == CallState.connected) {
      statusText = 'Active Call';
    } else if (call.callState == CallState.calling) {
      statusText = 'Calling...';
    } else if (call.callState == CallState.ringing) {
      statusText = 'Ringing...';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      body: SafeArea(
        child: Stack(
          children: [
            // Top Section (Status / Title)
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0),
                child: Column(
                  children: [
                    Text(
                      'AUDIO CALL',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Middle Section (Avatar & Call Info)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Avatar container
                  Container(
                    width: 140.0,
                    height: 140.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 4.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20.0,
                          spreadRadius: 5.0,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 66,
                      backgroundColor: Colors.blueGrey,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/300?img=60'),
                    ),
                  ),
                  const SizedBox(height: 24.0),
                  const Text(
                    'Active Call Session',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    call.durationString,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 20.0,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Call Action Controls
            const CallControls(),
          ],
        ),
      ),
    );
  }
}
