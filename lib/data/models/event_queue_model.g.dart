// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_queue_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetEventQueueModelCollection on Isar {
  IsarCollection<EventQueueModel> get eventQueueModels => this.collection();
}

const EventQueueModelSchema = CollectionSchema(
  name: r'EventQueue',
  id: 8017143989177430287,
  properties: {
    r'authorPubkey': PropertySchema(
      id: 0,
      name: r'authorPubkey',
      type: IsarType.string,
    ),
    r'content': PropertySchema(id: 1, name: r'content', type: IsarType.string),
    r'created': PropertySchema(
      id: 2,
      name: r'created',
      type: IsarType.dateTime,
    ),
    r'eTagRefs': PropertySchema(
      id: 3,
      name: r'eTagRefs',
      type: IsarType.stringList,
    ),
    r'enqueuedAt': PropertySchema(
      id: 4,
      name: r'enqueuedAt',
      type: IsarType.dateTime,
    ),
    r'eventId': PropertySchema(id: 5, name: r'eventId', type: IsarType.string),
    r'kind': PropertySchema(id: 6, name: r'kind', type: IsarType.long),
    r'pTagRefs': PropertySchema(
      id: 7,
      name: r'pTagRefs',
      type: IsarType.stringList,
    ),
    r'replyToEventId': PropertySchema(
      id: 8,
      name: r'replyToEventId',
      type: IsarType.string,
    ),
    r'rootEventId': PropertySchema(
      id: 9,
      name: r'rootEventId',
      type: IsarType.string,
    ),
    r'sentCount': PropertySchema(
      id: 10,
      name: r'sentCount',
      type: IsarType.long,
    ),
    r'sig': PropertySchema(id: 11, name: r'sig', type: IsarType.string),
    r'tTags': PropertySchema(id: 12, name: r'tTags', type: IsarType.stringList),
  },

  estimateSize: _eventQueueModelEstimateSize,
  serialize: _eventQueueModelSerialize,
  deserialize: _eventQueueModelDeserialize,
  deserializeProp: _eventQueueModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'eventId': IndexSchema(
      id: -2707901133518603130,
      name: r'eventId',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'eventId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _eventQueueModelGetId,
  getLinks: _eventQueueModelGetLinks,
  attach: _eventQueueModelAttach,
  version: '3.3.2',
);

int _eventQueueModelEstimateSize(
  EventQueueModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.authorPubkey.length * 3;
  bytesCount += 3 + object.content.length * 3;
  bytesCount += 3 + object.eTagRefs.length * 3;
  {
    for (var i = 0; i < object.eTagRefs.length; i++) {
      final value = object.eTagRefs[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.eventId.length * 3;
  bytesCount += 3 + object.pTagRefs.length * 3;
  {
    for (var i = 0; i < object.pTagRefs.length; i++) {
      final value = object.pTagRefs[i];
      bytesCount += value.length * 3;
    }
  }
  {
    final value = object.replyToEventId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.rootEventId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.sig.length * 3;
  bytesCount += 3 + object.tTags.length * 3;
  {
    for (var i = 0; i < object.tTags.length; i++) {
      final value = object.tTags[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _eventQueueModelSerialize(
  EventQueueModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.authorPubkey);
  writer.writeString(offsets[1], object.content);
  writer.writeDateTime(offsets[2], object.created);
  writer.writeStringList(offsets[3], object.eTagRefs);
  writer.writeDateTime(offsets[4], object.enqueuedAt);
  writer.writeString(offsets[5], object.eventId);
  writer.writeLong(offsets[6], object.kind);
  writer.writeStringList(offsets[7], object.pTagRefs);
  writer.writeString(offsets[8], object.replyToEventId);
  writer.writeString(offsets[9], object.rootEventId);
  writer.writeLong(offsets[10], object.sentCount);
  writer.writeString(offsets[11], object.sig);
  writer.writeStringList(offsets[12], object.tTags);
}

EventQueueModel _eventQueueModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = EventQueueModel();
  object.authorPubkey = reader.readString(offsets[0]);
  object.content = reader.readString(offsets[1]);
  object.created = reader.readDateTime(offsets[2]);
  object.eTagRefs = reader.readStringList(offsets[3]) ?? [];
  object.enqueuedAt = reader.readDateTime(offsets[4]);
  object.eventId = reader.readString(offsets[5]);
  object.id = id;
  object.kind = reader.readLong(offsets[6]);
  object.pTagRefs = reader.readStringList(offsets[7]) ?? [];
  object.replyToEventId = reader.readStringOrNull(offsets[8]);
  object.rootEventId = reader.readStringOrNull(offsets[9]);
  object.sentCount = reader.readLong(offsets[10]);
  object.sig = reader.readString(offsets[11]);
  object.tTags = reader.readStringList(offsets[12]) ?? [];
  return object;
}

P _eventQueueModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (reader.readStringList(offset) ?? []) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readStringList(offset) ?? []) as P;
    case 8:
      return (reader.readStringOrNull(offset)) as P;
    case 9:
      return (reader.readStringOrNull(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _eventQueueModelGetId(EventQueueModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _eventQueueModelGetLinks(EventQueueModel object) {
  return [];
}

void _eventQueueModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  EventQueueModel object,
) {
  object.id = id;
}

extension EventQueueModelByIndex on IsarCollection<EventQueueModel> {
  Future<EventQueueModel?> getByEventId(String eventId) {
    return getByIndex(r'eventId', [eventId]);
  }

  EventQueueModel? getByEventIdSync(String eventId) {
    return getByIndexSync(r'eventId', [eventId]);
  }

  Future<bool> deleteByEventId(String eventId) {
    return deleteByIndex(r'eventId', [eventId]);
  }

  bool deleteByEventIdSync(String eventId) {
    return deleteByIndexSync(r'eventId', [eventId]);
  }

  Future<List<EventQueueModel?>> getAllByEventId(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return getAllByIndex(r'eventId', values);
  }

  List<EventQueueModel?> getAllByEventIdSync(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'eventId', values);
  }

  Future<int> deleteAllByEventId(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'eventId', values);
  }

  int deleteAllByEventIdSync(List<String> eventIdValues) {
    final values = eventIdValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'eventId', values);
  }

  Future<Id> putByEventId(EventQueueModel object) {
    return putByIndex(r'eventId', object);
  }

  Id putByEventIdSync(EventQueueModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'eventId', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByEventId(List<EventQueueModel> objects) {
    return putAllByIndex(r'eventId', objects);
  }

  List<Id> putAllByEventIdSync(
    List<EventQueueModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'eventId', objects, saveLinks: saveLinks);
  }
}

extension EventQueueModelQueryWhereSort
    on QueryBuilder<EventQueueModel, EventQueueModel, QWhere> {
  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension EventQueueModelQueryWhere
    on QueryBuilder<EventQueueModel, EventQueueModel, QWhereClause> {
  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause> idEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause>
  idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause>
  eventIdEqualTo(String eventId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'eventId', value: [eventId]),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterWhereClause>
  eventIdNotEqualTo(String eventId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [],
                upper: [eventId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [eventId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [eventId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'eventId',
                lower: [],
                upper: [eventId],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension EventQueueModelQueryFilter
    on QueryBuilder<EventQueueModel, EventQueueModel, QFilterCondition> {
  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  authorPubkeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  authorPubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  authorPubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  authorPubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'authorPubkey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  authorPubkeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  authorPubkeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  authorPubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'authorPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  authorPubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'authorPubkey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  authorPubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'authorPubkey', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  authorPubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'authorPubkey', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  contentEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  contentGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  contentLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  contentBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'content',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  contentStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  contentEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  contentContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'content',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  contentMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'content',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  contentIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  contentIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'content', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  createdEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'created', value: value),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  createdGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'created',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  createdLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'created',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  createdBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'created',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eTagRefs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'eTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'eTagRefs',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eTagRefs', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eTagRefs', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTagRefs', length, true, length, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTagRefs', 0, true, 0, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTagRefs', 0, false, 999999, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTagRefs', 0, true, length, include);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTagRefs', length, include, 999999, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eTagRefsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'eTagRefs',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  enqueuedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'enqueuedAt', value: value),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  enqueuedAtGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'enqueuedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  enqueuedAtLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'enqueuedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  enqueuedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'enqueuedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eventId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'eventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'eventId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eventId', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  eventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eventId', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  idGreaterThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  idLessThan(Id value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  kindEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kind', value: value),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  kindGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kind',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  kindLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kind',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  kindBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kind',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'pTagRefs',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'pTagRefs',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'pTagRefs',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'pTagRefs', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'pTagRefs', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pTagRefs', length, true, length, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pTagRefs', 0, true, 0, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pTagRefs', 0, false, 999999, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pTagRefs', 0, true, length, include);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'pTagRefs', length, include, 999999, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  pTagRefsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'pTagRefs',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'replyToEventId'),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'replyToEventId'),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'replyToEventId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'replyToEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'replyToEventId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'replyToEventId', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  replyToEventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'replyToEventId', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'rootEventId'),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'rootEventId'),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdEqualTo(String? value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'rootEventId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'rootEventId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'rootEventId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'rootEventId', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  rootEventIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'rootEventId', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sentCountEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sentCount', value: value),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sentCountGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sentCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sentCountLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sentCount',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sentCountBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sentCount',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sigEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sigGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sigLessThan(String value, {bool include = false, bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sigBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sig',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sigStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sigEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sigContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sig',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sigMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sig',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sigIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sig', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  sigIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sig', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'tTags',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'tTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'tTags',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'tTags', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'tTags', value: ''),
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tTags', length, true, length, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tTags', 0, true, 0, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tTags', 0, false, 999999, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tTags', 0, true, length, include);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'tTags', length, include, 999999, true);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterFilterCondition>
  tTagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'tTags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension EventQueueModelQueryObject
    on QueryBuilder<EventQueueModel, EventQueueModel, QFilterCondition> {}

extension EventQueueModelQueryLinks
    on QueryBuilder<EventQueueModel, EventQueueModel, QFilterCondition> {}

extension EventQueueModelQuerySortBy
    on QueryBuilder<EventQueueModel, EventQueueModel, QSortBy> {
  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByAuthorPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorPubkey', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByAuthorPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorPubkey', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> sortByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> sortByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByEnqueuedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueuedAt', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByEnqueuedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueuedAt', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> sortByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> sortByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByReplyToEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToEventId', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByReplyToEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToEventId', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByRootEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rootEventId', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortByRootEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rootEventId', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortBySentCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentCount', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  sortBySentCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentCount', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> sortBySig() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sig', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> sortBySigDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sig', Sort.desc);
    });
  }
}

extension EventQueueModelQuerySortThenBy
    on QueryBuilder<EventQueueModel, EventQueueModel, QSortThenBy> {
  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByAuthorPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorPubkey', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByAuthorPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'authorPubkey', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> thenByContent() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByContentDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'content', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> thenByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByCreatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'created', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByEnqueuedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueuedAt', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByEnqueuedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enqueuedAt', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> thenByEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eventId', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> thenByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByKindDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'kind', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByReplyToEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToEventId', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByReplyToEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'replyToEventId', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByRootEventId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rootEventId', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenByRootEventIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'rootEventId', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenBySentCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentCount', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy>
  thenBySentCountDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sentCount', Sort.desc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> thenBySig() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sig', Sort.asc);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QAfterSortBy> thenBySigDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sig', Sort.desc);
    });
  }
}

extension EventQueueModelQueryWhereDistinct
    on QueryBuilder<EventQueueModel, EventQueueModel, QDistinct> {
  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct>
  distinctByAuthorPubkey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'authorPubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct> distinctByContent({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'content', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct>
  distinctByCreated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'created');
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct>
  distinctByETagRefs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eTagRefs');
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct>
  distinctByEnqueuedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enqueuedAt');
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct> distinctByEventId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eventId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct> distinctByKind() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kind');
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct>
  distinctByPTagRefs() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'pTagRefs');
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct>
  distinctByReplyToEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'replyToEventId',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct>
  distinctByRootEventId({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'rootEventId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct>
  distinctBySentCount() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sentCount');
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct> distinctBySig({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sig', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<EventQueueModel, EventQueueModel, QDistinct> distinctByTTags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tTags');
    });
  }
}

extension EventQueueModelQueryProperty
    on QueryBuilder<EventQueueModel, EventQueueModel, QQueryProperty> {
  QueryBuilder<EventQueueModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<EventQueueModel, String, QQueryOperations>
  authorPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'authorPubkey');
    });
  }

  QueryBuilder<EventQueueModel, String, QQueryOperations> contentProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'content');
    });
  }

  QueryBuilder<EventQueueModel, DateTime, QQueryOperations> createdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'created');
    });
  }

  QueryBuilder<EventQueueModel, List<String>, QQueryOperations>
  eTagRefsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eTagRefs');
    });
  }

  QueryBuilder<EventQueueModel, DateTime, QQueryOperations>
  enqueuedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enqueuedAt');
    });
  }

  QueryBuilder<EventQueueModel, String, QQueryOperations> eventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eventId');
    });
  }

  QueryBuilder<EventQueueModel, int, QQueryOperations> kindProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kind');
    });
  }

  QueryBuilder<EventQueueModel, List<String>, QQueryOperations>
  pTagRefsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'pTagRefs');
    });
  }

  QueryBuilder<EventQueueModel, String?, QQueryOperations>
  replyToEventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'replyToEventId');
    });
  }

  QueryBuilder<EventQueueModel, String?, QQueryOperations>
  rootEventIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'rootEventId');
    });
  }

  QueryBuilder<EventQueueModel, int, QQueryOperations> sentCountProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sentCount');
    });
  }

  QueryBuilder<EventQueueModel, String, QQueryOperations> sigProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sig');
    });
  }

  QueryBuilder<EventQueueModel, List<String>, QQueryOperations>
  tTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tTags');
    });
  }
}
