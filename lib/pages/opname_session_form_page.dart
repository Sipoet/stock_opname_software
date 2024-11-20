import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:stock_opname_software/models/opname_session.dart';
import 'package:stock_opname_software/extensions.dart';
import 'package:stock_opname_software/modules/opname_excel_generator.dart';
import 'package:toastification/toastification.dart';

class OpnameSessionFormPage extends StatefulWidget {
  final OpnameSession opnameSession;
  const OpnameSessionFormPage({required this.opnameSession, super.key});

  @override
  State<OpnameSessionFormPage> createState() => _OpnameSessionFormPageState();
}

class _OpnameSessionFormPageState extends State<OpnameSessionFormPage>
    with OpnameExcelGenerator {
  OpnameSession get opnameSession => widget.opnameSession;
  List<OpnameItem> get opnameItems => widget.opnameSession.items;
  final _focusNode = FocusNode();
  final _qtyController = TextEditingController();
  final _itemCodeController = TextEditingController();

  @override
  void initState() {
    _focusNode.requestFocus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    opnameItems.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
    return Scaffold(
      appBar: AppBar(
        title: Text("Session at: ${opnameSession.updatedAt.formatDate()}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          DropdownMenu<OpnameStatus>(
              label: const Text('Status'),
              initialSelection: opnameSession.status,
              dropdownMenuEntries: OpnameStatus.values
                  .map<DropdownMenuEntry<OpnameStatus>>((status) =>
                      DropdownMenuEntry<OpnameStatus>(
                          value: status, label: status.toString()))
                  .toList()),
          const SizedBox(
            width: 10,
          ),
          DropdownMenu<String>(
            label: const Text('Lokasi'),
            initialSelection: opnameSession.location,
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: 'TOKO', label: 'Toko'),
              DropdownMenuEntry(value: 'GDG', label: 'Gudang'),
            ],
          ),
          const SizedBox(
            width: 10,
          ),
          ElevatedButton(
              onPressed: () => _generateExcel(),
              child: const Text('export Excel')),
          const SizedBox(
            width: 10,
          )
        ],
        leading: IconButton.filled(
            onPressed: _backToHome, icon: const Icon(Icons.arrow_back)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(
          child: Column(
            children: [
              TextFormField(
                focusNode: _focusNode,
                controller: _itemCodeController,
                decoration: InputDecoration(
                  label: const Text('Kode Item/barcode'),
                  icon: IconButton(
                      onPressed: () => _checkCode(_itemCodeController.text),
                      icon: const Icon(Icons.subdirectory_arrow_left)),
                  suffixIcon: IconButton(
                    onPressed: _itemCodeController.clear,
                    icon: const Icon(Icons.clear),
                  ),
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
                ],
                onFieldSubmitted: (String? value) => _checkCode(value),
              ),
              Expanded(
                  child: ListView(
                children: opnameItems
                    .map<ListTile>((opnameItem) => ListTile(
                          title: Text("Kode Item: ${opnameItem.itemCode}"),
                          subtitle: Text(
                              "Tanggal: ${opnameItem.lastUpdated.formatDatetime()}"),
                          leading: Container(
                            constraints: const BoxConstraints(minWidth: 50),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('QTY'),
                                Text(
                                  opnameItem.quantity.toString(),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          trailing: IconButton(
                              onPressed: () => _removeItem(opnameItem),
                              icon: const Icon(Icons.close)),
                        ))
                    .toList(),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _removeItem(opnameItem) {
    setState(() {
      opnameSession.items.remove(opnameItem);
    });
  }

  void _generateExcel() {
    generateExcel(opnameSession).then((fileLocation) {
      if (fileLocation == null) {
        toastification.show(
          type: ToastificationType.error,
          title: const Text('Failed export excel.'),
          autoCloseDuration: const Duration(seconds: 5),
        );
      } else {
        toastification.show(
          type: ToastificationType.success,
          title: const Text('Success export excel.'),
          description: Text('save at $fileLocation'),
          autoCloseDuration: const Duration(seconds: 5),
        );
      }
    });
  }

  void _checkCode(String? value) {
    if (value == null || value.isEmpty) {
      return;
    }
    final focusNode2 = FocusNode();
    _openInputQuantityModal(value, focusNode: focusNode2).then((int? quantity) {
      if (quantity != null) {
        _addOpnameItem(value, quantity);
        _qtyController.text = '';
        _itemCodeController.text = '';
      }
    }).whenComplete(() {
      _focusNode.requestFocus();
    });
  }

  Future<int?> _openInputQuantityModal(String itemCode,
      {FocusNode? focusNode}) {
    focusNode?.requestFocus();
    return showDialog<int>(
        context: context,
        builder: (BuildContext context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              elevation: 5.0,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _qtyController,
                        focusNode: focusNode,
                        decoration:
                            const InputDecoration(label: Text('Jumlah')),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onFieldSubmitted: (value) =>
                            Navigator.of(context).pop(int.tryParse(value)),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                              onPressed: () => Navigator.of(context)
                                  .pop(int.tryParse(_qtyController.text)),
                              child: const Text('submit')),
                          const SizedBox(
                            width: 10,
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(null),
                            child: const Text('cancel'),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ));
  }

  OpnameItem? findOpnameItem(String itemCode) {
    final opnameItem = opnameSession.items.firstWhere(
      (opnameItem) => opnameItem.itemCode == itemCode,
      orElse: () => OpnameItem(),
    );
    if (opnameItem.itemCode.isEmpty) {
      return null;
    }
    return opnameItem;
  }

  void _addOpnameItem(String itemCode, int quantity) {
    OpnameItem? opnameItem = findOpnameItem(itemCode);
    if (opnameItem == null) {
      _insertOpnameItem(itemCode, quantity);
    } else {
      setState(() {
        opnameItem.quantity += quantity;
        opnameItem.lastUpdated = DateTime.now();
      });
    }
  }

  void _insertOpnameItem(String itemCode, int quantity) {
    setState(() {
      opnameSession.items.add(OpnameItem(
        itemCode: itemCode,
        quantity: quantity,
        lastUpdated: DateTime.now(),
      ));
    });
  }

  void _backToHome() {
    Navigator.of(context).pop();
  }
}
