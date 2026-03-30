// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmarked_competition.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$BookmarkedCompetition {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get soaringspotUrl => throw _privateConstructorUsedError;
  DateTime get bookmarkedAt => throw _privateConstructorUsedError;
  String? get selectedClass => throw _privateConstructorUsedError;

  /// Create a copy of BookmarkedCompetition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookmarkedCompetitionCopyWith<BookmarkedCompetition> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BookmarkedCompetitionCopyWith<$Res> {
  factory $BookmarkedCompetitionCopyWith(BookmarkedCompetition value,
          $Res Function(BookmarkedCompetition) then) =
      _$BookmarkedCompetitionCopyWithImpl<$Res, BookmarkedCompetition>;
  @useResult
  $Res call(
      {String id,
      String title,
      String soaringspotUrl,
      DateTime bookmarkedAt,
      String? selectedClass});
}

/// @nodoc
class _$BookmarkedCompetitionCopyWithImpl<$Res,
        $Val extends BookmarkedCompetition>
    implements $BookmarkedCompetitionCopyWith<$Res> {
  _$BookmarkedCompetitionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BookmarkedCompetition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? soaringspotUrl = null,
    Object? bookmarkedAt = null,
    Object? selectedClass = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      soaringspotUrl: null == soaringspotUrl
          ? _value.soaringspotUrl
          : soaringspotUrl // ignore: cast_nullable_to_non_nullable
              as String,
      bookmarkedAt: null == bookmarkedAt
          ? _value.bookmarkedAt
          : bookmarkedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      selectedClass: freezed == selectedClass
          ? _value.selectedClass
          : selectedClass // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BookmarkedCompetitionImplCopyWith<$Res>
    implements $BookmarkedCompetitionCopyWith<$Res> {
  factory _$$BookmarkedCompetitionImplCopyWith(
          _$BookmarkedCompetitionImpl value,
          $Res Function(_$BookmarkedCompetitionImpl) then) =
      __$$BookmarkedCompetitionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      String soaringspotUrl,
      DateTime bookmarkedAt,
      String? selectedClass});
}

/// @nodoc
class __$$BookmarkedCompetitionImplCopyWithImpl<$Res>
    extends _$BookmarkedCompetitionCopyWithImpl<$Res,
        _$BookmarkedCompetitionImpl>
    implements _$$BookmarkedCompetitionImplCopyWith<$Res> {
  __$$BookmarkedCompetitionImplCopyWithImpl(_$BookmarkedCompetitionImpl _value,
      $Res Function(_$BookmarkedCompetitionImpl) _then)
      : super(_value, _then);

  /// Create a copy of BookmarkedCompetition
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? soaringspotUrl = null,
    Object? bookmarkedAt = null,
    Object? selectedClass = freezed,
  }) {
    return _then(_$BookmarkedCompetitionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      soaringspotUrl: null == soaringspotUrl
          ? _value.soaringspotUrl
          : soaringspotUrl // ignore: cast_nullable_to_non_nullable
              as String,
      bookmarkedAt: null == bookmarkedAt
          ? _value.bookmarkedAt
          : bookmarkedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      selectedClass: freezed == selectedClass
          ? _value.selectedClass
          : selectedClass // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$BookmarkedCompetitionImpl implements _BookmarkedCompetition {
  const _$BookmarkedCompetitionImpl(
      {required this.id,
      required this.title,
      required this.soaringspotUrl,
      required this.bookmarkedAt,
      this.selectedClass});

  @override
  final String id;
  @override
  final String title;
  @override
  final String soaringspotUrl;
  @override
  final DateTime bookmarkedAt;
  @override
  final String? selectedClass;

  @override
  String toString() {
    return 'BookmarkedCompetition(id: $id, title: $title, soaringspotUrl: $soaringspotUrl, bookmarkedAt: $bookmarkedAt, selectedClass: $selectedClass)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookmarkedCompetitionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.soaringspotUrl, soaringspotUrl) ||
                other.soaringspotUrl == soaringspotUrl) &&
            (identical(other.bookmarkedAt, bookmarkedAt) ||
                other.bookmarkedAt == bookmarkedAt) &&
            (identical(other.selectedClass, selectedClass) ||
                other.selectedClass == selectedClass));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, id, title, soaringspotUrl, bookmarkedAt, selectedClass);

  /// Create a copy of BookmarkedCompetition
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookmarkedCompetitionImplCopyWith<_$BookmarkedCompetitionImpl>
      get copyWith => __$$BookmarkedCompetitionImplCopyWithImpl<
          _$BookmarkedCompetitionImpl>(this, _$identity);
}

abstract class _BookmarkedCompetition implements BookmarkedCompetition {
  const factory _BookmarkedCompetition(
      {required final String id,
      required final String title,
      required final String soaringspotUrl,
      required final DateTime bookmarkedAt,
      final String? selectedClass}) = _$BookmarkedCompetitionImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  String get soaringspotUrl;
  @override
  DateTime get bookmarkedAt;
  @override
  String? get selectedClass;

  /// Create a copy of BookmarkedCompetition
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookmarkedCompetitionImplCopyWith<_$BookmarkedCompetitionImpl>
      get copyWith => throw _privateConstructorUsedError;
}
