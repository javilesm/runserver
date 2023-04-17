#!/bin/bash
# getscripts

# Variables de autenticación de GitHub
username="javilesm" # usuario
path="/home/ubuntu/scripts/" # Directorio final
git_url="https://github.com/$username/scripts.git" # URL del repositorio a clonar con credenciales de autenticación

echo "************************"
echo "***GITHUB SYNC SCRIPT***"
echo "************************"
sleep 2

# Verificar si el directorio de destino ya existe
if [ -d $path ]; then
  echo "El directorio de destino ya existe. Realizando actualización..."
  chown "$USER:$USER" "$path"
  cd $path
  git pull $git_url
else
  echo "Creando directorio de destino"
  mkdir $path 
  chown "$USER:$USER" "$path"
  cd $path
  git clone $git_url $path
  echo "Clonando el repositorio..."
fi

# Eliminar la extensión ".sh" de los archivos copiados
find "$path" -type f -name "*.sh" -exec mv {} $(dirname {})/$(basename {} .sh) \;

# Asignar permisos de ejecución a cada archivo copiado
find "$path" -type f -exec chmod +x {} +

# Crear enlaces simbólicos en /usr/local/bin/
for script in $path*; do
  if [ -f "$script" ]; then
    ln -sf "$script" "/usr/local/bin/$(basename "$script")"
  fi
done

# Actualiza la sesión de tu terminal ejecutando source en el archivo de perfil de shell 
source ~/.bashrc

echo "El contenido del repositorio $git_url se ha copiado correctamente a $path con permisos de ejecución."
sleep 2
echo "************************"
echo "**********END***********"
echo "************************"
exit 1
