import 'package:freezed_annotation/freezed_annotation.dart';

part 'agent.freezed.dart';
part 'agent.g.dart';

@freezed
class Agent with _$Agent {
  const factory Agent({
    required String id,
    required String name,
    required String description,
    required List<String> capabilities,
    @Default({}) Map<String, dynamic> configuration,
    @Default(AgentStatus.idle) AgentStatus status,
  }) = _Agent;

  factory Agent.fromJson(Map<String, dynamic> json) => _$AgentFromJson(json);
}

enum AgentStatus {
  idle,
  active,
  paused,
  error
}
