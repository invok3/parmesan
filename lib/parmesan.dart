/// CLI tool to scaffold Flutter + C++ FFI projects.
///
/// ```sh
/// dart pub global activate parmesan
/// parmesan add:module my_module
/// parmesan add:platform linux
/// parmesan generate:bindings src/mymodule/mymodule.h
/// ```
library;

export 'src/commands/add_module_command.dart';
export 'src/commands/add_platform_command.dart';
export 'src/commands/generate_bindings_command.dart';
export 'src/templates/template_engine.dart';
export 'src/utils/file_utils.dart';
export 'src/utils/string_utils.dart';
export 'src/validators/project_validator.dart';
export 'src/parsers/cpp_header_parser.dart';
