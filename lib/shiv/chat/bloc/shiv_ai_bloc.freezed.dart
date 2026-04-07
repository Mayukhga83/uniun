// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shiv_ai_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShivAIEvent {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShivAIEvent);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShivAIEvent()';
}


}

/// @nodoc
class $ShivAIEventCopyWith<$Res>  {
$ShivAIEventCopyWith(ShivAIEvent _, $Res Function(ShivAIEvent) __);
}


/// Adds pattern-matching-related methods to [ShivAIEvent].
extension ShivAIEventPatterns on ShivAIEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( _LoadConversations value)?  loadConversations,TResult Function( _CreateConversation value)?  createConversation,TResult Function( _OpenConversation value)?  openConversation,TResult Function( _CloseConversation value)?  closeConversation,TResult Function( _DeleteConversation value)?  deleteConversation,TResult Function( _SendMessage value)?  sendMessage,TResult Function( _TokenReceived value)?  tokenReceived,TResult Function( _StreamDone value)?  streamDone,TResult Function( _StreamError value)?  streamError,required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LoadConversations() when loadConversations != null:
return loadConversations(_that);case _CreateConversation() when createConversation != null:
return createConversation(_that);case _OpenConversation() when openConversation != null:
return openConversation(_that);case _CloseConversation() when closeConversation != null:
return closeConversation(_that);case _DeleteConversation() when deleteConversation != null:
return deleteConversation(_that);case _SendMessage() when sendMessage != null:
return sendMessage(_that);case _TokenReceived() when tokenReceived != null:
return tokenReceived(_that);case _StreamDone() when streamDone != null:
return streamDone(_that);case _StreamError() when streamError != null:
return streamError(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( _LoadConversations value)  loadConversations,required TResult Function( _CreateConversation value)  createConversation,required TResult Function( _OpenConversation value)  openConversation,required TResult Function( _CloseConversation value)  closeConversation,required TResult Function( _DeleteConversation value)  deleteConversation,required TResult Function( _SendMessage value)  sendMessage,required TResult Function( _TokenReceived value)  tokenReceived,required TResult Function( _StreamDone value)  streamDone,required TResult Function( _StreamError value)  streamError,}){
final _that = this;
switch (_that) {
case _LoadConversations():
return loadConversations(_that);case _CreateConversation():
return createConversation(_that);case _OpenConversation():
return openConversation(_that);case _CloseConversation():
return closeConversation(_that);case _DeleteConversation():
return deleteConversation(_that);case _SendMessage():
return sendMessage(_that);case _TokenReceived():
return tokenReceived(_that);case _StreamDone():
return streamDone(_that);case _StreamError():
return streamError(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( _LoadConversations value)?  loadConversations,TResult? Function( _CreateConversation value)?  createConversation,TResult? Function( _OpenConversation value)?  openConversation,TResult? Function( _CloseConversation value)?  closeConversation,TResult? Function( _DeleteConversation value)?  deleteConversation,TResult? Function( _SendMessage value)?  sendMessage,TResult? Function( _TokenReceived value)?  tokenReceived,TResult? Function( _StreamDone value)?  streamDone,TResult? Function( _StreamError value)?  streamError,}){
final _that = this;
switch (_that) {
case _LoadConversations() when loadConversations != null:
return loadConversations(_that);case _CreateConversation() when createConversation != null:
return createConversation(_that);case _OpenConversation() when openConversation != null:
return openConversation(_that);case _CloseConversation() when closeConversation != null:
return closeConversation(_that);case _DeleteConversation() when deleteConversation != null:
return deleteConversation(_that);case _SendMessage() when sendMessage != null:
return sendMessage(_that);case _TokenReceived() when tokenReceived != null:
return tokenReceived(_that);case _StreamDone() when streamDone != null:
return streamDone(_that);case _StreamError() when streamError != null:
return streamError(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loadConversations,TResult Function()?  createConversation,TResult Function( String conversationId)?  openConversation,TResult Function()?  closeConversation,TResult Function( String conversationId)?  deleteConversation,TResult Function( String text)?  sendMessage,TResult Function( String token)?  tokenReceived,TResult Function()?  streamDone,TResult Function( String message)?  streamError,required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LoadConversations() when loadConversations != null:
return loadConversations();case _CreateConversation() when createConversation != null:
return createConversation();case _OpenConversation() when openConversation != null:
return openConversation(_that.conversationId);case _CloseConversation() when closeConversation != null:
return closeConversation();case _DeleteConversation() when deleteConversation != null:
return deleteConversation(_that.conversationId);case _SendMessage() when sendMessage != null:
return sendMessage(_that.text);case _TokenReceived() when tokenReceived != null:
return tokenReceived(_that.token);case _StreamDone() when streamDone != null:
return streamDone();case _StreamError() when streamError != null:
return streamError(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loadConversations,required TResult Function()  createConversation,required TResult Function( String conversationId)  openConversation,required TResult Function()  closeConversation,required TResult Function( String conversationId)  deleteConversation,required TResult Function( String text)  sendMessage,required TResult Function( String token)  tokenReceived,required TResult Function()  streamDone,required TResult Function( String message)  streamError,}) {final _that = this;
switch (_that) {
case _LoadConversations():
return loadConversations();case _CreateConversation():
return createConversation();case _OpenConversation():
return openConversation(_that.conversationId);case _CloseConversation():
return closeConversation();case _DeleteConversation():
return deleteConversation(_that.conversationId);case _SendMessage():
return sendMessage(_that.text);case _TokenReceived():
return tokenReceived(_that.token);case _StreamDone():
return streamDone();case _StreamError():
return streamError(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loadConversations,TResult? Function()?  createConversation,TResult? Function( String conversationId)?  openConversation,TResult? Function()?  closeConversation,TResult? Function( String conversationId)?  deleteConversation,TResult? Function( String text)?  sendMessage,TResult? Function( String token)?  tokenReceived,TResult? Function()?  streamDone,TResult? Function( String message)?  streamError,}) {final _that = this;
switch (_that) {
case _LoadConversations() when loadConversations != null:
return loadConversations();case _CreateConversation() when createConversation != null:
return createConversation();case _OpenConversation() when openConversation != null:
return openConversation(_that.conversationId);case _CloseConversation() when closeConversation != null:
return closeConversation();case _DeleteConversation() when deleteConversation != null:
return deleteConversation(_that.conversationId);case _SendMessage() when sendMessage != null:
return sendMessage(_that.text);case _TokenReceived() when tokenReceived != null:
return tokenReceived(_that.token);case _StreamDone() when streamDone != null:
return streamDone();case _StreamError() when streamError != null:
return streamError(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class _LoadConversations implements ShivAIEvent {
  const _LoadConversations();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LoadConversations);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShivAIEvent.loadConversations()';
}


}




/// @nodoc


class _CreateConversation implements ShivAIEvent {
  const _CreateConversation();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CreateConversation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShivAIEvent.createConversation()';
}


}




/// @nodoc


class _OpenConversation implements ShivAIEvent {
  const _OpenConversation(this.conversationId);
  

 final  String conversationId;

/// Create a copy of ShivAIEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpenConversationCopyWith<_OpenConversation> get copyWith => __$OpenConversationCopyWithImpl<_OpenConversation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpenConversation&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId);

@override
String toString() {
  return 'ShivAIEvent.openConversation(conversationId: $conversationId)';
}


}

/// @nodoc
abstract mixin class _$OpenConversationCopyWith<$Res> implements $ShivAIEventCopyWith<$Res> {
  factory _$OpenConversationCopyWith(_OpenConversation value, $Res Function(_OpenConversation) _then) = __$OpenConversationCopyWithImpl;
@useResult
$Res call({
 String conversationId
});




}
/// @nodoc
class __$OpenConversationCopyWithImpl<$Res>
    implements _$OpenConversationCopyWith<$Res> {
  __$OpenConversationCopyWithImpl(this._self, this._then);

  final _OpenConversation _self;
  final $Res Function(_OpenConversation) _then;

/// Create a copy of ShivAIEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? conversationId = null,}) {
  return _then(_OpenConversation(
null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _CloseConversation implements ShivAIEvent {
  const _CloseConversation();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CloseConversation);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShivAIEvent.closeConversation()';
}


}




/// @nodoc


class _DeleteConversation implements ShivAIEvent {
  const _DeleteConversation(this.conversationId);
  

 final  String conversationId;

/// Create a copy of ShivAIEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeleteConversationCopyWith<_DeleteConversation> get copyWith => __$DeleteConversationCopyWithImpl<_DeleteConversation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeleteConversation&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId));
}


@override
int get hashCode => Object.hash(runtimeType,conversationId);

@override
String toString() {
  return 'ShivAIEvent.deleteConversation(conversationId: $conversationId)';
}


}

/// @nodoc
abstract mixin class _$DeleteConversationCopyWith<$Res> implements $ShivAIEventCopyWith<$Res> {
  factory _$DeleteConversationCopyWith(_DeleteConversation value, $Res Function(_DeleteConversation) _then) = __$DeleteConversationCopyWithImpl;
@useResult
$Res call({
 String conversationId
});




}
/// @nodoc
class __$DeleteConversationCopyWithImpl<$Res>
    implements _$DeleteConversationCopyWith<$Res> {
  __$DeleteConversationCopyWithImpl(this._self, this._then);

  final _DeleteConversation _self;
  final $Res Function(_DeleteConversation) _then;

/// Create a copy of ShivAIEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? conversationId = null,}) {
  return _then(_DeleteConversation(
null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _SendMessage implements ShivAIEvent {
  const _SendMessage(this.text);
  

 final  String text;

/// Create a copy of ShivAIEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SendMessageCopyWith<_SendMessage> get copyWith => __$SendMessageCopyWithImpl<_SendMessage>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SendMessage&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode => Object.hash(runtimeType,text);

@override
String toString() {
  return 'ShivAIEvent.sendMessage(text: $text)';
}


}

/// @nodoc
abstract mixin class _$SendMessageCopyWith<$Res> implements $ShivAIEventCopyWith<$Res> {
  factory _$SendMessageCopyWith(_SendMessage value, $Res Function(_SendMessage) _then) = __$SendMessageCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class __$SendMessageCopyWithImpl<$Res>
    implements _$SendMessageCopyWith<$Res> {
  __$SendMessageCopyWithImpl(this._self, this._then);

  final _SendMessage _self;
  final $Res Function(_SendMessage) _then;

/// Create a copy of ShivAIEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(_SendMessage(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _TokenReceived implements ShivAIEvent {
  const _TokenReceived(this.token);
  

 final  String token;

/// Create a copy of ShivAIEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TokenReceivedCopyWith<_TokenReceived> get copyWith => __$TokenReceivedCopyWithImpl<_TokenReceived>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TokenReceived&&(identical(other.token, token) || other.token == token));
}


@override
int get hashCode => Object.hash(runtimeType,token);

@override
String toString() {
  return 'ShivAIEvent.tokenReceived(token: $token)';
}


}

/// @nodoc
abstract mixin class _$TokenReceivedCopyWith<$Res> implements $ShivAIEventCopyWith<$Res> {
  factory _$TokenReceivedCopyWith(_TokenReceived value, $Res Function(_TokenReceived) _then) = __$TokenReceivedCopyWithImpl;
@useResult
$Res call({
 String token
});




}
/// @nodoc
class __$TokenReceivedCopyWithImpl<$Res>
    implements _$TokenReceivedCopyWith<$Res> {
  __$TokenReceivedCopyWithImpl(this._self, this._then);

  final _TokenReceived _self;
  final $Res Function(_TokenReceived) _then;

/// Create a copy of ShivAIEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? token = null,}) {
  return _then(_TokenReceived(
null == token ? _self.token : token // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class _StreamDone implements ShivAIEvent {
  const _StreamDone();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamDone);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShivAIEvent.streamDone()';
}


}




/// @nodoc


class _StreamError implements ShivAIEvent {
  const _StreamError(this.message);
  

 final  String message;

/// Create a copy of ShivAIEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StreamErrorCopyWith<_StreamError> get copyWith => __$StreamErrorCopyWithImpl<_StreamError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StreamError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ShivAIEvent.streamError(message: $message)';
}


}

/// @nodoc
abstract mixin class _$StreamErrorCopyWith<$Res> implements $ShivAIEventCopyWith<$Res> {
  factory _$StreamErrorCopyWith(_StreamError value, $Res Function(_StreamError) _then) = __$StreamErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class __$StreamErrorCopyWithImpl<$Res>
    implements _$StreamErrorCopyWith<$Res> {
  __$StreamErrorCopyWithImpl(this._self, this._then);

  final _StreamError _self;
  final $Res Function(_StreamError) _then;

/// Create a copy of ShivAIEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(_StreamError(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$ShivAIState {

 ShivChatStatus get status; List<ShivConversationEntity> get conversations; ShivConversationEntity? get activeConversation; List<ShivMessageEntity> get messages;/// The streaming assistant message being built token-by-token.
/// Non-null only while [status] == [ShivChatStatus.streaming].
 String? get streamingContent;/// The messageId of the placeholder assistant message being streamed.
 String? get streamingMessageId; String? get errorMessage;
/// Create a copy of ShivAIState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShivAIStateCopyWith<ShivAIState> get copyWith => _$ShivAIStateCopyWithImpl<ShivAIState>(this as ShivAIState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShivAIState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.conversations, conversations)&&(identical(other.activeConversation, activeConversation) || other.activeConversation == activeConversation)&&const DeepCollectionEquality().equals(other.messages, messages)&&(identical(other.streamingContent, streamingContent) || other.streamingContent == streamingContent)&&(identical(other.streamingMessageId, streamingMessageId) || other.streamingMessageId == streamingMessageId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(conversations),activeConversation,const DeepCollectionEquality().hash(messages),streamingContent,streamingMessageId,errorMessage);

@override
String toString() {
  return 'ShivAIState(status: $status, conversations: $conversations, activeConversation: $activeConversation, messages: $messages, streamingContent: $streamingContent, streamingMessageId: $streamingMessageId, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $ShivAIStateCopyWith<$Res>  {
  factory $ShivAIStateCopyWith(ShivAIState value, $Res Function(ShivAIState) _then) = _$ShivAIStateCopyWithImpl;
@useResult
$Res call({
 ShivChatStatus status, List<ShivConversationEntity> conversations, ShivConversationEntity? activeConversation, List<ShivMessageEntity> messages, String? streamingContent, String? streamingMessageId, String? errorMessage
});


$ShivConversationEntityCopyWith<$Res>? get activeConversation;

}
/// @nodoc
class _$ShivAIStateCopyWithImpl<$Res>
    implements $ShivAIStateCopyWith<$Res> {
  _$ShivAIStateCopyWithImpl(this._self, this._then);

  final ShivAIState _self;
  final $Res Function(ShivAIState) _then;

/// Create a copy of ShivAIState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? conversations = null,Object? activeConversation = freezed,Object? messages = null,Object? streamingContent = freezed,Object? streamingMessageId = freezed,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShivChatStatus,conversations: null == conversations ? _self.conversations : conversations // ignore: cast_nullable_to_non_nullable
as List<ShivConversationEntity>,activeConversation: freezed == activeConversation ? _self.activeConversation : activeConversation // ignore: cast_nullable_to_non_nullable
as ShivConversationEntity?,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<ShivMessageEntity>,streamingContent: freezed == streamingContent ? _self.streamingContent : streamingContent // ignore: cast_nullable_to_non_nullable
as String?,streamingMessageId: freezed == streamingMessageId ? _self.streamingMessageId : streamingMessageId // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of ShivAIState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShivConversationEntityCopyWith<$Res>? get activeConversation {
    if (_self.activeConversation == null) {
    return null;
  }

  return $ShivConversationEntityCopyWith<$Res>(_self.activeConversation!, (value) {
    return _then(_self.copyWith(activeConversation: value));
  });
}
}


/// Adds pattern-matching-related methods to [ShivAIState].
extension ShivAIStatePatterns on ShivAIState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShivAIState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShivAIState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShivAIState value)  $default,){
final _that = this;
switch (_that) {
case _ShivAIState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShivAIState value)?  $default,){
final _that = this;
switch (_that) {
case _ShivAIState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ShivChatStatus status,  List<ShivConversationEntity> conversations,  ShivConversationEntity? activeConversation,  List<ShivMessageEntity> messages,  String? streamingContent,  String? streamingMessageId,  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShivAIState() when $default != null:
return $default(_that.status,_that.conversations,_that.activeConversation,_that.messages,_that.streamingContent,_that.streamingMessageId,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ShivChatStatus status,  List<ShivConversationEntity> conversations,  ShivConversationEntity? activeConversation,  List<ShivMessageEntity> messages,  String? streamingContent,  String? streamingMessageId,  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _ShivAIState():
return $default(_that.status,_that.conversations,_that.activeConversation,_that.messages,_that.streamingContent,_that.streamingMessageId,_that.errorMessage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ShivChatStatus status,  List<ShivConversationEntity> conversations,  ShivConversationEntity? activeConversation,  List<ShivMessageEntity> messages,  String? streamingContent,  String? streamingMessageId,  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _ShivAIState() when $default != null:
return $default(_that.status,_that.conversations,_that.activeConversation,_that.messages,_that.streamingContent,_that.streamingMessageId,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc


class _ShivAIState implements ShivAIState {
  const _ShivAIState({this.status = ShivChatStatus.idle, final  List<ShivConversationEntity> conversations = const [], this.activeConversation, final  List<ShivMessageEntity> messages = const [], this.streamingContent, this.streamingMessageId, this.errorMessage}): _conversations = conversations,_messages = messages;
  

@override@JsonKey() final  ShivChatStatus status;
 final  List<ShivConversationEntity> _conversations;
@override@JsonKey() List<ShivConversationEntity> get conversations {
  if (_conversations is EqualUnmodifiableListView) return _conversations;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_conversations);
}

@override final  ShivConversationEntity? activeConversation;
 final  List<ShivMessageEntity> _messages;
@override@JsonKey() List<ShivMessageEntity> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

/// The streaming assistant message being built token-by-token.
/// Non-null only while [status] == [ShivChatStatus.streaming].
@override final  String? streamingContent;
/// The messageId of the placeholder assistant message being streamed.
@override final  String? streamingMessageId;
@override final  String? errorMessage;

/// Create a copy of ShivAIState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShivAIStateCopyWith<_ShivAIState> get copyWith => __$ShivAIStateCopyWithImpl<_ShivAIState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShivAIState&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._conversations, _conversations)&&(identical(other.activeConversation, activeConversation) || other.activeConversation == activeConversation)&&const DeepCollectionEquality().equals(other._messages, _messages)&&(identical(other.streamingContent, streamingContent) || other.streamingContent == streamingContent)&&(identical(other.streamingMessageId, streamingMessageId) || other.streamingMessageId == streamingMessageId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}


@override
int get hashCode => Object.hash(runtimeType,status,const DeepCollectionEquality().hash(_conversations),activeConversation,const DeepCollectionEquality().hash(_messages),streamingContent,streamingMessageId,errorMessage);

@override
String toString() {
  return 'ShivAIState(status: $status, conversations: $conversations, activeConversation: $activeConversation, messages: $messages, streamingContent: $streamingContent, streamingMessageId: $streamingMessageId, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$ShivAIStateCopyWith<$Res> implements $ShivAIStateCopyWith<$Res> {
  factory _$ShivAIStateCopyWith(_ShivAIState value, $Res Function(_ShivAIState) _then) = __$ShivAIStateCopyWithImpl;
@override @useResult
$Res call({
 ShivChatStatus status, List<ShivConversationEntity> conversations, ShivConversationEntity? activeConversation, List<ShivMessageEntity> messages, String? streamingContent, String? streamingMessageId, String? errorMessage
});


@override $ShivConversationEntityCopyWith<$Res>? get activeConversation;

}
/// @nodoc
class __$ShivAIStateCopyWithImpl<$Res>
    implements _$ShivAIStateCopyWith<$Res> {
  __$ShivAIStateCopyWithImpl(this._self, this._then);

  final _ShivAIState _self;
  final $Res Function(_ShivAIState) _then;

/// Create a copy of ShivAIState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? conversations = null,Object? activeConversation = freezed,Object? messages = null,Object? streamingContent = freezed,Object? streamingMessageId = freezed,Object? errorMessage = freezed,}) {
  return _then(_ShivAIState(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ShivChatStatus,conversations: null == conversations ? _self._conversations : conversations // ignore: cast_nullable_to_non_nullable
as List<ShivConversationEntity>,activeConversation: freezed == activeConversation ? _self.activeConversation : activeConversation // ignore: cast_nullable_to_non_nullable
as ShivConversationEntity?,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<ShivMessageEntity>,streamingContent: freezed == streamingContent ? _self.streamingContent : streamingContent // ignore: cast_nullable_to_non_nullable
as String?,streamingMessageId: freezed == streamingMessageId ? _self.streamingMessageId : streamingMessageId // ignore: cast_nullable_to_non_nullable
as String?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of ShivAIState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ShivConversationEntityCopyWith<$Res>? get activeConversation {
    if (_self.activeConversation == null) {
    return null;
  }

  return $ShivConversationEntityCopyWith<$Res>(_self.activeConversation!, (value) {
    return _then(_self.copyWith(activeConversation: value));
  });
}
}

// dart format on
