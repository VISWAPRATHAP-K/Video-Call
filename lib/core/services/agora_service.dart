import 'dart:developer' as developer;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  bool _isInitialized = false;

  RtcEngine? get engine => _engine;

  // Callbacks to be hooked by CallController
  void Function(String channel, int uid, int elapsed)? onJoinChannelSuccessCallback;
  void Function(int remoteUid, int elapsed)? onUserJoinedCallback;
  void Function(int remoteUid)? onUserOfflineCallback;
  void Function()? onLeaveChannelCallback;
  void Function(ConnectionStateType state, ConnectionChangedReasonType reason)? onConnectionStateChangedCallback;
  void Function(ErrorCodeType err, String msg)? onErrorCallback;

  Future<void> initEngine({
    required String appId,
    void Function(String channel, int uid, int elapsed)? onJoinChannelSuccess,
    void Function(int remoteUid, int elapsed)? onUserJoined,
    void Function(int remoteUid)? onUserOffline,
    void Function()? onLeaveChannel,
    void Function(ConnectionStateType state, ConnectionChangedReasonType reason)? onConnectionStateChanged,
    void Function(ErrorCodeType err, String msg)? onError,
  }) async {
    if (_isInitialized && _engine != null) {
      developer.log('AgoraService: Engine already initialized');
      return;
    }

    // Set callback references
    onJoinChannelSuccessCallback = onJoinChannelSuccess;
    onUserJoinedCallback = onUserJoined;
    onUserOfflineCallback = onUserOffline;
    onLeaveChannelCallback = onLeaveChannel;
    onConnectionStateChangedCallback = onConnectionStateChanged;
    onErrorCallback = onError;

    try {
      developer.log('AgoraService: Initializing RtcEngine with App ID: $appId');
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            developer.log('AgoraService event: onJoinChannelSuccess channel: ${connection.channelId}, localUid: ${connection.localUid}');
            onJoinChannelSuccessCallback?.call(connection.channelId ?? '', connection.localUid ?? 0, elapsed);
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            developer.log('AgoraService event: onUserJoined remoteUid: $remoteUid');
            onUserJoinedCallback?.call(remoteUid, elapsed);
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            developer.log('AgoraService event: onUserOffline remoteUid: $remoteUid, reason: $reason');
            onUserOfflineCallback?.call(remoteUid);
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            developer.log('AgoraService event: onLeaveChannel');
            onLeaveChannelCallback?.call();
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            developer.log('AgoraService event: onConnectionStateChanged state: $state, reason: $reason');
            onConnectionStateChangedCallback?.call(state, reason);
          },
          onError: (ErrorCodeType err, String msg) {
            developer.log('AgoraService event: onError err: $err, msg: $msg');
            onErrorCallback?.call(err, msg);
          },
        ),
      );

      _isInitialized = true;
      developer.log('AgoraService: Engine successfully initialized');
    } catch (e) {
      developer.log('AgoraService Error: failed to initialize engine. $e');
    }
  }

  Future<void> joinChannel({
    required String token,
    required String channelId,
    required bool isVideo,
  }) async {
    if (_engine == null) {
      developer.log('AgoraService Error: Engine not initialized');
      return;
    }

    try {
      developer.log('AgoraService: Joining channel $channelId (Video: $isVideo)');
      
      if (isVideo) {
        await _engine!.enableVideo();
        await _engine!.startPreview();
      } else {
        await _engine!.enableAudio();
        await _engine!.disableVideo();
      }

      // Join the channel using dynamic token
      await _engine!.joinChannel(
        token: token,
        channelId: channelId,
        uid: 0, // 0 lets Agora automatically assign a UID
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          publishCameraTrack: isVideo,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: isVideo,
        ),
      );
    } catch (e) {
      developer.log('AgoraService Error: Failed to join channel. $e');
      onErrorCallback?.call(ErrorCodeType.errFailed, e.toString());
    }
  }

  Future<void> leaveChannel() async {
    if (_engine == null) return;
    try {
      developer.log('AgoraService: Leaving channel');
      await _engine!.stopPreview();
      await _engine!.leaveChannel();
    } catch (e) {
      developer.log('AgoraService Error: Failed to leave channel. $e');
    }
  }

  Future<void> release() async {
    if (_engine == null) return;
    try {
      developer.log('AgoraService: Releasing RtcEngine');
      await leaveChannel();
      await _engine!.release();
      _engine = null;
      _isInitialized = false;
    } catch (e) {
      developer.log('AgoraService Error: Failed to release engine. $e');
    }
  }

  Future<void> toggleMute(bool isMuted) async {
    if (_engine == null) return;
    try {
      developer.log('AgoraService: Toggling mute state to $isMuted');
      await _engine!.muteLocalAudioStream(isMuted);
    } catch (e) {
      developer.log('AgoraService Error: failed to toggle mute to $isMuted. $e');
    }
  }

  Future<void> toggleSpeaker(bool isSpeakerOn) async {
    if (_engine == null) return;
    try {
      developer.log('AgoraService: Toggling speaker state to $isSpeakerOn');
      await _engine!.setEnableSpeakerphone(isSpeakerOn);
    } catch (e) {
      developer.log('AgoraService Error: failed to toggle speaker to $isSpeakerOn. $e');
    }
  }

  Future<void> toggleCamera(bool isCameraOn) async {
    if (_engine == null) return;
    try {
      developer.log('AgoraService: Toggling camera enabled state to $isCameraOn');
      if (isCameraOn) {
        await _engine!.enableLocalVideo(true);
        await _engine!.startPreview();
      } else {
        await _engine!.stopPreview();
        await _engine!.enableLocalVideo(false);
      }
    } catch (e) {
      developer.log('AgoraService Error: failed to toggle camera to $isCameraOn. $e');
    }
  }

  Future<void> switchCamera() async {
    if (_engine == null) return;
    try {
      developer.log('AgoraService: Switching front/rear camera');
      await _engine!.switchCamera();
    } catch (e) {
      developer.log('AgoraService Error: failed to switch camera. $e');
    }
  }
}
