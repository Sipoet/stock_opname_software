import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stock_opname_software/models/application_record.dart';

import 'package:stock_opname_software/models/opname_session.dart';
import 'package:stock_opname_software/extensions.dart';
import 'package:stock_opname_software/modules/confirm_dialog.dart';
import 'package:stock_opname_software/modules/opname_excel_generator.dart';
import 'package:stock_opname_software/thousand_separator_formatter.dart';

import 'package:toastification/toastification.dart';
import 'package:provider/provider.dart';

class OpnameSessionFormPage extends StatefulWidget {
  final OpnameSession opnameSession;
  const OpnameSessionFormPage({required this.opnameSession, super.key});

  @override
  State<OpnameSessionFormPage> createState() => _OpnameSessionFormPageState();
}

class _OpnameSessionFormPageState extends State<OpnameSessionFormPage>
    with OpnameExcelGenerator, ConfirmDialog {
  OpnameSession get opnameSession => widget.opnameSession;
  List<OpnameItem> get opnameItems => widget.opnameSession.items;
  final _focusNode = FocusNode();
  final _qtyController = TextEditingController();
  final _itemCodeController = TextEditingController();
  late final Database db;
  bool _isFetchingItem = false;
  bool opnameSessionChanged = false;
  bool isAutoQty = false;
  int safetyNetQTY = 100;
  @override
  void initState() {
    db = context.read<Database>();
    if (opnameSession.id != null) {
      fetchOpnameItems();
    }
    _focusNode.requestFocus();
    super.initState();
  }

  void fetchOpnameItems() {
    setState(() {
      _isFetchingItem = true;
    });
    final db = context.read<Database>();
    final orm = Orm(
        tableName: OpnameItem.tableName, pkField: OpnameItem.pkField, db: db);

    orm
        .finds<OpnameItem>(
            convert: OpnameItem.convert,
            filter: {'opname_session_id': opnameSession.id})
        .then((opnameItems) => setState(() {
              opnameSession.items = opnameItems;
            }))
        .whenComplete(() => setState(() {
              _isFetchingItem = false;
            }));
  }

  @override
  Widget build(BuildContext context) {
    opnameItems.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return Scaffold(
      appBar: AppBar(
        title: Text("Session at: ${opnameSession.updatedAt.formatDate()}"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
              onPressed: _generateExcel,
              icon: const Icon(Icons.download),
              tooltip: 'export Excel'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownMenu<OpnameStatus>(
                label: const Text('Status'),
                initialSelection: opnameSession.status,
                width: 200,
                dropdownMenuEntries: OpnameStatus.values
                    .map<DropdownMenuEntry<OpnameStatus>>((status) =>
                        DropdownMenuEntry<OpnameStatus>(
                            value: status, label: status.toString()))
                    .toList(),
                onSelected: (value) {
                  opnameSession.status = value ?? opnameSession.status;
                  opnameSessionChanged = true;
                },
              ),
              const SizedBox(
                height: 10,
              ),
              DropdownMenu<String>(
                label: const Text('Lokasi'),
                width: 200,
                initialSelection: opnameSession.location,
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'TOKO', label: 'Toko'),
                  DropdownMenuEntry(value: 'GDG', label: 'Gudang'),
                ],
                onSelected: (value) {
                  opnameSession.location = value ?? opnameSession.location;
                  opnameSessionChanged = true;
                },
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  const Text('auto QTY 1 :'),
                  Switch(
                    value: isAutoQty,
                    onChanged: (value) => setState(() {
                      isAutoQty = value;
                    }),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
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
                keyboardType: TextInputType.visiblePassword,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp("[0-9a-zA-Z]")),
                ],
                onFieldSubmitted: (String? value) => _checkCode(value),
              ),
              Visibility(
                visible: _isFetchingItem,
                child: const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'fetch opname item',
                  ),
                ),
              ),
              Visibility(
                visible: !_isFetchingItem,
                child: Expanded(
                    child: ListView(
                  children: opnameItems
                      .map<ListTile>((opnameItem) => ListTile(
                          key: ObjectKey(opnameItem),
                          title: Text("Kode Item: ${opnameItem.itemCode}"),
                          subtitle: Text(
                              "Tanggal: ${opnameItem.updatedAt.formatDatetime()}"),
                          leading: Container(
                            constraints: const BoxConstraints(minWidth: 50),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('QTY'),
                                Text(
                                  opnameItem.quantity.format(),
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          trailing: MenuAnchor(
                            builder: (BuildContext context,
                                MenuController controller, Widget? child) {
                              return IconButton(
                                onPressed: () {
                                  if (controller.isOpen) {
                                    controller.close();
                                  } else {
                                    controller.open();
                                  }
                                },
                                icon: const Icon(Icons.more_vert),
                              );
                            },
                            menuChildren: [
                              MenuItemButton(
                                onPressed: () {
                                  _openInputQuantityModal(opnameItem.itemCode,
                                          quantity: opnameItem.quantity,
                                          focusNode: FocusNode())
                                      .then((int? quantity) {
                                    if (quantity != null) {
                                      setState(() {
                                        _qtyController.text = '';
                                        _itemCodeController.text = '';
                                        _updateOpnameItem(opnameItem,
                                            quantity: quantity);
                                      });
                                    }
                                  }).whenComplete(() {
                                    _focusNode.requestFocus();
                                  });
                                },
                                leadingIcon: const Icon(Icons.edit),
                                child: const Text('Edit'),
                              ),
                              MenuItemButton(
                                onPressed: () {
                                  confirmDialog(
                                          'Apakah anda yakin ingin menghapus item ${opnameItem.itemCode} ?')
                                      .then((isConfirmed) {
                                    if (isConfirmed) {
                                      _removeItem(opnameItem);
                                    }
                                  });
                                },
                                leadingIcon: const Icon(Icons.close),
                                child: const Text('Hapus'),
                              ),
                            ],
                          )))
                      .toList(),
                )),
              ),
            ],
          ),
        ),
      ),
    );
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
    if (isAutoQty) {
      _updateOpname(value, 1);
      _itemCodeController.text = '';
      _focusNode.requestFocus();
      return;
    }
    final focusNode2 = FocusNode();
    _openInputQuantityModal(value, focusNode: focusNode2).then((int? quantity) {
      if (quantity != null) {
        _updateOpname(value, quantity);
        _qtyController.text = '';
        _itemCodeController.text = '';
      }
    }).whenComplete(() {
      _focusNode.requestFocus();
    });
  }

  Future<int?> _openInputQuantityModal(String itemCode,
      {FocusNode? focusNode, int? quantity}) {
    focusNode?.requestFocus();
    _qtyController.text = quantity?.toString() ?? '';
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'Kode Item : ',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontSize: 16),
                          children: <TextSpan>[
                            TextSpan(
                                text: itemCode,
                                style: const TextStyle(
                                    fontWeight: FontWeight.normal)),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextFormField(
                        controller: _qtyController,
                        focusNode: focusNode,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(label: Text('Jumlah')),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ThousandSeparatorFormatter(),
                        ],
                        onFieldSubmitted: (value) =>
                            onSubmitted(focusNode, itemCode),
                      ),
                      const SizedBox(
                        height: 15,
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                              onPressed: () => onSubmitted(focusNode, itemCode),
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

  void onSubmitted(FocusNode? focusNode, String itemCode) {
    int? qty = int.tryParse(_qtyController.text.replaceAll(',', ''));
    if (qty != null && qty > safetyNetQTY) {
      var navigator = Navigator.of(context);
      confirmDialog(
              'Apakah anda yakin kode item $itemCode jumlahnya ${_qtyController.text} ?',
              delayedSubmitOnSeconds: 5)
          .then((isConfirmed) {
        if (isConfirmed) {
          navigator.pop(qty);
        } else {
          _qtyController.text = '';
          focusNode?.requestFocus();
        }
      });
    } else {
      Navigator.of(context).pop(qty);
    }
  }

  OpnameItem? findOpnameItem(String itemCode) {
    final opnameItem = opnameSession.items.firstWhere(
      (opnameItem) => opnameItem.itemCode == itemCode,
      orElse: () => OpnameItem(opnameSessionId: opnameSession.id ?? 0),
    );
    if (opnameItem.itemCode.isEmpty) {
      return null;
    }
    return opnameItem;
  }

  void _updateOpname(String itemCode, int quantity) async {
    if (opnameSession.id == null || opnameSessionChanged) {
      await createOpnameSession();
      opnameSessionChanged = false;
    }
    OpnameItem? opnameItem = findOpnameItem(itemCode);
    if (opnameItem == null) {
      _insertOpnameItem(itemCode, quantity);
    } else {
      _updateOpnameItem(opnameItem, quantity: opnameItem.quantity + quantity);
    }
  }

  Future<OpnameSession> createOpnameSession() async {
    final orm = Orm(
        tableName: OpnameSession.tableName,
        pkField: OpnameSession.pkField,
        db: db);
    opnameSession.id = await orm.save(opnameSession);
    return opnameSession;
  }

  void _updateOpnameItem(OpnameItem opnameItem, {required int quantity}) {
    final orm = Orm(
        tableName: OpnameItem.tableName, pkField: OpnameItem.pkField, db: db);
    final beforeUpdatedAt = opnameItem.updatedAt;
    final beforeQuantity = opnameItem.quantity;
    opnameItem.quantity = quantity;
    opnameItem.updatedAt = DateTime.now();
    orm.save(opnameItem).then(
        (value) => setState(() {
              opnameItem.quantity = opnameItem.quantity;
            }), onError: (error) {
      toastification.show(
        type: ToastificationType.error,
        title: Text('Failed update item ${opnameItem.itemCode}.'),
        autoCloseDuration: const Duration(seconds: 5),
      );
      setState(() {
        opnameItem.quantity = beforeQuantity;
        opnameItem.updatedAt = beforeUpdatedAt;
      });
    });
  }

  void _insertOpnameItem(String itemCode, int quantity) {
    final db = context.read<Database>();
    final orm = Orm(
        tableName: OpnameItem.tableName, pkField: OpnameItem.pkField, db: db);
    OpnameItem opnameItem = OpnameItem(
      itemCode: itemCode,
      quantity: quantity,
      opnameSessionId: opnameSession.id ?? 0,
      updatedAt: DateTime.now(),
    );
    orm.save(opnameItem).then(
        (value) => setState(() {
              opnameItem.id = value;
              opnameSession.items.add(opnameItem);
            }),
        onError: (error) => toastification.show(
              type: ToastificationType.error,
              title: Text('Failed insert item ${opnameItem.itemCode}.'),
              autoCloseDuration: const Duration(seconds: 5),
            ));
  }

  void _backToHome() {
    Navigator.of(context).pop();
  }

  void _removeItem(opnameItem) {
    final db = context.read<Database>();
    final orm = Orm(
        tableName: OpnameItem.tableName, pkField: OpnameItem.pkField, db: db);
    orm.delete(opnameItem.id).then(
        (value) => setState(() {
              opnameSession.items.remove(opnameItem);
            }),
        onError: (error) => toastification.show(
              type: ToastificationType.error,
              title: Text('Failed remove item ${opnameItem.itemCode}.'),
              autoCloseDuration: const Duration(seconds: 5),
            ));
  }
}
