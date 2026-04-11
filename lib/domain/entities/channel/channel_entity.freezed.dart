// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'channel_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChannelEntity {

 String get channelId; String get creatorPubKey; String get name; String get about; String get picture; List<String> get relays; int get createdAt; int get updatedAt; String? get lastMetaEvent; String? get lastReadEventId; int? get lastReadAt;
/// Create a copy of ChannelEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChannelEntityCopyWith<ChannelEntity> get copyWith => _$ChannelEntityCopyWithImpl<ChannelEntity>(this as ChannelEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChannelEntity&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.creatorPubKey, creatorPubKey) || other.creatorPubKey == creatorPubKey)&&(identical(other.name, name) || other.name == name)&&(identical(other.about, about) || other.about == about)&&(identical(other.picture, picture) || other.picture == picture)&&const DeepCollectionEquality().equals(other.relays, relays)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastMetaEvent, lastMetaEvent) || other.lastMetaEvent == lastMetaEvent)&&(identical(other.lastReadEventId, lastReadEventId) || other.lastReadEventId == lastReadEventId)&&(identical(other.lastReadAt, lastReadAt) || other.lastReadAt == lastReadAt));
}


@override
int get hashCode => Object.hash(runtimeType,channelId,creatorPubKey,name,about,picture,const DeepCollectionEquality().hash(relays),createdAt,updatedAt,lastMetaEvent,lastReadEventId,lastReadAt);

@override
String toString() {
  return 'ChannelEntity(channelId: $channelId, creatorPubKey: $creatorPubKey, name: $name, about: $about, picture: $picture, relays: $relays, createdAt: $createdAt, updatedAt: $updatedAt, lastMetaEvent: $lastMetaEvent, lastReadEventId: $lastReadEventId, lastReadAt: $lastReadAt)';
}


}

/// @nodoc
abstract mixin class $ChannelEntityCopyWith<$Res>  {
  factory $ChannelEntityCopyWith(ChannelEntity value, $Res Function(ChannelEntity) _then) = _$ChannelEntityCopyWithImpl;
@useResult
$Res call({
 String channelId, String creatorPubKey, String name, String about, String picture, List<String> relays, int createdAt, int updatedAt, String? lastMetaEvent, String? lastReadEventId, int? lastReadAt
});




}
/// @nodoc
class _$ChannelEntityCopyWithImpl<$Res>
    implements $ChannelEntityCopyWith<$Res> {
  _$ChannelEntityCopyWithImpl(this._self, this._then);

  final ChannelEntity _self;
  final $Res Function(ChannelEntity) _then;

/// Create a copy of ChannelEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? channelId = null,Object? creatorPubKey = null,Object? name = null,Object? about = null,Object? picture = null,Object? relays = null,Object? createdAt = null,Object? updatedAt = null,Object? lastMetaEvent = freezed,Object? lastReadEventId = freezed,Object? lastReadAt = freezed,}) {
  return _then(_self.copyWith(
channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,creatorPubKey: null == creatorPubKey ? _self.creatorPubKey : creatorPubKey // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,about: null == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String,picture: null == picture ? _self.picture : picture // ignore: cast_nullable_to_non_nullable
as String,relays: null == relays ? _self.relays : relays // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,lastMetaEvent: freezed == lastMetaEvent ? _self.lastMetaEvent : lastMetaEvent // ignore: cast_nullable_to_non_nullable
as String?,lastReadEventId: freezed == lastReadEventId ? _self.lastReadEventId : lastReadEventId // ignore: cast_nullable_to_non_nullable
as String?,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ChannelEntity].
extension ChannelEntityPatterns on ChannelEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChannelEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChannelEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChannelEntity value)  $default,){
final _that = this;
switch (_that) {
case _ChannelEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChannelEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ChannelEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String channelId,  String creatorPubKey,  String name,  String about,  String picture,  List<String> relays,  int createdAt,  int updatedAt,  String? lastMetaEvent,  String? lastReadEventId,  int? lastReadAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChannelEntity() when $default != null:
return $default(_that.channelId,_that.creatorPubKey,_that.name,_that.about,_that.picture,_that.relays,_that.createdAt,_that.updatedAt,_that.lastMetaEvent,_that.lastReadEventId,_that.lastReadAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String channelId,  String creatorPubKey,  String name,  String about,  String picture,  List<String> relays,  int createdAt,  int updatedAt,  String? lastMetaEvent,  String? lastReadEventId,  int? lastReadAt)  $default,) {final _that = this;
switch (_that) {
case _ChannelEntity():
return $default(_that.channelId,_that.creatorPubKey,_that.name,_that.about,_that.picture,_that.relays,_that.createdAt,_that.updatedAt,_that.lastMetaEvent,_that.lastReadEventId,_that.lastReadAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String channelId,  String creatorPubKey,  String name,  String about,  String picture,  List<String> relays,  int createdAt,  int updatedAt,  String? lastMetaEvent,  String? lastReadEventId,  int? lastReadAt)?  $default,) {final _that = this;
switch (_that) {
case _ChannelEntity() when $default != null:
return $default(_that.channelId,_that.creatorPubKey,_that.name,_that.about,_that.picture,_that.relays,_that.createdAt,_that.updatedAt,_that.lastMetaEvent,_that.lastReadEventId,_that.lastReadAt);case _:
  return null;

}
}

}

/// @nodoc


class _ChannelEntity implements ChannelEntity {
  const _ChannelEntity({required this.channelId, required this.creatorPubKey, required this.name, required this.about, required this.picture, required final  List<String> relays, required this.createdAt, required this.updatedAt, this.lastMetaEvent, this.lastReadEventId, this.lastReadAt}): _relays = relays;
  

@override final  String channelId;
@override final  String creatorPubKey;
@override final  String name;
@override final  String about;
@override final  String picture;
 final  List<String> _relays;
@override List<String> get relays {
  if (_relays is EqualUnmodifiableListView) return _relays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relays);
}

@override final  int createdAt;
@override final  int updatedAt;
@override final  String? lastMetaEvent;
@override final  String? lastReadEventId;
@override final  int? lastReadAt;

/// Create a copy of ChannelEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChannelEntityCopyWith<_ChannelEntity> get copyWith => __$ChannelEntityCopyWithImpl<_ChannelEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChannelEntity&&(identical(other.channelId, channelId) || other.channelId == channelId)&&(identical(other.creatorPubKey, creatorPubKey) || other.creatorPubKey == creatorPubKey)&&(identical(other.name, name) || other.name == name)&&(identical(other.about, about) || other.about == about)&&(identical(other.picture, picture) || other.picture == picture)&&const DeepCollectionEquality().equals(other._relays, _relays)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.lastMetaEvent, lastMetaEvent) || other.lastMetaEvent == lastMetaEvent)&&(identical(other.lastReadEventId, lastReadEventId) || other.lastReadEventId == lastReadEventId)&&(identical(other.lastReadAt, lastReadAt) || other.lastReadAt == lastReadAt));
}


@override
int get hashCode => Object.hash(runtimeType,channelId,creatorPubKey,name,about,picture,const DeepCollectionEquality().hash(_relays),createdAt,updatedAt,lastMetaEvent,lastReadEventId,lastReadAt);

@override
String toString() {
  return 'ChannelEntity(channelId: $channelId, creatorPubKey: $creatorPubKey, name: $name, about: $about, picture: $picture, relays: $relays, createdAt: $createdAt, updatedAt: $updatedAt, lastMetaEvent: $lastMetaEvent, lastReadEventId: $lastReadEventId, lastReadAt: $lastReadAt)';
}


}

/// @nodoc
abstract mixin class _$ChannelEntityCopyWith<$Res> implements $ChannelEntityCopyWith<$Res> {
  factory _$ChannelEntityCopyWith(_ChannelEntity value, $Res Function(_ChannelEntity) _then) = __$ChannelEntityCopyWithImpl;
@override @useResult
$Res call({
 String channelId, String creatorPubKey, String name, String about, String picture, List<String> relays, int createdAt, int updatedAt, String? lastMetaEvent, String? lastReadEventId, int? lastReadAt
});




}
/// @nodoc
class __$ChannelEntityCopyWithImpl<$Res>
    implements _$ChannelEntityCopyWith<$Res> {
  __$ChannelEntityCopyWithImpl(this._self, this._then);

  final _ChannelEntity _self;
  final $Res Function(_ChannelEntity) _then;

/// Create a copy of ChannelEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? channelId = null,Object? creatorPubKey = null,Object? name = null,Object? about = null,Object? picture = null,Object? relays = null,Object? createdAt = null,Object? updatedAt = null,Object? lastMetaEvent = freezed,Object? lastReadEventId = freezed,Object? lastReadAt = freezed,}) {
  return _then(_ChannelEntity(
channelId: null == channelId ? _self.channelId : channelId // ignore: cast_nullable_to_non_nullable
as String,creatorPubKey: null == creatorPubKey ? _self.creatorPubKey : creatorPubKey // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,about: null == about ? _self.about : about // ignore: cast_nullable_to_non_nullable
as String,picture: null == picture ? _self.picture : picture // ignore: cast_nullable_to_non_nullable
as String,relays: null == relays ? _self._relays : relays // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,lastMetaEvent: freezed == lastMetaEvent ? _self.lastMetaEvent : lastMetaEvent // ignore: cast_nullable_to_non_nullable
as String?,lastReadEventId: freezed == lastReadEventId ? _self.lastReadEventId : lastReadEventId // ignore: cast_nullable_to_non_nullable
as String?,lastReadAt: freezed == lastReadAt ? _self.lastReadAt : lastReadAt // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
