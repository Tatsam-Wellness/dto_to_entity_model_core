import 'package:dto_to_entity_model_core/dto_to_entity_model_core.dart';

Future<void> main(List<String> args) async {
  final engine = JavaConverter();
  await engine.execute(args);
}
