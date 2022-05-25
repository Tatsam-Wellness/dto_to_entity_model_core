import 'dart:io';

import 'package:dto_to_entity_model_core/src/generated.dart';

const _outputDir = '_generated/';
const _inputArgNames = ['--input', '-i'];
// const _dartPrimitives = ['int','double','String','bool'];

class DTOToEntityModelCore {
  /// --input = "filename"
  /// For command line usage
  Future<void> execute(List<String> args) async {
    assert(args.isNotEmpty);

    final inputFileArg = args.first.split('=');
    final inputFileSupplied =
        _inputArgNames.contains(inputFileArg.first.trim()) &&
            inputFileArg[1].isNotEmpty;
    if (inputFileSupplied) {
      final inputFileName = inputFileArg[1].trim();
      final inputFile = File(inputFileName);
      await _processInputFile(inputFile);
    } else {
      throw Exception(
          'Please use --input or -i to supply a valid input JAVA DTO file');
    }
  }

  /// Converts the given DTO file to App's Entity and Model
  /// And Saves in [_outputDir]
  /// Internally used by command line entrypoint
  Future<void> _processInputFile(File input) async {
    final contents = (await input.readAsString()).split('%% class');
    final classBody = contents[1].split('\n');

    final entityName = classBody.first.trim();
    final _entityFileName = "${entityName.toLowerCase()}.dart";

    final modelName = "${entityName}Model";
    final _modelFileName = "${modelName.toLowerCase()}.dart";

    final _generated = processString(await input.readAsString());
    await _saveFile(_entityFileName, _generated.entity);
    await _saveFile(_modelFileName, _generated.model);
  }

  /// App's UI directly uses it as engine for conversion
  Generated processString(String dtoStr) {
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

    /// Entity generation
    final _entity = _generateEntity(entityName, dartClassFields);

    /// Model generation
    final _model =
        _generateModel(entityName, _entityFileName, modelName, dartClassFields);

    return Generated(
      inputDTO: dtoStr,
      entity: _entity,
      model: _model,
    );
  }

  String _generateModel(
    String entityName,
    String entityFileName,
    String modelName,
    List<String> fields,
  ) {
    return [
      "import 'package:tatsam_app_experimental/core/logger/logger.dart';",
      "import 'package:tatsam_app_experimental/core/utils/helper_functions/check_if_null.dart';",
      "import 'package:tatsam_app_experimental/features/view-all-content/data/models/data-model.dart';",
      "import '$entityFileName';",
      '\n',
      'class $modelName extends DataModel<$entityName> {',
      _convertToModelFields(fields),
      _placeLogger(modelName),
      _generateToDomain(entityName, modelName, fields),
      _generateToJson(fields),
      _generateFromDomain(entityName, modelName, fields),
      _generateFromJson(entityName, modelName, fields),
      '}'
    ].join('\n');
  }

  String _generateFromJson(
    String entityName,
    String modelName,
    List<String> fields,
  ) {
    final _fromJsonLines = [];

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

    return _fromJsonLines.join();
  }

  String _generateFromDomain(
    String entityName,
    String modelName,
    List<String> fields,
  ) {
    final _fromDomainLines = [];

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

    return _fromDomainLines.join();
  }

  String _generateToJson(
    List<String> fields,
  ) {
    final _toJsonLines = [];

    /// Adding header
    _toJsonLines
        .add("\n@override\nMap<String, dynamic> toJson() {\nreturn {\n");

    for (int i = 0; i < fields.length; i++) {
      final field = fields[i].trim().replaceAll(";", "").split(" ");

      final fieldName = field[2];
      _toJsonLines.add('"$fieldName": $fieldName,\n');
    }

    _toJsonLines.add("};\n");
    _toJsonLines.add("}\n");

    return _toJsonLines.join();
  }

  String _generateToDomain(
    String entityName,
    String modelName,
    List<String> fields,
  ) {
    final _toDomainLines = [];

    /// Adding header
    _toDomainLines.add("@override\n$entityName toDomain() {\n");

    /// Placing null check function
    for (int i = 0; i < fields.length; i++) {
      final field = fields[i].trim().replaceAll(";", "").split(" ");

      final fieldName = field[2];
      _toDomainLines.add('checkIfNull($fieldName, "$fieldName", _logger);\n');
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
    _toDomainLines.add("}\n");

    return _toDomainLines.join();
  }

  String _placeLogger(String modelName) {
    return "final _logger = getLogger('$modelName');\n";
  }

  String _convertToModelFields(List<String> fields) {
    final _modelFields = [];

    for (int i = 0; i < fields.length; i++) {
      final field = fields[i].trim().split(" ");

      final fieldDataType = field[1];
      final fieldName = field[2];

      _modelFields.add("$fieldDataType? $fieldName\n");
    }

    return _modelFields.join();
  }

  String _generateEntity(String entityName, List<String> fields) {
    return [
      "import 'package:tatsam_app_experimental/features/view-all-content/domain/entities/entity.dart';",
      '\n',
      'class $entityName extends Entity {',
      ...fields,
      '\n',
      _generateConstructor(entityName, fields),
      '\n',
      _generateToString(entityName, fields),
      '\n',
      _generateHashCode(fields),
      '\n',
      _generateEquality(entityName, fields),
      '}'
    ].join('\n');
  }

  String _generateConstructor(String className, List<String> fields) {
    final List<String> _constructerFields = [];
    for (int i = 0; i < fields.length; i++) {
      final line = fields[i].trim().split(' ');
      final fieldName = line[2].replaceAll(';', ',');
      _constructerFields.add("required this.$fieldName");
    }

    return ["$className({", ..._constructerFields, "});"].join('\n');
  }

  String _generateToString(String className, List<String> fields) {
    final List<String> _stringifiedFields = [];
    for (int i = 0; i < fields.length; i++) {
      final line = fields[i].trim().split(' ');
      final fieldName = line[2].replaceAll(';', ',').replaceAll('\n', '');
      _stringifiedFields.add("$fieldName: \$$fieldName");
    }

    return [
      "@override\nString toString() {\n",
      "return '$className(",
      ..._stringifiedFields,
      ")';",
      "}"
    ].join();
  }

  String _generateHashCode(List<String> fields) {
    final List<String> _hashedFields = [];
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
      "@override\nint get hashCode {",
      "return ",
      ..._hashedFields,
      ";",
      "}"
    ].join();
  }

  String _generateEquality(String className, List<String> fields) {
    final List<String> _equalizedFields = [];
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
      "@override\nbool operator ==(Object other) {\nif (identical(this, other)) return true;\n",
      "return other is $className &&",
      ..._equalizedFields,
      ";",
      "}"
    ].join();
  }

  Future<void> _saveFile(String fileName, String contents) async {
    final outputPath = "$_outputDir$fileName";
    final file = File(outputPath);
    await file.writeAsString(contents);
  }
}
