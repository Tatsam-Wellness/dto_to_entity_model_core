import 'dart:io';

import 'package:dto_to_entity_model_core/src/template/entity_template.dart';

class EntityTemplateFiller {
  final String entityName;
  final List<String> fields;
  final List<String> constructorFields;
  final List<String> equality;
  final List<String> generatedHashCode;
  final List<String> toStr;

  EntityTemplateFiller({
    required this.entityName,
    required this.fields,
    required this.constructorFields,
    required this.equality,
    required this.generatedHashCode,
    required this.toStr,
  });

  Future<File> generateFile(String saveLocation) async {
    final _generatedEntityStr = generateEntity();

    return await File(saveLocation).writeAsString(_generatedEntityStr);
  }

  String generateEntity() {
    var templateStr = entityTemplate;
    templateStr = templateStr.replaceAll('{{ entityName }}', entityName);
    templateStr = templateStr.replaceAll('{{ fields }}', fields.join('\n'));
    templateStr = templateStr.replaceAll(
        '{{ constructorFields }}', constructorFields.join('\n'));
    templateStr = templateStr.replaceAll('{{ equality }}', equality.join('\n'));
    templateStr =
        templateStr.replaceAll('{{ hashCode }}', generatedHashCode.join('\n'));
    templateStr = templateStr.replaceAll('{{ toStr }}', toStr.join(''));

    return templateStr;
  }
}
