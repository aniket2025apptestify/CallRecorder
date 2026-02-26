class Recording {
  final int? id;
  final String filePath;
  final String fileName;
  final String phoneNumber;
  final String callType;
  final DateTime timestamp;
  final int durationSeconds;
  final int fileSizeBytes;
  final String audioSource;

  Recording({
    this.id,
    required this.filePath,
    required this.fileName,
    required this.phoneNumber,
    required this.callType,
    required this.timestamp,
    required this.durationSeconds,
    required this.fileSizeBytes,
    required this.audioSource,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'file_path': filePath,
      'file_name': fileName,
      'phone_number': phoneNumber,
      'call_type': callType,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'duration_seconds': durationSeconds,
      'file_size_bytes': fileSizeBytes,
      'audio_source': audioSource,
    };
  }

  factory Recording.fromMap(Map<String, dynamic> map) {
    return Recording(
      id: map['id'] as int?,
      filePath: map['file_path'] as String? ?? '',
      fileName: map['file_name'] as String? ?? '',
      phoneNumber: map['phone_number'] as String? ?? 'Unknown',
      callType: map['call_type'] as String? ?? 'unknown',
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      durationSeconds: map['duration_seconds'] as int? ?? 0,
      fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
      audioSource: map['audio_source'] as String? ?? 'UNKNOWN',
    );
  }

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes} B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isIncoming => callType == 'incoming';
}
