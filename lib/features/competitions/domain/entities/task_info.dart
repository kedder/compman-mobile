import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_info.freezed.dart';

/// Represents a downloadable XCSoar task file from SoarScore.
///
/// [compClass] is the competition class name (e.g. `"Club"`).
/// [title] is the human-readable task description (e.g. `"AAT 159/361km"`).
/// [dayNo] is the competition day number.
/// [taskNo] is the task number within that day.
/// [timestamp] is the generation timestamp string (e.g. `"01-07-2020 21:35:04"`).
/// [taskUrl] is the absolute URL to download the `.tsk` file.
@freezed
class TaskInfo with _$TaskInfo {
  /// Creates an immutable [TaskInfo].
  const factory TaskInfo({
    required String compClass,
    required String title,
    required int dayNo,
    required int taskNo,
    required String timestamp,
    required String taskUrl,
  }) = _TaskInfo;
}
