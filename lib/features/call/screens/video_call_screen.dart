import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/call_provider.dart';
import '../widgets/call_controls.dart';
import '../../../core/models/call_state.dart';
import '../../../core/services/agora_service.dart';

class VideoCallScreen extends ConsumerWidget {
  const VideoCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callProvider);
    final engine = AgoraService().engine;

    String statusText = 'Connecting...';
    if (call.callState == CallState.connected) {
      statusText = 'Connected';
    } else if (call.callState == CallState.calling) {
      statusText = 'Calling...';
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Full-screen Remote Video View
          Builder(
            builder: (context) {
              final remoteUid = call.remoteUid;
              final channelId = call.channelId;

              if (remoteUid == null || engine == null) {
                return Container(
                  color: const Color(0xFF141416),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Colors.blueAccent),
                      const SizedBox(height: 20.0),
                      Text(
                        'Waiting for remote user to join...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Channel: $channelId',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: engine,
                  canvas: VideoCanvas(uid: remoteUid),
                  connection: RtcConnection(channelId: channelId),
                ),
              );
            },
          ),

          // 2. Floating Local Video Preview (Top-Right overlay)
          Positioned(
            top: 50.0,
            right: 20.0,
            child: Builder(
              builder: (context) {
                final isCameraOn = call.isCameraOn;

                return Container(
                  width: 110.0,
                  height: 160.0,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10.0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.0),
                    child: (!isCameraOn || engine == null)
                        ? Center(
                            child: Icon(
                              Icons.videocam_off,
                              color: Colors.white.withOpacity(0.5),
                              size: 28.0,
                            ),
                          )
                        : AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: engine,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          // 3. Status Bar & Call Duration Timer Overlay (Top-Left overlay)
          Positioned(
            top: 50.0,
            left: 20.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Small blinking green indicator dot
                  if (call.callState == CallState.connected)
                    _buildBlinkingDot()
                  else
                    const Icon(Icons.swap_calls, color: Colors.amberAccent, size: 12.0),
                  const SizedBox(width: 6.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (call.callState == CallState.connected)
                        Text(
                          call.durationString,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10.0,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Call controls
          const CallControls(),
        ],
      ),
    );
  }

  Widget _buildBlinkingDot() {
    return Container(
      width: 8.0,
      height: 8.0,
      decoration: const BoxDecoration(
        color: Colors.greenAccent,
        shape: BoxShape.circle,
      ),
    );
  }
}
