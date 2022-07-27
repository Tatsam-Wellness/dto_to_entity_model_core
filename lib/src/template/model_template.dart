const modelTemplate = '''
import 'package:tatsam_app_experimental/core/logger/logger.dart';
import 'package:tatsam_app_experimental/core/utils/helper_functions/check_if_null.dart';
import 'package:tatsam_app_experimental/features/view-all-content/data/models/data-model.dart';
import '{{ entityFileName }}';

class {{ modelName }} extends DataModel<{{ entityName }}> {
  {{ generatedFields }}

  final _logger = getLogger({{ modelName }});

  @override
  {{ entityName }} toDomain() {
      {{ generatedToDomain }}
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      {{ generatedToJson }}
    };
  }

  {{ generatedFromDomain }}

  {{ generatedFromJson }}
}
''';
