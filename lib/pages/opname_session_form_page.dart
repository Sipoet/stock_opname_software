import 'package:flutter/material.dart';
import 'package:stock_opname_software/models/opname_session.dart';

class OpnameSessionFormPage extends StatefulWidget {
  final OpnameSession opnameSession;
  const OpnameSessionFormPage({required this.opnameSession, super.key});

  @override
  State<OpnameSessionFormPage> createState() => _OpnameSessionFormPageState();
}

class _OpnameSessionFormPageState extends State<OpnameSessionFormPage> {
  OpnameSession get opnameSession => widget.opnameSession;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(opnameSession.updatedAt.toString()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          DropdownMenu<OpnameStatus>(
              label: Text('Status'),
              initialSelection: opnameSession.status,
              dropdownMenuEntries: OpnameStatus.values
                  .map<DropdownMenuEntry<OpnameStatus>>((status) =>
                      DropdownMenuEntry<OpnameStatus>(
                          value: status, label: status.toString()))
                  .toList()),
          DropdownMenu<String>(
            label: Text('Lokasi'),
            initialSelection: opnameSession.location,
            dropdownMenuEntries: [
              DropdownMenuEntry(value: 'TOKO', label: Text('Toko')),
              DropdownMenuEntry(value: 'GDG', label: Text('GDG'))
            ],
          )
        ],
        leading: IconButton.filled(
            onPressed: _backToHome, icon: Icon(Icons.arrow_back)),
      ),
      body: Center(
        child: Text('form stock opname'),
      ),
    );
  }

  void _backToHome() {
    Navigator.of(context).pop();
  }
}
