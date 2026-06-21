import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:uuid/uuid.dart';
import 'package:video_call/firebase_options.dart';
import 'package:video_call/core/services/callkit_service.dart';

/// Top-level background message handler annotated with @pragma('vm:entry-point')
/// to ensure it runs in a background isolate when the app is terminated or in background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase before using any Firebase services (required in background isolate)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  developer.log('FCMService: Handling background message: ${message.messageId}');
  _handleCallPayload(message);
}

/// Helper function to parse FCM payload and trigger CallKit incoming screen
void _handleCallPayload(RemoteMessage message) {
  final data = message.data;
  if (data.isEmpty) {
    developer.log('FCMService: Message data is empty. Ignoring.');
    return;
  }

  developer.log('FCMService: Processing call payload data: $data');
  
  // Extract call parameters
  final String? uuid = data['uuid'] ?? data['id'];
  final String callerName = data['caller_name'] ?? data['name'] ?? 'Incoming Call';
  final String? channelId = data['channel_id'] ?? data['channel'];
  final String? avatar = data['avatar'] ?? data['avatar_url'];
  
  // check if is_video is true (support string representation like "true" or numeric 1 or "1")
  final isVideoVal = data['is_video'] ?? data['type'];
  final bool isVideo = isVideoVal == 'true' || isVideoVal == 'video' || isVideoVal == '1' || isVideoVal == 1;

  if (channelId != null && channelId.isNotEmpty) {
    final finalUuid = uuid ?? const Uuid().v4();
    CallKitService().showIncomingCall(
      uuid: finalUuid,
      callerName: callerName,
      channelId: channelId,
      isVideo: isVideo,
      avatar: avatar,
    );
  } else {
    developer.log('FCMService: Missing channelId in payload. Cannot show incoming call.');
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initialize Firebase Messaging configurations
  Future<void> initialize() async {
    // 1. Set the background message handler immediately (must be done before any async steps)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Request notification permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    developer.log('FCMService: User granted notification permission status: ${settings.authorizationStatus}');

    // 3. Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('FCMService: Received foreground message: ${message.messageId}');
      _handleCallPayload(message);
    });

    // 4. Handle when a message opens the app from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('FCMService: App opened from background via message: ${message.messageId}');
    });

    // 5. Check if the app was opened from terminated state via a message
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      developer.log('FCMService: App opened from terminated state via initial message: ${initialMessage.messageId}');
      _handleCallPayload(initialMessage);
    }

    // 6. Retrieve and display the FCM token in developer console
    final token = await getFCMToken();
    developer.log('FCMService: Registered FCM Token: $token');
  }

  /// Retrieve the FCM Registration Token
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      developer.log('FCMService Error fetching FCM token: $e');
      return null;
    }
  }
}
