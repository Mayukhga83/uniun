// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_record_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSubscriptionRecordModelCollection on Isar {
  IsarCollection<SubscriptionRecordModel> get subscriptionRecordModels =>
      this.collection();
}

const SubscriptionRecordModelSchema = CollectionSchema(
  name: r'SubscriptionRecord',
  id: -5833343487921943930,
  properties: {
    r'authors': PropertySchema(
      id: 0,
      name: r'authors',
      type: IsarType.stringList,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.long,
    ),
    r'eTags': PropertySchema(id: 2, name: r'eTags', type: IsarType.stringList),
    r'enabled': PropertySchema(id: 3, name: r'enabled', type: IsarType.bool),
    r'kinds': PropertySchema(id: 4, name: r'kinds', type: IsarType.longList),
    r'lastUntilByRelayJson': PropertySchema(
      id: 5,
      name: r'lastUntilByRelayJson',
      type: IsarType.string,
    ),
    r'limit': PropertySchema(id: 6, name: r'limit', type: IsarType.long),
    r'relays': PropertySchema(
      id: 7,
      name: r'relays',
      type: IsarType.stringList,
    ),
    r'updatedAt': PropertySchema(
      id: 8,
      name: r'updatedAt',
      type: IsarType.long,
    ),
  },

  estimateSize: _subscriptionRecordModelEstimateSize,
  serialize: _subscriptionRecordModelSerialize,
  deserialize: _subscriptionRecordModelDeserialize,
  deserializeProp: _subscriptionRecordModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'enabled': IndexSchema(
      id: -4605800638041043998,
      name: r'enabled',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'enabled',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _subscriptionRecordModelGetId,
  getLinks: _subscriptionRecordModelGetLinks,
  attach: _subscriptionRecordModelAttach,
  version: '3.3.2',
);

int _subscriptionRecordModelEstimateSize(
  SubscriptionRecordModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final list = object.authors;
    if (list != null) {
      bytesCount += 3 + list.length * 3;
      {
        for (var i = 0; i < list.length; i++) {
          final value = list[i];
          bytesCount += value.length * 3;
        }
      }
    }
  }
  bytesCount += 3 + object.eTags.length * 3;
  {
    for (var i = 0; i < object.eTags.length; i++) {
      final value = object.eTags[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.kinds.length * 8;
  bytesCount += 3 + object.lastUntilByRelayJson.length * 3;
  bytesCount += 3 + object.relays.length * 3;
  {
    for (var i = 0; i < object.relays.length; i++) {
      final value = object.relays[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _subscriptionRecordModelSerialize(
  SubscriptionRecordModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeStringList(offsets[0], object.authors);
  writer.writeLong(offsets[1], object.createdAt);
  writer.writeStringList(offsets[2], object.eTags);
  writer.writeBool(offsets[3], object.enabled);
  writer.writeLongList(offsets[4], object.kinds);
  writer.writeString(offsets[5], object.lastUntilByRelayJson);
  writer.writeLong(offsets[6], object.limit);
  writer.writeStringList(offsets[7], object.relays);
  writer.writeLong(offsets[8], object.updatedAt);
}

SubscriptionRecordModel _subscriptionRecordModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = SubscriptionRecordModel();
  object.authors = reader.readStringList(offsets[0]);
  object.createdAt = reader.readLong(offsets[1]);
  object.eTags = reader.readStringList(offsets[2]) ?? [];
  object.enabled = reader.readBool(offsets[3]);
  object.id = id;
  object.kinds = reader.readLongList(offsets[4]) ?? [];
  object.lastUntilByRelayJson = reader.readString(offsets[5]);
  object.limit = reader.readLongOrNull(offsets[6]);
  object.relays = reader.readStringList(offsets[7]) ?? [];
  object.updatedAt = reader.readLong(offsets[8]);
  return object;
}

P _subscriptionRecordModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readStringList(offset)) as P;
    case 1:
      return (reader.readLong(offset)) as P;
    case 2:
      return (reader.readStringList(offset) ?? []) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readLongList(offset) ?? []) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readStringList(offset) ?? []) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _subscriptionRecordModelGetId(SubscriptionRecordModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _subscriptionRecordModelGetLinks(
  SubscriptionRecordModel object,
) {
  return [];
}

void _subscriptionRecordModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  SubscriptionRecordModel object,
) {
  object.id = id;
}

extension SubscriptionRecordModelQueryWhereSort
    on QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QWhere> {
  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterWhere>
  anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterWhere>
  anyEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'enabled'),
      );
    });
  }
}

extension SubscriptionRecordModelQueryWhere
    on
        QueryBuilder<
          SubscriptionRecordModel,
          SubscriptionRecordModel,
          QWhereClause
        > {
  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterWhereClause
  >
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterWhereClause
  >
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

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterWhereClause
  >
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterWhereClause
  >
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterWhereClause
  >
  idBetween(
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

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterWhereClause
  >
  enabledEqualTo(bool enabled) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'enabled', value: [enabled]),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterWhereClause
  >
  enabledNotEqualTo(bool enabled) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'enabled',
                lower: [],
                upper: [enabled],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'enabled',
                lower: [enabled],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'enabled',
                lower: [enabled],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'enabled',
                lower: [],
                upper: [enabled],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension SubscriptionRecordModelQueryFilter
    on
        QueryBuilder<
          SubscriptionRecordModel,
          SubscriptionRecordModel,
          QFilterCondition
        > {
  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'authors'),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'authors'),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'authors',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'authors',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'authors',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'authors',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'authors',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'authors',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'authors',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'authors',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'authors', value: ''),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'authors', value: ''),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'authors', length, true, length, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'authors', 0, true, 0, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'authors', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'authors', 0, true, length, include);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'authors', length, include, 999999, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  authorsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'authors',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  createdAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createdAt', value: value),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  createdAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  createdAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createdAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  createdAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createdAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'eTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'eTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'eTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'eTags',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'eTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'eTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'eTags',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'eTags',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'eTags', value: ''),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'eTags', value: ''),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTags', length, true, length, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTags', 0, true, 0, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTags', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTags', 0, true, length, include);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'eTags', length, include, 999999, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  eTagsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'eTags',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  enabledEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'enabled', value: value),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
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

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  kindsElementEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'kinds', value: value),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  kindsElementGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'kinds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  kindsElementLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'kinds',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  kindsElementBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'kinds',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  kindsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'kinds', length, true, length, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  kindsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'kinds', 0, true, 0, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  kindsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'kinds', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  kindsLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'kinds', 0, true, length, include);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  kindsLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'kinds', length, include, 999999, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  kindsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'kinds',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  lastUntilByRelayJsonEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'lastUntilByRelayJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  lastUntilByRelayJsonGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'lastUntilByRelayJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  lastUntilByRelayJsonLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'lastUntilByRelayJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  lastUntilByRelayJsonBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'lastUntilByRelayJson',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  lastUntilByRelayJsonStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'lastUntilByRelayJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  lastUntilByRelayJsonEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'lastUntilByRelayJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  lastUntilByRelayJsonContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'lastUntilByRelayJson',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  lastUntilByRelayJsonMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'lastUntilByRelayJson',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  lastUntilByRelayJsonIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'lastUntilByRelayJson', value: ''),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  lastUntilByRelayJsonIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          property: r'lastUntilByRelayJson',
          value: '',
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  limitIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNull(property: r'limit'),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  limitIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        const FilterCondition.isNotNull(property: r'limit'),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  limitEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'limit', value: value),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  limitGreaterThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'limit',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  limitLessThan(int? value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'limit',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  limitBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'limit',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysElementEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'relays',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'relays',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'relays',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'relays',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysElementStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'relays',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysElementEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'relays',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'relays',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'relays',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'relays', value: ''),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'relays', value: ''),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'relays', length, true, length, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'relays', 0, true, 0, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'relays', 0, false, 999999, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'relays', 0, true, length, include);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'relays', length, include, 999999, true);
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  relaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'relays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  updatedAtEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updatedAt', value: value),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  updatedAtGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  updatedAtLessThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updatedAt',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<
    SubscriptionRecordModel,
    SubscriptionRecordModel,
    QAfterFilterCondition
  >
  updatedAtBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updatedAt',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension SubscriptionRecordModelQueryObject
    on
        QueryBuilder<
          SubscriptionRecordModel,
          SubscriptionRecordModel,
          QFilterCondition
        > {}

extension SubscriptionRecordModelQueryLinks
    on
        QueryBuilder<
          SubscriptionRecordModel,
          SubscriptionRecordModel,
          QFilterCondition
        > {}

extension SubscriptionRecordModelQuerySortBy
    on QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QSortBy> {
  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  sortByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  sortByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  sortByLastUntilByRelayJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUntilByRelayJson', Sort.asc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  sortByLastUntilByRelayJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUntilByRelayJson', Sort.desc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  sortByLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limit', Sort.asc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  sortByLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limit', Sort.desc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SubscriptionRecordModelQuerySortThenBy
    on
        QueryBuilder<
          SubscriptionRecordModel,
          SubscriptionRecordModel,
          QSortThenBy
        > {
  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.asc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenByEnabledDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'enabled', Sort.desc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenByLastUntilByRelayJson() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUntilByRelayJson', Sort.asc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenByLastUntilByRelayJsonDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUntilByRelayJson', Sort.desc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenByLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limit', Sort.asc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenByLimitDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'limit', Sort.desc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QAfterSortBy>
  thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension SubscriptionRecordModelQueryWhereDistinct
    on
        QueryBuilder<
          SubscriptionRecordModel,
          SubscriptionRecordModel,
          QDistinct
        > {
  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QDistinct>
  distinctByAuthors() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'authors');
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QDistinct>
  distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QDistinct>
  distinctByETags() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eTags');
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QDistinct>
  distinctByEnabled() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'enabled');
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QDistinct>
  distinctByKinds() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'kinds');
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QDistinct>
  distinctByLastUntilByRelayJson({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(
        r'lastUntilByRelayJson',
        caseSensitive: caseSensitive,
      );
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QDistinct>
  distinctByLimit() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'limit');
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QDistinct>
  distinctByRelays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relays');
    });
  }

  QueryBuilder<SubscriptionRecordModel, SubscriptionRecordModel, QDistinct>
  distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension SubscriptionRecordModelQueryProperty
    on
        QueryBuilder<
          SubscriptionRecordModel,
          SubscriptionRecordModel,
          QQueryProperty
        > {
  QueryBuilder<SubscriptionRecordModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<SubscriptionRecordModel, List<String>?, QQueryOperations>
  authorsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'authors');
    });
  }

  QueryBuilder<SubscriptionRecordModel, int, QQueryOperations>
  createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<SubscriptionRecordModel, List<String>, QQueryOperations>
  eTagsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eTags');
    });
  }

  QueryBuilder<SubscriptionRecordModel, bool, QQueryOperations>
  enabledProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'enabled');
    });
  }

  QueryBuilder<SubscriptionRecordModel, List<int>, QQueryOperations>
  kindsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'kinds');
    });
  }

  QueryBuilder<SubscriptionRecordModel, String, QQueryOperations>
  lastUntilByRelayJsonProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUntilByRelayJson');
    });
  }

  QueryBuilder<SubscriptionRecordModel, int?, QQueryOperations>
  limitProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'limit');
    });
  }

  QueryBuilder<SubscriptionRecordModel, List<String>, QQueryOperations>
  relaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relays');
    });
  }

  QueryBuilder<SubscriptionRecordModel, int, QQueryOperations>
  updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
