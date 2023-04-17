@echo off

rem Definir las variables para directorios locales
set script_dir=%~dp0
set local_file_path=%script_dir%\getscripts.sh          
set Config_Path=%script_dir%\config                      

rem Leer los valores de las variables 'HostName', 'User', 'IdentityFile' desde el archivo 'config'
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
set server_file_path=/home/%User%/getscripts.sh   

rem Copiar archivos locales a directorios remotos
echo Ejecutando la copia del archivo al servidor...
scp -v -i "%IdentityFile%" "%local_file_path%" "%User%@%HostName%:%server_file_path%"   

if %errorlevel% equ 0 (
  echo Copia de archivo completada exitosamente.
  echo Ejecutando comandos en el servidor...
  ssh -i "%IdentityFile%" "%User%@%HostName%" "sudo sudo apt-get install dos2unix && sudo dos2unix /home/%User%/getscripts.sh && sudo mv /home/%User%/getscripts.sh /home/%User%/getscripts && sudo chown $USER:$USER /home/%User%/getscripts && sudo chmod +x /home/%User%/getscripts && sudo bash /home/%User%/getscripts"
  echo Comandos en el servidor ejecutados exitosamente.
) else (
  echo Error durante la copia de archivo al servidor.
)
