import 'dart:io';

import 'package:dio/io.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stock_opname_software/extensions.dart';
import 'package:stock_opname_software/models/application_record.dart';
import 'package:stock_opname_software/models/item.dart';
import 'package:stock_opname_software/models/system_setting.dart';
import 'package:stock_opname_software/modules/app_updater.dart';
import 'package:stock_opname_software/modules/confirm_dialog.dart';
import 'package:stock_opname_software/modules/list_menu.dart';
import 'package:stock_opname_software/modules/opname_excel_generator.dart';
import 'package:stock_opname_software/pages/opname_session_form_page.dart';
import 'package:stock_opname_software/models/opname_session.dart';
import 'package:toastification/toastification.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with OpnameExcelGenerator, ListMenu, ConfirmDialog, AppUpdater {
  List<OpnameSession> opnameSessions = [];
  late final Database db;
  String host = '';
  String username = '';
  String password = '';
  @override
  void initState() {
    db = context.read<Database>();
    final orm = Orm(
        tableName: SystemSetting.tableName,
        pkField: SystemSetting.pkField,
        db: db);
    orm.findBy<SystemSetting>({'keyname': 'host'}, SystemSetting.convert).then(
        (systemSetting) {
      setState(() {
        host = systemSetting?.valueStr ?? '';
      });
    });
    orm.findBy<SystemSetting>(
        {'keyname': 'username'}, SystemSetting.convert).then((systemSetting) {
      setState(() {
        username = systemSetting?.valueStr ?? '';
      });
    });
    fetchOpnameSession();
    super.initState();
  }

  void fetchOpnameSession() {
    final orm = Orm(
        tableName: OpnameSession.tableName,
        pkField: OpnameSession.pkField,
        db: db);
    orm
        .finds<OpnameSession>(
            orderBy: 'updated_at',
            orderValue: QueryOrder.desc,
            convert: OpnameSession.convert)
        .then((data) => setState(() {
              opnameSessions = data;
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: menuDrawer(db),
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text('Stock Opname Session Generator'),
        actions: [
          IconButton(
              onPressed: fetchOpnameSession,
              tooltip: 'Refresh Opname',
              icon: const Icon(Icons.refresh)),
          IconButton(
              onPressed: openItemDownloadDialog,
              tooltip: 'Download Item Data',
              icon: const Icon(Icons.download))
        ],
        leading: const DrawerButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: opnameSessionView(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOpnameSession,
        tooltip: 'tambah Session',
        child: const Icon(Icons.add),
      ),
    );
  }

  openItemDownloadDialog() {
    password = '';
    showDialog(
        context: context,
        builder: (BuildContext context) {
          final navigator = Navigator.of(context);
          return AlertDialog(
            title: const Text('Download Item Data Form'),
            content: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    label: Text('Host/IP address'),
                    border: OutlineInputBorder(),
                  ),
                  initialValue: host,
                  onChanged: (value) => host = value,
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    label: Text('Username'),
                    border: OutlineInputBorder(),
                  ),
                  initialValue: username,
                  onChanged: (value) => username = value,
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    label: Text('Password'),
                    border: OutlineInputBorder(),
                  ),
                  onFieldSubmitted: (value) {
                    password = value;
                    fetchItems().then((isSuccess) {
                      if (isSuccess) navigator.pop();
                    });
                  },
                  obscureText: true,
                  initialValue: password,
                  onChanged: (value) => password = value,
                ),
                Visibility(
                    visible: currentLength >= 0,
                    child: Text("progress: $currentLength / $totalLength")),
              ],
            ),
            actions: [
              ElevatedButton(
                  onPressed: () => fetchItems().then((isSuccess) {
                        if (isSuccess) navigator.pop();
                      }),
                  child: const Text('Download')),
              ElevatedButton(
                  onPressed: () {
                    navigator.pop();
                  },
                  style: const ButtonStyle(
                      backgroundColor:
                          WidgetStatePropertyAll<Color>(Colors.grey)),
                  child: const Text('cancel')),
            ],
          );
        });
  }

  Future<String?> login(username, password) async {
    var url = Uri.https(host, 'api/login');
    var response = await dio.post(url.toString(),
        data: {
          'user': {'username': username, 'password': password}
        },
        options: Options(responseType: ResponseType.json));
    if (response.statusCode != 200) {
      toastification.show(
        type: ToastificationType.error,
        title: const Text('Gagal Download Item'),
        description:
            Text(response.data['message'] ?? 'Username/password salah'),
        autoCloseDuration: const Duration(seconds: 5),
      );
      return null;
    }
    saveHosts();
    return response.headers.value('Authorization');
  }

  void saveHosts() async {
    final orm = Orm(
        tableName: SystemSetting.tableName,
        pkField: SystemSetting.pkField,
        db: db);
    SystemSetting setting = await orm.findBy<SystemSetting>(
            {'keyname': 'host'}, SystemSetting.convert) ??
        SystemSetting(keyname: 'host');
    setting.valueStr = host;
    orm.save(setting);
    setting = await orm.findBy<SystemSetting>(
            {'keyname': 'username'}, SystemSetting.convert) ??
        SystemSetting(keyname: 'username');
    setting.valueStr = username;
    orm.save(setting);
  }

  int currentLength = -1;
  int totalLength = 1;

  Future<bool> fetchItems() async {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };
    setState(() {
      currentLength = 0;
    });
    String? token = await login(username, password);
    if (token == null) {
      toastification.show(
        type: ToastificationType.error,
        title: const Text('Gagal Download Item'),
        description: const Text('Username/password salah'),
        autoCloseDuration: const Duration(seconds: 5),
      );
      return false;
    }
    var orm = Orm(tableName: Item.tableName, pkField: Item.pkField, db: db);

    var lastUpdated = await orm.maxOf('updated_at');
    var url =
        Uri.https(host, 'api/items/download', {'last_updated_at': lastUpdated});
    try {
      var response = await dio.getUri(url,
          options: Options(
            receiveTimeout: const Duration(minutes: 20),
            headers: {
              'Authorization': token,
              'X-TEST': 'test-header',
              Headers.acceptHeader: 'application/json',
              Headers.contentTypeHeader: 'application/json',
            },
          ));
      List data = response.data['data'];
      setState(() {
        totalLength = data.length;
      });
      if (data.isEmpty) {
        toastification.show(
          type: ToastificationType.info,
          title: const Text('Tidak ada item baru'),
          autoCloseDuration: const Duration(seconds: 5),
        );
        return true;
      }
      orm = Orm(tableName: Item.tableName, pkField: Item.pkField, db: db);
      List<Item> items = [];
      for (Map row in data) {
        final attributes = row['attributes'];
        Item item = await orm.findBy<Item>(
                {'barcode': attributes['barcode']}, Item.convert) ??
            Item(barcode: attributes['barcode']);
        item.code = attributes['code'] ?? '';
        item.name = attributes['name'] ?? '';
        item.sellPrice =
            double.tryParse(attributes['sell_price'] ?? '') ?? item.sellPrice;
        item.updatedAt =
            DateTime.tryParse(attributes['updated_at']) ?? item.updatedAt;
        items.add(item);

        setState(() {
          currentLength = items.length;
        });
      }
      final massResult = await orm.massSave(items) as List<int?>;
      bool result = massResult.reduce((value, recentResult) =>
              value == 0 && recentResult == 0 ? 0 : 1)! >
          0;
      if (result) {
        toastification.show(
          type: ToastificationType.success,
          title: const Text('Sukses Download Item'),
          autoCloseDuration: const Duration(seconds: 5),
        );
      } else {
        toastification.show(
          type: ToastificationType.error,
          title: const Text('Gagal Download Item'),
          description: const Text('kontak technical support'),
          autoCloseDuration: const Duration(seconds: 10),
        );
      }
      setState(() {
        currentLength = -1;
      });
      return result;
    } on DioException catch (e) {
      String message = e.response?.data.toString() ??
          'tidak bisa ambil data item, kontak technical support';
      toastification.show(
        type: ToastificationType.error,
        title: const Text('Gagal Download Item'),
        description: Text(message),
        autoCloseDuration: const Duration(seconds: 10),
      );
      return false;
    }
  }

  void _addOpnameSession() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => Provider<Database>.value(
              value: db,
              child: OpnameSessionFormPage(
                opnameSession: OpnameSession(),
              ),
            ),
          ),
        )
        .whenComplete(fetchOpnameSession);
  }

  Widget opnameSessionView() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      child: ListView(
          children: opnameSessions
              .map<ListTile>((opnameSession) => ListTile(
                    title: Text(
                      "Lokasi : ${opnameSession.location}",
                    ),
                    subtitle: Text(
                        "Status ${opnameSession.status.toString()}, Tanggal: ${opnameSession.updatedAt.formatDatetime()}"),
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const Text('ID',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          opnameSession.id.toString(),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                    trailing: MenuAnchor(
                      builder: (BuildContext context, MenuController controller,
                          Widget? child) {
                        return IconButton(
                          onPressed: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                          icon: const Icon(Icons.more_vert),
                          tooltip: 'Show menu',
                        );
                      },
                      menuChildren: [
                        MenuItemButton(
                          onPressed: () async {
                            final orm = Orm(
                                tableName: OpnameItem.tableName,
                                pkField: OpnameItem.pkField,
                                db: db);
                            opnameSession.items = await orm.finds<OpnameItem>(
                                filter: {'opname_session_id': opnameSession.id},
                                convert: OpnameItem.convert);
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
                          },
                          leadingIcon: const Icon(Icons.download),
                          child: const Text('Export Excel'),
                        ),
                        MenuItemButton(
                          onPressed: () => _editOpnameSession(opnameSession),
                          leadingIcon: const Icon(Icons.edit),
                          child: const Text('edit'),
                        ),
                        MenuItemButton(
                          onPressed: () {
                            confirmDialog(
                                    'Apakah yakin hapus opname session ${opnameSession.id}')
                                .then(
                              (isConfirmed) {
                                if (isConfirmed) {
                                  _deleteOpnameSession(opnameSession);
                                }
                              },
                            );
                          },
                          leadingIcon: const Icon(Icons.delete),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  ))
              .toList()),
    );
  }

  void _editOpnameSession(opnameSession) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Provider<Database>.value(
          value: db,
          child: OpnameSessionFormPage(
            opnameSession: opnameSession,
          ),
        ),
      ),
    );
  }

  void _deleteOpnameSession(OpnameSession opnameSession) {
    _deleteOpnameItems(opnameSession);
    final orm = Orm(
        tableName: OpnameSession.tableName,
        pkField: OpnameSession.pkField,
        db: db);
    orm.delete(opnameSession.id).then(
        (value) => setState(() {
              opnameSessions.remove(opnameSession);
            }),
        onError: (error) => toastification.show(
              type: ToastificationType.error,
              title: Text(
                  'Failed remove Opname Session at ${opnameSession.updatedAt.formatDate()}.'),
              autoCloseDuration: const Duration(seconds: 5),
            ));
  }

  void _deleteOpnameItems(OpnameSession opnameSession) {
    final orm = Orm(
        tableName: OpnameItem.tableName, pkField: OpnameItem.pkField, db: db);
    orm.deleteWhere(where: 'opname_session_id = ?', whereArgs: [
      opnameSession.id
    ]).then(
        (value) => setState(() {
              opnameSession.items = [];
            }),
        onError: (error) => toastification.show(
              type: ToastificationType.error,
              title: Text(
                  'Failed remove Opname items from opname session at ${opnameSession.updatedAt.formatDate()}.'),
              autoCloseDuration: const Duration(seconds: 5),
            ));
  }
}
