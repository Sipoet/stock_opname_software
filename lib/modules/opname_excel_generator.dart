import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stock_opname_software/models/opname_session.dart';
import 'package:excel/excel.dart';
import 'package:stock_opname_software/extensions.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:downloadsfolder/downloadsfolder.dart' as df;

mixin OpnameExcelGenerator {
  int androidSdkInt = 0;
  Future<bool> _checkPermission() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      final androidInfo = await deviceInfoPlugin.androidInfo;
      androidSdkInt = androidInfo.version.sdkInt;
      if (androidSdkInt <= 32) {
        return await Permission.storage.request().isGranted;
      } else {
        return true;
      }
    } else {
      return true;
    }
  }

  Future<String?> generateExcel(OpnameSession opnameSession,
      {String? filename}) async {
    if (!await _checkPermission()) {
      return null;
    }
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
    cell = sheetObject.cell(CellIndex.indexByString('E1'));
    cell.value = TextCellValue('RAK (5)');
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
          "opname session at ${opnameSession.updatedAt.formatDate()}. last check at ${opnameItem.updatedAt.formatDatetime()}");
      cell = sheetObject.cell(
          CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: index + 1));
      cell.value = TextCellValue(opnameItem.rackFormat);
    }
    var fileBytes = excel.save();
    int randomNumber = Random().nextInt(8999) + 1000;
    filename ??=
        "stock-opname-${opnameSession.updatedAt.datetimeDigit()}${randomNumber.toString()}.xlsx";
    String? fileLocation = await _findLocation(filename);

    if (fileBytes != null && fileLocation != null) {
      return _saveFile(fileLocation, fileBytes, filename);
    } else {
      return null;
    }
  }

  Future<String?> _saveFile(
      String fileLocation, List<int> fileBytes, String filename) async {
    late File file;
    try {
      file = File(fileLocation)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      return fileLocation;
    } catch (e) {
      final dir = await getApplicationCacheDirectory();
      final newFileLocation = p.join(dir.path, filename);
      file = File(newFileLocation)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      await df.copyFileIntoDownloadFolder(newFileLocation, filename,
          file: file, desiredExtension: 'xlsx');
      file.delete();
      return fileLocation;
    }
  }

  Future<String?> _findLocation(String filename) async {
    Directory dir = await df.getDownloadDirectory();
    if (Platform.isAndroid) {
      return p.join(dir.path, filename);
    }
    return await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Excel opname di',
        type: FileType.custom,
        initialDirectory: dir.path,
        allowedExtensions: ['xlsx'],
        fileName: filename);
  }
}
