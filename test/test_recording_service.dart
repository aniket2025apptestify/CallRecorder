import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:call_recorder/services/recording_service.dart';
import 'package:call_recorder/models/recording.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecordingService Tests', () {
    const MethodChannel channel = MethodChannel('com.example.call_recorder/recording');
    late RecordingService service;

    setUpAll(() {
      // Initialize sqflite for FFI (desktop/test environment)
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() {
      service = RecordingService();
      
      // Mock MethodChannel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'getRecordings') {
          return [
            {
              'file_path': '/storage/emulated/0/callrecording/test1.m4a',
              'file_name': 'call_1234567890_20260226_120000.m4a',
              'file_size': 1024,
              'last_modified': DateTime.now().millisecondsSinceEpoch,
            }
          ];
        }
        if (methodCall.method == 'getRecordingPath') {
          return '/storage/emulated/0/callrecording';
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getRecordings should sync with native and return recordings', () async {
      final recordings = await service.getRecordings();
      
      expect(recordings, isNotEmpty);
      expect(recordings.first.phoneNumber, '1234567890');
      expect(recordings.first.fileSizeBytes, 1024);
    });

    test('isAutoRecordEnabled should return true by default', () async {
      final enabled = await service.isAutoRecordEnabled();
      expect(enabled, isTrue);
    });
  });
}
