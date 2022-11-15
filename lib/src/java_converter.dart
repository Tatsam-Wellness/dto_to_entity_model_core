import 'dart:io';

import 'package:dto_to_entity_model_core/src/commons.dart';
import 'package:dto_to_entity_model_core/src/converter_facade.dart';
import 'package:dto_to_entity_model_core/src/entity_template_filler.dart';
import 'package:dto_to_entity_model_core/src/generated.dart';
import 'package:dto_to_entity_model_core/src/model_template_filler.dart';


class JavaConverter implements CoverterFacade {
  @override
  String get lang => "java";

  @override
  Future<void> execute(List<String> args) async {
    assert(args.isNotEmpty);

    final inputFileArg = args.first.split('=');
    final inputFileSupplied =
        inputArgNames.contains(inputFileArg.first.trim()) &&
            inputFileArg[1].isNotEmpty;
    if (inputFileSupplied) {
      final inputFileName = inputFileArg[1].trim();
      final inputFile = File(inputFileName);
      await processInputFile(inputFile);
    } else {
      throw Exception(
          'Please use --input or -i to supply a valid input JAVA DTO file');
    }
  }

  @override
  Future<void> processInputFile(File input) async {
    // Parse
    final result = parseFile(await input.readAsString());

    // Save
    final entitySaveLocation =
        'generated/${result.entityTemplateFiller.entityName.toLowerCase()}.dart';
    final modelSaveLocation =
        'generated/${result.modelTemplateFiller.modelName.toLowerCase()}.dart';

    await result.entityTemplateFiller.generateFile(entitySaveLocation);
    await result.modelTemplateFiller.generateFile(modelSaveLocation);
  }

  @override
  Generated parseFile(String dtoStr) {
    final contents = dtoStr.split('%% class');
    final classBody = contents[1].split('\n');

    final entityName = classBody.first.trim();
    final _entityFileName = "${entityName.toLowerCase()}.dart";

    final modelName = "${entityName}Model";

    classBody.removeRange(0, 2);
    final javaClassFields =
        classBody.join('\n').replaceAll("{", "").replaceAll("}", "").trim();

    /// Conversion of java data-types to dart's
    final dartClassFields = javaClassFields
        .replaceAll("DTO", "")
        .replaceAll("private", "final")
        .replaceAll("UUID", "String")
        .replaceAll("long", "int")
        .split('\n');

    final entityFiller = EntityTemplateFiller(
      entityName: entityName,
      fields: dartClassFields,
      constructorFields: generateConstructor(entityName, dartClassFields),
      equality: generateEquality(entityName, dartClassFields),
      generatedHashCode: generateHashCode(dartClassFields),
      toStr: generateToString(entityName, dartClassFields),
    );

    final modelFiller = ModelTemplateFiller(
      entityName: entityName,
      modelName: modelName,
      entityFileName: _entityFileName,
      generatedFields: convertToModelFields(
        dartClassFields,
      ),
      generatedToDomain: generateToDomain(
        entityName,
        modelName,
        dartClassFields,
      ),
      generatedToJson: generateToJson(
        dartClassFields,
      ),
      generatedFromDomain: generateFromDomain(
        entityName,
        modelName,
        dartClassFields,
      ),
      generatedFromJson: generateFromJson(
        entityName,
        modelName,
        dartClassFields,
      ),
    );

    return Generated(
      entityTemplateFiller: entityFiller,
      modelTemplateFiller: modelFiller,
    );
  }

  @override
  List<String> generateFromJson(
    String entityName,
    String modelName,
    List<String> fields,
  ) {
    final _fromJsonLines = <String>[];

    /// Adding header
    _fromJsonLines.add("$modelName.fromJson(Map<String, dynamic> json)\n:");

    for (int i = 0; i < fields.length; i++) {
      final lastField = i == (fields.length - 1);

      final field = fields[i].trim().replaceAll(";", "").split(" ");

      final fieldDataType = field[1];
      final fieldName = field[2];

      _fromJsonLines.add('$fieldName = json["$fieldName"] as $fieldDataType?');

      if (lastField) {
        _fromJsonLines.add(';\n');
      } else {
        _fromJsonLines.add(',\n');
      }
    }

    return _fromJsonLines;
  }

  @override
  List<String> generateFromDomain(
    String entityName,
    String modelName,
    List<String> fields,
  ) {
    final _fromDomainLines = <String>[];

    /// Adding header
    _fromDomainLines.add("$modelName.fromDomain($entityName domain)\n:");

    for (int i = 0; i < fields.length; i++) {
      final lastField = i == (fields.length - 1);

      final field = fields[i].trim().replaceAll(";", "").split(" ");

      final fieldName = field[2];
      _fromDomainLines.add('$fieldName = domain.$fieldName');

      if (lastField) {
        _fromDomainLines.add(';\n');
      } else {
        _fromDomainLines.add(',\n');
      }
    }

    return _fromDomainLines;
  }

  @override
  List<String> generateToJson(
    List<String> fields,
  ) {
    final _toJsonLines = <String>[];

    for (int i = 0; i < fields.length; i++) {
      final field = fields[i].trim().replaceAll(";", "").split(" ");

      final fieldName = field[2];
      _toJsonLines.add('"$fieldName": $fieldName,\n');
    }

    return _toJsonLines;
  }

  @override
  List<String> generateToDomain(
    String entityName,
    String modelName,
    List<String> fields,
  ) {
    final List<String> _toDomainLines = [];

    for (int i = 0; i < fields.length; i++) {
      final field = fields[i].trim().replaceAll(";", "").split(" ");

      final fieldName = field[2];
      _toDomainLines.add('checkIfNull($fieldName, "$fieldName", _logger);');
    }
    _toDomainLines.add("\n");
    _toDomainLines.add("return $entityName(\n");

    /// returning entity
    for (int i = 0; i < fields.length; i++) {
      final field = fields[i].trim().replaceAll(";", "").split(" ");

      final fieldName = field[2];
      _toDomainLines.add('$fieldName: $fieldName!,\n');
    }
    _toDomainLines.add(");\n");

    return _toDomainLines;
  }

  @override
  List<String> convertToModelFields(List<String> fields) {
    final List<String> _modelFields = [];

    for (int i = 0; i < fields.length; i++) {
      final field = fields[i].trim().split(" ");

      final fieldDataType = field[1];
      final fieldName = field[2];

      _modelFields.add("$fieldDataType? $fieldName");
    }

    return _modelFields;
  }

  @override
  List<String> generateConstructor(String className, List<String> fields) {
    final List<String> _constructerFields = <String>[];
    for (int i = 0; i < fields.length; i++) {
      final line = fields[i].trim().split(' ');
      final fieldName = line[2].replaceAll(';', ',');
      _constructerFields.add("required this.$fieldName");
    }

    return _constructerFields;
  }

  @override
  List<String> generateToString(String className, List<String> fields) {
    final List<String> _stringifiedFields = [];
    for (int i = 0; i < fields.length; i++) {
      final line = fields[i].trim().split(' ');
      final fieldName = line[2].replaceAll(';', ',').replaceAll('\n', '');
      _stringifiedFields.add("$fieldName: \$$fieldName");
    }

    return [
      "'$className(",
      ..._stringifiedFields,
      ")'",
    ];
  }

  @override
  List<String> generateHashCode(List<String> fields) {
    final List<String> _hashedFields = <String>[];
    for (int i = 0; i < fields.length; i++) {
      final lastField = i == (fields.length - 1);
      final line = fields[i].trim().split(' ');
      final fieldName = line[2].replaceAll(';', '').replaceAll('\n', '');
      if (lastField) {
        _hashedFields.add("$fieldName.hashCode\n");
      } else {
        _hashedFields.add("$fieldName.hashCode ^\n");
      }
    }

    return [
      ..._hashedFields,
    ];
  }

    @override
  List<String> generateEquality(String className, List<String> fields) {
    final List<String> _equalizedFields = <String>[];
    for (int i = 0; i < fields.length; i++) {
      final lastField = i == (fields.length - 1);
      final line = fields[i].trim().split(' ');
      final fieldName = line[2].replaceAll(';', '').replaceAll('\n', '');
      if (lastField) {
        _equalizedFields.add("other.$fieldName == $fieldName\n");
      } else {
        _equalizedFields.add("other.$fieldName == $fieldName &&\n");
      }
    }

    return [
      "if (identical(this, other)) return true;\n",
      "return other is $className &&",
      ..._equalizedFields,
      ";",
    ];
  }
  

}
