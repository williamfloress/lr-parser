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
6. [Modo de Uso (CLI)](#modo-de-uso-cli)
7. [Casos de Prueba](#casos-de-prueba)
8. [Fases de Implementación](#fases-de-implementación)
9. [Requisitos](#requisitos)

---

## Objetivo del Proyecto

El objetivo es construir, **desde cero y sin dependencias externas**, un
analizador léxico-sintáctico (*front-end* de compilador) para un pequeño
lenguaje funcional matemático. El lenguaje permite definir funciones con
pre-requisitos, expresiones condicionales estratificadas, declaraciones locales
(`sea … en`) y llamadas recursivas.

El analizador es capaz de:

1. **Tokenizar** el código fuente produciendo una secuencia de tokens con
   número de línea — **Fase 2: Lexer**.
2. **Parsear** la secuencia de tokens y construir un **Árbol de Sintaxis
   Abstracta** (AST) fiel a la gramática EBNF — **Fase 3: Parser**.
3. **Detectar y reportar errores** léxicos y sintácticos indicando la línea
   exacta del problema (*Fail-Fast*) — **Fase 4: CLI**.
4. **Interfaz de línea de comandos** que recibe un archivo `.esp` y emite
   `Análisis OK` o un mensaje de error preciso — **Fase 4: CLI**.

---

## Estructura del Lenguaje

El lenguaje es **funcional y declarativo**. Sus unidades fundamentales son:

| Construcción | Descripción |
|---|---|
| `fun … ffun` | Declaración de función con parámetros de entrada y salida. |
| `dev` | Introduce los parámetros de retorno de la función. |
| `caso … fcaso` | Expresión condicional (guardas múltiples separadas por `[]`). |
| `sea … en` | Declaración de variables locales dentro de una expresión. |
| `prerequisito { … }` | Pre-condición de la función — **ignorada** por el Lexer. |
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
            | <Condic>
            | <DecLoc>
            | <valor>
            | <id>
            | "(" <Exp> ")"

<ParAct> ::= <Exp> { "," <Exp> }

<Condic> ::= caso <Exp> "->" <Exp> { "[]" <Exp> "->" <Exp> } fcaso

<DecLoc> ::= sea <id> "=" <Exp> { "," <id> "=" <Exp> } en <Exp>

<valor>  ::= <numero> | <cadena> | <caracter> | <booleano>
```

---

## Reglas Léxicas

| Token | Descripción | Ejemplos |
|---|---|---|
| `<id>` | Letra seguida de letras, dígitos o `_` | `mcd`, `a1`, `potencia` |
| `<numero>` | Secuencia de dígitos; con `.` si es real | `42`, `3.14` |
| `<cadena>` | Caracteres entre comillas dobles | `"hola mundo"` |
| `<caracter>` | Un carácter entre comillas simples | `'x'` |
| `<booleano>` | Literales | `verdadero`, `falso` |
| `{ … }` | Bloque de pre-requisito — **ignorado completamente** | `prerequisito { a >= 0 }` |
| `[]` | Separador de rama en `caso` (*maximal munch*) | `[] n > 0 -> …` |
| `->` | Flecha de guarda (*maximal munch*) | `caso b = 0 -> a` |
| `!=` `>=` `<=` | Operadores compuestos (*maximal munch*) | `a != b`, `n >= 0` |

---

## Arquitectura del Proyecto

```
lr-parser/
├── bin/
│   └── main.dart              # CLI — punto de entrada del analizador
├── ejemplos/
│   ├── prueba1_potencia.esp   # Función potencia (recursión simple)
│   ├── prueba2_suma.esp       # Suma sobre vector con sea/en
│   ├── prueba3_mcd.esp        # MCD con prerequisito ignorado
│   ├── programa_completo.esp  # Las 3 funciones en un solo archivo
│   ├── error_punto_y_coma.esp # Error: ';' inesperado (SyntaxException)
│   └── error_sin_ffun.esp     # Error: 'ffun' faltante (SyntaxException)
├── lib/
│   ├── ast/
│   │   └── ast.dart           # Nodos del AST (Fase 1)
│   └── lexer/
│       ├── token_type.dart    # Enum TokenType — 50+ variantes (Fase 2)
│       ├── token.dart         # Clase Token(type, lexeme, line) (Fase 2)
│       ├── lexer.dart         # Clase Lexer + LexicalException (Fase 2)
│       └── lexer_lib.dart     # Barrel de exportaciones
│   └── parser/
│       ├── syntax_exception.dart  # SyntaxException Fail-Fast (Fase 4)
│       ├── parser.dart            # Parser descendente recursivo (Fase 3)
│       └── parser_lib.dart        # Barrel de exportaciones
├── documentacion/
│   ├── EBNF.md                # Gramática EBNF formal
│   └── casos-prueba.md        # Programas de prueba del lenguaje
└── pubspec.yaml
```

---

## Modo de Uso (CLI)

### Instalación de dependencias

```bash
dart pub get
```

### Analizar un archivo `.esp`

```bash
dart run bin/main.dart <archivo.esp>
```

### Ejemplos de ejecución

```bash
# ── Análisis exitoso ──────────────────────────────────────────────────────────
dart run bin/main.dart ejemplos/prueba1_potencia.esp
# Salida: Análisis OK

dart run bin/main.dart ejemplos/programa_completo.esp
# Salida: Análisis OK

# ── Error sintáctico ──────────────────────────────────────────────────────────
dart run bin/main.dart ejemplos/error_sin_ffun.esp
# Salida (stderr): ejemplos/error_sin_ffun.esp: Error sintáctico en línea 5:
#   Cierre de función 'potencia': se esperaba 'ffun' pero se encontró '<fin de archivo>'

dart run bin/main.dart ejemplos/error_punto_y_coma.esp
# Salida (stderr): ejemplos/error_punto_y_coma.esp: Error sintáctico en línea 3:
#   Cierre 'fcaso' de expresión condicional: se esperaba 'fcaso' pero se encontró ';'

# ── Uso incorrecto ────────────────────────────────────────────────────────────
dart run bin/main.dart
# Salida (stderr): Uso: dart run bin/main.dart <archivo.esp>
#   ...
```

### Códigos de salida

| Código | Significado |
|--------|-------------|
| `0` | `Análisis OK` — el archivo es léxica y sintácticamente correcto |
| `1` | Error léxico o sintáctico detectado (mensaje en stderr con línea) |
| `2` | Error de uso: argumento faltante o archivo no encontrado |

### Formato de mensajes de error

```
<archivo.esp>: Error léxico en línea N: <descripción>
<archivo.esp>: Error sintáctico en línea N: <descripción>
```

Los mensajes de error siempre indican:
- El archivo analizado
- Si es error léxico o sintáctico
- La línea exacta donde ocurrió
- Lo que se esperaba y lo que se encontró (errores sintácticos)

---

## Casos de Prueba

### Prueba 1 — Función Potencia (`prueba1_potencia.esp`)

```
fun potencia(a: entero; n: natural) dev (q: entero) =
    caso n = 0 -> 1
    [] n > 0   -> a * potencia(a, n - 1)
    fcaso
ffun
```

### Prueba 2 — Suma sobre Vector (`prueba2_suma.esp`)

```
fun suma(a: vector; i, j: entero) dev (s: entero) =
    caso i > j -> 0
    [] i = j   -> a[i]
    [] i < j   -> sea m = (i + j) div 2 en
                      suma(a, i, m) + suma(a, m + 1, j)
    fcaso
ffun
```

**Construcciones verificadas:** `sea … en`, `a[i]`, `div` como operador, llamada recursiva con múltiples argumentos.

### Prueba 3 — MCD / Euclides (`prueba3_mcd.esp`)

```
prerequisito {a >= 0 ^ b >= 0 ^ ¬(a = 0 ^ b = 0)}

fun mcd(a, b: entero) dev (m: entero) =
    caso b = 0          -> a
    [] a = 0            -> b
    [] a >= b ^ b != 0  -> mcd(b, a mod b)
    [] b > a ^ a != 0   -> mcd(a, b mod a)
    fcaso
ffun
```

**Construcciones verificadas:** bloque `prerequisito { … }` ignorado, `mod`, `>=`, `!=`, `^` en guardia.

---

## Fases de Implementación

| Fase | Estado | Descripción |
|---|---|---|
| **1** | ✅ Completa | Ingeniería de gramática y diseño del AST |
| **2** | ✅ Completa | Analizador léxico (Lexer / Tokenizer) |
| **3** | ✅ Completa | Analizador sintáctico (Parser) |
| **4** | ✅ Completa | Manejo de errores y CLI |
| **5** | ✅ Completa | Documentación y entrega |

---

## Requisitos

- **Dart SDK** `>=3.0.0 <4.0.0`
- Sin dependencias externas (solo biblioteca estándar de Dart)

```bash
# Verificar instalación del SDK
dart --version

# Obtener dependencias (ninguna externa en este proyecto)
dart pub get

# Análisis estático del código fuente
dart analyze
```
