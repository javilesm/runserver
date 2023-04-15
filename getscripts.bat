@echo off
REM En este script, se utiliza la variable especial "%~dp0" para obtener la ruta del directorio donde se encuentra el script Batch. Luego, se utiliza esta ruta para construir las rutas de archivo de las variables "local_file_path" y "Config_Path" concatenando la ruta del directorio del script con los nombres de archivo "getscripts.sh" y "config" respectivamente. De esta manera, las rutas de archivo se obtendrán dinámicamente desde el directorio donde se encuentre el script, lo que permite que el script sea más portátil y se pueda ejecutar desde diferentes ubicaciones sin necesidad de modificar las rutas de archivo de manera estática.

set script_dir=%~dp0  REM Obtiene la ruta del directorio donde se encuentra el script
set server_file_path=/home/%server_user%/getscripts.sh
set local_file_path=%script_dir%\getscripts.sh  REM Construye la ruta del archivo local a partir del directorio del script
set Config_Path=%script_dir%\config  REM Construye la ruta del archivo de configuración a partir del directorio del script
for /f "usebackq tokens=1,2 delims= " %%i in ("%Config_Path%") do (
  if "%%i"=="HostName" set HostName=%%j  REM Lee la variable "HostName" del archivo de configuración
  if "%%i"=="User" set User=%%j  REM Lee la variable "User" del archivo de configuración
  if "%%i"=="IdentityFile" set IdentityFile=%%j  REM Lee la variable "IdentityFile" del archivo de configuración
)

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
