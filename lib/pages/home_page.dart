import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:stock_opname_software/extensions.dart';
import 'package:stock_opname_software/models/application_record.dart';
import 'package:stock_opname_software/modules/opname_excel_generator.dart';
import 'package:stock_opname_software/pages/opname_session_form_page.dart';
import 'package:stock_opname_software/pages/opname_session_combinator_page.dart';
import 'package:stock_opname_software/models/opname_session.dart';
import 'package:toastification/toastification.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with OpnameExcelGenerator {
  List<OpnameSession> opnameSessions = [];
  late final Database db;
  String activePage = 'opnameSession';
  late Widget activeWidget;
  @override
  void initState() {
    db = context.read<Database>();
    activeWidget = opnameSessionView();
    fetchOpnameSession();
    super.initState();
  }

  void fetchOpnameSession() {
    final orm = Orm(
        tableName: OpnameSession.tableName,
        pkField: OpnameSession.pkField,
        db: db);
    orm
        .finds<OpnameSession>(convert: OpnameSession.convert)
        .then((data) => setState(() {
              opnameSessions = data;
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Menu'),
          ),
          ListTile(
            title: const Text('Opname Session'),
            enabled: activePage != 'opnameSession',
            onTap: () {
              setState(() {
                activeWidget = opnameSessionView();
                activePage = 'opnameSession';
              });
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            title: const Text('Opname Session Combinator'),
            enabled: activePage != 'opnameSessionCombinator',
            onTap: () {
              setState(() {
                activeWidget = const OpnameSessionCombinatorPage();
                activePage = 'opnameSessionCombinator';
              });
              Navigator.of(context).pop();
            },
          ),
        ]),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
              onPressed: fetchOpnameSession, icon: const Icon(Icons.refresh))
        ],
        leading: const DrawerButton(),
      ),
      body: Center(
        child: activeWidget,

        // opnameSessionView2(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOpnameSession,
        tooltip: 'tambah Session',
        child: const Icon(Icons.add),
      ),
    );
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
    return ListView(
        children: opnameSessions
            .map<ListTile>((opnameSession) => ListTile(
                  title: Text(
                    "Lokasi : ${opnameSession.location}",
                  ),
                  subtitle:
                      Text("Tanggal: ${opnameSession.updatedAt.formatDate()}"),
                  leading: Text(
                    opnameSession.status.toString(),
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
                        onPressed: () => _deleteOpnameSession(opnameSession),
                        leadingIcon: const Icon(Icons.delete),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                ))
            .toList());
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
}
