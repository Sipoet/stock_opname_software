import 'dart:math';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:stock_opname_software/models/opname_session.dart';
import 'package:excel/excel.dart';
import 'package:stock_opname_software/extensions.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';

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

  Future<ShareResult?> shareFile(OpnameSession opnameSession,
      {String? text}) async {
    final dir = await getTemporaryDirectory();
    final filename = _generateFilename(opnameSession);
    final filePath = p.join(dir.path, filename);
    final data = await generateExcel(opnameSession, filename: filename);
    if (data == null) {
      return null;
    }
    File(filePath).writeAsBytesSync(data);
    final file = XFile(filePath);
    final params = ShareParams(
      previewThumbnail: file,
      files: [file],
    );
    return SharePlus.instance.share(params);
  }

  Future<Uint8List?> generateExcel(OpnameSession opnameSession,
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
    filename ??= _generateFilename(opnameSession);
    final bytes = excel.save(fileName: filename);
    if (bytes == null) {
      return null;
    }
    return Uint8List.fromList(bytes);
  }

  String _generateFilename(OpnameSession opnameSession) {
    int randomNumber = Random().nextInt(8999) + 1000;
    return "stock-opname-${opnameSession.updatedAt.datetimeDigit()}${randomNumber.toString()}.xlsx";
  }

  Future<String?> downloadOpnameExcel(OpnameSession opnameSession,
      {String? filename, Directory? dir}) async {
    final data = await generateExcel(opnameSession);
    if (data == null) {
      return null;
    }
    filename ??= _generateFilename(opnameSession);
    return await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan Excel opname di',
        type: FileType.custom,
        initialDirectory: dir?.path,
        allowedExtensions: ['xlsx'],
        fileName: filename,
        bytes: data);
  }
}
