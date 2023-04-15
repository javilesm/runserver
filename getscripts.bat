@echo off
set Config_Path=C:\Users\jorge\.ssh\config
for /f "usebackq tokens=1,2 delims= " %%i in ("%Config_Path%") do (
  if "%%i"=="HostName" set HostName=%%j
  if "%%i"=="User" set User=%%j
  if "%%i"=="IdentityFile" set IdentityFile=%%j
)

echo HostName: %HostName%
echo User: %User%
echo IdentityFile: %IdentityFile%
echo HostName: %HostName%
echo User: %User%
echo Ejecutando la copia del archivo al servidor...
scp -v -i "%IdentityFile%" "%local_file_path%" "%User%@%HostName%:%server_file_path%"

if %errorlevel% equ 0 (
  echo Copia de archivo completada exitosamente.
  echo Ejecutando comandos en el servidor...
  ssh -i "%IdentityFile%" "%User%@%HostName%" "sudo sudo apt-get install dos2unix && sudo dos2unix /home/ubuntu/getscripts.sh && sudo mv /home/ubuntu/getscripts.sh /home/ubuntu/getscripts && sudo chown $USER:$USER /home/ubuntu/getscripts && sudo chmod +x /home/ubuntu/getscripts && sudo bash /home/ubuntu/getscripts"
  echo Comandos en el servidor ejecutados exitosamente.
) else (
  echo Error durante la copia de archivo al servidor.
)
