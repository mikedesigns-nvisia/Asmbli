import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/verification_request.dart';
import '../models/verification_rule.dart';

/// Provider for the HumanVerificationService
final humanVerificationServiceProvider = Provider<HumanVerificationService>((ref) {
  return HumanVerificationService();
});

/// Stream of pending requests count for badges/notifications
final pendingVerificationCountProvider = StreamProvider<int>((ref) {
  final service = ref.watch(humanVerificationServiceProvider);
  return service.requestsStream.map(
    (requests) => requests.where((r) => r.status == VerificationStatus.pending).length
  );
});

/// Provider for verification rules
final verificationRulesProvider = StateNotifierProvider<VerificationRulesNotifier, List<VerificationRule>>((ref) {
  return VerificationRulesNotifier();
});

/// Notifier for managing verification rules
class VerificationRulesNotifier extends StateNotifier<List<VerificationRule>> {
  VerificationRulesNotifier() : super(VerificationRule.defaultRules);

  void addRule(VerificationRule rule) {
    state = [...state, rule];
  }

  void updateRule(VerificationRule rule) {
    state = state.map((r) => r.id == rule.id ? rule : r).toList();
  }

  void removeRule(String id) {
    state = state.where((r) => r.id != id).toList();
  }

  void toggleRule(String id) {
    state = state.map((r) {
      if (r.id == id) {
        return r.copyWith(enabled: !r.enabled);
      }
      return r;
    }).toList();
  }

  void resetToDefaults() {
    state = VerificationRule.defaultRules;
  }

  /// Check if an action requires verification based on rules
  VerificationRule? findMatchingRule({
    required String actionDescription,
    required String source,
    RiskLevel? actionRiskLevel,
  }) {
    final enabledRules = state.where((r) => r.enabled).toList();

    for (final rule in enabledRules) {
      // Check if source is exempt
      if (rule.exemptSources.contains(source)) continue;

      // Check risk level threshold
      if (actionRiskLevel != null && actionRiskLevel.index < rule.minimumRiskLevel.index) {
        continue;
      }

      // Check pattern matches
      for (final pattern in rule.patterns) {
        if (RegExp(pattern, caseSensitive: false).hasMatch(actionDescription)) {
          return rule;
        }
      }
    }

    return null;
  }
}

class HumanVerificationService {
  final _requestsController = StreamController<List<VerificationRequest>>.broadcast();
  final List<VerificationRequest> _requests = [];
  final _uuid = const Uuid();

  Stream<List<VerificationRequest>> get requestsStream => _requestsController.stream;

  /// Request human verification
  /// Returns a Future that completes when the user approves or rejects the request
  Future<VerificationResult> requestVerification({
    required String source,
    required String title,
    required String description,
    Map<String, dynamic> data = const {},
    Duration? timeout,
    VerificationCategory? category,
    RiskLevel? riskLevel,
  }) {
    final completer = Completer<VerificationResult>();

    final request = VerificationRequest(
      id: _uuid.v4(),
      source: source,
      title: title,
      description: description,
      data: {
        ...data,
        if (category != null) '_category': category.name,
        if (riskLevel != null) '_riskLevel': riskLevel.name,
      },
      createdAt: DateTime.now(),
      completer: completer,
    );

    _requests.insert(0, request); // Add to top
    _notifyListeners();

    // Handle timeout if specified
    if (timeout != null) {
      Timer(timeout, () {
        if (!completer.isCompleted) {
          _resolveRequest(request.id, VerificationStatus.timedOut, 'Request timed out');
          completer.complete(VerificationResult(
            approved: false,
            feedback: 'Verification timed out',
          ));
        }
      });
    }

    return completer.future;
  }

  /// Check if an action should trigger verification based on rules
  /// Returns the matching rule if verification is required, null otherwise
  VerificationRule? shouldRequestVerification({
    required List<VerificationRule> rules,
    required String actionDescription,
    required String source,
    RiskLevel? riskLevel,
  }) {
    final enabledRules = rules.where((r) => r.enabled).toList();

    for (final rule in enabledRules) {
      // Check if source is exempt
      if (rule.exemptSources.contains(source)) continue;

      // Check risk level threshold
      if (riskLevel != null && riskLevel.index < rule.minimumRiskLevel.index) {
        continue;
      }

      // Check pattern matches
      for (final pattern in rule.patterns) {
        try {
          if (RegExp(pattern, caseSensitive: false).hasMatch(actionDescription)) {
            return rule;
          }
        } catch (_) {
          // Invalid regex pattern, skip
        }
      }
    }

    return null;
  }

  /// Approve a request
  void approveRequest(String id, {String? feedback}) {
    final request = _getRequest(id);
    if (request != null && request.status == VerificationStatus.pending) {
      _resolveRequest(id, VerificationStatus.approved, feedback);
      request.complete(VerificationResult(
        approved: true,
        feedback: feedback,
      ));
    }
  }

  /// Reject a request
  void rejectRequest(String id, {String? feedback}) {
    final request = _getRequest(id);
    if (request != null && request.status == VerificationStatus.pending) {
      _resolveRequest(id, VerificationStatus.rejected, feedback);
      request.complete(VerificationResult(
        approved: false,
        feedback: feedback,
      ));
    }
  }

  VerificationRequest? _getRequest(String id) {
    try {
      return _requests.firstWhere((r) => r.id == id);
    } catch (e) {
      return null;
    }
  }

  void _resolveRequest(String id, VerificationStatus status, String? note) {
    final index = _requests.indexWhere((r) => r.id == id);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(
        status: status,
        resolvedAt: DateTime.now(),
        resolutionNote: note,
      );
      _notifyListeners();
    }
  }

  void _notifyListeners() {
    _requestsController.add(List.unmodifiable(_requests));
  }

  List<VerificationRequest> getPendingRequests() {
    return _requests.where((r) => r.status == VerificationStatus.pending).toList();
  }

  List<VerificationRequest> getHistory() {
    return _requests.where((r) => r.status != VerificationStatus.pending).toList();
  }

  void dispose() {
    _requestsController.close();
  }
}
