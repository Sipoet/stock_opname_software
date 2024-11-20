import 'package:flutter/material.dart';
import 'package:stock_opname_software/modules/opname_excel_generator.dart';
import 'package:stock_opname_software/pages/opname_session_form_page.dart';
import 'package:stock_opname_software/models/opname_session.dart';
import 'package:toastification/toastification.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with OpnameExcelGenerator {
  List<OpnameSession> opnameSessions = [
    OpnameSession(updatedAt: DateTime.now(), status: OpnameStatus.open, items: [
      OpnameItem(
        itemCode: '1440012352',
        quantity: 1,
      )
    ]),
    OpnameSession(
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        status: OpnameStatus.close,
        items: [
          OpnameItem(
            itemCode: '344712352',
            quantity: 2,
          )
        ]),
  ];

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the HomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: opnameSessionView(),

        // opnameSessionView2(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addOpnameSession,
        tooltip: 'tambah Session',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _addOpnameSession() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OpnameSessionFormPage(
          opnameSession: OpnameSession(),
        ),
      ),
    );
  }

  Widget opnameSessionView() {
    return ListView(
        children: opnameSessions
            .map<ListTile>((opnameSession) => ListTile(
                  title: Text(
                    opnameSession.location,
                  ),
                  subtitle: Text(opnameSession.updatedAt.toString()),
                  leading: Text(opnameSession.status.toString()),
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
                        onPressed: () {
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
                    ],
                  ),
                ))
            .toList());
  }

  void _editOpnameSession(opnameSession) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OpnameSessionFormPage(
          opnameSession: opnameSession,
        ),
      ),
    );
  }

  Widget opnameSessionView2() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Table(
        children: [
              const TableRow(children: [
                TableCell(
                  child: Text('Lokasi'),
                ),
                TableCell(
                  child: Text('TGL Diperbaharui'),
                ),
                TableCell(child: Text('Status')),
                TableCell(child: Text('action')),
              ]),
            ] +
            opnameSessions
                .map<TableRow>((opnameSession) => TableRow(children: [
                      TableCell(
                        child: Text(opnameSession.location),
                      ),
                      TableCell(
                        child: Text(opnameSession.updatedAt.toString()),
                      ),
                      TableCell(child: Text(opnameSession.status.toString())),
                      TableCell(
                          child: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editOpnameSession(opnameSession),
                      )),
                    ]))
                .toList(),
      ),
    );
  }
}
