#!/bin/bash
# get_scripts.sh
# Variables
API_URL="https://api.github.com" # API para autenticación en GitHub
repository="scripts" # Respositorio Github a clonar
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # Obtener el directorio actual
CREDENTIALS_FILE="git_credentials.txt"
CREDENTIALS_PATH="$CURRENT_PATH/$CREDENTIALS_FILE" # Directorio del archivo git_credentials.txt
path="$CURRENT_PATH/$repository" # Directorio final
SUB_SCRIPT="run_scripts.sh" #Subscript a ejecutar
# Función para leer credenciales desde archivo de texto
function read_credentials() {
    echo "Leyendo cedenciales..."
    if [ -f "$CREDENTIALS_PATH" ]; then
        source "$CREDENTIALS_PATH"
        echo "Credenciales de acceso:"
        echo "username: $username"
        echo "token: ${token:0:3}*********"
        export git="https://$username:$token@github.com/$username/$repository.git"
    else
        echo "El archivo $CREDENTIALS_FILE no existe en la ubicación $CREDENTIALS_PATH. Por favor, cree el archivo con las variables username y token, y vuelva a intentarlo."
        exit 1
    fi 
}
# Función para verificar si el directorio de destino ya existe y clonar/actualizar Git
function check_directory() {
    echo "Verificando si el directorio de destino ya existe..."
    if [ -d "$path" ]; then
        echo "El directorio de destino ya existe. Realizando actualización..."
        update_git
    else
        echo "El directorio de destino no existe. Clonando el repositorio..."
        clone_repository
    fi
}
# Función para clonar repositorios
function clone_repository() {
    echo "Clonando $git en $path..."
    if git clone "$git" "$path"; then
        echo "¡Clonado exitoso!"
    else
        echo "Error al clonar el repositorio. Por favor, verifique su conexión a Internet e inténtelo de nuevo."
        exit 1
    fi
}
# Función para actualizar repositorios
function update_git() {
    cd "$path"
    if response=$(curl -s -H "Authorization: token $token" "$API_URL/$username"); then
        echo "¡Inicio de sesión exitoso en GitHub!"
        echo "Actualizando $path desde $git..."
        if git pull "$git"; then
            echo "Actualización exitosa."
        else
            echo "Error al actualizar el repositorio. Por favor, verifique su conexión a Internet e inténtelo de nuevo."
            exit 1
        fi
    else
        echo "Error al iniciar sesión en GitHub. Por favor, verifica tu token de acceso."
        exit 1
    fi
}
# Función para actualizar la propiedad del directorio de destino
function update_dir_ownership() {
    echo "Actualizando la propiedad del directorio $path..."
    if ! chown -R "$USER:$USER" "$path"; then
        echo "No se pudo actualizar la propiedad del directorio de destino. Por favor, revise los permisos del directorio y vuelva a intentarlo."
    fi
    echo "La propiedad del directorio $path fue actualizada para $USER..."
}
# Función para verificar si el paquete dos2unix está instalado
check_dos2unix() {
    echo "Verificando si el paquete dos2unix está instalado..."
    if command -v dos2unix >/dev/null 2>&1; then
        echo "dos2unix está instalado. Se procederá a la corrección de los archivos."
        find "$path" -type f -exec dos2unix {} +
    else
        echo "dos2unix no está instalado. Instálalo para corregir los archivos."
        exit 1
    fi
}
# Función para eliminar la extensión ".sh" de los archivos copiados
function remove_extension() {
    echo "Eliminando la extensión ".sh" de los archivos copiados..."
    cd "$path" || { echo "Error al cambiar al directorio especificado"; exit 1; }
    for file in *.sh; do
        mv "$file" "${file%.sh}"
    done
}
# Función para asignar permisos de ejecución a los archivos copiados
function assign_execution_permissions() {
    echo "Asignando permisos de ejecución a los archivos copiados..."
    find "$path" -type f -exec chmod +x {} +
}
# Función para crear enlaces simbólicos
function create_symlinks() {
    echo "Creando enlaces simbólicos en /usr/local/bin..."
    cd "$SCRIPTS_PATH" || exit
    for file in *; do
        if [ -f "$file" ] && [ ! -L "/usr/local/bin/$file" ]; then
            ln -s "$SCRIPTS_PATH/$file" "/usr/local/bin/$file"
            echo "Enlace simbólico creado para $file."
        fi
    done
    echo "Enlaces simbólicos creados exitosamente."
}
# Función para actualizar la sesión de la terminal
function update_terminal_session() {
    echo "Actualizando la sesión de la terminal..."
    source ~/.bashrc
}
# Función para ejecutar el script "run_scripts.sh"
function run_subscript() {
    echo "Buscando y ejecutando el script $SUB_SCRIPT..."
    cd "$SCRIPTS_PATH" || exit
    if [ -f "$SUB_SCRIPT" ]; then
        sudo bash "$SUB_SCRIPT"
    else
        echo "El archivo $SUB_SCRIPT no fue encontrado."
    fi
    echo "El script $SUB_SCRIPT ha sido ejecutado."
}
# Función principal
function main() {
    echo "**********GET SCRIPTS***********"
    read_credentials || exit 1
    check_directory || exit 1
    update_dir_ownership || exit 1
    check_dos2unix || exit 1
    remove_extension || exit 1
    assign_execution_permissions || exit 1
    create_symlinks || exit 1
    update_terminal_session || exit 1
    run_subscript || exit 1
    echo "**************END***************"
}
# Llamar a la función principal
main
