// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shiv_conversation_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShivConversationEntity {

 String get conversationId; String get title; String get activeBranchId; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of ShivConversationEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShivConversationEntityCopyWith<ShivConversationEntity> get copyWith => _$ShivConversationEntityCopyWithImpl<ShivConversationEntity>(this as ShivConversationEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShivConversationEntity&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.title, title) || other.title == title)&&(identical(other.activeBranchId, activeBranchId) || other.activeBranchId == activeBranchId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,title,activeBranchId,createdAt,updatedAt);

@override
String toString() {
  return 'ShivConversationEntity(conversationId: $conversationId, title: $title, activeBranchId: $activeBranchId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ShivConversationEntityCopyWith<$Res>  {
  factory $ShivConversationEntityCopyWith(ShivConversationEntity value, $Res Function(ShivConversationEntity) _then) = _$ShivConversationEntityCopyWithImpl;
@useResult
$Res call({
 String conversationId, String title, String activeBranchId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ShivConversationEntityCopyWithImpl<$Res>
    implements $ShivConversationEntityCopyWith<$Res> {
  _$ShivConversationEntityCopyWithImpl(this._self, this._then);

  final ShivConversationEntity _self;
  final $Res Function(ShivConversationEntity) _then;

/// Create a copy of ShivConversationEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? title = null,Object? activeBranchId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,activeBranchId: null == activeBranchId ? _self.activeBranchId : activeBranchId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ShivConversationEntity].
extension ShivConversationEntityPatterns on ShivConversationEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShivConversationEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShivConversationEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShivConversationEntity value)  $default,){
final _that = this;
switch (_that) {
case _ShivConversationEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShivConversationEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ShivConversationEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String conversationId,  String title,  String activeBranchId,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShivConversationEntity() when $default != null:
return $default(_that.conversationId,_that.title,_that.activeBranchId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String conversationId,  String title,  String activeBranchId,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ShivConversationEntity():
return $default(_that.conversationId,_that.title,_that.activeBranchId,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String conversationId,  String title,  String activeBranchId,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ShivConversationEntity() when $default != null:
return $default(_that.conversationId,_that.title,_that.activeBranchId,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ShivConversationEntity implements ShivConversationEntity {
  const _ShivConversationEntity({required this.conversationId, required this.title, required this.activeBranchId, required this.createdAt, required this.updatedAt});
  

@override final  String conversationId;
@override final  String title;
@override final  String activeBranchId;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of ShivConversationEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShivConversationEntityCopyWith<_ShivConversationEntity> get copyWith => __$ShivConversationEntityCopyWithImpl<_ShivConversationEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShivConversationEntity&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.title, title) || other.title == title)&&(identical(other.activeBranchId, activeBranchId) || other.activeBranchId == activeBranchId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId,title,activeBranchId,createdAt,updatedAt);

@override
String toString() {
  return 'ShivConversationEntity(conversationId: $conversationId, title: $title, activeBranchId: $activeBranchId, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ShivConversationEntityCopyWith<$Res> implements $ShivConversationEntityCopyWith<$Res> {
  factory _$ShivConversationEntityCopyWith(_ShivConversationEntity value, $Res Function(_ShivConversationEntity) _then) = __$ShivConversationEntityCopyWithImpl;
@override @useResult
$Res call({
 String conversationId, String title, String activeBranchId, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ShivConversationEntityCopyWithImpl<$Res>
    implements _$ShivConversationEntityCopyWith<$Res> {
  __$ShivConversationEntityCopyWithImpl(this._self, this._then);

  final _ShivConversationEntity _self;
  final $Res Function(_ShivConversationEntity) _then;

/// Create a copy of ShivConversationEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? title = null,Object? activeBranchId = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ShivConversationEntity(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,activeBranchId: null == activeBranchId ? _self.activeBranchId : activeBranchId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
