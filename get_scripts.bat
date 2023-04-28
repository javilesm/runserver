@echo off

rem Definir las variables para directorios locales
set config_file=config
set script_dir=%~dp0
set script=get_scripts.sh
set credentials=git_credentials.txt
set local_file_path=%script_dir%%script%
set credentials_path=%script_dir%%credentials%
set Config_Path=%script_dir%%config_file%

rem Imprimir los valores de las variables
cho config_file: %config_file%
echo script_dir: %script_dir%
echo script: %script%
echo local_file_path: %local_file_path%
echo credentials: %credentials%
echo credentials_path: %credentials_path%
echo Config_Path: %Config_Path%
                  
rem Leer los valores de las variables 'HostName', 'User', 'IdentityFile' desde el archivo 'config'
echo Leyendo los valores de las variables 'HostName', 'User', 'IdentityFile' desde el archivo 'config'...
for /f "usebackq tokens=1,2 delims= " %%i in ("%Config_Path%") do (
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
set server_file_path=/home/%User%/%script%  
echo server_file_path: %server_file_path%

rem Copiar archivos locales a directorios remotos
echo Copiando archivos locales a directorios remotosr...
scp -v -i "%IdentityFile%" "%local_file_path%" "%User%@%HostName%:%server_file_path%"
scp -v -i "%IdentityFile%" "%credentials_path%" "%User%@%HostName%:%server_file_path%"  

if %errorlevel% equ 0 (
  echo Copia de archivos locales a directorios remotos completada exitosamente.
  echo Ejecutando comandos en el servidor...
  ssh -i "%IdentityFile%" "%User%@%HostName%" "sudo apt-get install dos2unix && sudo dos2unix /home/%User%/%script% && sudo chown $USER:$USER /home/%User%/%script% && sudo chmod +x /home/%User%/%script% && sudo bash /home/%User%/%script%"
  echo Comandos en el servidor ejecutados exitosamente.
) else (
  echo Error durante la copia de archivo al servidor.
)
