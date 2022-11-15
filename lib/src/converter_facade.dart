import 'dart:io';

import 'package:dto_to_entity_model_core/src/generated.dart';

abstract class CoverterFacade {
  /// --input = "filename"
  /// For command line usage
  Future<void> execute(List<String> args);

  /// Converts the given DTO file to App's Entity and Model
  /// And Saves in [_outputDir]
  /// Internally used by command line entrypoint
  Future<void> processInputFile(File input);

  /// App's UI directly uses it as engine for conversion
  Generated parseFile(String dtoStr);

  List<String> generateFromJson(String entityName, String modelName, List<String> fields);

  List<String> generateFromDomain(String entityName, String modelName, List<String> fields);

  List<String> generateToJson(List<String> fields);

  List<String> generateToDomain(String entityName, String modelName, List<String> fields);

  List<String> convertToModelFields(List<String> fields);

  List<String> generateConstructor(String className, List<String> fields);

  List<String> generateToString(String className, List<String> fields);

  List<String> generateHashCode(List<String> fields);

  List<String> generateEquality(String className, List<String> fields);
}
