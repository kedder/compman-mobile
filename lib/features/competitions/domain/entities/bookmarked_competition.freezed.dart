// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmarked_competition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BookmarkedCompetition {

 String get id; String get title; String get soaringspotUrl; DateTime get bookmarkedAt; String? get selectedClass; String? get description; DateTime? get startDate; DateTime? get endDate;
/// Create a copy of BookmarkedCompetition
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BookmarkedCompetitionCopyWith<BookmarkedCompetition> get copyWith => _$BookmarkedCompetitionCopyWithImpl<BookmarkedCompetition>(this as BookmarkedCompetition, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BookmarkedCompetition&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.soaringspotUrl, soaringspotUrl) || other.soaringspotUrl == soaringspotUrl)&&(identical(other.bookmarkedAt, bookmarkedAt) || other.bookmarkedAt == bookmarkedAt)&&(identical(other.selectedClass, selectedClass) || other.selectedClass == selectedClass)&&(identical(other.description, description) || other.description == description)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,soaringspotUrl,bookmarkedAt,selectedClass,description,startDate,endDate);

@override
String toString() {
  return 'BookmarkedCompetition(id: $id, title: $title, soaringspotUrl: $soaringspotUrl, bookmarkedAt: $bookmarkedAt, selectedClass: $selectedClass, description: $description, startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $BookmarkedCompetitionCopyWith<$Res>  {
  factory $BookmarkedCompetitionCopyWith(BookmarkedCompetition value, $Res Function(BookmarkedCompetition) _then) = _$BookmarkedCompetitionCopyWithImpl;
@useResult
$Res call({
 String id, String title, String soaringspotUrl, DateTime bookmarkedAt, String? selectedClass, String? description, DateTime? startDate, DateTime? endDate
});




}
/// @nodoc
class _$BookmarkedCompetitionCopyWithImpl<$Res>
    implements $BookmarkedCompetitionCopyWith<$Res> {
  _$BookmarkedCompetitionCopyWithImpl(this._self, this._then);

  final BookmarkedCompetition _self;
  final $Res Function(BookmarkedCompetition) _then;

/// Create a copy of BookmarkedCompetition
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? soaringspotUrl = null,Object? bookmarkedAt = null,Object? selectedClass = freezed,Object? description = freezed,Object? startDate = freezed,Object? endDate = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,soaringspotUrl: null == soaringspotUrl ? _self.soaringspotUrl : soaringspotUrl // ignore: cast_nullable_to_non_nullable
as String,bookmarkedAt: null == bookmarkedAt ? _self.bookmarkedAt : bookmarkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,selectedClass: freezed == selectedClass ? _self.selectedClass : selectedClass // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BookmarkedCompetition].
extension BookmarkedCompetitionPatterns on BookmarkedCompetition {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BookmarkedCompetition value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BookmarkedCompetition() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BookmarkedCompetition value)  $default,){
final _that = this;
switch (_that) {
case _BookmarkedCompetition():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BookmarkedCompetition value)?  $default,){
final _that = this;
switch (_that) {
case _BookmarkedCompetition() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String soaringspotUrl,  DateTime bookmarkedAt,  String? selectedClass,  String? description,  DateTime? startDate,  DateTime? endDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BookmarkedCompetition() when $default != null:
return $default(_that.id,_that.title,_that.soaringspotUrl,_that.bookmarkedAt,_that.selectedClass,_that.description,_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String soaringspotUrl,  DateTime bookmarkedAt,  String? selectedClass,  String? description,  DateTime? startDate,  DateTime? endDate)  $default,) {final _that = this;
switch (_that) {
case _BookmarkedCompetition():
return $default(_that.id,_that.title,_that.soaringspotUrl,_that.bookmarkedAt,_that.selectedClass,_that.description,_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String soaringspotUrl,  DateTime bookmarkedAt,  String? selectedClass,  String? description,  DateTime? startDate,  DateTime? endDate)?  $default,) {final _that = this;
switch (_that) {
case _BookmarkedCompetition() when $default != null:
return $default(_that.id,_that.title,_that.soaringspotUrl,_that.bookmarkedAt,_that.selectedClass,_that.description,_that.startDate,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc


class _BookmarkedCompetition extends BookmarkedCompetition {
  const _BookmarkedCompetition({required this.id, required this.title, required this.soaringspotUrl, required this.bookmarkedAt, this.selectedClass, this.description, this.startDate, this.endDate}): super._();
  

@override final  String id;
@override final  String title;
@override final  String soaringspotUrl;
@override final  DateTime bookmarkedAt;
@override final  String? selectedClass;
@override final  String? description;
@override final  DateTime? startDate;
@override final  DateTime? endDate;

/// Create a copy of BookmarkedCompetition
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BookmarkedCompetitionCopyWith<_BookmarkedCompetition> get copyWith => __$BookmarkedCompetitionCopyWithImpl<_BookmarkedCompetition>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BookmarkedCompetition&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.soaringspotUrl, soaringspotUrl) || other.soaringspotUrl == soaringspotUrl)&&(identical(other.bookmarkedAt, bookmarkedAt) || other.bookmarkedAt == bookmarkedAt)&&(identical(other.selectedClass, selectedClass) || other.selectedClass == selectedClass)&&(identical(other.description, description) || other.description == description)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,soaringspotUrl,bookmarkedAt,selectedClass,description,startDate,endDate);

@override
String toString() {
  return 'BookmarkedCompetition(id: $id, title: $title, soaringspotUrl: $soaringspotUrl, bookmarkedAt: $bookmarkedAt, selectedClass: $selectedClass, description: $description, startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class _$BookmarkedCompetitionCopyWith<$Res> implements $BookmarkedCompetitionCopyWith<$Res> {
  factory _$BookmarkedCompetitionCopyWith(_BookmarkedCompetition value, $Res Function(_BookmarkedCompetition) _then) = __$BookmarkedCompetitionCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String soaringspotUrl, DateTime bookmarkedAt, String? selectedClass, String? description, DateTime? startDate, DateTime? endDate
});




}
/// @nodoc
class __$BookmarkedCompetitionCopyWithImpl<$Res>
    implements _$BookmarkedCompetitionCopyWith<$Res> {
  __$BookmarkedCompetitionCopyWithImpl(this._self, this._then);

  final _BookmarkedCompetition _self;
  final $Res Function(_BookmarkedCompetition) _then;

/// Create a copy of BookmarkedCompetition
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? soaringspotUrl = null,Object? bookmarkedAt = null,Object? selectedClass = freezed,Object? description = freezed,Object? startDate = freezed,Object? endDate = freezed,}) {
  return _then(_BookmarkedCompetition(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,soaringspotUrl: null == soaringspotUrl ? _self.soaringspotUrl : soaringspotUrl // ignore: cast_nullable_to_non_nullable
as String,bookmarkedAt: null == bookmarkedAt ? _self.bookmarkedAt : bookmarkedAt // ignore: cast_nullable_to_non_nullable
as DateTime,selectedClass: freezed == selectedClass ? _self.selectedClass : selectedClass // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
