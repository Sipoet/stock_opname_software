import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stock_opname_software/models/application_record.dart';

import 'package:stock_opname_software/models/opname_session.dart';
import 'package:stock_opname_software/extensions.dart';
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
    with OpnameExcelGenerator {
  OpnameSession get opnameSession => widget.opnameSession;
  List<OpnameItem> get opnameItems => widget.opnameSession.items;
  final _focusNode = FocusNode();
  final _qtyController = TextEditingController();
  final _itemCodeController = TextEditingController();
  late final Database db;
  bool _isFetchingItem = false;
  bool opnameSessionChanged = false;
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
                            trailing: IconButton(
                                onPressed: () {
                                  confirmDialog(
                                          'Apakah anda yakin ingin menghapus item ${opnameItem.itemCode} ?')
                                      .then((isConfirmed) {
                                    if (isConfirmed) {
                                      _removeItem(opnameItem);
                                    }
                                  });
                                },
                                icon: const Icon(Icons.close)),
                          ))
                      .toList(),
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> confirmDialog(String message,
      {String agreeText = 'Ya',
      String declineText = 'Tidak',
      int delayedSubmitOnSeconds = 0}) {
    String messageDelayed = delayedSubmitOnSeconds == 0
        ? agreeText
        : 'tunggu $delayedSubmitOnSeconds detik';
    bool isInit = true;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter dialogSetState) {
          if (isInit && messageDelayed != agreeText) {
            Timer.periodic(const Duration(seconds: 1), (timer) {
              final second = delayedSubmitOnSeconds - timer.tick;
              dialogSetState(() {
                if (second > 0) {
                  messageDelayed = 'tunggu ${second.toString()} detik';
                } else {
                  messageDelayed = agreeText;
                  timer.cancel();
                }
              });
            });
          }
          isInit = false;
          return AlertDialog(
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: Text(
                  messageDelayed,
                  style: TextStyle(
                      color: messageDelayed == agreeText
                          ? Colors.black
                          : Colors.grey),
                ),
                onPressed: () {
                  if (messageDelayed == agreeText) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
              TextButton(
                child: Text(declineText),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
            ],
          );
        },
      ),
    ).then(
      (value) {
        if (value == true) {
          return true;
        }
        return false;
      },
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
      final orm = Orm(
          tableName: OpnameSession.tableName,
          pkField: OpnameSession.pkField,
          db: db);
      opnameSession.id = await orm.save(opnameSession);
      opnameSessionChanged = false;
    }
    OpnameItem? opnameItem = findOpnameItem(itemCode);
    if (opnameItem == null) {
      _insertOpnameItem(itemCode, quantity);
    } else {
      _updateOpnameItem(opnameItem, quantity);
    }
  }

  void _updateOpnameItem(OpnameItem opnameItem, int quantity) {
    final orm = Orm(
        tableName: OpnameItem.tableName, pkField: OpnameItem.pkField, db: db);
    final beforeUpdatedAt = opnameItem.updatedAt;
    opnameItem.quantity += quantity;
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
        opnameItem.quantity -= quantity;
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
