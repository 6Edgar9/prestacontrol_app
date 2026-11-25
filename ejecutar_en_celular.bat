@echo off
echo ==============================================
echo  Conectando celular a la API local por USB...
echo ==============================================
"C:\Users\megac\AppData\Local\Android\Sdk\platform-tools\adb.exe" reverse tcp:8080 tcp:8080
echo Tunel USB activado (puerto 8080 redirigido).
echo.
echo Iniciando Flutter en su dispositivo...
flutter run
