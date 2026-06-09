/// Excepción lanzada por el [Parser] cuando encuentra un token inesperado
/// o una construcción que no se ajusta a la gramática del lenguaje LR.
///
/// Sigue una estrategia **Fail-Fast**: en cuanto se detecta el primer error
/// sintáctico se detiene el análisis y se propaga esta excepción con el
/// contexto preciso del fallo.
///
/// ### Ejemplo de mensaje
/// ```
/// Error sintáctico en línea 3: se esperaba 'ffun' pero se encontró 'fun'
/// ```
class SyntaxException implements Exception {
  /// Descripción detallada del error sintáctico.
  final String message;

  /// Número de línea (1-indexado) donde se detectó el error.
  final int line;

  /// Crea una [SyntaxException] con el [message] y la [line] indicados.
  const SyntaxException(this.message, this.line);

  @override
  String toString() => 'Error sintáctico en línea $line: $message';
}
