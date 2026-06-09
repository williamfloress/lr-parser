import 'token.dart';
import 'token_type.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tabla de palabras reservadas
// ─────────────────────────────────────────────────────────────────────────────

/// Mapa de palabras reservadas del lenguaje hacia su [TokenType] correspondiente.
///
/// Cuando el lexer reconoce un identificador, consulta esta tabla para
/// determinar si es una palabra clave o un identificador de usuario.
const Map<String, TokenType> _keywords = {
  // Estructura de funciones
  'fun'          : TokenType.kwFun,
  'ffun'         : TokenType.kwFfun,
  'dev'          : TokenType.kwDev,
  // Declaración local
  'sea'          : TokenType.kwSea,
  'en'           : TokenType.kwEn,
  // Expresión condicional
  'caso'         : TokenType.kwCaso,
  'fcaso'        : TokenType.kwFcaso,
  // Pre-requisito (comentario estructural)
  'prerequisito' : TokenType.kwPrerequisito,
  // Tipos de datos primitivos
  'entero'       : TokenType.tyEntero,
  'natural'      : TokenType.tyNatural,
  'real'         : TokenType.tyReal,
  'booleano'     : TokenType.tyBooleano,
  'caracter'     : TokenType.tyCaracter,
  'cadena'       : TokenType.tyCadena,
  'vector'       : TokenType.tyVector,
  // Literales booleanos
  'verdadero'    : TokenType.litVerdadero,
  'falso'        : TokenType.litFalso,
  // Operadores alfanuméricos
  'div'          : TokenType.opDiv,
  'mod'          : TokenType.opMod,
  // Operador lógico OR ('v' es una letra, por eso va en keywords)
  'v'            : TokenType.opOr,
};

// ─────────────────────────────────────────────────────────────────────────────
// Clase principal: Lexer
// ─────────────────────────────────────────────────────────────────────────────

/// Analizador léxico (tokenizador) para el lenguaje LR.
///
/// Recorre el [source] carácter a carácter y produce una lista de [Token]s
/// que el parser consumirá posteriormente.
///
/// ## Comportamiento especial
/// - **Espacios en blanco y tabuladores** se ignoran silenciosamente.
/// - **Saltos de línea** (`\n`, `\r\n`, `\r`) incrementan el contador [_line].
/// - **Bloques `{ ... }`** (pre-requisitos / comentarios estructurales): el
///   lexer los omite completamente, incluyendo el token `prerequisito` que
///   los precede.
/// - **Secuencias `[]`**: se reconocen como el token [TokenType.symGuard]
///   (separador de rama en `caso`).
/// - **Símbolos compuestos** (`->`, `!=`, `>=`, `<=`): se reconocen
///   preferentemente antes que sus partes individuales.
///
/// ## Uso
/// ```dart
/// final lexer  = Lexer('fun suma(a: entero) dev (s: entero) = a ffun');
/// final tokens = lexer.tokenize();
/// for (final t in tokens) print(t);
/// ```
class Lexer {
  /// Código fuente completo a analizar.
  final String _source;

  /// Posición actual del cursor de lectura (índice en [_source]).
  int _pos = 0;

  /// Número de línea actual (1-indexado) para reportar en los tokens.
  int _line = 1;

  /// Crea un [Lexer] con el [source] a analizar.
  Lexer(String source) : _source = source;

  // ── Helpers de acceso al buffer ───────────────────────────────────────────

  /// Retorna `true` si ya se consumió todo el código fuente.
  bool get _isAtEnd => _pos >= _source.length;

  /// Carácter actual sin avanzar el cursor.
  ///
  /// Lanza [RangeError] si [_isAtEnd] es verdadero; llama a [_isAtEnd] antes.
  String get _current => _source[_pos];

  /// Carácter siguiente al actual sin avanzar el cursor.
  ///
  /// Retorna `'\x00'` (nulo) si no existe siguiente carácter.
  String get _next =>
      (_pos + 1 < _source.length) ? _source[_pos + 1] : '\x00';

  /// Avanza el cursor una posición y retorna el carácter que se acaba de consumir.
  ///
  /// Además incrementa [_line] cuando el carácter consumido es `\n`.
  String _advance() {
    final ch = _source[_pos++];
    if (ch == '\n') _line++;
    return ch;
  }

  // ── Punto de entrada ──────────────────────────────────────────────────────

  /// Recorre todo el [_source] y retorna la lista completa de tokens.
  ///
  /// El último token siempre es [TokenType.eof].
  ///
  /// Lanza [LexicalException] ante cualquier carácter no reconocido.
  List<Token> tokenize() {
    final tokens = <Token>[];

    while (!_isAtEnd) {
      _skipWhitespace();
      if (_isAtEnd) break;

      final token = _nextToken();
      if (token != null) tokens.add(token);
    }

    // Siempre cierra la secuencia con EOF
    tokens.add(Token(TokenType.eof, '', _line));
    return tokens;
  }

  // ── Ignorar espacios en blanco ────────────────────────────────────────────

  /// Avanza el cursor mientras el carácter actual sea un espacio en blanco
  /// (espacio, tabulador, retorno de carro o salto de línea).
  void _skipWhitespace() {
    while (!_isAtEnd) {
      final ch = _current;
      if (ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n') {
        _advance();
      } else {
        break;
      }
    }
  }

  // ── Ignorar bloque de pre-requisito { ... } ───────────────────────────────

  /// Consume todo el contenido de un bloque `{ ... }` sin producir tokens.
  ///
  /// Debe llamarse justo cuando [_current] es `{`.
  /// Lanza [LexicalException] si el bloque no se cierra antes del EOF.
  void _skipBlock() {
    final startLine = _line;
    _advance(); // consume '{'
    while (!_isAtEnd && _current != '}') {
      _advance();
    }
    if (_isAtEnd) {
      throw LexicalException(
        'Bloque { ... } sin cerrar (abierto en línea $startLine)',
        _line,
      );
    }
    _advance(); // consume '}'
  }

  // ── Producción del siguiente token ────────────────────────────────────────

  /// Intenta reconocer y producir el siguiente [Token] a partir de [_pos].
  ///
  /// Retorna `null` para lexemas que deben ignorarse:
  /// - Bloques `{ … }` sueltos (comentario estructural).
  /// - La palabra `prerequisito` junto con su bloque `{ … }`.
  Token? _nextToken() {
    final startLine = _line;
    final ch = _current;

    // ── Bloque { ... } suelto (comentario estructural) ────────────────────
    if (ch == '{') {
      _skipBlock();
      return null;
    }

    // ── Identificadores y palabras clave ──────────────────────────────────
    if (_isLetter(ch)) {
      // Puede retornar null si es 'prerequisito'
      return _readIdentifierOrKeyword(startLine);
    }

    // ── Literales numéricos ───────────────────────────────────────────────
    if (_isDigit(ch)) {
      return _readNumber(startLine);
    }

    // ── Literal cadena "..." ──────────────────────────────────────────────
    if (ch == '"') {
      return _readString(startLine);
    }

    // ── Literal carácter '...' ────────────────────────────────────────────
    if (ch == "'") {
      return _readChar(startLine);
    }

    // ── Negación lógica ¬ (U+00AC) ────────────────────────────────────────
    if (ch == '¬') {
      _advance();
      return Token(TokenType.opNot, '¬', startLine);
    }

    // ── Símbolos y operadores de puntuación ───────────────────────────────
    return _readSymbol(startLine);
  }

  // ── Lectura de identificadores y palabras clave ───────────────────────────

  /// Lee una secuencia `[a-zA-ZáéíóúÁÉÍÓÚñÑ][a-zA-Z0-9_]*` y la clasifica
  /// como palabra reservada o [TokenType.litId].
  ///
  /// Retorna `null` cuando el lexema es `prerequisito` (se suprime junto con
  /// el bloque `{ … }` que lo sigue).
  Token? _readIdentifierOrKeyword(int startLine) {
    final buf = StringBuffer();
    while (!_isAtEnd && (_isLetter(_current) || _isDigit(_current) || _current == '_')) {
      buf.write(_advance());
    }
    final lexeme = buf.toString();

    // ¿Es una palabra reservada?
    final type = _keywords[lexeme] ?? TokenType.litId;

    // Si el identificador es 'prerequisito', el siguiente token esperado es
    // un bloque { ... } que debe ignorarse junto con la palabra clave misma.
    if (type == TokenType.kwPrerequisito) {
      _skipWhitespace();
      if (!_isAtEnd && _current == '{') {
        _skipBlock(); // consumimos el bloque de pre-requisito
      }
      return null; // suprimir el token 'prerequisito'
    }

    return Token(type, lexeme, startLine);
  }

  // ── Lectura de literales numéricos ────────────────────────────────────────

  /// Lee una secuencia de dígitos, detectando si es real (contiene `.`).
  ///
  /// Produce [TokenType.litInt] o [TokenType.litReal].
  Token _readNumber(int startLine) {
    final buf = StringBuffer();
    while (!_isAtEnd && _isDigit(_current)) {
      buf.write(_advance());
    }

    // Parte decimal (real)
    if (!_isAtEnd && _current == '.' && _isDigit(_next)) {
      buf.write(_advance()); // consume '.'
      while (!_isAtEnd && _isDigit(_current)) {
        buf.write(_advance());
      }
      return Token(TokenType.litReal, buf.toString(), startLine);
    }

    return Token(TokenType.litInt, buf.toString(), startLine);
  }

  // ── Lectura de literal cadena ─────────────────────────────────────────────

  /// Lee el contenido entre comillas dobles, excluyendo las comillas mismas.
  ///
  /// Lanza [LexicalException] si la cadena no se cierra en la misma línea
  /// o antes del EOF.
  Token _readString(int startLine) {
    _advance(); // consume '"' inicial
    final buf = StringBuffer();
    while (!_isAtEnd && _current != '"') {
      if (_current == '\n') {
        throw LexicalException(
          'Cadena sin cerrar (iniciada en línea $startLine)',
          _line,
        );
      }
      buf.write(_advance());
    }
    if (_isAtEnd) {
      throw LexicalException(
        'Cadena sin cerrar (iniciada en línea $startLine)',
        _line,
      );
    }
    _advance(); // consume '"' final
    return Token(TokenType.litString, buf.toString(), startLine);
  }

  // ── Lectura de literal carácter ───────────────────────────────────────────

  /// Lee un solo carácter entre comillas simples.
  ///
  /// Lanza [LexicalException] si está vacío o sin cerrar.
  Token _readChar(int startLine) {
    _advance(); // consume "'" inicial
    if (_isAtEnd || _current == "'") {
      throw LexicalException(
        'Literal carácter vacío en línea $startLine',
        _line,
      );
    }
    final ch = _advance(); // el carácter en sí
    if (_isAtEnd || _current != "'") {
      throw LexicalException(
        "Literal carácter sin cerrar en línea $startLine",
        _line,
      );
    }
    _advance(); // consume "'" final
    return Token(TokenType.litChar, ch, startLine);
  }

  // ── Lectura de símbolos y operadores ─────────────────────────────────────

  /// Reconoce símbolos simples y compuestos (`->`, `!=`, `>=`, `<=`, `[]`).
  ///
  /// Lanza [LexicalException] ante cualquier carácter desconocido.
  Token _readSymbol(int startLine) {
    final ch = _advance(); // consume el carácter actual

    switch (ch) {
      case '(':  return Token(TokenType.symLParen,    ch, startLine);
      case ')':  return Token(TokenType.symRParen,    ch, startLine);
      case ',':  return Token(TokenType.symComma,     ch, startLine);
      case ';':  return Token(TokenType.symSemicolon, ch, startLine);
      case ':':  return Token(TokenType.symColon,     ch, startLine);
      case '+':  return Token(TokenType.opPlus,       ch, startLine);
      case '*':  return Token(TokenType.opStar,       ch, startLine);
      case '/':  return Token(TokenType.opSlash,      ch, startLine);
      case '^':  return Token(TokenType.opAnd,        ch, startLine);

      // '=' → operador de igualdad / asignación
      case '=':  return Token(TokenType.opEq,         ch, startLine);

      // '<' o '<='
      case '<':
        if (!_isAtEnd && _current == '=') {
          _advance();
          return Token(TokenType.opLe, '<=', startLine);
        }
        return Token(TokenType.opLt, ch, startLine);

      // '>' o '>='
      case '>':
        if (!_isAtEnd && _current == '=') {
          _advance();
          return Token(TokenType.opGe, '>=', startLine);
        }
        return Token(TokenType.opGt, ch, startLine);

      // '!' solo válido como '!='
      case '!':
        if (!_isAtEnd && _current == '=') {
          _advance();
          return Token(TokenType.opNeq, '!=', startLine);
        }
        throw LexicalException(
          "Carácter '!' sin '=' en línea $startLine",
          startLine,
        );

      // '-' o '->'
      case '-':
        if (!_isAtEnd && _current == '>') {
          _advance();
          return Token(TokenType.symArrow, '->', startLine);
        }
        return Token(TokenType.opMinus, ch, startLine);

      // '[' solo o '[]' (separador de rama)
      case '[':
        if (!_isAtEnd && _current == ']') {
          _advance();
          return Token(TokenType.symGuard, '[]', startLine);
        }
        return Token(TokenType.symLBracket, ch, startLine);

      case ']':  return Token(TokenType.symRBracket, ch, startLine);

      default:
        throw LexicalException(
          "Carácter inesperado '$ch' en línea $startLine",
          startLine,
        );
    }
  }

  // ── Predicados de carácter ────────────────────────────────────────────────

  /// Retorna `true` si [ch] es una letra ASCII o un carácter acentuado
  /// frecuente en español (á, é, í, ó, ú, ñ y sus mayúsculas).
  bool _isLetter(String ch) {
    final c = ch.codeUnitAt(0);
    // a-z
    if (c >= 0x61 && c <= 0x7A) return true;
    // A-Z
    if (c >= 0x41 && c <= 0x5A) return true;
    // Caracteres latinos extendidos usados en español
    const extras = {
      0xE1, 0xE9, 0xED, 0xF3, 0xFA, // á é í ó ú
      0xC1, 0xC9, 0xCD, 0xD3, 0xDA, // Á É Í Ó Ú
      0xF1, 0xD1,                    // ñ Ñ
    };
    return extras.contains(c);
  }

  /// Retorna `true` si [ch] es un dígito decimal (`0`–`9`).
  bool _isDigit(String ch) {
    final c = ch.codeUnitAt(0);
    return c >= 0x30 && c <= 0x39;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Excepción léxica
// ─────────────────────────────────────────────────────────────────────────────

/// Excepción lanzada cuando el [Lexer] encuentra un carácter o secuencia
/// que no pertenece al vocabulario del lenguaje LR.
///
/// Incluye el [message] descriptivo y el número de [line] donde ocurrió el
/// error, facilitando al usuario la localización del problema.
///
/// ### Ejemplo de mensaje
/// ```
/// Error léxico en línea 5: Carácter inesperado '@'
/// ```
class LexicalException implements Exception {
  /// Descripción del error léxico encontrado.
  final String message;

  /// Número de línea (1-indexado) donde se detectó el error.
  final int line;

  /// Crea una [LexicalException] con el [message] y la [line] indicados.
  const LexicalException(this.message, this.line);

  @override
  String toString() => 'Error léxico en línea $line: $message';
}
