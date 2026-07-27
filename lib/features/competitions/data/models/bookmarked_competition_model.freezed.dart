// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmarked_competition_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookmarkedCompetitionModel {

/// SoaringSpot competition slug used as storage key.
@HiveField(0) String get id;/// Human-readable competition title.
@HiveField(1) String get title;/// Full SoaringSpot URL for the competition.
@HiveField(2) String get soaringspotUrl;/// Timestamp when the user bookmarked this competition.
@HiveField(3) DateTime get bookmarkedAt;/// The competition class the user has selected (e.g. "Club", "Open").
@HiveField(4) String? get selectedClass;/// Competition listing description used for bookmark display.
@HiveField(5) String? get description;/// Competition start date parsed from the SoaringSpot listing.
@HiveField(6) DateTime? get startDate;/// Competition end date parsed from the SoaringSpot listing.
@HiveField(7) DateTime? get endDate;/// SoaringSpot version token of the last installed airspace file.
///
/// Stored as the raw timestamp string scraped from SoaringSpot at install
/// time. Null until an airspace file has been installed.
/// Old records without this field deserialise with null.
@HiveField(8) String? get airspaceVersion;/// SoaringSpot version token of the last installed waypoints file.
///
/// Old records without this field deserialise with null.
@HiveField(9) String? get waypointsVersion;/// Version token of the last installed task.
///
/// Old records without this field deserialise with null.
@HiveField(10) String? get taskVersion;
/// Create a copy of BookmarkedCompetitionModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookmarkedCompetitionModelCopyWith<BookmarkedCompetitionModel> get copyWith => _$BookmarkedCompetitionModelCopyWithImpl<BookmarkedCompetitionModel>(this as BookmarkedCompetitionModel, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookmarkedCompetitionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.soaringspotUrl, soaringspotUrl) || other.soaringspotUrl == soaringspotUrl)&&(identical(other.bookmarkedAt, bookmarkedAt) || other.bookmarkedAt == bookmarkedAt)&&(identical(other.selectedClass, selectedClass) || other.selectedClass == selectedClass)&&(identical(other.description, description) || other.description == description)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.airspaceVersion, airspaceVersion) || other.airspaceVersion == airspaceVersion)&&(identical(other.waypointsVersion, waypointsVersion) || other.waypointsVersion == waypointsVersion)&&(identical(other.taskVersion, taskVersion) || other.taskVersion == taskVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,soaringspotUrl,bookmarkedAt,selectedClass,description,startDate,endDate,airspaceVersion,waypointsVersion,taskVersion);

@override
String toString() {
  return 'BookmarkedCompetitionModel(id: $id, title: $title, soaringspotUrl: $soaringspotUrl, bookmarkedAt: $bookmarkedAt, selectedClass: $selectedClass, description: $description, startDate: $startDate, endDate: $endDate, airspaceVersion: $airspaceVersion, waypointsVersion: $waypointsVersion, taskVersion: $taskVersion)';
}


}

/// @nodoc
abstract mixin class $BookmarkedCompetitionModelCopyWith<$Res>  {
  factory $BookmarkedCompetitionModelCopyWith(BookmarkedCompetitionModel value, $Res Function(BookmarkedCompetitionModel) _then) = _$BookmarkedCompetitionModelCopyWithImpl;
@useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String title,@HiveField(2) String soaringspotUrl,@HiveField(3) DateTime bookmarkedAt,@HiveField(4) String? selectedClass,@HiveField(5) String? description,@HiveField(6) DateTime? startDate,@HiveField(7) DateTime? endDate,@HiveField(8) String? airspaceVersion,@HiveField(9) String? waypointsVersion,@HiveField(10) String? taskVersion
});




}
/// @nodoc
class _$BookmarkedCompetitionModelCopyWithImpl<$Res>
    implements $BookmarkedCompetitionModelCopyWith<$Res> {
  _$BookmarkedCompetitionModelCopyWithImpl(this._self, this._then);

  final BookmarkedCompetitionModel _self;
  final $Res Function(BookmarkedCompetitionModel) _then;

/// Create a copy of BookmarkedCompetitionModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? soaringspotUrl = null,Object? bookmarkedAt = null,Object? selectedClass = freezed,Object? description = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? airspaceVersion = freezed,Object? waypointsVersion = freezed,Object? taskVersion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,soaringspotUrl: null == soaringspotUrl ? _self.soaringspotUrl : soaringspotUrl // ignore: cast_nullable_to_non_nullable
as String,bookmarkedAt: null == bookmarkedAt ? _self.bookmarkedAt : bookmarkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,selectedClass: freezed == selectedClass ? _self.selectedClass : selectedClass // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,airspaceVersion: freezed == airspaceVersion ? _self.airspaceVersion : airspaceVersion // ignore: cast_nullable_to_non_nullable
as String?,waypointsVersion: freezed == waypointsVersion ? _self.waypointsVersion : waypointsVersion // ignore: cast_nullable_to_non_nullable
as String?,taskVersion: freezed == taskVersion ? _self.taskVersion : taskVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookmarkedCompetitionModel].
extension BookmarkedCompetitionModelPatterns on BookmarkedCompetitionModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookmarkedCompetitionModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookmarkedCompetitionModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookmarkedCompetitionModel value)  $default,){
final _that = this;
switch (_that) {
case _BookmarkedCompetitionModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookmarkedCompetitionModel value)?  $default,){
final _that = this;
switch (_that) {
case _BookmarkedCompetitionModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String title, @HiveField(2)  String soaringspotUrl, @HiveField(3)  DateTime bookmarkedAt, @HiveField(4)  String? selectedClass, @HiveField(5)  String? description, @HiveField(6)  DateTime? startDate, @HiveField(7)  DateTime? endDate, @HiveField(8)  String? airspaceVersion, @HiveField(9)  String? waypointsVersion, @HiveField(10)  String? taskVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookmarkedCompetitionModel() when $default != null:
return $default(_that.id,_that.title,_that.soaringspotUrl,_that.bookmarkedAt,_that.selectedClass,_that.description,_that.startDate,_that.endDate,_that.airspaceVersion,_that.waypointsVersion,_that.taskVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@HiveField(0)  String id, @HiveField(1)  String title, @HiveField(2)  String soaringspotUrl, @HiveField(3)  DateTime bookmarkedAt, @HiveField(4)  String? selectedClass, @HiveField(5)  String? description, @HiveField(6)  DateTime? startDate, @HiveField(7)  DateTime? endDate, @HiveField(8)  String? airspaceVersion, @HiveField(9)  String? waypointsVersion, @HiveField(10)  String? taskVersion)  $default,) {final _that = this;
switch (_that) {
case _BookmarkedCompetitionModel():
return $default(_that.id,_that.title,_that.soaringspotUrl,_that.bookmarkedAt,_that.selectedClass,_that.description,_that.startDate,_that.endDate,_that.airspaceVersion,_that.waypointsVersion,_that.taskVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@HiveField(0)  String id, @HiveField(1)  String title, @HiveField(2)  String soaringspotUrl, @HiveField(3)  DateTime bookmarkedAt, @HiveField(4)  String? selectedClass, @HiveField(5)  String? description, @HiveField(6)  DateTime? startDate, @HiveField(7)  DateTime? endDate, @HiveField(8)  String? airspaceVersion, @HiveField(9)  String? waypointsVersion, @HiveField(10)  String? taskVersion)?  $default,) {final _that = this;
switch (_that) {
case _BookmarkedCompetitionModel() when $default != null:
return $default(_that.id,_that.title,_that.soaringspotUrl,_that.bookmarkedAt,_that.selectedClass,_that.description,_that.startDate,_that.endDate,_that.airspaceVersion,_that.waypointsVersion,_that.taskVersion);case _:
  return null;

}
}

}

/// @nodoc


class _BookmarkedCompetitionModel extends BookmarkedCompetitionModel {
  const _BookmarkedCompetitionModel({@HiveField(0) required this.id, @HiveField(1) required this.title, @HiveField(2) required this.soaringspotUrl, @HiveField(3) required this.bookmarkedAt, @HiveField(4) this.selectedClass, @HiveField(5) this.description, @HiveField(6) this.startDate, @HiveField(7) this.endDate, @HiveField(8) this.airspaceVersion, @HiveField(9) this.waypointsVersion, @HiveField(10) this.taskVersion}): super._();
  

/// SoaringSpot competition slug used as storage key.
@override@HiveField(0) final  String id;
/// Human-readable competition title.
@override@HiveField(1) final  String title;
/// Full SoaringSpot URL for the competition.
@override@HiveField(2) final  String soaringspotUrl;
/// Timestamp when the user bookmarked this competition.
@override@HiveField(3) final  DateTime bookmarkedAt;
/// The competition class the user has selected (e.g. "Club", "Open").
@override@HiveField(4) final  String? selectedClass;
/// Competition listing description used for bookmark display.
@override@HiveField(5) final  String? description;
/// Competition start date parsed from the SoaringSpot listing.
@override@HiveField(6) final  DateTime? startDate;
/// Competition end date parsed from the SoaringSpot listing.
@override@HiveField(7) final  DateTime? endDate;
/// SoaringSpot version token of the last installed airspace file.
///
/// Stored as the raw timestamp string scraped from SoaringSpot at install
/// time. Null until an airspace file has been installed.
/// Old records without this field deserialise with null.
@override@HiveField(8) final  String? airspaceVersion;
/// SoaringSpot version token of the last installed waypoints file.
///
/// Old records without this field deserialise with null.
@override@HiveField(9) final  String? waypointsVersion;
/// Version token of the last installed task.
///
/// Old records without this field deserialise with null.
@override@HiveField(10) final  String? taskVersion;

/// Create a copy of BookmarkedCompetitionModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookmarkedCompetitionModelCopyWith<_BookmarkedCompetitionModel> get copyWith => __$BookmarkedCompetitionModelCopyWithImpl<_BookmarkedCompetitionModel>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookmarkedCompetitionModel&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.soaringspotUrl, soaringspotUrl) || other.soaringspotUrl == soaringspotUrl)&&(identical(other.bookmarkedAt, bookmarkedAt) || other.bookmarkedAt == bookmarkedAt)&&(identical(other.selectedClass, selectedClass) || other.selectedClass == selectedClass)&&(identical(other.description, description) || other.description == description)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.airspaceVersion, airspaceVersion) || other.airspaceVersion == airspaceVersion)&&(identical(other.waypointsVersion, waypointsVersion) || other.waypointsVersion == waypointsVersion)&&(identical(other.taskVersion, taskVersion) || other.taskVersion == taskVersion));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,soaringspotUrl,bookmarkedAt,selectedClass,description,startDate,endDate,airspaceVersion,waypointsVersion,taskVersion);

@override
String toString() {
  return 'BookmarkedCompetitionModel(id: $id, title: $title, soaringspotUrl: $soaringspotUrl, bookmarkedAt: $bookmarkedAt, selectedClass: $selectedClass, description: $description, startDate: $startDate, endDate: $endDate, airspaceVersion: $airspaceVersion, waypointsVersion: $waypointsVersion, taskVersion: $taskVersion)';
}


}

/// @nodoc
abstract mixin class _$BookmarkedCompetitionModelCopyWith<$Res> implements $BookmarkedCompetitionModelCopyWith<$Res> {
  factory _$BookmarkedCompetitionModelCopyWith(_BookmarkedCompetitionModel value, $Res Function(_BookmarkedCompetitionModel) _then) = __$BookmarkedCompetitionModelCopyWithImpl;
@override @useResult
$Res call({
@HiveField(0) String id,@HiveField(1) String title,@HiveField(2) String soaringspotUrl,@HiveField(3) DateTime bookmarkedAt,@HiveField(4) String? selectedClass,@HiveField(5) String? description,@HiveField(6) DateTime? startDate,@HiveField(7) DateTime? endDate,@HiveField(8) String? airspaceVersion,@HiveField(9) String? waypointsVersion,@HiveField(10) String? taskVersion
});




}
/// @nodoc
class __$BookmarkedCompetitionModelCopyWithImpl<$Res>
    implements _$BookmarkedCompetitionModelCopyWith<$Res> {
  __$BookmarkedCompetitionModelCopyWithImpl(this._self, this._then);

  final _BookmarkedCompetitionModel _self;
  final $Res Function(_BookmarkedCompetitionModel) _then;

/// Create a copy of BookmarkedCompetitionModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? soaringspotUrl = null,Object? bookmarkedAt = null,Object? selectedClass = freezed,Object? description = freezed,Object? startDate = freezed,Object? endDate = freezed,Object? airspaceVersion = freezed,Object? waypointsVersion = freezed,Object? taskVersion = freezed,}) {
  return _then(_BookmarkedCompetitionModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,soaringspotUrl: null == soaringspotUrl ? _self.soaringspotUrl : soaringspotUrl // ignore: cast_nullable_to_non_nullable
as String,bookmarkedAt: null == bookmarkedAt ? _self.bookmarkedAt : bookmarkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,selectedClass: freezed == selectedClass ? _self.selectedClass : selectedClass // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,airspaceVersion: freezed == airspaceVersion ? _self.airspaceVersion : airspaceVersion // ignore: cast_nullable_to_non_nullable
as String?,waypointsVersion: freezed == waypointsVersion ? _self.waypointsVersion : waypointsVersion // ignore: cast_nullable_to_non_nullable
as String?,taskVersion: freezed == taskVersion ? _self.taskVersion : taskVersion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
