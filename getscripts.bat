@echo off

set HostName=ec2-3-220-58-75.compute-1.amazonaws.com
set User=ubuntu
set IdentityFile=C:\Users\jorge\.ssh\samava.pem
set local_file_path=C:\Users\jorge\.ssh\getscripts.sh
set server_file_path=/home/%User%/getscripts.sh

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
