import 'dart:async';

enum VerificationStatus {
  pending,
  approved,
  rejected,
  timedOut,
}

class VerificationRequest {
  final String id;
  final String source;
  final String title;
  final String description;
  final Map<String, dynamic> data;
  final VerificationStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? resolutionNote;
  
  // Internal completer to handle the async response
  final Completer<VerificationResult>? _completer;

  const VerificationRequest({
    required this.id,
    required this.source,
    required this.title,
    required this.description,
    this.data = const {},
    this.status = VerificationStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.resolutionNote,
    Completer<VerificationResult>? completer,
  }) : _completer = completer;

  VerificationRequest copyWith({
    String? id,
    String? source,
    String? title,
    String? description,
    Map<String, dynamic>? data,
    VerificationStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? resolutionNote,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      source: source ?? this.source,
      title: title ?? this.title,
      description: description ?? this.description,
      data: data ?? this.data,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      completer: _completer, // Keep the same completer
    );
  }
  
  void complete(VerificationResult result) {
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }
}

class VerificationResult {
  final bool approved;
  final String? feedback;
  final DateTime timestamp;

  VerificationResult({
    required this.approved,
    this.feedback,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
