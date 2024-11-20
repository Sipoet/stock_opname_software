import 'package:flutter/material.dart';
import 'package:stock_opname_software/pages/opname_session_form_page.dart';
import 'package:stock_opname_software/models/opname_session.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Opname Session',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Stock Opname Session Generator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<OpnameSession> opnameSessions = [
    OpnameSession(updatedAt: DateTime.now(), status: OpnameStatus.open, items: [
      OpnameItem(
        kodeitem: '1440012352',
        quantity: 1,
      )
    ]),
    OpnameSession(
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        status: OpnameStatus.close,
        items: [
          OpnameItem(
            kodeitem: '344712352',
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
        // Here we take the value from the MyHomePage object that was created by
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
                  onTap: () => _editOpnameSession(opnameSession),
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
