import 'dart:io';

import 'package:dto_to_entity_model_core/src/template/model_template.dart';

class ModelTemplateFiller {
  final String entityName;
  final String entityFileName;
  final String modelName;
  final List<String> generatedFields;
  final List<String> generatedToDomain;
  final List<String> generatedToJson;
  final List<String> generatedFromDomain;
  final List<String> generatedFromJson;

  ModelTemplateFiller({
    required this.entityName,
    required this.modelName,
    required this.entityFileName,
    required this.generatedFields,
    required this.generatedToDomain,
    required this.generatedToJson,
    required this.generatedFromDomain,
    required this.generatedFromJson,
  });

  Future<File> generateFile(String saveLocation) async {
    final _generatedModelStr = generateModel();

    return await File(saveLocation).writeAsString(_generatedModelStr);
  }

  String generateModel() {
    var templateStr = modelTemplate;

    templateStr = templateStr.replaceAll('{{ modelName }}', modelName);
    templateStr = templateStr.replaceAll('{{ entityName }}', entityName);
    templateStr =
        templateStr.replaceAll('{{ entityFileName }}', entityFileName);
    templateStr = templateStr.replaceAll(
        '{{ generatedFields }}', generatedFields.join('\n'));
    templateStr = templateStr.replaceAll(
        '{{ generatedToDomain }}', generatedToDomain.join('\n'));
    templateStr = templateStr.replaceAll(
        '{{ generatedToJson }}', generatedToJson.join('\n'));
    templateStr = templateStr.replaceAll(
        '{{ generatedFromDomain }}', generatedFromDomain.join('\n'));
    templateStr = templateStr.replaceAll(
        '{{ generatedFromJson }}', generatedFromJson.join('\n'));

    return templateStr;
  }
}
