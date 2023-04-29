@echo off

rem Definir las variables para directorios locales
set CONFIG_FILE=config
set LOCAL_DIR=%~dp0
set CONFIG_PATH=%LOCAL_DIR%%CONFIG_FILE%
set SCRIPT_FILE=get_scripts.sh
set SCRIPT_PATH=%LOCAL_DIR%%SCRIPT_FILE%
set CREDENTIALS_FILE=git_credentials.txt
set CREDENTIALS_PATH=%LOCAL_DIR%%CREDENTIALS_FILE%
 
rem Imprimir los valores de las variables
echo CONFIG_PATH: %CONFIG_PATH%
echo SCRIPT_PATH: %SCRIPT_PATH%
echo CREDENTIALS_PATH: %CREDENTIALS_PATH%
                  
rem Leer los valores de las variables 'HostName', 'User', 'IdentityFile' desde el archivo 'config'
echo Leyendo los valores de las variables 'HostName', 'User', 'IdentityFile' desde el archivo 'config'...
for /f "usebackq tokens=1,2 delims= " %%i in ("%CONFIG_PATH%") do (
  if "%%i"=="HostName" set HostName=%%j                  
  if "%%i"=="User" set User=%%j                          
  if "%%i"=="IdentityFile" set IdentityFile=%%j          
)

rem Eliminar espacios en blanco alrededor de los valores de las variables
set HostName=%HostName: =%
set User=%User: =%
set IdentityFile=%IdentityFile: =%

rem Mostrar los valores de las variables 'HostName', 'User'
echo IdentityFile: %IdentityFile%                        
echo HostName: %HostName%                                
echo User: %User%                                        

rem Defir las variables para directorios remotos    
set REMOTE_DIR=/home/%User%/
echo REMOTE_DIR: %REMOTE_DIR%

rem Copiar archivos locales a directorios remotos
echo Copiando archivo '%SCRIPT_FILE%' al directorio '%REMOTE_DIR%'...
scp -v -i "%IdentityFile%" "%SCRIPT_PATH%" "%User%@%HostName%:%REMOTE_DIR%"  
echo Copiando archivo '%CREDENTIALS_FILE%' al directorio '%REMOTE_DIR%'...
scp -v -i "%IdentityFile%" "%CREDENTIALS_PATH%" "%User%@%HostName%:%REMOTE_DIR%"  

if %errorlevel% equ 0 (
  echo Copia de archivo completada exitosamente.
  echo Ejecutando comandos en el servidor...
  echo Instalando dos2unix...
  ssh -i "%IdentityFile%" "%User%@%HostName%" "sudo apt-get install dos2unix"
  echo Ejecutando dos2unix en: %REMOTE_DIR%%SCRIPT_FILE%
  ssh -i "%IdentityFile%" "%User%@%HostName%" "sudo dos2unix %REMOTE_DIR%%SCRIPT_FILE%"
  echo Ejecutando dos2unix en: %REMOTE_DIR%%CREDENTIALS_FILE%
  ssh -i "%IdentityFile%" "%User%@%HostName%" "sudo dos2unix %REMOTE_DIR%%CREDENTIALS_FILE%"
  echo Cambiando propiedad al usuario de: %REMOTE_DIR%%SCRIPT_FILE%
  ssh -i "%IdentityFile%" "%User%@%HostName%" "sudo chown $USER:$USER %REMOTE_DIR%%SCRIPT_FILE%"
  echo Cambiando propiedad al usuario de: %REMOTE_DIR%%CREDENTIALS_FILE%
  ssh -i "%IdentityFile%" "%User%@%HostName%" "sudo chown $USER:$USER %REMOTE_DIR%%CREDENTIALS_FILE%"
  echo Cambiando permisos en: %REMOTE_DIR%%SCRIPT_FILE%
  ssh -i "%IdentityFile%" "%User%@%HostName%" "sudo chmod +x %REMOTE_DIR%%SCRIPT_FILE%"
  echo Cambiando permisos en: %REMOTE_DIR%%CREDENTIALS_FILE%
  ssh -i "%IdentityFile%" "%User%@%HostName%" "sudo chmod 600 %REMOTE_DIR%%CREDENTIALS_FILE%"
  echo Ejecutando remotamente el script: %REMOTE_DIR%%SCRIPT_FILE%
  ssh -i "%IdentityFile%" "%User%@%HostName%" "sudo bash %REMOTE_DIR%%SCRIPT_FILE%"
  echo Comandos en el servidor ejecutados exitosamente.
) else (
  echo Error durante la copia de archivo al servidor.
)
