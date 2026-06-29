enum SetupApplyStatus {
  idle,
  running,
  succeeded,
  failed,
}

class SetupApplyState {
  SetupApplyState({
    this.status = SetupApplyStatus.idle,
    this.startedAt,
    this.finishedAt,
    this.error,
    this.result,
    List<String>? logs,
  }) : logs = logs ?? [];

  SetupApplyStatus status;
  DateTime? startedAt;
  DateTime? finishedAt;
  String? error;
  Map<String, dynamic>? result;
  final List<String> logs;

  Map<String, dynamic> toJson({int logOffset = 0}) {
    final slice = logOffset < logs.length ? logs.sublist(logOffset) : <String>[];
    return {
      'status': status.name,
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'error': error,
      'result': result,
      'logs': slice,
      'log_total': logs.length,
    };
  }
}
