import 'package:o_web/utils/logger.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:o_web/services/supabase_service.dart';

class NotificationService {
  static Future<void> initialize() async {
    // Note: You must run 'flutterfire configure' or add your firebase_options.dart for this to work
    // For now, we will handle the logic gracefully
    try {
      await Firebase.initializeApp();

      final messaging = FirebaseMessaging.instance;

      // Request Permission
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get Token
        final token = await messaging.getToken(
            vapidKey:
                "YOUR_PUBLIC_VAPID_KEY" // Add your VAPID key here from Firebase Console
            );

        if (token != null) {
          await SupabaseService.savePushToken(token);
        }
      }

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } catch (e) {
      safeLog("Firebase initialization skipped or failed: $e");
    }
  }

  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    safeLog("Handling background message: ${message.messageId}");
  }
}
