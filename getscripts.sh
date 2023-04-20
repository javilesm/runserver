#!/bin/bash
# getscripts

# Variables de GitHub
API_URL="https://api.github.com" # API para autenticación en GitHub
repository="scripts"


# Obtener la ubicación del archivo git_credentials.txt
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CREDENTIALS_FILE="$CURRENT_PATH/git_credentials.txt"

# variables del sistema
path="$CURRENT_PATH/$repository/" # Directorio final
SUB_SCRIPT="run_scripts" #Subscript a ejecutar

# Función para leer credenciales desde archivo de texto
function read_credentials() {
    if [ -f $CREDENTIALS_FILE ]; then
        source $CREDENTIALS_FILE
        username=$username
        token=$token
        echo "Credenciales de acceso:"
        echo "username: $username"
        echo "token: ${token:0:3}*********"
    else
        echo "El archivo git_credentials.txt no existe en la ubicación $CREDENTIALS_FILE. Por favor, cree el archivo con las variables username y token, y vuelva a intentarlo."
        exit 1
    fi
}

# Función para verificar si el directorio de destino ya existe
function check_directory() {
    git="https://$username:$token@github.com/$username/$repository.git"
    if [ -d "$path" ]; then
        echo "El directorio de destino ya existe. Realizando actualización..."
        cd "$path"
        response=$(curl -s -H "Authorization: token $token" $API_URL/$username)
        echo "Inicio de sesión exitoso en GitHub"
        if [ $? -eq 0 ]; then
            echo "Actualizando $path desde $git"
            cd "$path"
            git pull "$git"
        else
            echo "Error al iniciar sesión en GitHub. Por favor, verifica tu token de acceso."
            exit 1
        fi
    else
        echo "Creando directorio de destino"
        mkdir "$path" 
        echo "Clonando el repositorio $git..."
        git clone "$git" "$path"
        if [ $? -eq 0 ]; then
            echo "El repositorio se ha clonado exitosamente en "$path""
        else
            echo "Ha ocurrido un error al clonar el repositorio."
            exit 1
        fi
    fi
}

# Función principal
function main() {
    echo "**********GET SCRIPTS***********"
    echo "Verificando si el directorio de destino ya existe"
    read_credentials
    check_directory "$username" "$token"
    echo "¡Clonado/Actualizado exitosamente!"
}

# Llamar a la función principal
main

# Actualiza la propiedad del directorio de destino
echo "Actualizando la propiedad del directorio de destino"
chown -R "$USER:$USER" "$path"

# Eliminar la extensión ".sh" de los archivos copiados
echo "Eliminando la extensión ".sh" de los archivos copiados"
cd "$path" # Cambiar al directorio especificado

# Ejecutar dos2unix en todo el contenido del directorio
echo "Ejecutando dos2unix en todo el contenido del directorio"
find "$path" -type f -exec dos2unix {} +

# Recorrer todos los archivos con extensión ".sh"
for file in *.sh; do
  # Obtener el nombre del archivo sin la extensión ".sh"
  new_name="${file%.sh}"
  
  # Renombrar el archivo sin la extensión ".sh"
  mv "$file" "$new_name"
  ls -a -lh "$path"
  
  # Crear enlace simbólico en /usr/local/bin/ si no existe
  if [ ! -L "/usr/local/bin/$new_name" ]; then
    ln -s "$path$new_name" "/usr/local/bin/$new_name"
    echo "Se ha creado un enlace simbólico en /usr/local/bin/$new_name"
  else
    echo "El enlace simbólico /usr/local/bin/$new_name ya existe, no se ha creado uno nuevo"
  fi
done

# Asignar permisos de ejecución a cada archivo copiado
echo "Asignando permisos de ejecución a cada archivo copiado"
find "$path" -type f -exec chmod +x {} +

# Buscar el script "run_scripts.sh" y ejecutarlo
echo "Buscando el script $SUB_SCRIPT y ejecutarlo"
if [ -f "$SUB_SCRIPT" ]; then
    echo "Ejecutando $SUB_SCRIPT ..."
    sudo "$SUB_SCRIPT"
else
    echo "No se encontró el archivo $SUB_SCRIPT"
fi

# Fin
echo "**********END***********"
exit 0
