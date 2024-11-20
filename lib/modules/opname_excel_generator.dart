import 'package:stock_opname_software/models/opname_session.dart';
import 'package:excel/excel.dart';
import 'package:stock_opname_software/extensions.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

mixin OpnameExcelGenerator {
  Future<String?> generateExcel(OpnameSession opnameSession) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    final cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.fromHexString('#FFCC99'),
        bold: true,
        textWrapping: TextWrapping.WrapText);
    var cell = sheetObject.cell(CellIndex.indexByString('A1'));
    cell.value = TextCellValue('KODE ITEM / BARCODE (1)');
    cell.cellStyle = cellStyle;
    cell = sheetObject.cell(CellIndex.indexByString('B1'));
    cell.value = TextCellValue('KODE GUDANG (2)');
    cell.cellStyle = cellStyle;
    cell = sheetObject.cell(CellIndex.indexByString('C1'));
    cell.value = TextCellValue('JUMLAH FISIK SATUAN DASAR (3)');
    cell.cellStyle = cellStyle;
    cell = sheetObject.cell(CellIndex.indexByString('D1'));
    cell.value = TextCellValue('KETERANGAN (4)');
    cell.cellStyle = cellStyle;
    opnameSession.items.sort((a, b) => a.itemCode.compareTo(b.itemCode));
    for (final (index, opnameItem) in opnameSession.items.indexed) {
      cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: index + 1));
      cell.value = TextCellValue(opnameItem.itemCode);
      cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: index + 1));
      cell.value = TextCellValue(opnameSession.location);
      cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: index + 1));
      cell.value = IntCellValue(opnameItem.quantity);
      cell.cellStyle = CellStyle(
          numberFormat: const CustomNumericNumFormat(formatCode: '#,##0'));
      cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: index + 1));
      cell.value = TextCellValue(
          "opname session at ${opnameSession.updatedAt.formatDate()}. last check at ${opnameItem.lastUpdated.formatDatetime()}");
    }
    var fileBytes = excel.save();
    Directory? directory = await getDownloadsDirectory();
    if (fileBytes != null && directory != null) {
      final fileLocation = p.join(directory.path,
          'stock-opname-${opnameSession.updatedAt.dateIso()}.xlsx');
      File(fileLocation)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      return fileLocation;
    } else {
      return null;
    }
  }
}
