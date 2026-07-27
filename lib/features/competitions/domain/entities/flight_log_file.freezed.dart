// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flight_log_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FlightLogFile {

/// Raw on-disk name, e.g. `"2018-02-26-XCS-WUX-01.igc"`.
 String get filename;/// SAF `content://` URI string for this document.
 String get uri;
/// Create a copy of FlightLogFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlightLogFileCopyWith<FlightLogFile> get copyWith => _$FlightLogFileCopyWithImpl<FlightLogFile>(this as FlightLogFile, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlightLogFile&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.uri, uri) || other.uri == uri));
}


@override
int get hashCode => Object.hash(runtimeType,filename,uri);

@override
String toString() {
  return 'FlightLogFile(filename: $filename, uri: $uri)';
}


}

/// @nodoc
abstract mixin class $FlightLogFileCopyWith<$Res>  {
  factory $FlightLogFileCopyWith(FlightLogFile value, $Res Function(FlightLogFile) _then) = _$FlightLogFileCopyWithImpl;
@useResult
$Res call({
 String filename, String uri
});




}
/// @nodoc
class _$FlightLogFileCopyWithImpl<$Res>
    implements $FlightLogFileCopyWith<$Res> {
  _$FlightLogFileCopyWithImpl(this._self, this._then);

  final FlightLogFile _self;
  final $Res Function(FlightLogFile) _then;

/// Create a copy of FlightLogFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filename = null,Object? uri = null,}) {
  return _then(_self.copyWith(
filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [FlightLogFile].
extension FlightLogFilePatterns on FlightLogFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FlightLogFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FlightLogFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FlightLogFile value)  $default,){
final _that = this;
switch (_that) {
case _FlightLogFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FlightLogFile value)?  $default,){
final _that = this;
switch (_that) {
case _FlightLogFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String filename,  String uri)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FlightLogFile() when $default != null:
return $default(_that.filename,_that.uri);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String filename,  String uri)  $default,) {final _that = this;
switch (_that) {
case _FlightLogFile():
return $default(_that.filename,_that.uri);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String filename,  String uri)?  $default,) {final _that = this;
switch (_that) {
case _FlightLogFile() when $default != null:
return $default(_that.filename,_that.uri);case _:
  return null;

}
}

}

/// @nodoc


class _FlightLogFile implements FlightLogFile {
  const _FlightLogFile({required this.filename, required this.uri});
  

/// Raw on-disk name, e.g. `"2018-02-26-XCS-WUX-01.igc"`.
@override final  String filename;
/// SAF `content://` URI string for this document.
@override final  String uri;

/// Create a copy of FlightLogFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlightLogFileCopyWith<_FlightLogFile> get copyWith => __$FlightLogFileCopyWithImpl<_FlightLogFile>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FlightLogFile&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.uri, uri) || other.uri == uri));
}


@override
int get hashCode => Object.hash(runtimeType,filename,uri);

@override
String toString() {
  return 'FlightLogFile(filename: $filename, uri: $uri)';
}


}

/// @nodoc
abstract mixin class _$FlightLogFileCopyWith<$Res> implements $FlightLogFileCopyWith<$Res> {
  factory _$FlightLogFileCopyWith(_FlightLogFile value, $Res Function(_FlightLogFile) _then) = __$FlightLogFileCopyWithImpl;
@override @useResult
$Res call({
 String filename, String uri
});




}
/// @nodoc
class __$FlightLogFileCopyWithImpl<$Res>
    implements _$FlightLogFileCopyWith<$Res> {
  __$FlightLogFileCopyWithImpl(this._self, this._then);

  final _FlightLogFile _self;
  final $Res Function(_FlightLogFile) _then;

/// Create a copy of FlightLogFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? filename = null,Object? uri = null,}) {
  return _then(_FlightLogFile(
filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,uri: null == uri ? _self.uri : uri // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
