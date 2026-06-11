/*
Proyecto realizado por :
Nombre: William Flores
CI: 24.107.343
Correo: w.flores.s24@gmail.com
*/
/// Módulo del analizador sintáctico (Parser) del proyecto LR Parser.
///
/// Exporta los componentes de la fase de análisis sintáctico:
/// - [Parser]: analizador descendente recursivo que construye el AST.
/// - [SyntaxException]: excepción lanzada ante errores sintácticos.
/// - Nodos adicionales del AST definidos en el parser:
///   [RealLiteralExpr], [StringLiteralExpr], [CharLiteralExpr], [BoolLiteralExpr].
library parser;

export 'syntax_exception.dart';
export 'parser.dart';
