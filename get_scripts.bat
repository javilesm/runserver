@echo off

rem Definir las variables para directorios locales
set CONFIG_FILE=config
set LOCAL_DIR=%~dp0
set CONFIG_PATH=%LOCAL_DIR%%CONFIG_FILE%
set SCRIPT_FILE=get_scripts.sh
set SCRIPT_PATH=%LOCAL_DIR%%SCRIPT_FILE%
set RUN_SCRIPT_FILE=run_scripts.sh
set RUN_SCRIPT_PATH=%LOCAL_DIR%%RUN_SCRIPT_FILE%
set CREDENTIALS_FILE=git_credentials.txt
set CREDENTIALS_PATH=%LOCAL_DIR%%CREDENTIALS_FILE%
set TYPER_SCRIPT_FILE=typer.sh
set TYPER_SCRIPT_PATH=%LOCAL_DIR%%TYPER_SCRIPT_FILE%
 
rem Imprimir los valores de las variables
echo CONFIG_PATH: %CONFIG_PATH%
echo SCRIPT_PATH: %SCRIPT_PATH%
echo CREDENTIALS_PATH: %CREDENTIALS_PATH%
                  
rem Verificar si el archivo de configuración existe
if not exist "%CONFIG_PATH%" (
  echo El archivo de configuración '%CONFIG_PATH%' no existe.
  exit /b 1
)

rem Leer los valores de las variables 'HostName', 'User', 'IdentityFile' desde el archivo 'config'
echo Leyendo los valores de las variables 'HostName', 'User', 'IdentityFile' desde el archivo 'config'...
for /f "usebackq tokens=1,2 delims= " %%i in ("%CONFIG_PATH%") do (
  if "%%i"=="HostName" set HostName=%%j                  
  if "%%i"=="User" set User=%%j                          
  if "%%i"=="IdentityFile" set IdentityFile=%%j          
)

rem Verificar si se han proporcionado las credenciales de acceso al servidor
if "%HostName%"=="" (
  echo No se ha proporcionado el valor de HostName en el archivo de configuración.
  exit /b 1
)

if "%User%"=="" (
  echo No se ha proporcionado el valor de User en el archivo de configuración.
  exit /b 1
)

if "%IdentityFile%"=="" (
  echo No se ha proporcionado el valor de IdentityFile en el archivo de configuración.
  exit /b 1
)

rem Eliminar espacios en blanco alrededor de los valores y Mostrar los valores de las variables 'IdentityFile', 'HostName', 'User'
set HostName=%HostName: =%
echo HostName: %HostName%   
set User=%User: =%
echo User: %User%  
set IdentityFile=%IdentityFile: =%
echo IdentityFile: %IdentityFile% 

rem Defir las variables para directorios remotos    
set REMOTE_DIR=/home/%User%/
echo REMOTE_DIR: %REMOTE_DIR%

rem Verificar que los archivos locales existen
if not exist "%SCRIPT_PATH%" (
  echo El archivo de scripts '%SCRIPT_FILE%' no existe.
  exit /b 1
)
echo Copiando archivo '%SCRIPT_FILE%' al directorio '%REMOTE_DIR%'...
scp -v -i "%IdentityFile%" "%SCRIPT_PATH%" "%User%@%HostName%:%REMOTE_DIR%"  

if not exist "%RUN_SCRIPT_PATH%" (
  echo El archivo de scripts '%RUN_SCRIPT_FILE%' no existe.
  exit /b 1
)
echo Copiando archivo '%RUN_SCRIPT_FILE%' al directorio '%REMOTE_DIR%'...
scp -v -i "%IdentityFile%" "%RUN_SCRIPT_PATH%" "%User%@%HostName%:%REMOTE_DIR%" 

if not exist "%CREDENTIALS_PATH%" (
  echo El archivo de credenciales '%CREDENTIALS_FILE%' no existe.
  exit /b 1
)
echo Copiando archivo '%CREDENTIALS_FILE%' al directorio '%REMOTE_DIR%'...
scp -v -i "%IdentityFile%" "%CREDENTIALS_PATH%" "%User%@%HostName%:%REMOTE_DIR%" 

rem  Crear una función que tome como parámetro el comando SSH que se va a ejecutar y la cadena de texto que se va a imprimir
echo Crear una función que tome como parámetro el comando SSH que se va a ejecutar y la cadena de texto que se va a imprimir
set SSH_COMMAND=ssh -i "%IdentityFile%" "%User%@%HostName%"
if %errorlevel% equ 0 (
  echo Copia de archivo completada exitosamente.
  echo Ejecutando comandos en el servidor...
  echo Eliminando el directorio scripts...
  call :execute_command "sudo rm -r %REMOTE_DIR%scripts" 
  echo Actualizando paquetes...
  call :execute_command "sudo apt-get update -y" 
  echo Instalando dos2unix...
  call :execute_command "sudo apt-get install dos2unix" 
  echo Ejecutando dos2unix en: %REMOTE_DIR%%SCRIPT_FILE%
  call :execute_command "sudo dos2unix %REMOTE_DIR%%SCRIPT_FILE%" 
  echo Ejecutando dos2unix en: %REMOTE_DIR%%RUN_SCRIPT_FILE%
  call :execute_command "sudo dos2unix %REMOTE_DIR%%RUN_SCRIPT_FILE%" 
  echo Ejecutando dos2unix en: %REMOTE_DIR%%CREDENTIALS_FILE%
  call :execute_command "sudo dos2unix %REMOTE_DIR%%CREDENTIALS_FILE%" 
  echo Cambiando propiedad al usuario de: %REMOTE_DIR%%SCRIPT_FILE%
  call :execute_command "sudo chown $USER:$USER %REMOTE_DIR%%SCRIPT_FILE%" 
  echo Cambiando propiedad al usuario de: %REMOTE_DIR%%CREDENTIALS_FILE%
  call :execute_command "sudo chown $USER:$USER %REMOTE_DIR%%CREDENTIALS_FILE%" 
  echo Cambiando permisos en: %REMOTE_DIR%%SCRIPT_FILE%
  call :execute_command "sudo chmod +x %REMOTE_DIR%%SCRIPT_FILE%" 
  echo Cambiando permisos en: %REMOTE_DIR%%RUN_SCRIPT_FILE%
  call :execute_command "sudo chmod +x %REMOTE_DIR%%RUN_SCRIPT_FILE%" 
  echo Cambiando permisos en: %REMOTE_DIR%%CREDENTIALS_FILE%
  call :execute_command "sudo chmod 600 %REMOTE_DIR%%CREDENTIALS_FILE%" 
  echo Ejecutando script: %REMOTE_DIR%%SCRIPT_FILE%
  call :execute_command "sudo bash %REMOTE_DIR%%SCRIPT_FILE%" 

  echo Comandos en el servidor ejecutados exitosamente.

) else (
  echo Error durante la copia de archivo al servidor.
)

goto :end

:execute_command
  %SSH_COMMAND% "%~1"
  echo %~2
  goto :eof

:end

echo Esperando antes de intentar reconectar al servidor...
timeout /t 60
echo Reconectando al servidor...

set MAX_RETRIES=9999
set RETRIES=0
set CONNECTED=false

:reconnect
if %CONNECTED%==true goto :end_reconnect

set /a RETRIES+=1
echo Intento de reconexión %RETRIES% de %MAX_RETRIES%...

if %errorlevel% equ 0 (
  set CONNECTED=true
  echo Reconexión exitosa.
  echo Ejecutando script: %REMOTE_DIR%%RUN_SCRIPT_FILE%
  call :execute_command "sudo bash %REMOTE_DIR%%RUN_SCRIPT_FILE%"

) else (
  echo Error en la reconexión.
)

if %RETRIES% lss %MAX_RETRIES% (
  echo Esperando 10 segundos antes de intentar nuevamente...
  timeout /t 10
  goto :reconnect
) else (
  echo No se pudo establecer conexión con el servidor después de %MAX_RETRIES% intentos.
)

:end_reconnect

