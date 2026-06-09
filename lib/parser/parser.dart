import '../ast/ast.dart';
import '../lexer/token.dart';
import '../lexer/token_type.dart';
import 'syntax_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Parser — Analizador Sintáctico Descendente Recursivo (RDP)
// ─────────────────────────────────────────────────────────────────────────────

/// Analizador sintáctico para el lenguaje LR.
///
/// Implementa un **análisis descendente recursivo** (Recursive Descent Parser)
/// que sigue fielmente la estratificación de la gramática EBNF definida en
/// `documentacion/EBNF.md`.
///
/// Recibe la lista de tokens producida por [Lexer] y construye el
/// **Árbol de Sintaxis Abstracta** (AST) correspondiente.
///
/// ## Jerarquía de expresiones (mayor a menor precedencia)
/// ```
/// LogicalOrExp   →  v
/// LogicalAndExp  →  ^
/// EqualityExp    →  = | !=
/// RelationalExp  →  > | < | >= | <=
/// ArithExp       →  + | -
/// Term           →  * | / | div | mod
/// Factor         →  [ + | - | ¬ ] Primary
/// Primary        →  literal | id | id(args) | id[idx] | (exp) | caso | sea
/// ```
///
/// ## Estrategia de error
/// Se utiliza **Fail-Fast**: ante cualquier incongruencia gramatical se lanza
/// [SyntaxException] con el número de línea y una descripción precisa.
///
/// ## Uso
/// ```dart
/// final tokens = Lexer(source).tokenize();
/// final ast    = Parser(tokens).parseProgram();
/// ```
class Parser {
  /// Lista de tokens producida por el [Lexer].
  final List<Token> _tokens;

  /// Índice del token actual dentro de [_tokens].
  int _pos = 0;

  /// Crea un [Parser] con la [tokens] lista producida por el [Lexer].
  ///
  /// La lista debe terminar con exactamente un token [TokenType.eof].
  Parser(List<Token> tokens) : _tokens = tokens;

  // ═══════════════════════════════════════════════════════════════════════════
  // Sección 1 — Primitivas de navegación de tokens
  // ═══════════════════════════════════════════════════════════════════════════

  /// Retorna el token en la posición actual sin consumirlo (lookahead 1).
  Token get _peek => _tokens[_pos];

  /// Retorna el tipo del token actual.
  TokenType get _peekType => _peek.type;

  /// Retorna `true` si el token actual es del [type] indicado.
  bool _check(TokenType type) => _peekType == type;

  /// Retorna `true` si el token actual es alguno de los [types] indicados.
  bool _checkAny(List<TokenType> types) => types.contains(_peekType);

  /// Avanza al siguiente token y retorna el que se acaba de consumir.
  Token _advance() {
    final tok = _tokens[_pos];
    if (tok.type != TokenType.eof) _pos++;
    return tok;
  }

  /// Si el token actual es del [type] indicado, lo consume y lo retorna.
  ///
  /// Retorna `null` si no coincide (sin lanzar excepción).
  Token? _match(TokenType type) {
    if (_check(type)) return _advance();
    return null;
  }

  /// Si el token actual es alguno de los [types], lo consume y lo retorna.
  ///
  /// Retorna `null` si ninguno coincide.
  Token? _matchAny(List<TokenType> types) {
    if (_checkAny(types)) return _advance();
    return null;
  }

  /// Consume el token actual si es del [type] indicado.
  ///
  /// Lanza [SyntaxException] si el tipo no coincide.
  ///
  /// [context] es una cadena descriptiva del contexto gramatical, usada en
  /// el mensaje de error para facilitar la depuración.
  Token _consume(TokenType type, String context) {
    if (_check(type)) return _advance();
    final found = _peek;
    throw SyntaxException(
      "$context: se esperaba '${_typeName(type)}' "
      "pero se encontró '${found.lexeme.isEmpty ? _typeName(found.type) : found.lexeme}'",
      found.line,
    );
  }

  /// Convierte un [TokenType] en su representación legible para mensajes de error.
  String _typeName(TokenType t) {
    return switch (t) {
      TokenType.kwFun       => 'fun',
      TokenType.kwFfun      => 'ffun',
      TokenType.kwDev       => 'dev',
      TokenType.kwSea       => 'sea',
      TokenType.kwEn        => 'en',
      TokenType.kwCaso      => 'caso',
      TokenType.kwFcaso     => 'fcaso',
      TokenType.symLParen   => '(',
      TokenType.symRParen   => ')',
      TokenType.symLBracket => '[',
      TokenType.symRBracket => ']',
      TokenType.symComma    => ',',
      TokenType.symSemicolon => ';',
      TokenType.symColon    => ':',
      TokenType.symArrow    => '->',
      TokenType.symGuard    => '[]',
      TokenType.opEq        => '=',
      TokenType.opNeq       => '!=',
      TokenType.opGt        => '>',
      TokenType.opLt        => '<',
      TokenType.opGe        => '>=',
      TokenType.opLe        => '<=',
      TokenType.opPlus      => '+',
      TokenType.opMinus     => '-',
      TokenType.opStar      => '*',
      TokenType.opSlash     => '/',
      TokenType.opDiv       => 'div',
      TokenType.opMod       => 'mod',
      TokenType.opAnd       => '^',
      TokenType.opOr        => 'v',
      TokenType.opNot       => '¬',
      TokenType.litId       => '<identificador>',
      TokenType.litInt      => '<entero>',
      TokenType.litReal     => '<real>',
      TokenType.litString   => '<cadena>',
      TokenType.litChar     => '<caracter>',
      TokenType.litVerdadero => 'verdadero',
      TokenType.litFalso    => 'falso',
      TokenType.eof         => '<fin de archivo>',
      _                     => t.name,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sección 2 — Punto de entrada: parseProgram
  // ═══════════════════════════════════════════════════════════════════════════

  /// Punto de entrada del parser.
  ///
  /// Parsea la regla:
  /// ```ebnf
  /// <Prog> ::= { fun <id> "(" <ParForm> ")" dev "(" <ParForm> ")" "=" <Exp> ffun }
  /// ```
  ///
  /// Retorna el nodo raíz [Prog] del AST.
  /// Lanza [SyntaxException] si hay errores de sintaxis.
  Prog parseProgram() {
    final functions = <FuncDecl>[];

    // El programa es una secuencia de declaraciones de función
    while (!_check(TokenType.eof)) {
      functions.add(_parseFunction());
    }

    // Verificar que se consumió todo el input
    _consume(TokenType.eof, 'Fin de programa');
    return Prog(functions);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sección 3 — Declaración de función: parseFunction
  // ═══════════════════════════════════════════════════════════════════════════

  /// Parsea una declaración de función completa.
  ///
  /// ```ebnf
  /// fun <id> "(" <ParForm> ")" dev "(" <ParForm> ")" "=" <Exp> ffun
  /// ```
  FuncDecl _parseFunction() {
    // 'fun'
    _consume(TokenType.kwFun, 'Declaración de función');

    // <id> — nombre de la función
    final nameTok = _consume(TokenType.litId, 'Nombre de función');

    // "(" <ParForm> ")"  — parámetros de entrada
    _consume(TokenType.symLParen, "Parámetros de entrada de '${nameTok.lexeme}'");
    final params = _parseParForm();
    _consume(TokenType.symRParen, "Cierre de parámetros de entrada de '${nameTok.lexeme}'");

    // 'dev' "(" <ParForm> ")"  — parámetros de salida
    _consume(TokenType.kwDev, "Sección 'dev' de '${nameTok.lexeme}'");
    _consume(TokenType.symLParen, "Parámetros de salida de '${nameTok.lexeme}'");
    final returns = _parseParForm();
    _consume(TokenType.symRParen, "Cierre de parámetros de salida de '${nameTok.lexeme}'");

    // '=' <Exp>  — cuerpo
    _consume(TokenType.opEq, "Asignación de cuerpo de '${nameTok.lexeme}'");
    final body = _parseExpression();

    // 'ffun'
    _consume(TokenType.kwFfun, "Cierre de función '${nameTok.lexeme}'");

    return FuncDecl(nameTok.lexeme, params, returns, body);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sección 4 — Parámetros formales: parseParForm
  // ═══════════════════════════════════════════════════════════════════════════

  /// Parsea la lista de parámetros formales de una función.
  ///
  /// ```ebnf
  /// <ParForm> ::= <id> { "," <id> } ":" <Tipo>
  ///               { ";" <id> { "," <id> } ":" <Tipo> }
  /// ```
  ///
  /// Retorna una lista de [ParForm], uno por cada grupo `ids : tipo`.
  List<ParForm> _parseParForm() {
    final result = <ParForm>[];

    // Primer grupo obligatorio
    result.add(_parseOneParGroup());

    // Grupos adicionales separados por ';'
    while (_match(TokenType.symSemicolon) != null) {
      result.add(_parseOneParGroup());
    }

    return result;
  }

  /// Parsea un grupo `<id> { "," <id> } ":" <Tipo>`.
  ParForm _parseOneParGroup() {
    // Uno o más identificadores separados por coma
    final names = <String>[];
    names.add(_consume(TokenType.litId, 'Nombre de parámetro').lexeme);
    while (_match(TokenType.symComma) != null) {
      names.add(_consume(TokenType.litId, 'Nombre de parámetro').lexeme);
    }

    // ':' <Tipo>
    _consume(TokenType.symColon, 'Tipo de parámetro');
    final typeName = _parseType();

    return ParForm(names, typeName);
  }

  /// Parsea un tipo de dato.
  ///
  /// ```ebnf
  /// <Tipo> ::= entero | natural | real | booleano | caracter | cadena | vector | <id>
  /// ```
  String _parseType() {
    const typeTokens = [
      TokenType.tyEntero,
      TokenType.tyNatural,
      TokenType.tyReal,
      TokenType.tyBooleano,
      TokenType.tyCaracter,
      TokenType.tyCadena,
      TokenType.tyVector,
      TokenType.litId,   // tipo definido por el usuario
    ];

    final tok = _matchAny(typeTokens);
    if (tok == null) {
      throw SyntaxException(
        "Se esperaba un tipo de dato pero se encontró '${_peek.lexeme}'",
        _peek.line,
      );
    }
    return tok.lexeme;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sección 5 — Expresiones: jerarquía completa
  // ═══════════════════════════════════════════════════════════════════════════

  /// Punto de entrada de la jerarquía de expresiones.
  ///
  /// Delega al nivel más bajo de precedencia (OR lógico).
  ///
  /// ```ebnf
  /// <Exp> ::= <LogicalOrExp>
  /// ```
  Expr _parseExpression() => _parseLogicalOr();

  // ── Nivel 1: OR lógico ────────────────────────────────────────────────────

  /// ```ebnf
  /// <LogicalOrExp> ::= <LogicalAndExp> { "v" <LogicalAndExp> }
  /// ```
  Expr _parseLogicalOr() {
    var left = _parseLogicalAnd();

    while (_check(TokenType.opOr)) {
      final op = _advance();
      final right = _parseLogicalAnd();
      left = BinaryExpr(left, op.lexeme, right);
    }

    return left;
  }

  // ── Nivel 2: AND lógico ───────────────────────────────────────────────────

  /// ```ebnf
  /// <LogicalAndExp> ::= <EqualityExp> { "^" <EqualityExp> }
  /// ```
  Expr _parseLogicalAnd() {
    var left = _parseEquality();

    while (_check(TokenType.opAnd)) {
      final op = _advance();
      final right = _parseEquality();
      left = BinaryExpr(left, op.lexeme, right);
    }

    return left;
  }

  // ── Nivel 3: igualdad ─────────────────────────────────────────────────────

  /// ```ebnf
  /// <EqualityExp> ::= <RelationalExp> { ("=" | "!=") <RelationalExp> }
  /// ```
  Expr _parseEquality() {
    var left = _parseRelational();

    Token? op;
    while ((op = _matchAny([TokenType.opEq, TokenType.opNeq])) != null) {
      final right = _parseRelational();
      left = BinaryExpr(left, op!.lexeme, right);
    }

    return left;
  }

  // ── Nivel 4: relacional ───────────────────────────────────────────────────

  /// ```ebnf
  /// <RelationalExp> ::= <ArithExp> { (">" | "<" | ">=" | "<=") <ArithExp> }
  /// ```
  Expr _parseRelational() {
    var left = _parseArith();

    Token? op;
    final relOps = [
      TokenType.opGt,
      TokenType.opLt,
      TokenType.opGe,
      TokenType.opLe,
    ];
    while ((op = _matchAny(relOps)) != null) {
      final right = _parseArith();
      left = BinaryExpr(left, op!.lexeme, right);
    }

    return left;
  }

  // ── Nivel 5: adición/sustracción ─────────────────────────────────────────

  /// ```ebnf
  /// <ArithExp> ::= <Term> { ("+" | "-") <Term> }
  /// ```
  Expr _parseArith() {
    var left = _parseTerm();

    Token? op;
    while ((op = _matchAny([TokenType.opPlus, TokenType.opMinus])) != null) {
      final right = _parseTerm();
      left = BinaryExpr(left, op!.lexeme, right);
    }

    return left;
  }

  // ── Nivel 6: multiplicación/división ─────────────────────────────────────

  /// ```ebnf
  /// <Term> ::= <Factor> { ("*" | "/" | "div" | "mod") <Factor> }
  /// ```
  Expr _parseTerm() {
    var left = _parseFactor();

    Token? op;
    final mulOps = [
      TokenType.opStar,
      TokenType.opSlash,
      TokenType.opDiv,
      TokenType.opMod,
    ];
    while ((op = _matchAny(mulOps)) != null) {
      final right = _parseFactor();
      left = BinaryExpr(left, op!.lexeme, right);
    }

    return left;
  }

  // ── Nivel 7: unario ───────────────────────────────────────────────────────

  /// ```ebnf
  /// <Factor> ::= [ "+" | "-" | "¬" ] <Primary>
  /// ```
  Expr _parseFactor() {
    final op = _matchAny([
      TokenType.opPlus,
      TokenType.opMinus,
      TokenType.opNot,
    ]);

    final operand = _parsePrimary();

    if (op != null) {
      return UnaryExpr(op.lexeme, operand);
    }
    return operand;
  }

  // ── Nivel 8: primario ─────────────────────────────────────────────────────

  /// Parsea la unidad atómica de una expresión.
  ///
  /// ```ebnf
  /// <Primary> ::= <id> "(" <ParAct> ")"   (* llamada a función *)
  ///             | <id> "[" <Exp> "]"       (* acceso a vector   *)
  ///             | <id>                     (* identificador     *)
  ///             | <valor>                  (* literal           *)
  ///             | <Condic>                 (* caso … fcaso      *)
  ///             | <DecLoc>                 (* sea … en          *)
  ///             | "(" <Exp> ")"            (* agrupación / tupla*)
  /// ```
  ///
  /// **Nota de desambiguación:** cuando se encuentra `<id>` se hace lookahead
  /// al siguiente token para distinguir entre llamada, acceso a vector e
  /// identificador simple.
  Expr _parsePrimary() {
    // ── caso … fcaso ──────────────────────────────────────────────────────
    if (_check(TokenType.kwCaso)) {
      return _parseCondic();
    }

    // ── sea … en  ─────────────────────────────────────────────────────────
    if (_check(TokenType.kwSea)) {
      return _parseDecLoc();
    }

    // ── "(" <Exp> { "," <Exp> } ")"  →  tupla o agrupada ─────────────────
    if (_check(TokenType.symLParen)) {
      return _parseParenOrTuple();
    }

    // ── <id> … ───────────────────────────────────────────────────────────
    if (_check(TokenType.litId)) {
      final idTok = _advance(); // consume el identificador

      // id "(" <ParAct> ")"  → llamada a función
      if (_match(TokenType.symLParen) != null) {
        final args = _parseParAct();
        _consume(TokenType.symRParen, "Cierre de argumentos de '${idTok.lexeme}'");
        return CallExpr(idTok.lexeme, args);
      }

      // id "[" <Exp> "]"  → acceso a vector
      if (_match(TokenType.symLBracket) != null) {
        final index = _parseExpression();
        _consume(TokenType.symRBracket, "Cierre de índice de '${idTok.lexeme}'");
        return ArrayAccessExpr(idTok.lexeme, index);
      }

      // id solo  → identificador
      return IdExpr(idTok.lexeme);
    }

    // ── Literales numéricos ───────────────────────────────────────────────
    if (_check(TokenType.litInt)) {
      final tok = _advance();
      return LiteralExpr(int.parse(tok.lexeme));
    }

    if (_check(TokenType.litReal)) {
      final tok = _advance();
      return RealLiteralExpr(double.parse(tok.lexeme));
    }

    // ── Literales de cadena ───────────────────────────────────────────────
    if (_check(TokenType.litString)) {
      final tok = _advance();
      return StringLiteralExpr(tok.lexeme);
    }

    // ── Literales de carácter ─────────────────────────────────────────────
    if (_check(TokenType.litChar)) {
      final tok = _advance();
      return CharLiteralExpr(tok.lexeme);
    }

    // ── Literales booleanos ───────────────────────────────────────────────
    if (_check(TokenType.litVerdadero) || _check(TokenType.litFalso)) {
      final tok = _advance();
      return BoolLiteralExpr(tok.lexeme == 'verdadero');
    }

    // Token no reconocido como inicio de expresión
    throw SyntaxException(
      "Se esperaba una expresión pero se encontró "
      "'${_peek.lexeme.isEmpty ? _typeName(_peekType) : _peek.lexeme}'",
      _peek.line,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Sección 6 — Construcciones especiales
  // ═══════════════════════════════════════════════════════════════════════════

  // ── Tupla o expresión agrupada ────────────────────────────────────────────

  /// Parsea `"(" <Exp> { "," <Exp> } ")"`.
  ///
  /// - Una sola expresión → retorna la expresión directamente (agrupación).
  /// - Dos o más expresiones → retorna [TuplaExpr].
  Expr _parseParenOrTuple() {
    _consume(TokenType.symLParen, 'Inicio de grupo/tupla');
    final first = _parseExpression();

    if (_match(TokenType.symComma) == null) {
      // Expresión agrupada: ( <Exp> )
      _consume(TokenType.symRParen, 'Cierre de expresión agrupada');
      return first;
    }

    // Tupla: ( <Exp> , <Exp> { , <Exp> } )
    final values = <Expr>[first];
    values.add(_parseExpression());
    while (_match(TokenType.symComma) != null) {
      values.add(_parseExpression());
    }
    _consume(TokenType.symRParen, 'Cierre de tupla');
    return TuplaExpr(values);
  }

  // ── Parámetros actuales ───────────────────────────────────────────────────

  /// Parsea la lista de argumentos de una llamada a función.
  ///
  /// ```ebnf
  /// <ParAct> ::= <Exp> { "," <Exp> }
  /// ```
  ///
  /// Permite lista vacía (retorna `[]`) para funciones sin argumentos.
  List<Expr> _parseParAct() {
    final args = <Expr>[];

    // Si el siguiente token es ')' la lista de argumentos está vacía
    if (_check(TokenType.symRParen)) return args;

    args.add(_parseExpression());
    while (_match(TokenType.symComma) != null) {
      args.add(_parseExpression());
    }

    return args;
  }

  // ── Expresión condicional: caso … fcaso ───────────────────────────────────

  /// Parsea la expresión condicional.
  ///
  /// ```ebnf
  /// <Condic> ::= caso <Exp> "->" <Exp>
  ///              { "[]" <Exp> "->" <Exp> }
  ///              fcaso
  /// ```
  CondicExpr _parseCondic() {
    _consume(TokenType.kwCaso, 'Expresión condicional');

    final branches = <CondBranch>[];

    // Primera rama obligatoria
    final firstCond = _parseExpression();
    _consume(TokenType.symArrow, 'Flecha de primera guarda');
    final firstResult = _parseExpression();
    branches.add(CondBranch(firstCond, firstResult));

    // Ramas adicionales precedidas por '[]'
    while (_match(TokenType.symGuard) != null) {
      final cond = _parseExpression();
      _consume(TokenType.symArrow, 'Flecha de guarda');
      final result = _parseExpression();
      branches.add(CondBranch(cond, result));
    }

    _consume(TokenType.kwFcaso, "Cierre 'fcaso' de expresión condicional");
    return CondicExpr(branches);
  }

  // ── Declaración local: sea … en ───────────────────────────────────────────

  /// Parsea la declaración de variables locales.
  ///
  /// ```ebnf
  /// <DecLoc> ::= sea <id> "=" <Exp> { "," <id> "=" <Exp> } en <Exp>
  /// ```
  DecLocExpr _parseDecLoc() {
    _consume(TokenType.kwSea, 'Declaración local');

    final defs = <VarDef>[];

    // Primera variable obligatoria
    defs.add(_parseVarDef());

    // Variables adicionales separadas por coma
    while (_match(TokenType.symComma) != null) {
      defs.add(_parseVarDef());
    }

    // 'en' <Exp>  — cuerpo donde se usan las variables
    _consume(TokenType.kwEn, "Cuerpo 'en' de declaración local");
    final body = _parseExpression();

    return DecLocExpr(defs, body);
  }

  /// Parsea una definición de variable `<id> "=" <Exp>`.
  VarDef _parseVarDef() {
    final idTok = _consume(TokenType.litId, 'Nombre de variable local');
    _consume(TokenType.opEq, "Asignación de variable '${idTok.lexeme}'");
    final value = _parseExpression();
    return VarDef(idTok.lexeme, value);
  }
}


