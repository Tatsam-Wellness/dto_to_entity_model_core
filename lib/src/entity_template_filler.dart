import 'dart:io';

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
    final _generatedEntityStr = await generateEntity();

    return await File(saveLocation).writeAsString(_generatedEntityStr);
  }

  Future<String> generateEntity() async {
    var templateStr = await File('template/entity_template').readAsString();
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
