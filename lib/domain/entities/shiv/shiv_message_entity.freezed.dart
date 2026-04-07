// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shiv_message_entity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShivMessageEntity {

 String get messageId; String get conversationId; String? get parentId; String get branchId; MessageRole get role; String get content; DateTime get createdAt;
/// Create a copy of ShivMessageEntity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShivMessageEntityCopyWith<ShivMessageEntity> get copyWith => _$ShivMessageEntityCopyWithImpl<ShivMessageEntity>(this as ShivMessageEntity, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShivMessageEntity&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,messageId,conversationId,parentId,branchId,role,content,createdAt);

@override
String toString() {
  return 'ShivMessageEntity(messageId: $messageId, conversationId: $conversationId, parentId: $parentId, branchId: $branchId, role: $role, content: $content, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $ShivMessageEntityCopyWith<$Res>  {
  factory $ShivMessageEntityCopyWith(ShivMessageEntity value, $Res Function(ShivMessageEntity) _then) = _$ShivMessageEntityCopyWithImpl;
@useResult
$Res call({
 String messageId, String conversationId, String? parentId, String branchId, MessageRole role, String content, DateTime createdAt
});




}
/// @nodoc
class _$ShivMessageEntityCopyWithImpl<$Res>
    implements $ShivMessageEntityCopyWith<$Res> {
  _$ShivMessageEntityCopyWithImpl(this._self, this._then);

  final ShivMessageEntity _self;
  final $Res Function(ShivMessageEntity) _then;

/// Create a copy of ShivMessageEntity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? messageId = null,Object? conversationId = null,Object? parentId = freezed,Object? branchId = null,Object? role = null,Object? content = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MessageRole,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ShivMessageEntity].
extension ShivMessageEntityPatterns on ShivMessageEntity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShivMessageEntity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShivMessageEntity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShivMessageEntity value)  $default,){
final _that = this;
switch (_that) {
case _ShivMessageEntity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShivMessageEntity value)?  $default,){
final _that = this;
switch (_that) {
case _ShivMessageEntity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String messageId,  String conversationId,  String? parentId,  String branchId,  MessageRole role,  String content,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShivMessageEntity() when $default != null:
return $default(_that.messageId,_that.conversationId,_that.parentId,_that.branchId,_that.role,_that.content,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String messageId,  String conversationId,  String? parentId,  String branchId,  MessageRole role,  String content,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _ShivMessageEntity():
return $default(_that.messageId,_that.conversationId,_that.parentId,_that.branchId,_that.role,_that.content,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String messageId,  String conversationId,  String? parentId,  String branchId,  MessageRole role,  String content,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _ShivMessageEntity() when $default != null:
return $default(_that.messageId,_that.conversationId,_that.parentId,_that.branchId,_that.role,_that.content,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _ShivMessageEntity implements ShivMessageEntity {
  const _ShivMessageEntity({required this.messageId, required this.conversationId, this.parentId, required this.branchId, required this.role, required this.content, required this.createdAt});
  

@override final  String messageId;
@override final  String conversationId;
@override final  String? parentId;
@override final  String branchId;
@override final  MessageRole role;
@override final  String content;
@override final  DateTime createdAt;

/// Create a copy of ShivMessageEntity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShivMessageEntityCopyWith<_ShivMessageEntity> get copyWith => __$ShivMessageEntityCopyWithImpl<_ShivMessageEntity>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShivMessageEntity&&(identical(other.messageId, messageId) || other.messageId == messageId)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.parentId, parentId) || other.parentId == parentId)&&(identical(other.branchId, branchId) || other.branchId == branchId)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,messageId,conversationId,parentId,branchId,role,content,createdAt);

@override
String toString() {
  return 'ShivMessageEntity(messageId: $messageId, conversationId: $conversationId, parentId: $parentId, branchId: $branchId, role: $role, content: $content, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ShivMessageEntityCopyWith<$Res> implements $ShivMessageEntityCopyWith<$Res> {
  factory _$ShivMessageEntityCopyWith(_ShivMessageEntity value, $Res Function(_ShivMessageEntity) _then) = __$ShivMessageEntityCopyWithImpl;
@override @useResult
$Res call({
 String messageId, String conversationId, String? parentId, String branchId, MessageRole role, String content, DateTime createdAt
});




}
/// @nodoc
class __$ShivMessageEntityCopyWithImpl<$Res>
    implements _$ShivMessageEntityCopyWith<$Res> {
  __$ShivMessageEntityCopyWithImpl(this._self, this._then);

  final _ShivMessageEntity _self;
  final $Res Function(_ShivMessageEntity) _then;

/// Create a copy of ShivMessageEntity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? messageId = null,Object? conversationId = null,Object? parentId = freezed,Object? branchId = null,Object? role = null,Object? content = null,Object? createdAt = null,}) {
  return _then(_ShivMessageEntity(
messageId: null == messageId ? _self.messageId : messageId // ignore: cast_nullable_to_non_nullable
as String,conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,parentId: freezed == parentId ? _self.parentId : parentId // ignore: cast_nullable_to_non_nullable
as String?,branchId: null == branchId ? _self.branchId : branchId // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as MessageRole,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
