@echo off

set server_host=ec2-3-220-58-75.compute-1.amazonaws.com
set server_user=ubuntu
set private_key_path=C:\Users\jorge\.ssh\samava.pem
set local_file_path=C:\Users\jorge\.ssh\getscripts.sh
set server_file_path=/home/%server_user%/getscripts.sh

echo Ejecutando la copia del archivo al servidor...
scp -v -i "%private_key_path%" "%local_file_path%" "%server_user%@%server_host%:%server_file_path%"

if %errorlevel% equ 0 (
  echo Copia de archivo completada exitosamente.
 ) else (
  echo Error durante la copia de archivo al servidor.
)

