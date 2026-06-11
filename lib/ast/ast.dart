/*
Proyecto realizado por :
Nombre: William Flores
CI: 24.107.343
Correo: w.flores.s24@gmail.com
*/
/// Nodos del Árbol de Sintaxis Abstracta (AST) para el analizador LR.
///
/// Todos los nodos heredan de [ASTNode]. La jerarquía se divide en dos ramas:
/// - **Declaraciones**: [Prog], [FuncDecl], [ParForm].
/// - **Expresiones**: [Expr] y todas sus subclases.
///
/// El [Parser] construye este árbol a partir de la secuencia de tokens
/// producida por el [Lexer].

// ─────────────────────────────────────────────────────────────────────────────
// Nodo base
// ─────────────────────────────────────────────────────────────────────────────

/// Nodo base del que heredan todos los demás nodos del AST.
abstract class ASTNode {}

// ─────────────────────────────────────────────────────────────────────────────
// Declaraciones
// ─────────────────────────────────────────────────────────────────────────────

/// Raíz del programa: contiene la lista ordenada de funciones declaradas.
///
/// Corresponde a la regla:
/// ```ebnf
/// <Prog> ::= { fun <id> "(" <ParForm> ")" dev "(" <ParForm> ")" "=" <Exp> ffun }
/// ```
class Prog extends ASTNode {
  /// Funciones declaradas en el programa, en orden de aparición.
  final List<FuncDecl> functions;

  /// Crea el nodo raíz con la lista de [functions].
  Prog(this.functions);
}

/// Declaración de una función: nombre, parámetros de entrada, parámetros de
/// salida y expresión cuerpo.
///
/// Corresponde a la regla:
/// ```ebnf
/// fun <id> "(" <ParForm> ")" dev "(" <ParForm> ")" "=" <Exp> ffun
/// ```
class FuncDecl extends ASTNode {
  /// Nombre de la función (identificador).
  final String name;

  /// Parámetros formales de entrada (después de `fun id (`).
  final List<ParForm> params;

  /// Parámetros formales de salida (después de `dev (`).
  final List<ParForm> returns;

  /// Expresión cuerpo de la función (después de `=`).
  final Expr body;

  /// Crea un nodo [FuncDecl] con los atributos indicados.
  FuncDecl(this.name, this.params, this.returns, this.body);
}

/// Parámetro formal: uno o varios identificadores del mismo tipo.
///
/// Ejemplo: `a, b: entero` → `ParForm(['a','b'], 'entero')`.
///
/// Corresponde a la regla:
/// ```ebnf
/// <id> { "," <id> } ":" <Tipo>
/// ```
class ParForm extends ASTNode {
  /// Lista de identificadores del grupo de parámetros.
  final List<String> names;

  /// Tipo de dato declarado (`entero`, `natural`, `vector`, etc.).
  final String type;

  /// Crea un [ParForm] con los [names] e identificador de [type].
  ParForm(this.names, this.type);
}

// ─────────────────────────────────────────────────────────────────────────────
// Expresiones — clase base
// ─────────────────────────────────────────────────────────────────────────────

/// Clase abstracta base para todas las expresiones del lenguaje.
///
/// Las expresiones se estratifican en orden de precedencia creciente:
/// `LogicalOr → LogicalAnd → Equality → Relational → Arith → Term → Factor → Primary`.
abstract class Expr extends ASTNode {}

// ─────────────────────────────────────────────────────────────────────────────
// Expresiones — construcciones de alto nivel
// ─────────────────────────────────────────────────────────────────────────────

/// Declaración de variables locales seguida de una expresión cuerpo.
///
/// ```ebnf
/// sea <id> = <Exp> { "," <id> = <Exp> } en <Exp>
/// ```
///
/// Ejemplo: `sea m = (i + j) div 2 en suma(a, i, m)`.
class DecLocExpr extends Expr {
  /// Lista de definiciones de variables locales (orden de aparición).
  final List<VarDef> definitions;

  /// Expresión donde se usan las variables definidas (cuerpo del `en`).
  final Expr body;

  /// Crea un [DecLocExpr] con las [definitions] y el [body].
  DecLocExpr(this.definitions, this.body);
}

/// Definición de una variable dentro de `sea … en`.
///
/// Ejemplo: `m = (i + j) div 2`.
class VarDef extends ASTNode {
  /// Nombre de la variable local.
  final String id;

  /// Expresión cuyo valor se asigna a [id].
  final Expr value;

  /// Crea un [VarDef] con el [id] y su [value].
  VarDef(this.id, this.value);
}

/// Expresión condicional con guardas múltiples.
///
/// ```ebnf
/// caso <Exp> "->" <Exp> { "[]" <Exp> "->" <Exp> } fcaso
/// ```
///
/// Ejemplo:
/// ```
/// caso n = 0 -> 1
/// [] n > 0   -> a * potencia(a, n - 1)
/// fcaso
/// ```
class CondicExpr extends Expr {
  /// Lista de ramas `condición → resultado`, en orden de evaluación.
  final List<CondBranch> branches;

  /// Crea un [CondicExpr] con las [branches] indicadas.
  CondicExpr(this.branches);
}

/// Una rama de un [CondicExpr]: condición de guarda y expresión resultado.
class CondBranch extends ASTNode {
  /// Expresión booleana que activa esta rama.
  final Expr condition;

  /// Expresión evaluada cuando [condition] es verdadera.
  final Expr result;

  /// Crea un [CondBranch] con la [condition] y el [result].
  CondBranch(this.condition, this.result);
}

// ─────────────────────────────────────────────────────────────────────────────
// Expresiones — operadores
// ─────────────────────────────────────────────────────────────────────────────

/// Expresión binaria con dos operandos y un operador infijo.
///
/// Cubre todos los niveles de la jerarquía: lógico, relacional y aritmético.
///
/// Ejemplos: `a + b`, `n > 0`, `p ^ q`.
class BinaryExpr extends Expr {
  /// Operando izquierdo.
  final Expr left;

  /// Lexema del operador (`+`, `-`, `^`, `v`, `=`, `!=`, `>`, etc.).
  final String operator;

  /// Operando derecho.
  final Expr right;

  /// Crea un [BinaryExpr] con [left], [operator] y [right].
  BinaryExpr(this.left, this.operator, this.right);
}

/// Expresión unaria con un operador prefijo y un operando.
///
/// Operadores posibles: `+` (positivo), `-` (negación aritmética), `¬` (NOT lógico).
///
/// Ejemplo: `¬(a > 0)`, `-n`.
class UnaryExpr extends Expr {
  /// Lexema del operador unario (`+`, `-` o `¬`).
  final String operator;

  /// Operando al que se aplica el operador.
  final Expr operand;

  /// Crea un [UnaryExpr] con el [operator] y el [operand].
  UnaryExpr(this.operator, this.operand);
}

// ─────────────────────────────────────────────────────────────────────────────
// Expresiones — primarios
// ─────────────────────────────────────────────────────────────────────────────

/// Llamada a función con lista de argumentos actuales.
///
/// ```ebnf
/// <id> "(" <ParAct> ")"
/// ```
///
/// Ejemplo: `potencia(a, n - 1)`, `mcd(b, a mod b)`.
class CallExpr extends Expr {
  /// Nombre de la función invocada.
  final String callee;

  /// Lista de expresiones argumento (puede estar vacía).
  final List<Expr> arguments;

  /// Crea un [CallExpr] para la función [callee] con los [arguments].
  CallExpr(this.callee, this.arguments);
}

/// Acceso indexado a un vector.
///
/// ```ebnf
/// <id> "[" <Exp> "]"
/// ```
///
/// Ejemplo: `a[i]`.
class ArrayAccessExpr extends Expr {
  /// Nombre del vector al que se accede.
  final String array;

  /// Expresión que evalúa al índice de acceso.
  final Expr index;

  /// Crea un [ArrayAccessExpr] para el [array] con el [index] dado.
  ArrayAccessExpr(this.array, this.index);
}

/// Tupla: secuencia de dos o más expresiones entre paréntesis.
///
/// ```ebnf
/// "(" <Exp> "," <Exp> { "," <Exp> } ")"
/// ```
///
/// Ejemplo: `(a, b, c)`.
class TuplaExpr extends Expr {
  /// Lista de expresiones que componen la tupla (mínimo 2 elementos).
  final List<Expr> values;

  /// Crea un [TuplaExpr] con los [values] indicados.
  TuplaExpr(this.values);
}

/// Referencia a un identificador (variable, parámetro o nombre de función).
///
/// Ejemplo: `n`, `a`, `mcd`.
class IdExpr extends Expr {
  /// Nombre del identificador referenciado.
  final String name;

  /// Crea un [IdExpr] para el identificador [name].
  IdExpr(this.name);
}

// ─────────────────────────────────────────────────────────────────────────────
// Expresiones — literales
// ─────────────────────────────────────────────────────────────────────────────

/// Literal numérico entero.
///
/// Ejemplos: `0`, `42`, `100`.
class LiteralExpr extends Expr {
  /// Valor entero representado.
  final int value;

  /// Crea un [LiteralExpr] con el [value] dado.
  LiteralExpr(this.value);
}

/// Literal numérico de punto flotante.
///
/// Ejemplos: `3.14`, `0.5`.
class RealLiteralExpr extends Expr {
  /// Valor real representado.
  final double value;

  /// Crea un [RealLiteralExpr] con el [value] dado.
  RealLiteralExpr(this.value);
}

/// Literal de cadena de texto (entre comillas dobles).
///
/// Ejemplo: `"hola mundo"` → `StringLiteralExpr('hola mundo')`.
class StringLiteralExpr extends Expr {
  /// Contenido de la cadena, sin las comillas delimitadoras.
  final String value;

  /// Crea un [StringLiteralExpr] con el [value] dado.
  StringLiteralExpr(this.value);
}

/// Literal de carácter (entre comillas simples).
///
/// Ejemplo: `'x'` → `CharLiteralExpr('x')`.
class CharLiteralExpr extends Expr {
  /// El carácter representado, sin las comillas.
  final String value;

  /// Crea un [CharLiteralExpr] con el [value] dado.
  CharLiteralExpr(this.value);
}

/// Literal booleano: `verdadero` o `falso`.
class BoolLiteralExpr extends Expr {
  /// `true` si el literal es `verdadero`; `false` si es `falso`.
  final bool value;

  /// Crea un [BoolLiteralExpr] con el [value] dado.
  BoolLiteralExpr(this.value);
}
