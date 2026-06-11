/*
Proyecto realizado por :
Nombre: William Flores
CI: 24.107.343
Correo: w.flores.s24@gmail.com
*/
import 'dart:io';

import 'package:lr_parser/lexer/lexer.dart';
import 'package:lr_parser/lexer/token.dart';
import 'package:lr_parser/parser/parser.dart';
import 'package:lr_parser/parser/syntax_exception.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Punto de entrada del CLI del analizador léxico-sintáctico LR Parser
// ─────────────────────────────────────────────────────────────────────────────

/// Lee un archivo `.esp`, lo tokeniza y lo parsea.
///
/// ## Modo de uso
/// ```
/// dart run bin/main.dart <archivo.esp>
/// ```
///
/// ## Salidas posibles
/// | Caso | Salida estándar |
/// |------|-----------------|
/// | Análisis exitoso | `Análisis OK` |
/// | Error léxico     | `Error léxico en línea N: <descripción>` |
/// | Error sintáctico | `Error sintáctico en línea N: <descripción>` |
/// | Argumento faltante / archivo no encontrado | Mensaje descriptivo + exit 2 |
void main(List<String> args) {
  // ── 1. Validar argumentos ──────────────────────────────────────────────────
  if (args.isEmpty) {
    _printUsage();
    exit(2);
  }

  final path = args[0];
  final file = File(path);

  if (!file.existsSync()) {
    stderr.writeln('Error: no se encontró el archivo "$path".');
    exit(2);
  }

  // ── 2. Leer el código fuente ───────────────────────────────────────────────
  final String source;
  try {
    source = file.readAsStringSync();
  } catch (e) {
    stderr.writeln('Error al leer "$path": $e');
    exit(2);
  }

  // ── 3. Fase léxica ────────────────────────────────────────────────────────
  final tokens = _runLexer(source, path);
  if (tokens == null) exit(1); // Error léxico ya impreso

  // ── 4. Fase sintáctica ────────────────────────────────────────────────────
  final ok = _runParser(tokens, path);
  if (!ok) exit(1); // Error sintáctico ya impreso

  // ── 5. Salida de éxito ────────────────────────────────────────────────────
  print('Análisis OK');
  exit(0);
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers internos
// ─────────────────────────────────────────────────────────────────────────────

/// Ejecuta la fase léxica y retorna la lista de tokens, o `null` si hubo error.
///
/// Los errores léxicos se imprimen a [stderr] con el formato:
/// `<archivo>: Error léxico en línea N: <descripción>`
List<Token>? _runLexer(String source, String path) {
  try {
    return Lexer(source).tokenize();
  } on LexicalException catch (e) {
    stderr.writeln('$path: $e');
    return null;
  } catch (e) {
    stderr.writeln('$path: Error inesperado en análisis léxico: $e');
    return null;
  }
}

/// Ejecuta la fase sintáctica y retorna `true` si el análisis fue exitoso.
///
/// Los errores sintácticos se imprimen a [stderr] con el formato:
/// `<archivo>: Error sintáctico en línea N: <descripción>`
bool _runParser(List<Token> tokens, String path) {
  try {
    Parser(tokens).parseProgram();
    return true;
  } on SyntaxException catch (e) {
    stderr.writeln('$path: $e');
    return false;
  } catch (e) {
    stderr.writeln('$path: Error inesperado en análisis sintáctico: $e');
    return false;
  }
}

/// Imprime las instrucciones de uso del CLI.
void _printUsage() {
  stderr.writeln('Uso: dart run bin/main.dart <archivo.esp>');
  stderr.writeln('');
  stderr.writeln('  <archivo.esp>  Ruta al archivo fuente a analizar.');
  stderr.writeln('');
  stderr.writeln('Códigos de salida:');
  stderr.writeln('  0  Análisis OK — el archivo es léxica y sintácticamente correcto.');
  stderr.writeln('  1  Error léxico o sintáctico detectado.');
  stderr.writeln('  2  Error de uso (argumento faltante o archivo no encontrado).');
}
