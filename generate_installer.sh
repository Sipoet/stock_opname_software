#!bin/sh
flutter build windows && flutter build apk && cp .\build\app\outputs\apk\release\app-release.apk .\src\android\stock-opname.apk