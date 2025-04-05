import 'package:flutter/material.dart';
import 'package:stock_opname_software/modules/app_updater.dart';
import 'package:stock_opname_software/pages/home_page.dart';
import 'package:stock_opname_software/pages/opname_session_combinator_page.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

mixin ListMenu<T extends StatefulWidget> on State<T> implements AppUpdater<T> {
  Color get backgroundColor => Theme.of(context).colorScheme.inversePrimary;
  Drawer menuDrawer(Database db, {activePage = 'opnameSession'}) {
    var navigator = Navigator.of(context);
    return Drawer(
      child: ListView(children: [
        const DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.blue,
          ),
          child: Text('Menu'),
        ),
        ListTile(
          key: const ValueKey('opnameSession'),
          title: const Text('Opname Session'),
          enabled: activePage != 'opnameSession',
          onTap: () {
            setState(() {
              activePage = 'opnameSession';
            });
            navigator
              ..pop()
              ..pushReplacement(
                MaterialPageRoute(
                  builder: (context) => Provider<Database>.value(
                    value: db,
                    child: const HomePage(),
                  ),
                ),
              );
          },
        ),
        ListTile(
          key: const ValueKey('opnameSessionCombinator'),
          title: const Text('Opname Session Combinator'),
          enabled: activePage != 'opnameSessionCombinator',
          onTap: () {
            setState(() {
              activePage = 'opnameSessionCombinator';
            });
            navigator
              ..pop()
              ..pushReplacement(
                MaterialPageRoute(
                  builder: (context) => Provider<Database>.value(
                    value: db,
                    child: const OpnameSessionCombinatorPage(),
                  ),
                ),
              );
          },
        ),
        ListTile(
          key: const ValueKey('checkUpdate'),
          title: const Text('Check Update'),
          onTap: () {
            checkUpdate();
          },
        ),
        ListTile(
          key: const ValueKey('showVersion'),
          title: const Text('About'),
          onTap: () async {
            final version = await appVersion();
            showVersion(version);
          },
        ),
      ]),
    );
  }
}
