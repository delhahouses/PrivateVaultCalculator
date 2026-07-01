import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class VaultPermissionHelper {
  /// Requests storage permissions dynamically based on the Android system.
  /// On Android 13+ (API 33+), requests scoped photo/video media access.
  /// On Android 12 and below, requests standard storage access.
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) return true;

    // Check if we are on Android 13+ (API 33+) by checking photos status
    // On Android 13+, Permission.storage is immediately granted/ignored by the system,
    // and we must request scoped media access (photos and videos) instead.
    final List<Permission> permissions = [
      Permission.storage,
      Permission.photos,
      Permission.videos,
    ];

    final Map<Permission, PermissionStatus> statuses = await permissions.request();

    final isStorageGranted = statuses[Permission.storage]?.isGranted == true;
    final isPhotosGranted = statuses[Permission.photos]?.isGranted == true;
    final isVideosGranted = statuses[Permission.videos]?.isGranted == true;

    if (!isStorageGranted && !isPhotosGranted && !isVideosGranted) {
      if (context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          title: 'Storage Permission Required',
          description: 'Storage permission is required to import, encrypt, and secure files from your gallery into the private vault, or decrypt and export them back.',
        );
      }
      return false;
    }
    return true;
  }

  /// Requests camera and optional microphone permissions for private capture.
  static Future<bool> requestCameraPermission(BuildContext context, {required bool needMicrophone}) async {
    if (!Platform.isAndroid) return true;

    final permissions = [Permission.camera];
    if (needMicrophone) {
      permissions.add(Permission.microphone);
    }

    final statuses = await permissions.request();
    final cameraGranted = statuses[Permission.camera]?.isGranted == true;
    final micGranted = !needMicrophone || statuses[Permission.microphone]?.isGranted == true;

    if (!cameraGranted || !micGranted) {
      if (context.mounted) {
        await _showPermissionDeniedDialog(
          context,
          title: needMicrophone ? 'Camera & Microphone Access Required' : 'Camera Access Required',
          description: needMicrophone
              ? 'This app needs access to your camera and microphone to capture and encrypt private videos directly into your secure vault.'
              : 'This app needs access to your camera to capture and encrypt private photos directly into your secure vault.',
        );
      }
      return false;
    }
    return true;
  }

  /// Helper to present dialog with direct retry setting links.
  static Future<void> _showPermissionDeniedDialog(
    BuildContext context, {
    required String title,
    required String description,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.redAccent, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  style: const TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold, fontSize: 18)
                ),
              ),
            ],
          ),
          content: Text(
            description,
            style: const TextStyle(fontFamily: 'Outfit', fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Outfit')),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('Open Settings', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
