// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskInfo {

 String get compClass; String get title; int get dayNo; int get taskNo; String get timestamp; String get taskUrl;
/// Create a copy of TaskInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskInfoCopyWith<TaskInfo> get copyWith => _$TaskInfoCopyWithImpl<TaskInfo>(this as TaskInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskInfo&&(identical(other.compClass, compClass) || other.compClass == compClass)&&(identical(other.title, title) || other.title == title)&&(identical(other.dayNo, dayNo) || other.dayNo == dayNo)&&(identical(other.taskNo, taskNo) || other.taskNo == taskNo)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.taskUrl, taskUrl) || other.taskUrl == taskUrl));
}


@override
int get hashCode => Object.hash(runtimeType,compClass,title,dayNo,taskNo,timestamp,taskUrl);

@override
String toString() {
  return 'TaskInfo(compClass: $compClass, title: $title, dayNo: $dayNo, taskNo: $taskNo, timestamp: $timestamp, taskUrl: $taskUrl)';
}


}

/// @nodoc
abstract mixin class $TaskInfoCopyWith<$Res>  {
  factory $TaskInfoCopyWith(TaskInfo value, $Res Function(TaskInfo) _then) = _$TaskInfoCopyWithImpl;
@useResult
$Res call({
 String compClass, String title, int dayNo, int taskNo, String timestamp, String taskUrl
});




}
/// @nodoc
class _$TaskInfoCopyWithImpl<$Res>
    implements $TaskInfoCopyWith<$Res> {
  _$TaskInfoCopyWithImpl(this._self, this._then);

  final TaskInfo _self;
  final $Res Function(TaskInfo) _then;

/// Create a copy of TaskInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? compClass = null,Object? title = null,Object? dayNo = null,Object? taskNo = null,Object? timestamp = null,Object? taskUrl = null,}) {
  return _then(_self.copyWith(
compClass: null == compClass ? _self.compClass : compClass // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,dayNo: null == dayNo ? _self.dayNo : dayNo // ignore: cast_nullable_to_non_nullable
as int,taskNo: null == taskNo ? _self.taskNo : taskNo // ignore: cast_nullable_to_non_nullable
as int,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String,taskUrl: null == taskUrl ? _self.taskUrl : taskUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskInfo].
extension TaskInfoPatterns on TaskInfo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskInfo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskInfo value)  $default,){
final _that = this;
switch (_that) {
case _TaskInfo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskInfo value)?  $default,){
final _that = this;
switch (_that) {
case _TaskInfo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String compClass,  String title,  int dayNo,  int taskNo,  String timestamp,  String taskUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskInfo() when $default != null:
return $default(_that.compClass,_that.title,_that.dayNo,_that.taskNo,_that.timestamp,_that.taskUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String compClass,  String title,  int dayNo,  int taskNo,  String timestamp,  String taskUrl)  $default,) {final _that = this;
switch (_that) {
case _TaskInfo():
return $default(_that.compClass,_that.title,_that.dayNo,_that.taskNo,_that.timestamp,_that.taskUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String compClass,  String title,  int dayNo,  int taskNo,  String timestamp,  String taskUrl)?  $default,) {final _that = this;
switch (_that) {
case _TaskInfo() when $default != null:
return $default(_that.compClass,_that.title,_that.dayNo,_that.taskNo,_that.timestamp,_that.taskUrl);case _:
  return null;

}
}

}

/// @nodoc


class _TaskInfo implements TaskInfo {
  const _TaskInfo({required this.compClass, required this.title, required this.dayNo, required this.taskNo, required this.timestamp, required this.taskUrl});
  

@override final  String compClass;
@override final  String title;
@override final  int dayNo;
@override final  int taskNo;
@override final  String timestamp;
@override final  String taskUrl;

/// Create a copy of TaskInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskInfoCopyWith<_TaskInfo> get copyWith => __$TaskInfoCopyWithImpl<_TaskInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskInfo&&(identical(other.compClass, compClass) || other.compClass == compClass)&&(identical(other.title, title) || other.title == title)&&(identical(other.dayNo, dayNo) || other.dayNo == dayNo)&&(identical(other.taskNo, taskNo) || other.taskNo == taskNo)&&(identical(other.timestamp, timestamp) || other.timestamp == timestamp)&&(identical(other.taskUrl, taskUrl) || other.taskUrl == taskUrl));
}


@override
int get hashCode => Object.hash(runtimeType,compClass,title,dayNo,taskNo,timestamp,taskUrl);

@override
String toString() {
  return 'TaskInfo(compClass: $compClass, title: $title, dayNo: $dayNo, taskNo: $taskNo, timestamp: $timestamp, taskUrl: $taskUrl)';
}


}

/// @nodoc
abstract mixin class _$TaskInfoCopyWith<$Res> implements $TaskInfoCopyWith<$Res> {
  factory _$TaskInfoCopyWith(_TaskInfo value, $Res Function(_TaskInfo) _then) = __$TaskInfoCopyWithImpl;
@override @useResult
$Res call({
 String compClass, String title, int dayNo, int taskNo, String timestamp, String taskUrl
});




}
/// @nodoc
class __$TaskInfoCopyWithImpl<$Res>
    implements _$TaskInfoCopyWith<$Res> {
  __$TaskInfoCopyWithImpl(this._self, this._then);

  final _TaskInfo _self;
  final $Res Function(_TaskInfo) _then;

/// Create a copy of TaskInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? compClass = null,Object? title = null,Object? dayNo = null,Object? taskNo = null,Object? timestamp = null,Object? taskUrl = null,}) {
  return _then(_TaskInfo(
compClass: null == compClass ? _self.compClass : compClass // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,dayNo: null == dayNo ? _self.dayNo : dayNo // ignore: cast_nullable_to_non_nullable
as int,taskNo: null == taskNo ? _self.taskNo : taskNo // ignore: cast_nullable_to_non_nullable
as int,timestamp: null == timestamp ? _self.timestamp : timestamp // ignore: cast_nullable_to_non_nullable
as String,taskUrl: null == taskUrl ? _self.taskUrl : taskUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
