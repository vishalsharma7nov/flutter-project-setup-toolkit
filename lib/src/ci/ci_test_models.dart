enum CiTestJobStatus {
  idle,
  running,
  passed,
  failed,
  skipped,
}

class CiTestStepResult {
  CiTestStepResult({
    required this.id,
    required this.ok,
    this.durationMs,
    this.skipped = false,
    this.message,
  });

  final String id;
  final bool ok;
  final int? durationMs;
  final bool skipped;
  final String? message;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ok': ok,
        if (durationMs != null) 'duration_ms': durationMs,
        'skipped': skipped,
        if (message != null) 'message': message,
      };
}

class CiTestJobState {
  CiTestJobState({
    this.status = CiTestJobStatus.idle,
    this.runner = 'native',
    this.startedAt,
    this.finishedAt,
    this.error,
    List<String>? logs,
    List<CiTestStepResult>? steps,
  })  : logs = logs ?? [],
        steps = steps ?? [];

  CiTestJobStatus status;
  String runner;
  DateTime? startedAt;
  DateTime? finishedAt;
  String? error;
  final List<String> logs;
  final List<CiTestStepResult> steps;

  bool get passed => status == CiTestJobStatus.passed;

  Map<String, dynamic> toJson({int logOffset = 0}) {
    final slice =
        logOffset < logs.length ? logs.sublist(logOffset) : <String>[];
    return {
      'status': status.name,
      'runner': runner,
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'error': error,
      'logs': slice,
      'log_total': logs.length,
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }
}
