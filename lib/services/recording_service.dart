import 'dart:io';
import 'package:flutter/services.dart';
import '../models/recording.dart';
import '../utils/constants.dart';
import 'database_service.dart';

class RecordingService {
  static final RecordingService _instance = RecordingService._internal();
  factory RecordingService() => _instance;
  RecordingService._internal();

  static const _methodChannel = MethodChannel(kMethodChannel);
  static const _eventChannel = EventChannel(kEventChannel);

  final DatabaseService _dbService = DatabaseService();

  Stream<dynamic> get onRecordingComplete => _eventChannel.receiveBroadcastStream();

  Future<void> listenForRecordingEvents(Function(Recording) onNewRecording) async {
    onRecordingComplete.listen((event) async {
      if (event is Map) {
        final recording = Recording(
          filePath: event['file_path'] as String? ?? '',
          fileName: (event['file_path'] as String? ?? '').split('/').last,
          phoneNumber: event['phone_number'] as String? ?? 'Unknown',
          callType: event['call_type'] as String? ?? 'unknown',
          timestamp: DateTime.fromMillisecondsSinceEpoch(
            (event['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
          ),
          durationSeconds: event['duration'] as int? ?? 0,
          fileSizeBytes: (event['file_size'] as int?) ?? 0,
          audioSource: event['audio_source'] as String? ?? 'UNKNOWN',
        );

        await _dbService.insertRecording(recording);
        onNewRecording(recording);
      }
    });
  }

  Future<List<Recording>> getRecordings() async {
    // First sync with actual files on disk
    await _syncRecordings();
    return await _dbService.getRecordings();
  }

  Future<void> _syncRecordings() async {
    try {
      final List<dynamic> files = await _methodChannel.invokeMethod('getRecordings');
      for (final file in files) {
        if (file is Map) {
          final filePath = file['file_path'] as String? ?? '';
          final existing = await _dbService.getRecordingByPath(filePath);
          if (existing == null && filePath.isNotEmpty) {
            // Parse file name to extract info: call_<number>_<timestamp>.m4a
            final fileName = file['file_name'] as String? ?? '';
            String phoneNumber = 'Unknown';
            if (fileName.startsWith('call_')) {
              final parts = fileName.replaceAll('.m4a', '').split('_');
              if (parts.length >= 2) {
                phoneNumber = parts[1];
              }
            }

            final recording = Recording(
              filePath: filePath,
              fileName: fileName,
              phoneNumber: phoneNumber,
              callType: 'unknown',
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                (file['last_modified'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
              ),
              durationSeconds: 0,
              fileSizeBytes: (file['file_size'] as int?) ?? 0,
              audioSource: 'UNKNOWN',
            );
            await _dbService.insertRecording(recording);
          }
        }
      }
    } catch (e) {
      // Silently handle - files might not exist yet
    }
  }

  Future<bool> deleteRecording(Recording recording) async {
    try {
      // Delete from file system
      final file = File(recording.filePath);
      if (await file.exists()) {
        await file.delete();
      }
      // Also try via native channel
      await _methodChannel.invokeMethod('deleteRecording', {
        'file_path': recording.filePath,
      });
      // Delete from database
      if (recording.id != null) {
        await _dbService.deleteRecording(recording.id!);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleAutoRecord(bool enabled) async {
    try {
      final result = await _methodChannel.invokeMethod('toggleAutoRecord', {
        'enabled': enabled,
      });
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isAutoRecordEnabled() async {
    try {
      final result = await _methodChannel.invokeMethod('isAutoRecordEnabled');
      return result as bool;
    } catch (e) {
      return true; // Default to enabled
    }
  }

  Future<bool> isRecording() async {
    try {
      final result = await _methodChannel.invokeMethod('isRecording');
      return result as bool;
    } catch (e) {
      return false;
    }
  }

  Future<String> getRecordingPath() async {
    try {
      final result = await _methodChannel.invokeMethod('getRecordingPath');
      return result as String;
    } catch (e) {
      return '/storage/emulated/0/callrecording';
    }
  }

  Future<List<Recording>> searchRecordings(String query) async {
    return await _dbService.searchRecordings(query);
  }
}
