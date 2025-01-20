import 'package:flutter/material.dart';
import 'dart:async';

mixin ConfirmDialog<T extends StatefulWidget> on State<T> {
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
}
