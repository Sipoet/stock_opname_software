import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:stock_opname_software/modules/platform_checker.dart';
import 'package:stock_opname_software/modules/app_updater.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as w;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:stock_opname_software/pages/home_page.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage>
    with AppUpdater, PlatformChecker {
  String progress = '';
  late final Database db;
  final dbName = 'app_db.sqlite3';
  @override
  void initState() {
    checkPermission().then((value) {
      checkUpdate().then((isConfirmed) => prepareDatabase());
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const CircularProgressIndicator(
                // value: 1,
                semanticsLabel: 'in progress',
              ),
              Text(progress),
            ],
          ),
        ),
      ),
    );
  }

  void _goToHomePage() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) =>
            Provider<Database>.value(value: db, child: const HomePage())));
  }

  void prepareDatabase() async {
    WidgetsFlutterBinding.ensureInitialized();
    final dbPath = await getDbPath();
    // await File(dbPath).delete();

    openDatabase(
      dbPath,
      version: 3,
      onCreate: createTables,
      onUpgrade: updateTables,
      onConfigure: (db) {},
    ).then((Database database) {
      db = database;
      _goToHomePage();
    });
  }

  Future checkPermission() async {
    try {
      List<Permission> permissions = [];
      if (isAndroid()) {
        DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        permissions.addAll([
          Permission.requestInstallPackages,
          Permission.camera,
        ]);
        if (androidInfo.version.sdkInt <= 32) {
          permissions.add(Permission.storage);
        } else {
          permissions.add(Permission.accessMediaLocation);
        }
      } else if (isIOS()) {
        permissions.addAll([Permission.mediaLibrary, Permission.photos]);
      }
      for (Permission permission in permissions) {
        _requestPermission(permission);
      }
    } catch (error) {
      AlertDialog(
        title: const Text('Error'),
        content: Text(error.toString()),
        actions: [
          ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('close'))
        ],
      );
    }
  }

  Future _requestPermission(Permission permission) async {
    debugPrint('===cek permission ${permission.toString()}');
    final status = await permission.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await permission.request().isGranted;
    }
  }

  Future<String> getDbPath() async {
    loadSqlLib();
    try {
      String dirPath = await getDatabasesPath();
      return p.join(dirPath, dbName);
    } catch (error) {
      Directory dir = await getApplicationSupportDirectory();
      return p.join(dir.path, dbName);
    }
  }

  void loadSqlLib() {
    if (Platform.isWindows) {
      databaseFactory = w.databaseFactoryFfi;
    } else if (Platform.isAndroid || Platform.isMacOS || Platform.isIOS) {}
  }

  Future createTables(Database db, int version) async {
    updateTables(db, 0, version);
  }

  Future<void> updateTables(Database db, int oldVersion, int newVersion) async {
    await db.transaction((trx) async {
      if (oldVersion < 1) {
        trx.execute('''
          CREATE TABLE opname_sessions (
            id INTEGER NOT NULL PRIMARY KEY,
            status VARCHAR(50) NOT NULL,
            location VARCHAR(50) NOT NULL,
            updated_at DATETIME NOT NULL
          );
        ''');
        oldVersion += 1;
      }
      if (oldVersion < 2) {
        trx.execute('''
          CREATE TABLE opname_items (
          id INTEGER NOT NULL PRIMARY KEY,
          opname_session_id INTEGER NOT NULL,
          rack VARCHAR(50),
          item_code VARCHAR(50) NOT NULL,
          quantity INTEGER NOT NULL,
          updated_at DATETIME NOT NULL
        );''');
        trx.execute('''CREATE TABLE items (
          id INTEGER NOT NULL PRIMARY KEY,
          code VARCHAR(50) NOT NULL,
          name VARCHAR(250) NOT NULL,
          barcode VARCHAR(20) NOT NULL UNIQUE,
          sell_price REAL NOT NULL DEFAULT 999999,
          updated_at DATETIME NOT NULL
        );''');
        trx.execute('''CREATE TABLE system_settings (
          id INTEGER NOT NULL PRIMARY KEY,
          keyname VARCHAR(50) NOT NULL,
          value_str VARCHAR(250) NOT NULL
        );''');
        oldVersion += 1;
      }
      if (oldVersion < 3) {
        trx.execute('''
          CREATE TABLE IF NOT EXISTS opname_items (
            id INTEGER NOT NULL PRIMARY KEY,
            opname_session_id INTEGER NOT NULL,
            rack VARCHAR(50),
            item_code VARCHAR(50) NOT NULL,
            quantity INTEGER NOT NULL,
            updated_at DATETIME NOT NULL
          );
        ''');
        oldVersion += 1;
      }
    });
  }
}
