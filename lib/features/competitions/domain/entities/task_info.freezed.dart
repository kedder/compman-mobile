// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$TaskInfo {
  String get compClass => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int get dayNo => throw _privateConstructorUsedError;
  int get taskNo => throw _privateConstructorUsedError;
  String get timestamp => throw _privateConstructorUsedError;
  String get taskUrl => throw _privateConstructorUsedError;

  /// Create a copy of TaskInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskInfoCopyWith<TaskInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskInfoCopyWith<$Res> {
  factory $TaskInfoCopyWith(TaskInfo value, $Res Function(TaskInfo) then) =
      _$TaskInfoCopyWithImpl<$Res, TaskInfo>;
  @useResult
  $Res call(
      {String compClass,
      String title,
      int dayNo,
      int taskNo,
      String timestamp,
      String taskUrl});
}

/// @nodoc
class _$TaskInfoCopyWithImpl<$Res, $Val extends TaskInfo>
    implements $TaskInfoCopyWith<$Res> {
  _$TaskInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? compClass = null,
    Object? title = null,
    Object? dayNo = null,
    Object? taskNo = null,
    Object? timestamp = null,
    Object? taskUrl = null,
  }) {
    return _then(_value.copyWith(
      compClass: null == compClass
          ? _value.compClass
          : compClass // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dayNo: null == dayNo
          ? _value.dayNo
          : dayNo // ignore: cast_nullable_to_non_nullable
              as int,
      taskNo: null == taskNo
          ? _value.taskNo
          : taskNo // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
      taskUrl: null == taskUrl
          ? _value.taskUrl
          : taskUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TaskInfoImplCopyWith<$Res>
    implements $TaskInfoCopyWith<$Res> {
  factory _$$TaskInfoImplCopyWith(
          _$TaskInfoImpl value, $Res Function(_$TaskInfoImpl) then) =
      __$$TaskInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String compClass,
      String title,
      int dayNo,
      int taskNo,
      String timestamp,
      String taskUrl});
}

/// @nodoc
class __$$TaskInfoImplCopyWithImpl<$Res>
    extends _$TaskInfoCopyWithImpl<$Res, _$TaskInfoImpl>
    implements _$$TaskInfoImplCopyWith<$Res> {
  __$$TaskInfoImplCopyWithImpl(
      _$TaskInfoImpl _value, $Res Function(_$TaskInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of TaskInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? compClass = null,
    Object? title = null,
    Object? dayNo = null,
    Object? taskNo = null,
    Object? timestamp = null,
    Object? taskUrl = null,
  }) {
    return _then(_$TaskInfoImpl(
      compClass: null == compClass
          ? _value.compClass
          : compClass // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dayNo: null == dayNo
          ? _value.dayNo
          : dayNo // ignore: cast_nullable_to_non_nullable
              as int,
      taskNo: null == taskNo
          ? _value.taskNo
          : taskNo // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as String,
      taskUrl: null == taskUrl
          ? _value.taskUrl
          : taskUrl // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$TaskInfoImpl implements _TaskInfo {
  const _$TaskInfoImpl(
      {required this.compClass,
      required this.title,
      required this.dayNo,
      required this.taskNo,
      required this.timestamp,
      required this.taskUrl});

  @override
  final String compClass;
  @override
  final String title;
  @override
  final int dayNo;
  @override
  final int taskNo;
  @override
  final String timestamp;
  @override
  final String taskUrl;

  @override
  String toString() {
    return 'TaskInfo(compClass: $compClass, title: $title, dayNo: $dayNo, taskNo: $taskNo, timestamp: $timestamp, taskUrl: $taskUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskInfoImpl &&
            (identical(other.compClass, compClass) ||
                other.compClass == compClass) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.dayNo, dayNo) || other.dayNo == dayNo) &&
            (identical(other.taskNo, taskNo) || other.taskNo == taskNo) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.taskUrl, taskUrl) || other.taskUrl == taskUrl));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, compClass, title, dayNo, taskNo, timestamp, taskUrl);

  /// Create a copy of TaskInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskInfoImplCopyWith<_$TaskInfoImpl> get copyWith =>
      __$$TaskInfoImplCopyWithImpl<_$TaskInfoImpl>(this, _$identity);
}

abstract class _TaskInfo implements TaskInfo {
  const factory _TaskInfo(
      {required final String compClass,
      required final String title,
      required final int dayNo,
      required final int taskNo,
      required final String timestamp,
      required final String taskUrl}) = _$TaskInfoImpl;

  @override
  String get compClass;
  @override
  String get title;
  @override
  int get dayNo;
  @override
  int get taskNo;
  @override
  String get timestamp;
  @override
  String get taskUrl;

  /// Create a copy of TaskInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskInfoImplCopyWith<_$TaskInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
