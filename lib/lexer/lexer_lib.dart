/// Módulo del analizador léxico (Lexer) del proyecto LR Parser.
///
/// Exporta los tres componentes que conforman la fase léxica:
/// - [TokenType]: enumeración de todos los tipos de tokens del lenguaje.
/// - [Token]: clase inmutable que representa un token con tipo, lexema y línea.
/// - [Lexer]: analizador léxico que convierte código fuente en lista de tokens.
/// - [LexicalException]: excepción lanzada ante errores léxicos.
library lexer;

export 'token_type.dart';
export 'token.dart';
export 'lexer.dart';
