import 'package:flutter/material.dart';
import '../models/recording.dart';
import '../services/recording_service.dart';

class RecordingProvider extends ChangeNotifier {
  final RecordingService _recordingService = RecordingService();

  List<Recording> _recordings = [];
  List<Recording> _filteredRecordings = [];
  bool _isLoading = false;
  bool _autoRecordEnabled = true;
  bool _isRecording = false;
  String _searchQuery = '';
  String _recordingPath = '';

  List<Recording> get recordings =>
      _searchQuery.isEmpty ? _recordings : _filteredRecordings;
  bool get isLoading => _isLoading;
  bool get autoRecordEnabled => _autoRecordEnabled;
  bool get isRecording => _isRecording;
  String get recordingPath => _recordingPath;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _autoRecordEnabled = await _recordingService.isAutoRecordEnabled();
    _isRecording = await _recordingService.isRecording();
    _recordingPath = await _recordingService.getRecordingPath();

    await loadRecordings();

    // Listen for new recordings
    _recordingService.listenForRecordingEvents((recording) {
      _recordings.insert(0, recording);
      _isRecording = false;
      notifyListeners();
    });
  }

  Future<void> loadRecordings() async {
    _isLoading = true;
    notifyListeners();

    try {
      _recordings = await _recordingService.getRecordings();
    } catch (e) {
      debugPrint('Error loading recordings: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteRecording(Recording recording) async {
    final success = await _recordingService.deleteRecording(recording);
    if (success) {
      _recordings.removeWhere((r) => r.filePath == recording.filePath);
      _filteredRecordings.removeWhere((r) => r.filePath == recording.filePath);
      notifyListeners();
    }
  }

  Future<void> toggleAutoRecord() async {
    final newValue = !_autoRecordEnabled;
    debugPrint('Provider: Toggling auto-record to: $newValue');
    final success = await _recordingService.toggleAutoRecord(newValue);
    if (success) {
      _autoRecordEnabled = newValue;
      debugPrint('Provider: Successfully updated auto-record to: $_autoRecordEnabled');
      notifyListeners();
    } else {
      debugPrint('Provider: Failed to update auto-record');
    }
  }

  void search(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredRecordings = [];
    } else {
      _filteredRecordings = _recordings
          .where((r) =>
              r.phoneNumber.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<void> refreshRecordingStatus() async {
    _isRecording = await _recordingService.isRecording();
    notifyListeners();
  }
}
