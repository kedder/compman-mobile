// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'downloadable_file_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DownloadableFileInfo {

/// Original filename on SoaringSpot (e.g. `"germany_2026.txt"`).
 String get filename;/// Absolute download URL.
 String get downloadUrl;/// File kind — airspace (.txt) or waypoints (.cup).
 DownloadableFileKind get kind;/// File size in bytes, if advertised in the HTML. Null when not present.
 int? get fileSize;/// Raw modification timestamp string scraped from SoaringSpot (e.g.
/// `"19/04/2026, 12:53"`). Treated as an opaque version token — never
/// parsed into a [DateTime]. Null when the HTML carries no timestamp.
///
/// **Why String, not DateTime?** Parsing the timestamp into a DateTime
/// would require knowing the server's timezone, which SoaringSpot does
/// not advertise in the HTML. Comparing parsed datetimes across timezones
/// risks false positives or missed badges. Storing the raw string and
/// comparing for equality avoids that entirely: the badge fires when the
/// scraped string differs from the string stored at last install,
/// regardless of what the string represents as a point in time.
 String? get publishedVersion;
/// Create a copy of DownloadableFileInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DownloadableFileInfoCopyWith<DownloadableFileInfo> get copyWith => _$DownloadableFileInfoCopyWithImpl<DownloadableFileInfo>(this as DownloadableFileInfo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DownloadableFileInfo&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.publishedVersion, publishedVersion) || other.publishedVersion == publishedVersion));
}


@override
int get hashCode => Object.hash(runtimeType,filename,downloadUrl,kind,fileSize,publishedVersion);

@override
String toString() {
  return 'DownloadableFileInfo(filename: $filename, downloadUrl: $downloadUrl, kind: $kind, fileSize: $fileSize, publishedVersion: $publishedVersion)';
}


}

/// @nodoc
abstract mixin class $DownloadableFileInfoCopyWith<$Res>  {
  factory $DownloadableFileInfoCopyWith(DownloadableFileInfo value, $Res Function(DownloadableFileInfo) _then) = _$DownloadableFileInfoCopyWithImpl;
@useResult
$Res call({
 String filename, String downloadUrl, DownloadableFileKind kind, int? fileSize, String? publishedVersion
});




}
/// @nodoc
class _$DownloadableFileInfoCopyWithImpl<$Res>
    implements $DownloadableFileInfoCopyWith<$Res> {
  _$DownloadableFileInfoCopyWithImpl(this._self, this._then);

  final DownloadableFileInfo _self;
  final $Res Function(DownloadableFileInfo) _then;

/// Create a copy of DownloadableFileInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? filename = null,Object? downloadUrl = null,Object? kind = null,Object? fileSize = freezed,Object? publishedVersion = freezed,}) {
  return _then(_self.copyWith(
filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,downloadUrl: null == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DownloadableFileKind,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,publishedVersion: freezed == publishedVersion ? _self.publishedVersion : publishedVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [DownloadableFileInfo].
extension DownloadableFileInfoPatterns on DownloadableFileInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DownloadableFileInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DownloadableFileInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DownloadableFileInfo value)  $default,){
final _that = this;
switch (_that) {
case _DownloadableFileInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DownloadableFileInfo value)?  $default,){
final _that = this;
switch (_that) {
case _DownloadableFileInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String filename,  String downloadUrl,  DownloadableFileKind kind,  int? fileSize,  String? publishedVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DownloadableFileInfo() when $default != null:
return $default(_that.filename,_that.downloadUrl,_that.kind,_that.fileSize,_that.publishedVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String filename,  String downloadUrl,  DownloadableFileKind kind,  int? fileSize,  String? publishedVersion)  $default,) {final _that = this;
switch (_that) {
case _DownloadableFileInfo():
return $default(_that.filename,_that.downloadUrl,_that.kind,_that.fileSize,_that.publishedVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String filename,  String downloadUrl,  DownloadableFileKind kind,  int? fileSize,  String? publishedVersion)?  $default,) {final _that = this;
switch (_that) {
case _DownloadableFileInfo() when $default != null:
return $default(_that.filename,_that.downloadUrl,_that.kind,_that.fileSize,_that.publishedVersion);case _:
  return null;

}
}

}

/// @nodoc


class _DownloadableFileInfo implements DownloadableFileInfo {
  const _DownloadableFileInfo({required this.filename, required this.downloadUrl, required this.kind, this.fileSize, this.publishedVersion});
  

/// Original filename on SoaringSpot (e.g. `"germany_2026.txt"`).
@override final  String filename;
/// Absolute download URL.
@override final  String downloadUrl;
/// File kind — airspace (.txt) or waypoints (.cup).
@override final  DownloadableFileKind kind;
/// File size in bytes, if advertised in the HTML. Null when not present.
@override final  int? fileSize;
/// Raw modification timestamp string scraped from SoaringSpot (e.g.
/// `"19/04/2026, 12:53"`). Treated as an opaque version token — never
/// parsed into a [DateTime]. Null when the HTML carries no timestamp.
///
/// **Why String, not DateTime?** Parsing the timestamp into a DateTime
/// would require knowing the server's timezone, which SoaringSpot does
/// not advertise in the HTML. Comparing parsed datetimes across timezones
/// risks false positives or missed badges. Storing the raw string and
/// comparing for equality avoids that entirely: the badge fires when the
/// scraped string differs from the string stored at last install,
/// regardless of what the string represents as a point in time.
@override final  String? publishedVersion;

/// Create a copy of DownloadableFileInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DownloadableFileInfoCopyWith<_DownloadableFileInfo> get copyWith => __$DownloadableFileInfoCopyWithImpl<_DownloadableFileInfo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DownloadableFileInfo&&(identical(other.filename, filename) || other.filename == filename)&&(identical(other.downloadUrl, downloadUrl) || other.downloadUrl == downloadUrl)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.fileSize, fileSize) || other.fileSize == fileSize)&&(identical(other.publishedVersion, publishedVersion) || other.publishedVersion == publishedVersion));
}


@override
int get hashCode => Object.hash(runtimeType,filename,downloadUrl,kind,fileSize,publishedVersion);

@override
String toString() {
  return 'DownloadableFileInfo(filename: $filename, downloadUrl: $downloadUrl, kind: $kind, fileSize: $fileSize, publishedVersion: $publishedVersion)';
}


}

/// @nodoc
abstract mixin class _$DownloadableFileInfoCopyWith<$Res> implements $DownloadableFileInfoCopyWith<$Res> {
  factory _$DownloadableFileInfoCopyWith(_DownloadableFileInfo value, $Res Function(_DownloadableFileInfo) _then) = __$DownloadableFileInfoCopyWithImpl;
@override @useResult
$Res call({
 String filename, String downloadUrl, DownloadableFileKind kind, int? fileSize, String? publishedVersion
});




}
/// @nodoc
class __$DownloadableFileInfoCopyWithImpl<$Res>
    implements _$DownloadableFileInfoCopyWith<$Res> {
  __$DownloadableFileInfoCopyWithImpl(this._self, this._then);

  final _DownloadableFileInfo _self;
  final $Res Function(_DownloadableFileInfo) _then;

/// Create a copy of DownloadableFileInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? filename = null,Object? downloadUrl = null,Object? kind = null,Object? fileSize = freezed,Object? publishedVersion = freezed,}) {
  return _then(_DownloadableFileInfo(
filename: null == filename ? _self.filename : filename // ignore: cast_nullable_to_non_nullable
as String,downloadUrl: null == downloadUrl ? _self.downloadUrl : downloadUrl // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as DownloadableFileKind,fileSize: freezed == fileSize ? _self.fileSize : fileSize // ignore: cast_nullable_to_non_nullable
as int?,publishedVersion: freezed == publishedVersion ? _self.publishedVersion : publishedVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
