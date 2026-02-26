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
      permissions.add(Permission.storage);
      permissions.add(Permission.manageExternalStorage);
    }

    final statuses = await permissions.request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted && !status.isLimited) {
        allGranted = false;
      }
    });

    // Also request call log permission separately
    final callLogStatus = await Permission.phone.request();
    if (!callLogStatus.isGranted) {
      allGranted = false;
    }

    return allGranted;
  }

  static Future<bool> areAllPermissionsGranted() async {
    final phone = await Permission.phone.isGranted;
    final microphone = await Permission.microphone.isGranted;
    final notification = await Permission.notification.isGranted;

    return phone && microphone && notification;
  }

  static Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
