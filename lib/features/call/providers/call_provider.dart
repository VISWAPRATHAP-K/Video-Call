import 'dart:async';
import 'dart:developer' as developer;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/models/call_state.dart';
import '../../../core/models/call_model.dart';
import '../../../core/services/agora_service.dart';
import '../../../core/services/callkit_service.dart';
import '../../../core/services/api_service.dart';
import '../../../core/navigation.dart';
import '../screens/audio_call_screen.dart';
import '../screens/video_call_screen.dart';

class CallNotifier extends StateNotifier<CallModel> {
  final AgoraService _agoraService = AgoraService();
  final CallKitService _callKitService = CallKitService();
  final ApiService _apiService = ApiService();

  String? _currentCallUuid;
  Timer? _durationTimer;
  StreamSubscription<CallEvent?>? _callKitSubscription;

  CallNotifier() : super(CallModel.initial()) {
    _listenToCallKitEvents();
    _checkActiveCalls();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _callKitSubscription?.cancel();
    _agoraService.release();
    super.dispose();
  }

  /// Listen to events from flutter_callkit_incoming
  void _listenToCallKitEvents() {
    _callKitSubscription = _callKitService.onCallEvent.listen((event) async {
      if (event == null) return;
      developer.log('CallNotifier: Received CallKit Event: ${event.eventName}');

      if (event is CallEventActionCallIncoming) {
        state = state.copyWith(callState: CallState.ringing);
      } else if (event is CallEventActionCallAccept) {
        developer.log('CallNotifier: Call accepted via CallKit');
        final params = event.callKitParams;
        final acceptedChannelId = params.handle ?? 'demo123';
        final acceptedIsVideo = params.type == 1;
        _currentCallUuid = params.id;

        state = state.copyWith(
          channelId: acceptedChannelId,
          isVideoCall: acceptedIsVideo,
          callState: CallState.connecting,
          isMuted: false,
          isCameraOn: true,
          isSpeakerOn: acceptedIsVideo,
        );

        // Fetch receiver's Agora RTC token from the backend
        try {
          final response = await _apiService.acceptCall(channelName: acceptedChannelId);
          if (response.statusCode == 200) {
            final token = response.data['token'] ?? '';
            state = state.copyWith(token: token);
          }
        } catch (e) {
          developer.log('CallNotifier Error fetching accept token: $e');
        }

        // Navigate to calling screen
        _navigateToCallScreen();

        // Connect to Agora channel
        await _joinAgoraChannel();
      } else if (event is CallEventActionCallDecline) {
        developer.log('CallNotifier: Call declined via CallKit');
        _cleanupCallSession();
      } else if (event is CallEventActionCallEnded) {
        developer.log('CallNotifier: Call ended via CallKit');
        _cleanupCallSession();
      } else if (event is CallEventActionCallTimeout) {
        developer.log('CallNotifier: Call timeout (missed)');
        _cleanupCallSession();
      }
    });
  }

  /// Check if there are active calls when app launches
  Future<void> _checkActiveCalls() async {
    try {
      final activeCalls = await _callKitService.getActiveCalls();
      if (activeCalls != null && activeCalls.isNotEmpty) {
        developer.log('CallNotifier: Active calls found on startup: $activeCalls');
        final latestCall = activeCalls.last;
        String? activeUuid;
        String activeChannelId = 'demo123';
        bool activeIsVideo = false;

        if (latestCall is CallKitParams) {
          activeUuid = latestCall.id;
          activeChannelId = latestCall.handle ?? 'demo123';
          activeIsVideo = latestCall.type == 1;
        } else if (latestCall is Map) {
          activeUuid = latestCall['id']?.toString();
          activeChannelId = latestCall['handle']?.toString() ?? 'demo123';
          activeIsVideo = latestCall['type'] == 1;
        }

        _currentCallUuid = activeUuid;
        state = state.copyWith(
          channelId: activeChannelId,
          isVideoCall: activeIsVideo,
          callState: CallState.connecting,
        );

        _navigateToCallScreen();
        await _joinAgoraChannel();
      }
    } catch (e) {
      developer.log('CallNotifier Error checking active calls: $e');
    }
  }

  /// Request runtime permissions for Camera, Microphone and Overlay
  Future<bool> requestPermissions(BuildContext context) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    if (!cameraGranted || !micGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera and Microphone permissions are required to make calls.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return false;
    }
    return true;
  }

  /// Start an outgoing call
  Future<void> startOutgoingCall({
    required BuildContext context,
    required String channelId,
    required bool isVideo,
    required int receiverId,
  }) async {
    if (state.callState != CallState.idle) return;

    final hasPermissions = await requestPermissions(context);
    if (!hasPermissions) return;

    state = state.copyWith(
      callState: CallState.calling,
      channelId: channelId,
      isVideoCall: isVideo,
      isMuted: false,
      isCameraOn: true,
      isSpeakerOn: isVideo,
    );

    developer.log('CallNotifier: Starting outgoing call. Channel: $channelId, Receiver: $receiverId');

    final uuid = const Uuid().v4();
    _currentCallUuid = uuid;

    // Trigger CallKit outgoing visual feedback
    await _callKitService.startOutgoingCall(
      uuid: uuid,
      callerName: 'Calling Contact...',
      channelId: channelId,
      isVideo: isVideo,
    );

    // Call backend to trigger FCM Call and obtain local Agora Token
    try {
      final response = await _apiService.initiateCall(
        receiverId: receiverId,
        channelName: channelId,
        isVideo: isVideo,
      );

      if (response.statusCode == 200) {
        final generatedToken = response.data['token'] ?? '';
        state = state.copyWith(token: generatedToken);

        // Open call screen immediately
        _navigateToCallScreen();

        // Connect to Agora channel
        await _joinAgoraChannel();
      } else {
        _cleanupCallSession();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call failed: ${response.data['message']}')),
        );
      }
    } catch (e) {
      _cleanupCallSession();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Call failed to connect: $e')),
      );
    }
  }

  /// Simulate an incoming call locally (backend-less testing)
  Future<void> simulateIncomingCall(BuildContext context, String channelId, bool isVideo) async {
    if (state.callState != CallState.idle) return;

    final hasPermissions = await requestPermissions(context);
    if (!hasPermissions) return;

    final uuid = const Uuid().v4();
    _currentCallUuid = uuid;
    
    state = state.copyWith(
      channelId: channelId,
      isVideoCall: isVideo,
      isMuted: false,
      isCameraOn: true,
      isSpeakerOn: isVideo,
    );

    developer.log('CallNotifier: Simulating incoming call. Channel: $channelId');

    await _callKitService.showIncomingCall(
      uuid: uuid,
      callerName: 'Incoming Simulation',
      channelId: channelId,
      isVideo: isVideo,
    );
  }

  /// End current call session
  Future<void> endCall() async {
    developer.log('CallNotifier: Ending call manually');
    if (_currentCallUuid != null) {
      await _callKitService.endCall(_currentCallUuid!);
    }
    await _cleanupCallSession();
  }

  /// Setup Agora Service and Join Channel
  Future<void> _joinAgoraChannel() async {
    if (state.appId.isEmpty) {
      developer.log('CallNotifier Error: Agora App ID is empty');
      state = state.copyWith(callState: CallState.failed);
      return;
    }

    try {
      await _agoraService.initEngine(
        appId: state.appId,
        onJoinChannelSuccess: (channel, uid, elapsed) {
          developer.log('CallNotifier: Local user joined channel: $channel, uid: $uid');
          state = state.copyWith(callState: CallState.connected);
          _startTimer();
        },
        onUserJoined: (remoteUid, elapsed) {
          developer.log('CallNotifier: Remote user joined: $remoteUid');
          state = state.copyWith(remoteUid: () => remoteUid);
          
          if (state.isVideoCall) {
            _agoraService.toggleSpeaker(true);
            state = state.copyWith(isSpeakerOn: true);
          }
        },
        onUserOffline: (remoteUid) {
          developer.log('CallNotifier: Remote user offline: $remoteUid');
          state = state.copyWith(remoteUid: () => null);
          endCall();
        },
        onLeaveChannel: () {
          developer.log('CallNotifier: Local user left channel');
        },
        onConnectionStateChanged: (connectionState, reason) {
          developer.log('CallNotifier: Connection state changed: $connectionState, reason: $reason');
          if (connectionState == ConnectionStateType.connectionStateDisconnected ||
              connectionState == ConnectionStateType.connectionStateFailed) {
            if (state.callState == CallState.connected) {
              state = state.copyWith(callState: CallState.connecting);
            }
          }
        },
        onError: (err, msg) {
          developer.log('CallNotifier Error from Agora: $err - $msg');
          if (err == ErrorCodeType.errTokenExpired) {
            endCall();
          }
        },
      );

      await _agoraService.toggleSpeaker(state.isSpeakerOn);

      await _agoraService.joinChannel(
        token: state.token,
        channelId: state.channelId,
        isVideo: state.isVideoCall,
      );
    } catch (e) {
      developer.log('CallNotifier Error: Agora join failed. $e');
      state = state.copyWith(callState: CallState.failed);
    }
  }

  /// Toggle audio muting
  void toggleMute() {
    final newState = !state.isMuted;
    state = state.copyWith(isMuted: newState);
    _agoraService.toggleMute(newState);
  }

  /// Toggle speakerphone
  void toggleSpeaker() {
    final newState = !state.isSpeakerOn;
    state = state.copyWith(isSpeakerOn: newState);
    _agoraService.toggleSpeaker(newState);
  }

  /// Toggle camera on/off
  void toggleCamera() {
    final newState = !state.isCameraOn;
    state = state.copyWith(isCameraOn: newState);
    _agoraService.toggleCamera(newState);
  }

  /// Switch between front and rear cameras
  void switchCamera() {
    _agoraService.switchCamera();
  }

  /// Navigate to call screen based on type
  void _navigateToCallScreen() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => state.isVideoCall 
            ? const VideoCallScreen() 
            : const AudioCallScreen()
        ),
      );
    }
  }

  /// Start call duration timer
  void _startTimer() {
    _durationTimer?.cancel();
    state = state.copyWith(duration: 0);
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      state = state.copyWith(duration: state.duration + 1);
    });
  }

  /// Cleanup states and release Agora/CallKit resources
  Future<void> _cleanupCallSession() async {
    developer.log('CallNotifier: Cleaning up call session');
    _durationTimer?.cancel();
    _durationTimer = null;

    state = state.copyWith(callState: CallState.ended);

    await _agoraService.leaveChannel();
    state = state.copyWith(
      remoteUid: () => null,
      duration: 0,
      isMuted: false,
      isSpeakerOn: false,
      isCameraOn: true,
      token: '',
    );
    _currentCallUuid = null;

    // Pop call screens and return back to Contacts
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    state = state.copyWith(callState: CallState.idle);
  }
}

// Global Call Provider
final callProvider = StateNotifierProvider<CallNotifier, CallModel>((ref) {
  return CallNotifier();
});
