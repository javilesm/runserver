#!/bin/bash
# getscripts

# Variables de autenticación de GitHub
username="javilesm" # usuario GitHub
token="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" # Token personal del usuario GitHub
repository="scripts.git"
path="/home/ubuntu/scripts/" # Directorio final
git="https://$username:$token@github.com/$username/$repository"
API_URL="https://api.github.com" # API para autenticación en GitHub

echo "************************"
echo "***GITHUB SYNC SCRIPT***"
echo "************************"
sleep 1

# Verificar si el directorio de destino ya existe
if [ -d "$path" ]; then
  echo "El directorio de destino ya existe. Realizando actualización..."
  cd "$path"
    # Realiza la autenticación en la API de GitHub utilizando el token de acceso
  response=$(curl -s -H "Authorization: token $token" $API_URL/$username)

  # Verifica si la autenticación fue exitosa
  if [ $? -eq 0 ]; then
    echo "Inicio de sesión exitoso en GitHub"
    git pull "$git"
  else
    echo "Error al iniciar sesión en GitHub. Por favor, verifica tu token de acceso."
    exit 1
  fi
  
else
  echo "Creando directorio de destino"
  mkdir "$path" 
  git clone "$git" "$path"
  echo "Clonando el repositorio..."
  if [ $? -eq 0 ]; then
    echo "El repositorio se ha clonado exitosamente en "$path""
  else
    echo "Ha ocurrido un error al clonar el repositorio."
    exit 1
  fi
fi

echo "¡Clonado/Actualizado exitosamente!"

# Actualiza la propiedad del directorio de destino
chown -R "$USER:$USER" "$path"

# Eliminar la extensión ".sh" de los archivos copiados
cd "$path" # Cambiar al directorio especificado

# Recorrer todos los archivos con extensión ".sh"
for file in *.sh; do
  # Obtener el nombre del archivo sin la extensión ".sh"
  new_name="${file%.sh}"
  
  # Renombrar el archivo sin la extensión ".sh"
  mv "$file" "$new_name"
  
  # Crear enlace simbólico en /usr/local/bin/ si no existe
  if [ ! -L "/usr/local/bin/$new_name" ]; then
    ln -s "$path$new_name" "/usr/local/bin/$new_name"
    echo "Se ha creado un enlace simbólico en /usr/local/bin/$new_name"
  else
    echo "El enlace simbólico /usr/local/bin/$new_name ya existe, no se ha creado uno nuevo"
  fi
done

# Crear enlaces simbólicos en /usr/local/bin/
for script in "$path"*; do
  if [ -f "$script" ]; then
    ln -sf "$script" "/usr/local/bin/$(basename "$script")"
  fi
done

# Asignar permisos de ejecución a cada archivo copiado
find "$path" -type f -exec chmod +x {} +

# Actualiza la sesión de tu terminal ejecutando source en el archivo de perfil de shell 
source ~/.bashrc

echo "El contenido del repositorio "$git" se ha copiado correctamente a "$path" con permisos de ejecución."
ls -a -lh $path
sleep 2

echo "************************"
echo "**********END***********"
echo "************************"
exit 1
