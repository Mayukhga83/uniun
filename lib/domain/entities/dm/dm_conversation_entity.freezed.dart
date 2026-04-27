// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dm_conversation_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DmConversationEntity {

 int get id; String get otherPubkey; List<String> get relays;
/// Create a copy of DmConversationEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DmConversationEntityCopyWith<DmConversationEntity> get copyWith => _$DmConversationEntityCopyWithImpl<DmConversationEntity>(this as DmConversationEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DmConversationEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.otherPubkey, otherPubkey) || other.otherPubkey == otherPubkey)&&const DeepCollectionEquality().equals(other.relays, relays));
}


@override
int get hashCode => Object.hash(runtimeType,id,otherPubkey,const DeepCollectionEquality().hash(relays));

@override
String toString() {
  return 'DmConversationEntity(id: $id, otherPubkey: $otherPubkey, relays: $relays)';
}


}

/// @nodoc
abstract mixin class $DmConversationEntityCopyWith<$Res>  {
  factory $DmConversationEntityCopyWith(DmConversationEntity value, $Res Function(DmConversationEntity) _then) = _$DmConversationEntityCopyWithImpl;
@useResult
$Res call({
 int id, String otherPubkey, List<String> relays
});




}
/// @nodoc
class _$DmConversationEntityCopyWithImpl<$Res>
    implements $DmConversationEntityCopyWith<$Res> {
  _$DmConversationEntityCopyWithImpl(this._self, this._then);

  final DmConversationEntity _self;
  final $Res Function(DmConversationEntity) _then;

/// Create a copy of DmConversationEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? otherPubkey = null,Object? relays = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,otherPubkey: null == otherPubkey ? _self.otherPubkey : otherPubkey // ignore: cast_nullable_to_non_nullable
as String,relays: null == relays ? _self.relays : relays // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [DmConversationEntity].
extension DmConversationEntityPatterns on DmConversationEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DmConversationEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DmConversationEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DmConversationEntity value)  $default,){
final _that = this;
switch (_that) {
case _DmConversationEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DmConversationEntity value)?  $default,){
final _that = this;
switch (_that) {
case _DmConversationEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String otherPubkey,  List<String> relays)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DmConversationEntity() when $default != null:
return $default(_that.id,_that.otherPubkey,_that.relays);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String otherPubkey,  List<String> relays)  $default,) {final _that = this;
switch (_that) {
case _DmConversationEntity():
return $default(_that.id,_that.otherPubkey,_that.relays);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String otherPubkey,  List<String> relays)?  $default,) {final _that = this;
switch (_that) {
case _DmConversationEntity() when $default != null:
return $default(_that.id,_that.otherPubkey,_that.relays);case _:
  return null;

}
}

}

/// @nodoc


class _DmConversationEntity implements DmConversationEntity {
  const _DmConversationEntity({required this.id, required this.otherPubkey, final  List<String> relays = const []}): _relays = relays;
  

@override final  int id;
@override final  String otherPubkey;
 final  List<String> _relays;
@override@JsonKey() List<String> get relays {
  if (_relays is EqualUnmodifiableListView) return _relays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_relays);
}


/// Create a copy of DmConversationEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DmConversationEntityCopyWith<_DmConversationEntity> get copyWith => __$DmConversationEntityCopyWithImpl<_DmConversationEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DmConversationEntity&&(identical(other.id, id) || other.id == id)&&(identical(other.otherPubkey, otherPubkey) || other.otherPubkey == otherPubkey)&&const DeepCollectionEquality().equals(other._relays, _relays));
}


@override
int get hashCode => Object.hash(runtimeType,id,otherPubkey,const DeepCollectionEquality().hash(_relays));

@override
String toString() {
  return 'DmConversationEntity(id: $id, otherPubkey: $otherPubkey, relays: $relays)';
}


}

/// @nodoc
abstract mixin class _$DmConversationEntityCopyWith<$Res> implements $DmConversationEntityCopyWith<$Res> {
  factory _$DmConversationEntityCopyWith(_DmConversationEntity value, $Res Function(_DmConversationEntity) _then) = __$DmConversationEntityCopyWithImpl;
@override @useResult
$Res call({
 int id, String otherPubkey, List<String> relays
});




}
/// @nodoc
class __$DmConversationEntityCopyWithImpl<$Res>
    implements _$DmConversationEntityCopyWith<$Res> {
  __$DmConversationEntityCopyWithImpl(this._self, this._then);

  final _DmConversationEntity _self;
  final $Res Function(_DmConversationEntity) _then;

/// Create a copy of DmConversationEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? otherPubkey = null,Object? relays = null,}) {
  return _then(_DmConversationEntity(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,otherPubkey: null == otherPubkey ? _self.otherPubkey : otherPubkey // ignore: cast_nullable_to_non_nullable
as String,relays: null == relays ? _self._relays : relays // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
