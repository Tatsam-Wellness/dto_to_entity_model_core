const entityTemplate = '''
import 'package:tatsam_app_experimental/features/view-all-content/domain/entities/entity.dart';

class {{ entityName }} extends Entity {
  {{ fields }}

  {{ entityName }}({
    {{ constructorFields }}  
  });
  

  @override
  String toString() => {{ toStr }};

  @override
  bool operator ==(Object other) {
    {{ equality }}
  }

  @override
  int get hashCode => {{ hashCode }};
}
''';
