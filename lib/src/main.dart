import 'package:dto_to_entity_model_core/dto_to_entity_model_core.dart';

Future<void> main(List<String> args) async {
  final engine = DTOToEntityModelCore();
  await engine.execute(args);
}
