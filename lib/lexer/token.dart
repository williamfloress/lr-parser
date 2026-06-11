/*
Proyecto realizado por :
Nombre: William Flores
CI: 24.107.343
Correo: w.flores.s24@gmail.com
*/
import 'token_type.dart';

/// Representa un token individual producido por el [Lexer].
///
/// Cada token captura:
/// - Su [type]: el tipo semántico del lexema (palabra clave, operador, literal…).
/// - Su [lexeme]: la cadena de texto exacta leída desde el código fuente.
/// - Su [line]: el número de línea (1-indexado) donde aparece en la entrada,
///   imprescindible para generar mensajes de error precisos.
///
/// ### Ejemplo
/// ```dart
/// final tok = Token(TokenType.kwFun, 'fun', 1);
/// print(tok); // Token(kwFun, 'fun', línea 1)
/// ```
class Token {
  /// Tipo semántico del token (ver [TokenType]).
  final TokenType type;

  /// Texto literal tal como aparece en el código fuente.
  final String lexeme;

  /// Número de línea (1-indexado) en la que se encontró el token.
  final int line;

  /// Crea un [Token] con el tipo, lexema y línea indicados.
  const Token(this.type, this.lexeme, this.line);

  @override
  String toString() => 'Token($type, \'$lexeme\', línea $line)';
}
