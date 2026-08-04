import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Una fila de resultado a mostrar en el PDF (etiqueta + valor).
class FilaPdf {
  final String etiqueta;
  final String valor;
  const FilaPdf(this.etiqueta, this.valor);
}

/// Genera y abre el diálogo nativo de imprimir/guardar como PDF con un
/// reporte simple: título, subtítulo opcional, tabla de resultados y
/// una nota al pie. Se usa desde cualquier calculadora de StructIA.
Future<void> exportarResultadosPdf({
  required String titulo,
  String? subtitulo,
  required List<FilaPdf> filas,
  String? nota,
}) async {
  final documento = pw.Document();

  documento.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'StructIA',
              style: pw.TextStyle(fontSize: 14, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              titulo,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            if (subtitulo != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(subtitulo, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
            ],
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
              },
              children: filas.map((fila) {
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(fila.etiqueta),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        fila.valor,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            if (nota != null) ...[
              pw.SizedBox(height: 20),
              pw.Text(
                nota,
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
              ),
            ],
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) => documento.save(),
    name: titulo,
  );
}
