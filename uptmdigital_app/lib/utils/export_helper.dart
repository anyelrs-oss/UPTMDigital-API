import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:typed_data';

class ExportHelper {
  /// Exporta una lista de datos a un archivo Excel (.xlsx)
  static Future<void> exportToExcel({
    required String fileName,
    required List<String> headers,
    required List<List<dynamic>> rows,
  }) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // Agregar encabezados
    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(bold: true);
    }

    // Agregar filas
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1));
        cell.value = TextCellValue(rows[r][c].toString());
      }
    }

    final bytes = excel.encode();
    if (bytes != null) {
      await Printing.sharePdf(bytes: Uint8List.fromList(bytes), filename: "$fileName.xlsx");
    }
  }

  /// Genera y abre un reporte PDF con formato institucional
  static Future<void> exportToPDF({
    required String title,
    required List<String> headers,
    required List<List<String>> data,
    String? subtitle,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("UPTM DIGITAL - REPORTE OFICIAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text(DateTime.now().toString().split('.')[0], style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          ),
          if (subtitle != null)
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(top: 8),
                child: pw.Text(subtitle, style: const pw.TextStyle(fontSize: 12)),
              ),
            ),
          pw.SizedBox(height: 30),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            border: pw.TableBorder.all(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
            },
          ),
          pw.SizedBox(height: 50),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              children: [
                pw.Container(width: 150, border: const pw.Border(top: pw.BorderSide(width: 1))),
                pw.Text("Sello y Firma Autorizada", style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
