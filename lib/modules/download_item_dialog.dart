import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/io.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stock_opname_software/models/system_setting.dart';

import 'package:stock_opname_software/models/application_record.dart';
import 'package:stock_opname_software/models/item.dart';
import 'package:toastification/toastification.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';

mixin DonwloadItemDialog<T extends StatefulWidget> on State<T> {
  String? token;
  bool _isLoading = false;
  String _password = '';
  String _username = '';
  String _host = '';
  final _dio = Dio();
  Future<Item?> downloadAndSaveItem(String barcode, Database db) async {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    };

    token ??= await _openLoginFormDialog();

    if (token == null) {
      toastification.show(
        type: ToastificationType.error,
        title: const Text('Gagal Download Item'),
        description: const Text('Username/password salah'),
        autoCloseDuration: const Duration(seconds: 5),
      );
      return null;
    }
    Item? item = await fetchRemoteItem(token: token!, barcode: barcode);
    if (item == null) {
      return null;
    }
    var orm = Orm(tableName: Item.tableName, pkField: Item.pkField, db: db);
    Item? altItem =
        await orm.findBy<Item>({'barcode': item.code}, Item.convert);
    if (altItem != null) {
      return altItem;
    }
    await orm.save(item);
    return orm.findBy<Item>({'barcode': barcode}, Item.convert);
  }

  Future<Item?> fetchRemoteItem(
      {required String token, required String barcode}) async {
    var url = Uri.https(
      _host,
      'api/ipos/items/$barcode',
    );
    try {
      var response = await _dio.getUri(url,
          options: Options(
            receiveTimeout: const Duration(minutes: 20),
            headers: {
              'Authorization': token,
              'X-TEST': 'test-header',
              Headers.acceptHeader: 'application/json',
              Headers.contentTypeHeader: 'application/json',
            },
          ));
      if (response.statusCode != 200) {
        return null;
      }
      final data = response.data['data']['attributes'];
      return Item(
          code: data['code'],
          updatedAt: DateTime.tryParse(data['updated_at'] ?? ''),
          barcode: barcode,
          name: data['name'],
          sellPrice: double.tryParse(data['sell_price'].toString()) ?? 0);
    } catch (e) {
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.badResponse:
          case DioExceptionType.cancel:
            return null;
          default:
            toastification.show(
              type: ToastificationType.error,
              title: const Text('Gagal Download Item'),
              description: const Text('hubungi teknikal service'),
              autoCloseDuration: const Duration(seconds: 5),
            );
        }
      }
      return null;
    }
  }

  Future<String?> _openLoginFormDialog() {
    _password = '';
    final colorScheme = Theme.of(context).colorScheme;
    return showDialog<String?>(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setStateDialog) {
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
                    initialValue: _host,
                    onChanged: (value) => _host = value,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(
                      label: Text('Username'),
                      border: OutlineInputBorder(),
                    ),
                    initialValue: _username,
                    onChanged: (value) => _username = value,
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
                      _password = value;
                      if (_isLoading) {
                        return;
                      }
                      setStateDialog(() {
                        _isLoading = true;
                      });
                      _login(_username, _password).then((token) {
                        if (token != null) {
                          navigator.pop(token);
                        }
                      }).whenComplete(
                          () => setStateDialog(() => _isLoading = false));
                    },
                    obscureText: true,
                    initialValue: _password,
                    onChanged: (value) => _password = value,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Visibility(
                    visible: _isLoading,
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: CircularProgressIndicator(
                        color: colorScheme.onPrimary,
                        backgroundColor: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setStateDialog(() {
                              _isLoading = true;
                            });
                            _login(_username, _password).then((token) {
                              if (token != null) {
                                navigator.pop(token);
                              }
                            }).whenComplete(
                                () => setStateDialog(() => _isLoading = false));
                          },
                    child: const Text('Download')),
                ElevatedButton(
                    onPressed: () {
                      navigator.pop(null);
                    },
                    style: const ButtonStyle(
                        backgroundColor:
                            WidgetStatePropertyAll<Color>(Colors.grey)),
                    child: const Text('cancel')),
              ],
            );
          });
        });
  }

  Future<String?> _login(username, password) async {
    var url = Uri.https(_host, 'api/login');
    try {
      var response = await _dio.post(url.toString(),
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
      _saveHosts();
      return response.headers.value('Authorization');
    } catch (e) {
      toastification.show(
        type: ToastificationType.error,
        title: const Text('Gagal Download Item'),
        description: const Text('periksa koneksi anda'),
        autoCloseDuration: const Duration(seconds: 5),
      );
      return null;
    }
  }

  void _saveHosts() async {
    final db = context.read<Database>();
    final orm = Orm(
        tableName: SystemSetting.tableName,
        pkField: SystemSetting.pkField,
        db: db);
    SystemSetting setting = await orm.findBy<SystemSetting>(
            {'keyname': 'host'}, SystemSetting.convert) ??
        SystemSetting(keyname: 'host');
    setting.valueStr = _host;
    orm.save(setting);
    setting = await orm.findBy<SystemSetting>(
            {'keyname': 'username'}, SystemSetting.convert) ??
        SystemSetting(keyname: 'username');
    setting.valueStr = _username;
    orm.save(setting);
  }
}
