# LR Parser — Analizador Léxico y Sintáctico en Dart

> Analizador léxico-sintáctico nativo escrito en **Dart puro** para un lenguaje
> de especificación funcional de algoritmos basado en la notación matemática
> usada en cursos de Algoritmos y Estructuras de Datos.

---

## Tabla de Contenidos

1. [Objetivo del Proyecto](#objetivo-del-proyecto)
2. [Estructura del Lenguaje](#estructura-del-lenguaje)
3. [Gramática EBNF](#gramática-ebnf)
4. [Reglas Léxicas](#reglas-léxicas)
5. [Arquitectura del Proyecto](#arquitectura-del-proyecto)
6. [Fases de Implementación](#fases-de-implementación)
7. [Casos de Prueba](#casos-de-prueba)
8. [Modo de Uso](#modo-de-uso)
9. [Requisitos](#requisitos)

---

## Objetivo del Proyecto

El objetivo es construir, **desde cero y sin dependencias externas**, un
analizador léxico-sintáctico (*front-end* de compilador) para un pequeño
lenguaje funcional matemático. El lenguaje permite definir funciones con
pre-requisitos, expresiones condicionales estratificadas, declaraciones locales
(`sea … en`) y llamadas recursivas.

El analizador debe ser capaz de:

1. **Tokenizar** el código fuente produciendo una secuencia de tokens con
   número de línea (Fase 2 — Lexer).
2. **Parsear** la secuencia de tokens y construir un **Árbol de Sintaxis
   Abstracta** (AST) fiel a la gramática EBNF definida (Fase 3 — Parser).
3. **Detectar y reportar errores** léxicos y sintácticos indicando la línea
   exacta del problema, siguiendo una estrategia *Fail-Fast* (Fase 4).
4. Integrarse en una **interfaz de línea de comandos** que reciba un archivo
   `.esp` y emita `Análisis OK` o un mensaje de error (Fase 4).

---

## Estructura del Lenguaje

El lenguaje es **funcional y declarativo**. Sus unidades fundamentales son:

| Construcción | Descripción |
|---|---|
| `fun … ffun` | Declaración de función con parámetros de entrada y salida. |
| `dev` | Palabra clave que introduce los parámetros de retorno de la función. |
| `caso … fcaso` | Expresión condicional (guardas múltiples separadas por `[]`). |
| `sea … en` | Declaración de variables locales dentro de una expresión. |
| `prerequisito { … }` | Pre-condición de la función (bloque ignorado por el lexer). |
| Operadores | Aritméticos (`+`, `-`, `*`, `/`, `div`, `mod`), lógicos (`^`, `v`, `¬`), relacionales (`=`, `!=`, `<`, `>`, `<=`, `>=`). |

### Tipos de Datos

`entero` · `natural` · `real` · `booleano` · `caracter` · `cadena` · `vector`

---

## Gramática EBNF

La gramática es **estratificada** para expresar la precedencia de operadores
sin ambigüedad y habilitar un análisis descendente recursivo (LL).

```ebnf
<Prog> ::= { fun <id> "(" <ParForm> ")" dev "(" <ParForm> ")" "=" <Exp> ffun }

<ParForm> ::= <id> { "," <id> } ":" <Tipo> { ";" <id> { "," <id> } ":" <Tipo> }

<Tipo> ::= entero | natural | real | booleano | caracter | cadena | vector | <id>

(* Punto de entrada de expresiones *)
<Exp> ::= <LogicalOrExp>

(* Estratificación — mayor número = mayor precedencia *)
<LogicalOrExp>  ::= <LogicalAndExp>  { "v"  <LogicalAndExp>  }
<LogicalAndExp> ::= <EqualityExp>    { "^"  <EqualityExp>    }
<EqualityExp>   ::= <RelationalExp>  { ("=" | "!=") <RelationalExp> }
<RelationalExp> ::= <ArithExp>       { (">" | "<" | ">=" | "<=") <ArithExp> }
<ArithExp>      ::= <Term>           { ("+" | "-") <Term>    }
<Term>          ::= <Factor>         { ("*" | "/" | "div" | "mod") <Factor> }
<Factor>        ::= [ "+" | "-" | "¬" ] <Primary>

<Primary> ::= <id> "(" <ParAct> ")"    (* llamada a función *)
            | <id> "[" <Exp>  "]"      (* acceso a vector   *)
            | <Const>
            | <Tupla>
            | <valor>
            | <id>
            | "(" <Exp> ")"

<ParAct> ::= <Exp> { "," <Exp> }

<Tupla>  ::= "(" <Exp> { "," <Exp> } ")"

<Condic> ::= caso <Exp> "->" <Exp> { "[]" <Exp> "->" <Exp> } fcaso

<DecLoc> ::= sea <id> "=" <Exp> { "," <id> "=" <Exp> } en <Exp>

<Const>  ::= <id> "=" <valor>

<valor>  ::= <numero> | <cadena> | <caracter> | <booleano>
```

> **Nota sobre `<Condic>` y `<DecLoc>`**: estas formas son reconocidas a nivel
> de `<Primary>` cuando el token de apertura es `caso` o `sea` respectivamente.

---

## Reglas Léxicas

| Token | Descripción | Ejemplos |
|---|---|---|
| `<id>` | Letra seguida de letras, dígitos o `_` | `mcd`, `a1`, `potencia` |
| `<numero>` | Secuencia de dígitos; con `.` si es real | `42`, `3.14` |
| `<cadena>` | Caracteres entre comillas dobles | `"hola mundo"` |
| `<caracter>` | Un carácter entre comillas simples | `'x'` |
| `<booleano>` | Literales | `verdadero`, `falso` |
| `{ … }` | Bloque de pre-requisito — **ignorado** | `prerequisito { a >= 0 }` |
| `[]` | Separador de rama en `caso` | `[] n > 0 -> …` |
| `->` | Flecha de guarda | `caso b = 0 -> a` |
| Operadores compuestos | `!=`, `>=`, `<=` | `a != b` |

### Prioridad de reconocimiento

El lexer aplica la regla **máximo avance** (*maximal munch*): siempre consume
el lexema más largo posible. Así, `[]` se reconoce como `symGuard` antes que
dos tokens `[` y `]` por separado, y `->` como `symArrow` antes que `-` y `>`.

---

## Arquitectura del Proyecto

```
lr-parser/
├── lib/
│   ├── ast/
│   │   └── ast.dart          # Nodos del AST (Fase 1)
│   └── lexer/
│       ├── token_type.dart   # Enum TokenType (Fase 2)
│       ├── token.dart        # Clase Token (Fase 2)
│       ├── lexer.dart        # Clase Lexer + LexicalException (Fase 2)
│       └── lexer_lib.dart    # Barrel de exportaciones
├── documentacion/
│   ├── EBNF.md               # Gramática EBNF formal
│   └── casos-prueba.md       # Programas de prueba del lenguaje
├── pubspec.yaml
└── README.md
```

---

## Fases de Implementación

| Fase | Estado | Descripción |
|---|---|---|
| **1** | ✅ Completa | Ingeniería de gramática y diseño del AST |
| **2** | ✅ Completa | Analizador léxico (Lexer / Tokenizer) |
| **3** | 🔲 Pendiente | Analizador sintáctico (Parser) |
| **4** | 🔲 Pendiente | Manejo de errores y CLI |
| **5** | 🔲 Pendiente | Documentación final y entrega |

### Fase 1 — AST (`lib/ast/ast.dart`)

Define la jerarquía de nodos Dart que el parser poblará:

- `Prog` — raíz del programa (lista de `FuncDecl`).
- `FuncDecl` — función: nombre, parámetros de entrada/salida y cuerpo.
- `ParForm` — parámetro formal: lista de identificadores + tipo.
- `DecLocExpr`, `VarDef` — expresión `sea … en`.
- `CondicExpr`, `CondBranch` — expresión `caso … fcaso`.
- `BinaryExpr`, `UnaryExpr` — operadores binarios y unarios.
- `CallExpr`, `ArrayAccessExpr` — llamada a función y acceso a vector.
- `LiteralExpr`, `IdExpr` — valores hoja del árbol.

### Fase 2 — Lexer (`lib/lexer/`)

Recorre el código fuente carácter a carácter y produce tokens:

| Archivo | Responsabilidad |
|---|---|
| `token_type.dart` | Enum `TokenType` con 50+ variantes comentadas |
| `token.dart` | Clase inmutable `Token(type, lexeme, line)` |
| `lexer.dart` | Clase `Lexer` con método `tokenize()` y `LexicalException` |

Comportamientos especiales del Lexer:

- **Ignorar bloques `{ … }`**: los pre-requisitos y sus llaves se consumen sin
  producir ningún token.
- **Ignorar `prerequisito`**: la palabra clave y el bloque que la sigue se
  omiten juntos.
- **Símbolo `[]`**: detectado antes que `[` suelto, produciendo `symGuard`.
- **Símbolo `->`**: detectado antes que `-` suelto, produciendo `symArrow`.
- **Reales**: `3.14` se produce como `litReal`; `3` como `litInt`.
- **Error léxico**: se lanza `LexicalException` con número de línea.

---

## Casos de Prueba

### Prueba 1 — Función Potencia

```
fun potencia(a: entero; n: natural) dev (q: entero) =
    caso n = 0 -> 1
    [] n > 0  -> a * potencia(a, n - 1)
    fcaso
ffun
```

**Tokens esperados (resumen):** `kwFun` · `litId("potencia")` · `symLParen` ·
`litId("a")` · `symColon` · `tyEntero` · `symSemicolon` · `litId("n")` ·
`symColon` · `tyNatural` · `symRParen` · `kwDev` · `symLParen` ·
`litId("q")` · `symColon` · `tyEntero` · `symRParen` · `opEq` · `kwCaso` ·
`litId("n")` · `opEq` · `litInt("0")` · `symArrow` · `litInt("1")` ·
`symGuard` · `litId("n")` · `opGt` · `litInt("0")` · `symArrow` · … · `kwFcaso` · `kwFfun`

---

### Prueba 2 — Suma sobre un vector

```
fun suma(a: vector; i, j: entero) dev (s: entero) =
    caso i > j -> 0
    [] i = j   -> a[i]
    [] i < j   -> sea m = (i + j) div 2 en
                      suma(a, i, m) + suma(a, m + 1, j)
    fcaso
ffun
```

**Tokens destacados:** `symLBracket` / `symRBracket` en `a[i]`; `kwSea`,
`opEq`, `kwEn` en la declaración local; `opDiv` para `div`.

---

### Prueba 3 — Máximo Común Divisor (con pre-requisito)

```
prerequisito { a >= 0 ^ b >= 0 ^ ¬(a = 0 ^ b = 0) }

fun mcd(a, b: entero) dev (m: entero) =
    caso b = 0      -> a
    [] a = 0        -> b
    [] a >= b ^ b != 0 -> mcd(b, a mod b)
    [] b > a ^ a != 0  -> mcd(a, b mod a)
    fcaso
ffun
```

**Comportamiento especial:** el bloque `prerequisito { … }` es completamente
ignorado por el Lexer; el primer token visible es `kwFun`.

---

## Modo de Uso

> La CLI se implementará en la **Fase 4**. Por ahora puede usarse el Lexer
> directamente desde Dart:

```dart
import 'lib/lexer/lexer_lib.dart';

void main() {
  const source = '''
    fun suma(a, b: entero) dev (s: entero) = a + b
    ffun
  ''';

  final lexer  = Lexer(source);
  final tokens = lexer.tokenize();

  for (final token in tokens) {
    print(token); // Token(kwFun, 'fun', línea 2) ...
  }
}
```

Salida esperada:
```
Token(kwFun, 'fun', línea 2)
Token(litId, 'suma', línea 2)
Token(symLParen, '(', línea 2)
Token(litId, 'a', línea 2)
...
Token(eof, '', línea 3)
```

Cuando se complete la Fase 4, el uso será:

```bash
dart run bin/main.dart programa.esp
# Salida: Análisis OK  ó  Error léxico/sintáctico en línea N: <descripción>
```

---

## Requisitos

- **Dart SDK** `>=3.0.0 <4.0.0`
- Sin dependencias externas (solo biblioteca estándar de Dart).

```bash
# Verificar instalación
dart --version

# Ejecutar análisis estático
dart analyze
```
