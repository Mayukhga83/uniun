// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_record_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubscriptionRecordEntity {

 String get key; List<int> get kinds; List<String> get eTags; List<String>? get authors; int? get limit; List<String> get relays; Map<String, int> get lastUntilByRelay; int get createdAt; int get updatedAt; bool get enabled;
/// Create a copy of SubscriptionRecordEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionRecordEntityCopyWith<SubscriptionRecordEntity> get copyWith => _$SubscriptionRecordEntityCopyWithImpl<SubscriptionRecordEntity>(this as SubscriptionRecordEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionRecordEntity&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other.kinds, kinds)&&const DeepCollectionEquality().equals(other.eTags, eTags)&&const DeepCollectionEquality().equals(other.authors, authors)&&(identical(other.limit, limit) || other.limit == limit)&&const DeepCollectionEquality().equals(other.relays, relays)&&const DeepCollectionEquality().equals(other.lastUntilByRelay, lastUntilByRelay)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode => Object.hash(runtimeType,key,const DeepCollectionEquality().hash(kinds),const DeepCollectionEquality().hash(eTags),const DeepCollectionEquality().hash(authors),limit,const DeepCollectionEquality().hash(relays),const DeepCollectionEquality().hash(lastUntilByRelay),createdAt,updatedAt,enabled);

@override
String toString() {
  return 'SubscriptionRecordEntity(key: $key, kinds: $kinds, eTags: $eTags, authors: $authors, limit: $limit, relays: $relays, lastUntilByRelay: $lastUntilByRelay, createdAt: $createdAt, updatedAt: $updatedAt, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class $SubscriptionRecordEntityCopyWith<$Res>  {
  factory $SubscriptionRecordEntityCopyWith(SubscriptionRecordEntity value, $Res Function(SubscriptionRecordEntity) _then) = _$SubscriptionRecordEntityCopyWithImpl;
@useResult
$Res call({
 String key, List<int> kinds, List<String> eTags, List<String>? authors, int? limit, List<String> relays, Map<String, int> lastUntilByRelay, int createdAt, int updatedAt, bool enabled
});




}
/// @nodoc
class _$SubscriptionRecordEntityCopyWithImpl<$Res>
    implements $SubscriptionRecordEntityCopyWith<$Res> {
  _$SubscriptionRecordEntityCopyWithImpl(this._self, this._then);

  final SubscriptionRecordEntity _self;
  final $Res Function(SubscriptionRecordEntity) _then;

/// Create a copy of SubscriptionRecordEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? kinds = null,Object? eTags = null,Object? authors = freezed,Object? limit = freezed,Object? relays = null,Object? lastUntilByRelay = null,Object? createdAt = null,Object? updatedAt = null,Object? enabled = null,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,kinds: null == kinds ? _self.kinds : kinds // ignore: cast_nullable_to_non_nullable
as List<int>,eTags: null == eTags ? _self.eTags : eTags // ignore: cast_nullable_to_non_nullable
as List<String>,authors: freezed == authors ? _self.authors : authors // ignore: cast_nullable_to_non_nullable
as List<String>?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int?,relays: null == relays ? _self.relays : relays // ignore: cast_nullable_to_non_nullable
as List<String>,lastUntilByRelay: null == lastUntilByRelay ? _self.lastUntilByRelay : lastUntilByRelay // ignore: cast_nullable_to_non_nullable
as Map<String, int>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionRecordEntity].
extension SubscriptionRecordEntityPatterns on SubscriptionRecordEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionRecordEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionRecordEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionRecordEntity value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionRecordEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionRecordEntity value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionRecordEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  List<int> kinds,  List<String> eTags,  List<String>? authors,  int? limit,  List<String> relays,  Map<String, int> lastUntilByRelay,  int createdAt,  int updatedAt,  bool enabled)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionRecordEntity() when $default != null:
return $default(_that.key,_that.kinds,_that.eTags,_that.authors,_that.limit,_that.relays,_that.lastUntilByRelay,_that.createdAt,_that.updatedAt,_that.enabled);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  List<int> kinds,  List<String> eTags,  List<String>? authors,  int? limit,  List<String> relays,  Map<String, int> lastUntilByRelay,  int createdAt,  int updatedAt,  bool enabled)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionRecordEntity():
return $default(_that.key,_that.kinds,_that.eTags,_that.authors,_that.limit,_that.relays,_that.lastUntilByRelay,_that.createdAt,_that.updatedAt,_that.enabled);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  List<int> kinds,  List<String> eTags,  List<String>? authors,  int? limit,  List<String> relays,  Map<String, int> lastUntilByRelay,  int createdAt,  int updatedAt,  bool enabled)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionRecordEntity() when $default != null:
return $default(_that.key,_that.kinds,_that.eTags,_that.authors,_that.limit,_that.relays,_that.lastUntilByRelay,_that.createdAt,_that.updatedAt,_that.enabled);case _:
  return null;

}
}

}

/// @nodoc


class _SubscriptionRecordEntity implements SubscriptionRecordEntity {
  const _SubscriptionRecordEntity({required this.key, required final  List<int> kinds, required final  List<String> eTags, final  List<String>? authors, this.limit, required final  List<String> relays, required final  Map<String, int> lastUntilByRelay, required this.createdAt, required this.updatedAt, this.enabled = true}): _kinds = kinds,_eTags = eTags,_authors = authors,_relays = relays,_lastUntilByRelay = lastUntilByRelay;
  

@override final  String key;
 final  List<int> _kinds;
@override List<int> get kinds {
  if (_kinds is EqualUnmodifiableListView) return _kinds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_kinds);
}

 final  List<String> _eTags;
@override List<String> get eTags {
  if (_eTags is EqualUnmodifiableListView) return _eTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_eTags);
}

 final  List<String>? _authors;
@override List<String>? get authors {
  final value = _authors;
  if (value == null) return null;
  if (_authors is EqualUnmodifiableListView) return _authors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  int? limit;
 final  List<String> _relays;
@override List<String> get relays {
  if (_relays is EqualUnmodifiableListView) return _relays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relays);
}

 final  Map<String, int> _lastUntilByRelay;
@override Map<String, int> get lastUntilByRelay {
  if (_lastUntilByRelay is EqualUnmodifiableMapView) return _lastUntilByRelay;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_lastUntilByRelay);
}

@override final  int createdAt;
@override final  int updatedAt;
@override@JsonKey() final  bool enabled;

/// Create a copy of SubscriptionRecordEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionRecordEntityCopyWith<_SubscriptionRecordEntity> get copyWith => __$SubscriptionRecordEntityCopyWithImpl<_SubscriptionRecordEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionRecordEntity&&(identical(other.key, key) || other.key == key)&&const DeepCollectionEquality().equals(other._kinds, _kinds)&&const DeepCollectionEquality().equals(other._eTags, _eTags)&&const DeepCollectionEquality().equals(other._authors, _authors)&&(identical(other.limit, limit) || other.limit == limit)&&const DeepCollectionEquality().equals(other._relays, _relays)&&const DeepCollectionEquality().equals(other._lastUntilByRelay, _lastUntilByRelay)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.enabled, enabled) || other.enabled == enabled));
}


@override
int get hashCode => Object.hash(runtimeType,key,const DeepCollectionEquality().hash(_kinds),const DeepCollectionEquality().hash(_eTags),const DeepCollectionEquality().hash(_authors),limit,const DeepCollectionEquality().hash(_relays),const DeepCollectionEquality().hash(_lastUntilByRelay),createdAt,updatedAt,enabled);

@override
String toString() {
  return 'SubscriptionRecordEntity(key: $key, kinds: $kinds, eTags: $eTags, authors: $authors, limit: $limit, relays: $relays, lastUntilByRelay: $lastUntilByRelay, createdAt: $createdAt, updatedAt: $updatedAt, enabled: $enabled)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionRecordEntityCopyWith<$Res> implements $SubscriptionRecordEntityCopyWith<$Res> {
  factory _$SubscriptionRecordEntityCopyWith(_SubscriptionRecordEntity value, $Res Function(_SubscriptionRecordEntity) _then) = __$SubscriptionRecordEntityCopyWithImpl;
@override @useResult
$Res call({
 String key, List<int> kinds, List<String> eTags, List<String>? authors, int? limit, List<String> relays, Map<String, int> lastUntilByRelay, int createdAt, int updatedAt, bool enabled
});




}
/// @nodoc
class __$SubscriptionRecordEntityCopyWithImpl<$Res>
    implements _$SubscriptionRecordEntityCopyWith<$Res> {
  __$SubscriptionRecordEntityCopyWithImpl(this._self, this._then);

  final _SubscriptionRecordEntity _self;
  final $Res Function(_SubscriptionRecordEntity) _then;

/// Create a copy of SubscriptionRecordEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? kinds = null,Object? eTags = null,Object? authors = freezed,Object? limit = freezed,Object? relays = null,Object? lastUntilByRelay = null,Object? createdAt = null,Object? updatedAt = null,Object? enabled = null,}) {
  return _then(_SubscriptionRecordEntity(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,kinds: null == kinds ? _self._kinds : kinds // ignore: cast_nullable_to_non_nullable
as List<int>,eTags: null == eTags ? _self._eTags : eTags // ignore: cast_nullable_to_non_nullable
as List<String>,authors: freezed == authors ? _self._authors : authors // ignore: cast_nullable_to_non_nullable
as List<String>?,limit: freezed == limit ? _self.limit : limit // ignore: cast_nullable_to_non_nullable
as int?,relays: null == relays ? _self._relays : relays // ignore: cast_nullable_to_non_nullable
as List<String>,lastUntilByRelay: null == lastUntilByRelay ? _self._lastUntilByRelay : lastUntilByRelay // ignore: cast_nullable_to_non_nullable
as Map<String, int>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
