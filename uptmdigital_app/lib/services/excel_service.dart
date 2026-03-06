import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;

class ExcelService {
  Future<void> generateClassListExcel(String asignaturaName, List<dynamic> students) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Lista de Clase'];
    
    // Add Header
    sheetObject.appendRow([TextCellValue('UPTM DIGITAL - Lista de Clase')]);
    sheetObject.appendRow([TextCellValue('Asignatura: $asignaturaName')]);
    sheetObject.appendRow([TextCellValue('Fecha: ${DateTime.now().toIso8601String().split('T')[0]}')]);
    sheetObject.appendRow([TextCellValue('')]);
    
    // Add Table Headers
    sheetObject.appendRow([
      TextCellValue('Cedula'), 
      TextCellValue('Estudiante'), 
      TextCellValue('Correo'),
      TextCellValue('Carrera')
    ]);

    // Add Data
    for (var item in students) {
      final est = item['estudiante'];
      if (est != null) {
        sheetObject.appendRow([
          TextCellValue(est['cedula'] ?? ''),
          TextCellValue("${est['nombres']} ${est['apellidos']}"),
          TextCellValue(est['correoInstitucional'] ?? ''),
          TextCellValue(est['carrera'] ?? '')
        ]);
      }
    }
    
    // Save
    var fileBytes = excel.save();

    if (kIsWeb && fileBytes != null) {
      final blob = html.Blob([fileBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.document.createElement('a') as html.AnchorElement
        ..href = url
        ..style.display = 'none'
        ..download = 'Listado_$asignaturaName.xlsx';
      html.document.body!.children.add(anchor);
      anchor.click();
      html.document.body!.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }
  }
}
