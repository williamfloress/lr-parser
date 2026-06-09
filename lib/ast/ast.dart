// Nodos del Árbol de Sintaxis Abstracta (AST) para el analizador LR

// Nodo base del que heredan todos los demás nodos del AST
abstract class ASTNode {}

// --- Declaraciones ---

// Raíz del programa: contiene la lista de funciones definidas
class Prog extends ASTNode {
  final List<FuncDecl> functions;
  Prog(this.functions);
}

// Declaración de una función: nombre, parámetros de entrada, parámetros de salida y cuerpo
class FuncDecl extends ASTNode {
  final String name;
  final List<ParForm> params;   // Parámetros formales de entrada
  final List<ParForm> returns;  // Parámetros formales de salida (dev)
  final Expr body;

  FuncDecl(this.name, this.params, this.returns, this.body);
}

// Parámetro formal: uno o varios identificadores del mismo tipo (ej: a, b: entero)
class ParForm extends ASTNode {
  final List<String> names; // Identificadores del parámetro
  final String type;        // Tipo de dato (entero, natural, vector, etc.)

  ParForm(this.names, this.type);
}

// --- Expresiones ---

// Clase abstracta base para todas las expresiones del lenguaje
abstract class Expr extends ASTNode {}

// Declaración local: sea <id> = <Exp> {, <id> = <Exp>} en <Exp>
class DecLocExpr extends Expr {
  final List<VarDef> definitions; // Lista de variables locales definidas
  final Expr body;                // Expresión donde se usan las variables

  DecLocExpr(this.definitions, this.body);
}

// Definición de una variable dentro de una declaración local (sea)
class VarDef extends ASTNode {
  final String id;  // Nombre de la variable
  final Expr value; // Valor asignado

  VarDef(this.id, this.value);
}

// Expresión condicional: caso <Exp> -> <Exp> {[] <Exp> -> <Exp>} fcaso
class CondicExpr extends Expr {
  final List<CondBranch> branches; // Lista de ramas condición -> resultado

  CondicExpr(this.branches);
}

// Una rama del caso: condición y su expresión resultado
class CondBranch extends ASTNode {
  final Expr condition; // Condición de la guarda
  final Expr result;    // Expresión resultado si se cumple la condición

  CondBranch(this.condition, this.result);
}

// Expresión binaria: dos operandos y un operador (ej: a + b, a > b, a ^ b)
class BinaryExpr extends Expr {
  final Expr left;
  final String operator;
  final Expr right;

  BinaryExpr(this.left, this.operator, this.right);
}

// Expresión unaria: un operador y un operando (ej: -a, ¬b)
class UnaryExpr extends Expr {
  final String operator;
  final Expr operand;

  UnaryExpr(this.operator, this.operand);
}

// Llamada a función: nombre de la función y lista de argumentos actuales
class CallExpr extends Expr {
  final String callee;          // Nombre de la función
  final List<Expr> arguments;   // Argumentos de la llamada (separados por ,)

  CallExpr(this.callee, this.arguments);
}

// Acceso a un elemento de un vector: id[índice]
class ArrayAccessExpr extends Expr {
  final String array; // Nombre del vector
  final Expr index;   // Expresión del índice

  ArrayAccessExpr(this.array, this.index);
}

// Expresión de vector literal: [<Exp>]
class LiteralArrayExpr extends Expr {
  final Expr value;

  LiteralArrayExpr(this.value);
}

// Tupla: agrupación de expresiones entre paréntesis (<Exp>, <Exp>, ...)
class TuplaExpr extends Expr {
  final List<Expr> values;

  TuplaExpr(this.values);
}

// Constante: id = valor (una variable de solo lectura con valor fijo)
class ConstExpr extends Expr {
  final String id;  // Nombre de la constante
  final Expr value; // Valor asignado (numero, cadena, caracter o booleano)

  ConstExpr(this.id, this.value);
}

// Literal numérico entero (ej: 42, 0)
class LiteralExpr extends Expr {
  final int value;

  LiteralExpr(this.value);
}

// Literal numérico real (ej: 3.14, 0.5)
class RealLiteralExpr extends Expr {
  final double value;

  RealLiteralExpr(this.value);
}

// Literal de cadena de texto encerrada entre comillas dobles (ej: "hola")
class StringLiteralExpr extends Expr {
  /// Contenido de la cadena sin las comillas delimitadoras.
  final String value;

  StringLiteralExpr(this.value);
}

// Literal de carácter encerrado entre comillas simples (ej: 'x')
class CharLiteralExpr extends Expr {
  /// El carácter representado, sin las comillas.
  final String value;

  CharLiteralExpr(this.value);
}

// Literal booleano: verdadero o falso
class BoolLiteralExpr extends Expr {
  final bool value;

  BoolLiteralExpr(this.value);
}

// Referencia a un identificador (variable o constante por nombre)
class IdExpr extends Expr {
  final String name;

  IdExpr(this.name);
}
