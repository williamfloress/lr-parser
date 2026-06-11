/*
Proyecto realizado por :
Nombre: William Flores
CI: 24.107.343
Correo: w.flores.s24@gmail.com
*/
/// Enumeración de todos los tipos de tokens reconocidos por el analizador léxico.
///
/// Los tokens se agrupan en las siguientes categorías:
///   - Palabras clave del lenguaje (fun, dev, sea, en, caso, fcaso, ffun, etc.)
///   - Tipos de datos primitivos (entero, natural, real, booleano, caracter, cadena, vector)
///   - Valores literales booleanos (verdadero, falso)
///   - Operadores aritméticos, lógicos y relacionales
///   - Símbolos compuestos y puntuación
///   - Literales (identificadores, números enteros, reales, cadenas de texto, caracteres)
///   - Tokens de control (EOF)
enum TokenType {
  // ── Palabras clave ────────────────────────────────────────────────────────

  /// Inicio de declaración de función: `fun`
  kwFun,

  /// Fin de declaración de función: `ffun`
  kwFfun,

  /// Sección de valor de retorno: `dev`
  kwDev,

  /// Inicio de declaración local: `sea`
  kwSea,

  /// Separador cuerpo en declaración local: `en`
  kwEn,

  /// Inicio de expresión condicional: `caso`
  kwCaso,

  /// Fin de expresión condicional: `fcaso`
  kwFcaso,

  /// Etiqueta de pre-requisito (ignorado por el lexer): `prerequisito`
  kwPrerequisito,

  // ── Tipos de datos ────────────────────────────────────────────────────────

  /// Tipo entero: `entero`
  tyEntero,

  /// Tipo natural (entero no negativo): `natural`
  tyNatural,

  /// Tipo real (punto flotante): `real`
  tyReal,

  /// Tipo booleano: `booleano`
  tyBooleano,

  /// Tipo carácter: `caracter`
  tyCaracter,

  /// Tipo cadena de texto: `cadena`
  tyCadena,

  /// Tipo vector (arreglo): `vector`
  tyVector,

  // ── Literales booleanos ───────────────────────────────────────────────────

  /// Valor booleano verdadero: `verdadero`
  litVerdadero,

  /// Valor booleano falso: `falso`
  litFalso,

  // ── Operadores lógicos ────────────────────────────────────────────────────

  /// Disyunción lógica (OR): `v`
  opOr,

  /// Conjunción lógica (AND): `^`
  opAnd,

  /// Negación lógica: `¬`
  opNot,

  // ── Operadores relacionales ───────────────────────────────────────────────

  /// Igualdad: `=`
  opEq,

  /// Desigualdad: `!=`
  opNeq,

  /// Mayor que: `>`
  opGt,

  /// Menor que: `<`
  opLt,

  /// Mayor o igual que: `>=`
  opGe,

  /// Menor o igual que: `<=`
  opLe,

  // ── Operadores aritméticos ────────────────────────────────────────────────

  /// Suma: `+`
  opPlus,

  /// Resta: `-`
  opMinus,

  /// Multiplicación: `*`
  opStar,

  /// División real: `/`
  opSlash,

  /// División entera: `div`
  opDiv,

  /// Módulo: `mod`
  opMod,

  // ── Símbolos de puntuación ────────────────────────────────────────────────

  /// Paréntesis izquierdo: `(`
  symLParen,

  /// Paréntesis derecho: `)`
  symRParen,

  /// Corchete izquierdo: `[`
  symLBracket,

  /// Corchete derecho: `]`
  symRBracket,

  /// Coma: `,`
  symComma,

  /// Punto y coma: `;`
  symSemicolon,

  /// Dos puntos: `:`
  symColon,

  /// Flecha de guarda: `->`
  symArrow,

  /// Separador de rama: `[]`
  symGuard,

  // ── Literales ─────────────────────────────────────────────────────────────

  /// Identificador: letra seguida de letras o dígitos (ej. `mcd`, `a1`)
  litId,

  /// Número entero: secuencia de dígitos (ej. `42`)
  litInt,

  /// Número real: entero con punto decimal (ej. `3.14`)
  litReal,

  /// Cadena de texto: contenido entre comillas dobles (ej. `"hola"`)
  litString,

  /// Carácter: contenido entre comillas simples (ej. `'x'`)
  litChar,

  // ── Control ───────────────────────────────────────────────────────────────

  /// Fin de archivo (End Of File)
  eof,
}
