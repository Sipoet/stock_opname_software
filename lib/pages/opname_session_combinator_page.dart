import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:stock_opname_software/extensions.dart';
import 'package:stock_opname_software/models/opname_session.dart';
import 'package:stock_opname_software/modules/list_menu.dart';
import 'package:stock_opname_software/modules/opname_excel_generator.dart';

class OpnameSessionCombinatorPage extends StatefulWidget {
  const OpnameSessionCombinatorPage({super.key});

  @override
  State<OpnameSessionCombinatorPage> createState() =>
      _OpnameSessionCombinatorPageState();
}

class _OpnameSessionCombinatorPageState
    extends State<OpnameSessionCombinatorPage>
    with OpnameExcelGenerator, ListMenu {
  late final Database db;
  Map<String, OpnameItem> masterContainers = {};
  String? location;
  List<File> files = [];
  @override
  void initState() {
    db = context.read<Database>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      drawer: menuDrawer(db, activePage: 'opnameSessionCombinator'),
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Stock Opname Combinator'),
        leading: const DrawerButton(),
        actions: [
          ElevatedButton(
            onPressed: _pickFiles,
            child: const Text('Pick File'),
          ),
          const SizedBox(
            width: 10,
          ),
          ElevatedButton(
            onPressed: _combineDataExcel,
            child: const Text('Combine File'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView.separated(
            separatorBuilder: (context, index) => const SizedBox(
              height: 10,
            ),
            itemCount: files.length,
            itemBuilder: (BuildContext context, int index) => ListTile(
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(5),
              ),
              dense: true,
              tileColor: colorScheme.onPrimary,
              textColor: colorScheme.primary,
              title: Text(files[index].path),
              // contentPadding: EdgeInsets.all(10),
              hoverColor: colorScheme.secondary,
              trailing: IconButton(
                  onPressed: () => setState(() {
                        files.removeAt(index);
                      }),
                  icon: const Icon(Icons.close)),
            ),
          ),
        ),
      ),
    );
  }

  void _pickFiles() async {
    FilePicker.platform.pickFiles(allowMultiple: true).then((result) {
      if (result != null) {
        setState(() {
          files = result.paths.map((path) => File(path!)).toList();
        });
      }
    });
  }

  List<OpnameItem> openExcelFile(File file) {
    var bytes = file.readAsBytesSync();
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel['Sheet1'];

    List<OpnameItem> results = [];
    int rowIndex = 2;
    String itemCode;
    int quantity;
    do {
      itemCode = sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 0, rowIndex: rowIndex))
              .value
              ?.toString() ??
          '';
      location ??= sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value
          ?.toString();
      quantity = int.tryParse(sheet
              .cell(CellIndex.indexByColumnRow(
                  columnIndex: 2, rowIndex: rowIndex))
              .value
              .toString()) ??
          0;
      if (itemCode.isNotEmpty) {
        results.add(OpnameItem(
            itemCode: itemCode, quantity: quantity, opnameSessionId: 9999));
      }
      rowIndex += 1;
    } while (itemCode.isNotEmpty);
    return results;
  }

  void combineWithMasterContainer(List<OpnameItem> opnameItems) {
    for (OpnameItem opnameItem in opnameItems) {
      if (masterContainers[opnameItem.itemCode] == null) {
        masterContainers[opnameItem.itemCode] = opnameItem;
      } else {
        masterContainers[opnameItem.itemCode]!.quantity += opnameItem.quantity;
      }
    }
  }

  void _combineDataExcel() async {
    masterContainers = {};
    for (File file in files) {
      var opnameItems = openExcelFile(file);
      combineWithMasterContainer(opnameItems);
    }
    final opnameSession = createOpnameSession();
    generateExcel(opnameSession,
        filename:
            'stock-opname-combine-${files.length.toString()}file-${opnameSession.updatedAt.dateIso()}.xlsx');
  }

  OpnameSession createOpnameSession() {
    return OpnameSession(
        location: location ?? 'TOKO', items: masterContainers.values.toList());
  }
}
