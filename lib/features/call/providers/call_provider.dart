import 'dart:async';
import 'dart:developer' as developer;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/models/call_state.dart';
import '../../../core/services/agora_service.dart';
import '../../../core/services/callkit_service.dart';
import '../screens/audio_call_screen.dart';
import '../screens/video_call_screen.dart';

class CallController extends GetxController {
  final AgoraService _agoraService = AgoraService();
  final CallKitService _callKitService = CallKitService();

  // Observable states
  final rxCallState = CallState.idle.obs;
  final rxChannelId = ''.obs;
  final rxRemoteUid = RxnInt();
  final rxIsMuted = false.obs;
  final rxIsSpeakerOn = false.obs;
  final rxIsCameraOn = true.obs;
  final rxDuration = 0.obs;
  final rxIsVideoCall = false.obs;
  final rxAppId = '28879eb326cc4482952d7fb40d33585a'.obs; // Default App ID provided by user
  final rxToken = '007eJxTYCiLvb3SPJxfp6Yj4ut9Xy2ptxO2Tdno0nRprnvZpN6Hzu0KDEYWFuaWqUnGRmbJySYmFkaWpkYp5mlJJgYpxsamFqaJK+VNshoCGRkOcexlYmSAQBCfnSElNTff0MiYgQEAnM4fbw=='.obs;

  // Call session tracking
  String? _currentCallUuid;
  Timer? _durationTimer;
  StreamSubscription<CallEvent?>? _callKitSubscription;

  // Getters for views
  CallState get callState => rxCallState.value;
  String get channelId => rxChannelId.value;
  int? get remoteUid => rxRemoteUid.value;
  bool get isMuted => rxIsMuted.value;
  bool get isSpeakerOn => rxIsSpeakerOn.value;
  bool get isCameraOn => rxIsCameraOn.value;
  int get duration => rxDuration.value;
  bool get isVideoCall => rxIsVideoCall.value;
  String get appId => rxAppId.value;
  String get token => rxToken.value;
  RtcEngine? get engine => _agoraService.engine;

  String get durationString {
    final minutes = (duration / 60).floor().toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void onInit() {
    super.onInit();
    _listenToCallKitEvents();
    _checkActiveCalls();
  }

  @override
  void onClose() {
    _durationTimer?.cancel();
    _callKitSubscription?.cancel();
    _agoraService.release();
    super.onClose();
  }

  /// Listen to events from flutter_callkit_incoming
  void _listenToCallKitEvents() {
    _callKitSubscription = _callKitService.onCallEvent.listen((event) async {
      if (event == null) return;
      developer.log('CallController: Received CallKit Event: ${event.eventName}');

      if (event is CallEventActionCallIncoming) {
        rxCallState.value = CallState.ringing;
      } else if (event is CallEventActionCallAccept) {
        developer.log('CallController: Call accepted via CallKit');
        final params = event.callKitParams;
        final acceptedChannelId = params.handle ?? 'demo123';
        final acceptedIsVideo = params.type == 1;
        _currentCallUuid = params.id;

        rxChannelId.value = acceptedChannelId;
        rxIsVideoCall.value = acceptedIsVideo;
        rxCallState.value = CallState.connecting;

        // Open calling screen before connecting Agora
        _navigateToCallScreen();

        // Connect to Agora channel
        await _joinAgoraChannel();
      } else if (event is CallEventActionCallDecline) {
        developer.log('CallController: Call declined via CallKit');
        _cleanupCallSession();
      } else if (event is CallEventActionCallEnded) {
        developer.log('CallController: Call ended via CallKit');
        _cleanupCallSession();
      } else if (event is CallEventActionCallTimeout) {
        developer.log('CallController: Call timeout (missed)');
        _cleanupCallSession();
      }
    });
  }

  /// Check if there are active calls when app launches (e.g. from terminated state)
  Future<void> _checkActiveCalls() async {
    try {
      final activeCalls = await _callKitService.getActiveCalls();
      if (activeCalls != null && activeCalls.isNotEmpty) {
        developer.log('CallController: Active calls found on startup: $activeCalls');
        final latestCall = activeCalls.last;
        if (latestCall is CallKitParams) {
          _currentCallUuid = latestCall.id;
          rxChannelId.value = latestCall.handle ?? 'demo123';
          rxIsVideoCall.value = latestCall.type == 1;
        } else if (latestCall is Map) {
          _currentCallUuid = latestCall['id']?.toString();
          rxChannelId.value = latestCall['handle']?.toString() ?? 'demo123';
          rxIsVideoCall.value = latestCall['type'] == 1;
        }

        rxCallState.value = CallState.connecting;
        _navigateToCallScreen();
        await _joinAgoraChannel();
      }
    } catch (e) {
      developer.log('CallController Error checking active calls: $e');
    }
  }

  /// Request runtime permissions for Camera, Microphone and Notifications
  Future<bool> requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    // Request notification permission for Android 13+
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Request system alert window permission for background overlay support
    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

    if (!cameraGranted || !micGranted) {
      Get.snackbar(
        'Permissions Denied',
        'Camera and Microphone permissions are required to make calls.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
      return false;
    }
    return true;
  }

  /// Start an outgoing call
  Future<void> startOutgoingCall(String channelId, bool isVideo) async {
    if (rxCallState.value != CallState.idle) return;

    final hasPermissions = await requestPermissions();
    if (!hasPermissions) return;

    final uuid = const Uuid().v4();
    _currentCallUuid = uuid;
    rxChannelId.value = channelId;
    rxIsVideoCall.value = isVideo;
    rxCallState.value = CallState.calling;
    rxIsMuted.value = false;
    rxIsCameraOn.value = true;
    // Set speaker on by default for video, off for audio
    rxIsSpeakerOn.value = isVideo;

    developer.log('CallController: Starting outgoing call. Channel: $channelId');

    // Notify CallKit of outgoing call
    await _callKitService.startOutgoingCall(
      uuid: uuid,
      callerName: 'Call Partner',
      channelId: channelId,
      isVideo: isVideo,
    );

    // Open call screen immediately
    _navigateToCallScreen();

    // Connect to Agora channel
    await _joinAgoraChannel();
  }

  /// Simulate an incoming call locally (backend-less testing)
  Future<void> simulateIncomingCall(String channelId, bool isVideo) async {
    if (rxCallState.value != CallState.idle) return;

    final hasPermissions = await requestPermissions();
    if (!hasPermissions) return;

    final uuid = const Uuid().v4();
    _currentCallUuid = uuid;
    rxChannelId.value = channelId;
    rxIsVideoCall.value = isVideo;
    rxIsMuted.value = false;
    rxIsCameraOn.value = true;
    rxIsSpeakerOn.value = isVideo;

    developer.log('CallController: Simulating incoming call. Channel: $channelId');

    await _callKitService.showIncomingCall(
      uuid: uuid,
      callerName: 'Incoming Caller',
      channelId: channelId,
      isVideo: isVideo,
    );
  }

  /// Accept call manually from app UI
  Future<void> acceptCall() async {
    if (_currentCallUuid == null) return;
    developer.log('CallController: Accept call triggered manually');
    rxCallState.value = CallState.connecting;
    _navigateToCallScreen();
    await _joinAgoraChannel();
  }

  /// End current call session
  Future<void> endCall() async {
    developer.log('CallController: Ending call manually');
    if (_currentCallUuid != null) {
      await _callKitService.endCall(_currentCallUuid!);
    }
    await _cleanupCallSession();
  }

  /// Setup Agora Service and Join Channel
  Future<void> _joinAgoraChannel() async {
    if (appId.isEmpty) {
      developer.log('CallController Error: Agora App ID is empty');
      rxCallState.value = CallState.failed;
      Get.snackbar('Error', 'Agora App ID is empty.');
      return;
    }

    try {
      // Initialize Agora engine and hook callbacks
      await _agoraService.initEngine(
        appId: appId,
        onJoinChannelSuccess: (channel, uid, elapsed) {
          developer.log('CallController: Local user joined channel: $channel, uid: $uid');
          rxCallState.value = CallState.connected;
          _startTimer();
        },
        onUserJoined: (remoteUid, elapsed) {
          developer.log('CallController: Remote user joined: $remoteUid');
          rxRemoteUid.value = remoteUid;
          // Set speaker on if remote user joins a video call
          if (rxIsVideoCall.value) {
            _agoraService.toggleSpeaker(true);
            rxIsSpeakerOn.value = true;
          }
        },
        onUserOffline: (remoteUid) {
          developer.log('CallController: Remote user offline: $remoteUid');
          rxRemoteUid.value = null;
          // In 1-on-1 call, end the call if remote user leaves
          endCall();
        },
        onLeaveChannel: () {
          developer.log('CallController: Local user left channel');
        },
        onConnectionStateChanged: (state, reason) {
          developer.log('CallController: Connection state changed: $state, reason: $reason');
          if (state == ConnectionStateType.connectionStateDisconnected ||
              state == ConnectionStateType.connectionStateFailed) {
            // Keep call running, but show connecting state if reconnecting
            if (rxCallState.value == CallState.connected) {
              rxCallState.value = CallState.connecting;
            }
          }
        },
        onError: (err, msg) {
          developer.log('CallController Error from Agora: $err - $msg');
          if (err == ErrorCodeType.errTokenExpired) {
            Get.snackbar('Session Expired', 'Agora token expired.');
            endCall();
          }
        },
      );

      // Trigger Agora speakerphone toggle based on defaults
      await _agoraService.toggleSpeaker(rxIsSpeakerOn.value);

      // Join Agora channel
      await _agoraService.joinChannel(
        token: token,
        channelId: rxChannelId.value,
        isVideo: rxIsVideoCall.value,
      );
    } catch (e) {
      developer.log('CallController Error: Agora join failed. $e');
      rxCallState.value = CallState.failed;
    }
  }

  /// Toggle audio muting
  void toggleMute() {
    final newState = !rxIsMuted.value;
    rxIsMuted.value = newState;
    _agoraService.toggleMute(newState);
  }

  /// Toggle speakerphone
  void toggleSpeaker() {
    final newState = !rxIsSpeakerOn.value;
    rxIsSpeakerOn.value = newState;
    _agoraService.toggleSpeaker(newState);
  }

  /// Toggle camera on/off
  void toggleCamera() {
    final newState = !rxIsCameraOn.value;
    rxIsCameraOn.value = newState;
    _agoraService.toggleCamera(newState);
  }

  /// Switch between front and rear cameras
  void switchCamera() {
    _agoraService.switchCamera();
  }

  /// Navigate to call screen based on type
  void _navigateToCallScreen() {
    if (rxIsVideoCall.value) {
      Get.to(() => const VideoCallScreen(), transition: Transition.fadeIn);
    } else {
      Get.to(() => const AudioCallScreen(), transition: Transition.fadeIn);
    }
  }

  /// Start call duration timer
  void _startTimer() {
    _durationTimer?.cancel();
    rxDuration.value = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      rxDuration.value++;
    });
  }

  /// Cleanup states and release Agora/CallKit resources
  Future<void> _cleanupCallSession() async {
    developer.log('CallController: Cleaning up call session');
    _durationTimer?.cancel();
    _durationTimer = null;

    rxCallState.value = CallState.ended;

    await _agoraService.leaveChannel();
    rxRemoteUid.value = null;
    rxDuration.value = 0;
    rxIsMuted.value = false;
    rxIsSpeakerOn.value = false;
    rxIsCameraOn.value = true;
    _currentCallUuid = null;

    // Return to main screen if currently showing a call screen
    if (Get.currentRoute.contains('CallScreen') || 
        Get.currentRoute == '/AudioCallScreen' || 
        Get.currentRoute == '/VideoCallScreen') {
      Get.until((route) => route.isFirst);
    }

    rxCallState.value = CallState.idle;
  }

  /// Update user's Agora App ID from UI input
  void updateAppId(String newAppId) {
    rxAppId.value = newAppId.trim();
    developer.log('CallController: Agora App ID updated to: ${rxAppId.value}');
  }

  /// Update user's Agora Token from UI input
  void updateToken(String newToken) {
    rxToken.value = newToken.trim();
    developer.log('CallController: Agora Token updated to: ${rxToken.value}');
  }
}
