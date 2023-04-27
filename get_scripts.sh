#!/bin/bash
# get_scripts.sh
# Variables
API_URL="https://api.github.com" # API para autenticación en GitHub
REPOSITORY="scripts" # Respositorio Github a clonar
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # Obtener el directorio actual
CREDENTIALS_FILE="git_credentials.txt"
CREDENTIALS_PATH="$CURRENT_PATH/$CREDENTIALS_FILE" # Directorio del archivo git_credentials.txt
SCRIPT_DIR="$CURRENT_PATH/$REPOSITORY" # Directorio final
UTILITIES_PATH="$SCRIPT_DIR/utilities"
# Vector de sub-scripts a ejecutar recursivamente
scripts=(
    #"update_system.sh"
    #"add_repositories.sh"
    #"tree_install.sh"
    #"zip_install.sh"
    #"AWS/aws_install.sh"
    #"JQ/jq_install.sh"
    #"NGINX/nginx_install.sh"
    #"NodeJS/nodejs_install.sh"
    #"PHP/php_install.sh"
    #"Python/python_install.sh"
    "MySQL/mysql_install.sh"
    #"PostgreSQL/postgresql_install.sh"
    #"NEXTCLOUD/nextcloud_install.sh"

)
# Función para leer credenciales desde archivo de texto
function read_credentials() {
  echo "Leyendo cedenciales..."
if [ -f "$CREDENTIALS_PATH" ]; then
    source "$CREDENTIALS_PATH"
    username=${username%%[[:space:]]}  # Eliminar espacios en blanco finales
    token=${token##+[[:space:]]}       # Eliminar espacios en blanco iniciales
    export git="https://${username}:${token}@github.com/${username}/${REPOSITORY}.git"
    echo "Credenciales de acceso:"
    echo "username: $username"
    echo "token: ${token:0:3}*********"
    echo "URL: $git"
else
    echo "El archivo $CREDENTIALS_FILE no existe en la ubicación $CREDENTIALS_PATH. Por favor, cree el archivo con las variables username y token, y vuelva a intentarlo."
    exit 1
fi 
}
# Función para verificar si el directorio de destino ya existe y clonar/actualizar Git
function check_directory() {
    echo "Verificando si el directorio de destino ya existe..."
  if [ -d "$SCRIPT_DIR" ]; then
      echo "El directorio de destino ya existe. Realizando actualización..."
      update_git
  else
      echo "El directorio de destino no existe."
      clone_REPOSITORY
  fi
}
# Función para clonar repositorios
function clone_REPOSITORY() {
  echo "Creando directorio $SCRIPT_DIR..."
  mkdir "$SCRIPT_DIR"
  echo "Clonando $git en $SCRIPT_DIR..."
  if git clone "$git" "$SCRIPT_DIR"; then
      echo "¡Clonado exitoso!"
  else
      echo "Error al clonar el repositorio."
      exit 1
  fi
}
# Función para actualizar repositorios
function update_git () {
    cd "$SCRIPT_DIR"
    if response=$(curl -s -H "Authorization: token $token" "$API_URL/$username"); then
        echo "¡Inicio de sesión exitoso en GitHub!"
        echo "Actualizando $SCRIPT_DIR desde $git..."
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
function update_dir_ownership () {
    echo "Actualizando la propiedad del directorio $SCRIPT_DIR..."
    if ! chown -R "$USER:$USER" "$SCRIPT_DIR"; then
        echo "No se pudo actualizar la propiedad del directorio $SCRIPT_DIR. Por favor, revise los permisos del directorio y vuelva a intentarlo."
    fi
    echo "La propiedad del directorio $SCRIPT_DIR fue actualizada para $USER..."
    
     echo "Actualizando la propiedad del directorio $UTILITIES_PATH..."
    if ! chown -R "$USER:$USER" "$UTILITIES_PATH"; then
        echo "No se pudo actualizar la propiedad del directorio $UTILITIES_PATH. Por favor, revise los permisos del directorio y vuelva a intentarlo."
    fi
    echo "La propiedad del directorio $UTILITIES_PATH fue actualizada para $USER..."
}
# Función para verificar si el paquete dos2unix está instalado
function check_dos2unix () {
    echo "Verificando si el paquete dos2unix está instalado..."
    if command -v dos2unix >/dev/null 2>&1; then
        echo "dos2unix está instalado. Se procederá a la corrección de los archivos."
        find "$SCRIPT_DIR" -type f -exec dos2unix {} +
    else
        echo "dos2unix no está instalado. Instálalo para corregir los archivos."
        exit 1
    fi
}
# Función para asignar permisos de ejecución a los archivos copiados
function assign_execution_permissions () {
    echo "Asignando permisos de ejecución a los archivos copiados en $SCRIPT_DIR..."
    find "$SCRIPT_DIR" -type f -exec chmod +x {} +
    
    echo "Asignando permisos de ejecución a los archivos copiados en $UTILITIES_PATH..."
    find "$UTILITIES_PATH" -type f -exec chmod +x {} +
}
# Función para crear enlaces simbólicos en $SCRIPT_DIR
function create_symlinks () {
    echo "Creando enlaces simbólicos entre $SCRIPT_DIR y /usr/local/bin..."
    cd "$SCRIPT_DIR" || exit
    for file in *; do
        if [ -f "$file" ] && [ ! -L "/usr/local/bin/$file" ]; then
            ln -s "$SCRIPT_DIR/$file" "/usr/local/bin/$file"
            if [ $? -eq 0 ]; then
            echo "Enlace simbólico creado para $file."
            else
            echo "Error: no se pudo crear el enlace simbólico para $file. Verifique los permisos."
            fi
        fi
    done
    echo "Enlaces simbólicos creados exitosamente desde $SCRIPT_DIR."
}
# Función para crear enlaces simbólicos en $UTILITIES_PATH
function create_symlinks2 () {
    echo "Creando enlaces simbólicos entre $UTILITIES_PATH y /usr/local/bin..."
    cd "$UTILITIES_PATH" || exit
    for archivo in *; do
        if [ -f "$archivo" ] && [ ! -L "/usr/local/bin/$archivo" ]; then
            ln -s "$UTILITIES_PATH/$archivo" "/usr/local/bin/$archivo"
            if [ $? -eq 0 ]; then
            echo "Enlace simbólico creado para $archivo."
            else
            echo "Error: no se pudo crear el enlace simbólico para $archivo. Verifique los permisos."
            fi
        fi
    done
    echo "Enlaces simbólicos creados exitosamente desde $UTILITIES_PATH."
}
# Función para actualizar la sesión de la terminal
function update_terminal_session () {
    echo "Actualizando la sesión de la terminal..."
    source ~/.bashrc
}
# Función para actualizar el sistema
function update_system() {
  echo "Actualizando sistema...."
  sudo apt-get update || { echo "Ha ocurrido un error al actualizar el sistema."; exit 1; }
  echo "Sistema actualizado."
}
# Función para validar si cada script en el vector "scripts" existe y tiene permiso de ejecución
function validate_scripts() {
  echo "Validando la existencia de cada script en la lista de sub-scripts..."
  for script in "${scripts[@]}"; do
    echo "Compobando '$script' en: $SCRIPT_DIR/..."
    if [ ! -f "$SCRIPT_DIR/$script" ] || [ ! -x "$SCRIPT_DIR/$script" ]; then
      echo "Error: $script no existe o no tiene permiso de ejecución"
      exit 1
    fi
    echo "El script '$script' existe en: $SCRIPT_DIR/"
  done
  echo "Todos los sub-scripts en '$SCRIPT_DIR' existen y tienen permiso de ejecución."
  return 0
}
# Función para ejecutar los scripts una vez
function run_scripts () {
  echo "Ejecutando cada script en la lista de sub-scripts..."
  for script in "${scripts[@]}"; do
    echo "Compobando '$script' en: $SCRIPT_DIR/..."
    if [ -f "$SCRIPT_DIR/$script" ] && [ -x "$SCRIPT_DIR/$script" ]; then
      echo "Ejecutando script: $script"
      sudo bash "$SCRIPT_DIR/$script"
    else
      echo "Error: $script no existe o no tiene permiso de ejecución"
    fi
    echo "El script: '$script' fue ejecutado."
    echo "Todos los subscripts en '$SCRIPT_DIR' se han ejecutado correctamente."
  return 0
  done
}
# Función para actualizar paquetes
function upgrade_system() {
  echo "Actualizando paquetes...."
  sudo apt-get upgrade -y || { echo "Ha ocurrido un error al actualizar los paquetes."; exit 1; }
  echo "Paquetes actualizados."
}
# Función para limpiar sistema
function clean_system() {
  echo "Limpiando sistema..."
  sudo apt-get clean -y
  sudo apt autoremove -y
  echo "Limpieza de sistema completada."
}
# Función principal
function get_scripts () {
    echo "**********GET & RUN SCRIPTS***********"
    #read_credentials
    #check_directory
    #update_dir_ownership
    #check_dos2unix
    #assign_execution_permissions
    #create_symlinks
    #create_symlinks2
    #update_terminal_session
    #update_system
    validate_scripts
    run_scripts
    upgrade_system
    clean_system
    echo "**********GET & RUN SCRIPTS***********"
    echo "**************ALL DONE***************"
}
# Llamar a la función principal
get_scripts
