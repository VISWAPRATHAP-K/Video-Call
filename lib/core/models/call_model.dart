import 'call_state.dart';

class CallModel {
  final CallState callState;
  final String channelId;
  final int? remoteUid;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isCameraOn;
  final int duration;
  final bool isVideoCall;
  final String appId;
  final String token;

  CallModel({
    required this.callState,
    required this.channelId,
    this.remoteUid,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.isCameraOn,
    required this.duration,
    required this.isVideoCall,
    required this.appId,
    required this.token,
  });

  factory CallModel.initial() {
    return CallModel(
      callState: CallState.idle,
      channelId: '',
      remoteUid: null,
      isMuted: false,
      isSpeakerOn: false,
      isCameraOn: true,
      duration: 0,
      isVideoCall: false,
      appId: '28879eb326cc4482952d7fb40d33585a', // Default Demo Agora App ID
      token: '',
    );
  }

  String get durationString {
    final minutes = (duration / 60).floor().toString().padLeft(2, '0');
    final seconds = (duration % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  CallModel copyWith({
    CallState? callState,
    String? channelId,
    int? Function()? remoteUid, // Allows setting to null explicitly via: () => null
    bool? isMuted,
    bool? isSpeakerOn,
    bool? isCameraOn,
    int? duration,
    bool? isVideoCall,
    String? appId,
    String? token,
  }) {
    return CallModel(
      callState: callState ?? this.callState,
      channelId: channelId ?? this.channelId,
      remoteUid: remoteUid != null ? remoteUid() : this.remoteUid,
      isMuted: isMuted ?? this.isMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      duration: duration ?? this.duration,
      isVideoCall: isVideoCall ?? this.isVideoCall,
      appId: appId ?? this.appId,
      token: token ?? this.token,
    );
  }
}
