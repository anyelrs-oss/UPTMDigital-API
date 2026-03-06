import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:uptmdigital_app/models/constancia.dart';

class PdfService {
  Future<void> generateAndPrintConstancia(Constancia constancia, String studentName, String cedula) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Center(child: pw.Text("UPTM DIGITAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24))),
            ),
            pw.SizedBox(height: 50),
            pw.Text("CONSTANCIA", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 30),
            pw.Paragraph(
              text: "Por medio de la presente se hace constar que el ciudadano(a) $studentName, titular de la cédula de identidad N° $cedula, es estudiante regular de esta institución.",
              style: const pw.TextStyle(fontSize: 14),
              textAlign: pw.TextAlign.justify,
            ),
            pw.SizedBox(height: 20),
            pw.Paragraph(
              text: "Tipo de Constancia: ${constancia.tipoConstancia}",
              style: const pw.TextStyle(fontSize: 14),
            ),
             pw.Paragraph(
              text: "Estado: ${constancia.estado}",
              style: const pw.TextStyle(fontSize: 14),
            ),
            pw.SizedBox(height: 50),
            pw.Text("Se expide la presente a petición de la parte interesada."),
            pw.SizedBox(height: 20),
            pw.Text("Fecha: ${DateTime.now().toString().split(' ')[0]}"),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("UPTM Digital - Sistema de Gestión Académica", style: const pw.TextStyle(color: PdfColors.grey)),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }

  Future<void> generateClassListPdf(String asignaturaName, List<dynamic> students) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (context) => pw.Column(
          children: [
            pw.Center(child: pw.Text("UPTM DIGITAL", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24))),
            pw.SizedBox(height: 10),
            pw.Text("LISTA DE CLASE", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.Text("Asignatura: $asignaturaName", style: const pw.TextStyle(fontSize: 14)),
            pw.Text("Fecha: ${DateTime.now().toString().split(' ')[0]}", style: const pw.TextStyle(fontSize: 12)),
            pw.SizedBox(height: 20),
          ]
        ),
        footer: (context) => pw.Column(
          children: [
             pw.Divider(),
             pw.Row(
               mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
               children: [
                 pw.Text("UPTM Digital", style: const pw.TextStyle(fontSize: 10)),
                 pw.Text("Página ${context.pageNumber} de ${context.pagesCount}", style: const pw.TextStyle(fontSize: 10)),
               ]
             )
          ]
        ),
        build: (pw.Context context) {
          return [
            pw.Table.fromTextArray(
              context: context,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              data: <List<String>>[
                <String>['#', 'Cédula', 'Nombre Completo', 'Correo'],
                ...students.asMap().entries.map((entry) {
                  final index = entry.key + 1;
                  final est = entry.value['estudiante'];
                  return [
                    index.toString(),
                    est['cedula'] ?? '-',
                    "${est['nombres']} ${est['apellidos']}",
                    est['correoInstitucional'] ?? '-',
                  ];
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
    );
  }
}
