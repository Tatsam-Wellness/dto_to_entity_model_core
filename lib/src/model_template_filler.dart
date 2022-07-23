import 'dart:io';

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

  Future<File> getGeneratedFile() async {
    var templateStr = await File('template/model_template').readAsString();

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

    return await File('generated/${modelName.toLowerCase()}.dart')
        .writeAsString(templateStr);
  }
}
