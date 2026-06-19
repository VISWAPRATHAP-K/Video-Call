import 'dart:developer' as developer;
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

class CallKitService {
  static final CallKitService _instance = CallKitService._internal();
  factory CallKitService() => _instance;
  CallKitService._internal();

  Stream<CallEvent?> get onCallEvent => FlutterCallkitIncoming.onEvent;

  Future<void> showIncomingCall({
    required String uuid,
    required String callerName,
    required String channelId,
    required bool isVideo,
  }) async {
    developer.log('CallKitService: Showing incoming call. UUID: $uuid, Caller: $callerName, Channel: $channelId, Video: $isVideo');

    final params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'Agora Video Call',
      avatar: 'https://i.pravatar.cc/150?img=60',
      handle: channelId,
      type: isVideo ? 1 : 0, // 0 = Audio, 1 = Video
      duration: 30000, // Ringing duration in ms (30s)
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: false,
        subtitle: 'Missed Call',
        callbackText: 'Call Back',
      ),
      extra: <String, dynamic>{
        'channelId': channelId,
        'isVideo': isVideo,
      },
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        backgroundColor: '#1C1C1E', // Dark UI background
        actionColor: '#4CAF50',
        textColor: '#FFFFFF',
        incomingCallNotificationChannelName: 'Incoming Call',
        missedCallNotificationChannelName: 'Missed Call',
        isShowFullLockedScreen: true,
        textAccept: 'Accept',
        textDecline: 'Decline',
      ),
      ios: IOSParams(
        iconName: 'AppIcon',
        handleType: 'generic',
        supportsVideo: isVideo,
        maximumCallGroups: 1,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'default',
        audioSessionActive: true,
        supportsDTMF: false,
        supportsHolding: false,
        supportsGrouping: false,
        supportsUngrouping: false,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> startOutgoingCall({
    required String uuid,
    required String callerName,
    required String channelId,
    required bool isVideo,
  }) async {
    developer.log('CallKitService: Starting outgoing call. UUID: $uuid');
    
    final params = CallKitParams(
      id: uuid,
      nameCaller: callerName,
      appName: 'Agora Video Call',
      handle: channelId,
      type: isVideo ? 1 : 0,
      duration: 30000,
      extra: <String, dynamic>{
        'channelId': channelId,
        'isVideo': isVideo,
      },
      ios: IOSParams(
        supportsVideo: isVideo,
        handleType: 'generic',
      ),
    );
    
    await FlutterCallkitIncoming.startCall(params);
  }

  Future<void> endCall(String uuid) async {
    developer.log('CallKitService: Ending call. UUID: $uuid');
    await FlutterCallkitIncoming.endCall(uuid);
  }

  Future<void> endAllCalls() async {
    developer.log('CallKitService: Ending all calls');
    await FlutterCallkitIncoming.endAllCalls();
  }

  Future<List<dynamic>?> getActiveCalls() async {
    return await FlutterCallkitIncoming.activeCalls();
  }
}
