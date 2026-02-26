import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestAllPermissions() async {
    final permissions = <Permission>[
      Permission.phone,
      Permission.microphone,
      Permission.notification,
    ];

    // Add storage permissions based on Android version
    if (Platform.isAndroid) {
      // For Android 13+ (API 33), we need READ_MEDIA_AUDIO
      // Permission.audio is mapped to READ_MEDIA_AUDIO
      permissions.add(Permission.storage);
      // We don't explicitly add Permission.audio here to avoid index mismatch on older devices, 
      // but we'll check it in areAllPermissionsGranted
    }

    final statuses = await permissions.request();

    // Check if we need to request MANAGE_EXTERNAL_STORAGE separately for Android 11+
    if (Platform.isAndroid) {
      final status = await Permission.manageExternalStorage.status;
      if (status.isDenied) {
        // Only request if standard storage isn't sufficient or if we want root access
        await Permission.manageExternalStorage.request();
      }
    }

    return await areAllPermissionsGranted();
  }

  static Future<bool> areAllPermissionsGranted() async {
    final phone = await Permission.phone.isGranted;
    final microphone = await Permission.microphone.isGranted;
    final notification = await Permission.notification.isGranted;
    
    // On Android 13+, Permission.storage might be denied but Permission.audio could be granted
    // However, since we use fallback paths, we primarily need the core ones.
    bool storageGranted = await Permission.storage.isGranted;
    
    if (Platform.isAndroid) {
      // Check for manageExternalStorage (Android 11+)
      final manageStorage = await Permission.manageExternalStorage.isGranted;
      
      // Check for Audio permission (Android 13+)
      // Note: Permission.audio is only available in newer permission_handler versions
      // For now, we rely on the fact that if manageStorage or storage is granted, we are good.
      storageGranted = storageGranted || manageStorage;
      
      // If we are on Android 13+, and storage is not granted, we might need to check specific media permissions
      // but for call recording, standard storage or managed storage is usually what's needed for the root folder.
    }

    return phone && microphone && notification && storageGranted;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
