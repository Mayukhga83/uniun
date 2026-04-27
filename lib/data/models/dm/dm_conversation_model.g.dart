// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dm_conversation_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDmConversationModelCollection on Isar {
  IsarCollection<DmConversationModel> get dmConversationModels =>
      this.collection();
}

const DmConversationModelSchema = CollectionSchema(
  name: r'DmConversation',
  id: -335175152521103665,
  properties: {
    r'otherPubkey': PropertySchema(
      id: 0,
      name: r'otherPubkey',
      type: IsarType.string,
    ),
    r'relays': PropertySchema(
      id: 1,
      name: r'relays',
      type: IsarType.stringList,
    ),
  },

  estimateSize: _dmConversationModelEstimateSize,
  serialize: _dmConversationModelSerialize,
  deserialize: _dmConversationModelDeserialize,
  deserializeProp: _dmConversationModelDeserializeProp,
  idName: r'id',
  indexes: {
    r'otherPubkey': IndexSchema(
      id: 9140102187253743011,
      name: r'otherPubkey',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'otherPubkey',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _dmConversationModelGetId,
  getLinks: _dmConversationModelGetLinks,
  attach: _dmConversationModelAttach,
  version: '3.3.2',
);

int _dmConversationModelEstimateSize(
  DmConversationModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.otherPubkey.length * 3;
  bytesCount += 3 + object.relays.length * 3;
  {
    for (var i = 0; i < object.relays.length; i++) {
      final value = object.relays[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _dmConversationModelSerialize(
  DmConversationModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.otherPubkey);
  writer.writeStringList(offsets[1], object.relays);
}

DmConversationModel _dmConversationModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DmConversationModel();
  object.id = id;
  object.otherPubkey = reader.readString(offsets[0]);
  object.relays = reader.readStringList(offsets[1]) ?? [];
  return object;
}

P _dmConversationModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _dmConversationModelGetId(DmConversationModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _dmConversationModelGetLinks(
  DmConversationModel object,
) {
  return [];
}

void _dmConversationModelAttach(
  IsarCollection<dynamic> col,
  Id id,
  DmConversationModel object,
) {
  object.id = id;
}

extension DmConversationModelByIndex on IsarCollection<DmConversationModel> {
  Future<DmConversationModel?> getByOtherPubkey(String otherPubkey) {
    return getByIndex(r'otherPubkey', [otherPubkey]);
  }

  DmConversationModel? getByOtherPubkeySync(String otherPubkey) {
    return getByIndexSync(r'otherPubkey', [otherPubkey]);
  }

  Future<bool> deleteByOtherPubkey(String otherPubkey) {
    return deleteByIndex(r'otherPubkey', [otherPubkey]);
  }

  bool deleteByOtherPubkeySync(String otherPubkey) {
    return deleteByIndexSync(r'otherPubkey', [otherPubkey]);
  }

  Future<List<DmConversationModel?>> getAllByOtherPubkey(
    List<String> otherPubkeyValues,
  ) {
    final values = otherPubkeyValues.map((e) => [e]).toList();
    return getAllByIndex(r'otherPubkey', values);
  }

  List<DmConversationModel?> getAllByOtherPubkeySync(
    List<String> otherPubkeyValues,
  ) {
    final values = otherPubkeyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'otherPubkey', values);
  }

  Future<int> deleteAllByOtherPubkey(List<String> otherPubkeyValues) {
    final values = otherPubkeyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'otherPubkey', values);
  }

  int deleteAllByOtherPubkeySync(List<String> otherPubkeyValues) {
    final values = otherPubkeyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'otherPubkey', values);
  }

  Future<Id> putByOtherPubkey(DmConversationModel object) {
    return putByIndex(r'otherPubkey', object);
  }

  Id putByOtherPubkeySync(DmConversationModel object, {bool saveLinks = true}) {
    return putByIndexSync(r'otherPubkey', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByOtherPubkey(List<DmConversationModel> objects) {
    return putAllByIndex(r'otherPubkey', objects);
  }

  List<Id> putAllByOtherPubkeySync(
    List<DmConversationModel> objects, {
    bool saveLinks = true,
  }) {
    return putAllByIndexSync(r'otherPubkey', objects, saveLinks: saveLinks);
  }
}

extension DmConversationModelQueryWhereSort
    on QueryBuilder<DmConversationModel, DmConversationModel, QWhere> {
  QueryBuilder<DmConversationModel, DmConversationModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension DmConversationModelQueryWhere
    on QueryBuilder<DmConversationModel, DmConversationModel, QWhereClause> {
  QueryBuilder<DmConversationModel, DmConversationModel, QAfterWhereClause>
  idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterWhereClause>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterWhereClause>
  idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterWhereClause>
  idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterWhereClause>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterWhereClause>
  otherPubkeyEqualTo(String otherPubkey) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'otherPubkey',
          value: [otherPubkey],
        ),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterWhereClause>
  otherPubkeyNotEqualTo(String otherPubkey) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'otherPubkey',
                lower: [],
                upper: [otherPubkey],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'otherPubkey',
                lower: [otherPubkey],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'otherPubkey',
                lower: [otherPubkey],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'otherPubkey',
                lower: [],
                upper: [otherPubkey],
                includeUpper: false,
              ),
            );
      }
    });
  }
}

extension DmConversationModelQueryFilter
    on
        QueryBuilder<
          DmConversationModel,
          DmConversationModel,
          QFilterCondition
        > {
  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  otherPubkeyEqualTo(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'otherPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  otherPubkeyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'otherPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  otherPubkeyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'otherPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  otherPubkeyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'otherPubkey',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  otherPubkeyStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'otherPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  otherPubkeyEndsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'otherPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  otherPubkeyContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'otherPubkey',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  otherPubkeyMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'otherPubkey',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  otherPubkeyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'otherPubkey', value: ''),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  otherPubkeyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'otherPubkey', value: ''),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  relaysElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'relays', value: ''),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  relaysElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'relays', value: ''),
      );
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  relaysLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'relays', length, true, length, true);
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  relaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'relays', 0, true, 0, true);
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  relaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'relays', 0, false, 999999, true);
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  relaysLengthLessThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'relays', 0, true, length, include);
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
  relaysLengthGreaterThan(int length, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(r'relays', length, include, 999999, true);
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterFilterCondition>
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
}

extension DmConversationModelQueryObject
    on
        QueryBuilder<
          DmConversationModel,
          DmConversationModel,
          QFilterCondition
        > {}

extension DmConversationModelQueryLinks
    on
        QueryBuilder<
          DmConversationModel,
          DmConversationModel,
          QFilterCondition
        > {}

extension DmConversationModelQuerySortBy
    on QueryBuilder<DmConversationModel, DmConversationModel, QSortBy> {
  QueryBuilder<DmConversationModel, DmConversationModel, QAfterSortBy>
  sortByOtherPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherPubkey', Sort.asc);
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterSortBy>
  sortByOtherPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherPubkey', Sort.desc);
    });
  }
}

extension DmConversationModelQuerySortThenBy
    on QueryBuilder<DmConversationModel, DmConversationModel, QSortThenBy> {
  QueryBuilder<DmConversationModel, DmConversationModel, QAfterSortBy>
  thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterSortBy>
  thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterSortBy>
  thenByOtherPubkey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherPubkey', Sort.asc);
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QAfterSortBy>
  thenByOtherPubkeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'otherPubkey', Sort.desc);
    });
  }
}

extension DmConversationModelQueryWhereDistinct
    on QueryBuilder<DmConversationModel, DmConversationModel, QDistinct> {
  QueryBuilder<DmConversationModel, DmConversationModel, QDistinct>
  distinctByOtherPubkey({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'otherPubkey', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<DmConversationModel, DmConversationModel, QDistinct>
  distinctByRelays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'relays');
    });
  }
}

extension DmConversationModelQueryProperty
    on QueryBuilder<DmConversationModel, DmConversationModel, QQueryProperty> {
  QueryBuilder<DmConversationModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<DmConversationModel, String, QQueryOperations>
  otherPubkeyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'otherPubkey');
    });
  }

  QueryBuilder<DmConversationModel, List<String>, QQueryOperations>
  relaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'relays');
    });
  }
}
