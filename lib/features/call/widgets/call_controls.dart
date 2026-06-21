import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/call_provider.dart';

class CallControls extends ConsumerWidget {
  const CallControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callProvider);
    final callNotifier = ref.read(callProvider.notifier);
    final isVideo = call.isVideoCall;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 40.0, left: 20.0, right: 20.0),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mute Mic Button
                _buildControlButton(
                  onPressed: () => callNotifier.toggleMute(),
                  icon: call.isMuted ? Icons.mic_off : Icons.mic,
                  color: call.isMuted ? Colors.redAccent : Colors.white.withOpacity(0.2),
                  iconColor: Colors.white,
                  tooltip: 'Mute',
                ),

                // Speakerphone Button
                _buildControlButton(
                  onPressed: () => callNotifier.toggleSpeaker(),
                  icon: call.isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                  color: call.isSpeakerOn ? Colors.blueAccent : Colors.white.withOpacity(0.2),
                  iconColor: Colors.white,
                  tooltip: 'Speaker',
                ),

                // Camera Toggle Button (Video Only)
                if (isVideo)
                  _buildControlButton(
                    onPressed: () => callNotifier.toggleCamera(),
                    icon: call.isCameraOn ? Icons.videocam : Icons.videocam_off,
                    color: call.isCameraOn ? Colors.white.withOpacity(0.2) : Colors.redAccent,
                    iconColor: Colors.white,
                    tooltip: 'Camera',
                  ),

                // Switch Camera Button (Video Only)
                if (isVideo)
                  _buildControlButton(
                    onPressed: () => callNotifier.switchCamera(),
                    icon: Icons.flip_camera_ios,
                    color: Colors.white.withOpacity(0.2),
                    iconColor: Colors.white,
                    tooltip: 'Flip Camera',
                  ),

                // End Call Button (Red, always visible)
                _buildControlButton(
                  onPressed: () => callNotifier.endCall(),
                  icon: Icons.call_end,
                  color: Colors.red,
                  iconColor: Colors.white,
                  tooltip: 'End Call',
                  size: 56.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required Color color,
    required Color iconColor,
    required String tooltip,
    double size = 48.0,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor),
        iconSize: size * 0.5,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        splashRadius: size * 0.6,
      ),
    );
  }
}
