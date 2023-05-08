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
DATE=$(date +"%Y%m%d_%H%M%S") # Obtener la fecha y hora actual para el nombre del archivo de registro
LOG_FILE="get_scripts_$DATE.log" # Nombre del archivo de registro
LOG_PATH="$CURRENT_PATH/$LOG_FILE" # Ruta al archivo de registro
# Vector de sub-scripts a ejecutar recursivamente
scripts=(
    "install_spc.sh"
    "add_repositories.sh"
    "update_system.sh"
    "tree_install.sh"
    "zip_install.sh"
    "snap_install.sh"
    "clamav_install.sh"
    "AWS/aws_install.sh"
    "JQ/jq_install.sh"
    "NGINX/nginx_install.sh"
    "NodeJS/nodejs_install.sh"
    "PHP/php_install.sh"
    "Python/python_install.sh"
    "certbot_install.sh"
    "MySQL/mysql_install.sh"
    "NEXTCLOUD/nextcloud_install.sh"
    "PostgreSQL/postgresql_install.sh"
    "Dovecot/dovecot_install.sh"
    "upgrade_system.sh"
    "clean_system.sh"
)
# Función para crear un archivo de registro
function create_log() {
    # Verificar si el archivo de registro ya existe
    if [ -f "$LOG_PATH" ]; then
        echo "El archivo de registro '$LOG_FILE' ya existe."
        return 1
    fi
    
    # Intentar crear el archivo de registro
    echo "Creando archivo de registro '$LOG_FILE'... "
    sudo touch "$LOG_PATH"
    if [ $? -ne 0 ]; then
        echo "Error al crear el archivo de registro '$LOG_FILE'."
        return 1
    fi
    echo "Archivo de registro '$LOG_FILE' creado exitosamente. "
    # Redirección de la salida estándar y de error al archivo de registro
    exec &> >(tee -a "$LOG_PATH")
    if [ $? -ne 0 ]; then
        echo "Error al redirigir la salida estándar y de error al archivo de registro."
        return 1
    fi
    # Mostrar un mensaje de inicio
    echo "Registro de eventos iniciado a las $(date '+%Y-%m-%d %H:%M:%S')."
    # Agregar una función de finalización para detener el logging
    trap "stop_logging" EXIT
}
# Función para leer credenciales desde archivo de texto
function read_credentials() {
  echo "Leyendo cedenciales..."
if [ -f "$CREDENTIALS_PATH" ]; then
    source "$CREDENTIALS_PATH"
    username=${username%%[[:space:]]}  # Eliminar espacios en blanco finales
    token=${token##+[[:space:]]}       # Eliminar espacios en blanco iniciales
    export git="https://${username}:${token}@github.com/${username}/${REPOSITORY}.git"
    echo "***Credenciales de acceso***"
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
      clone_repository
  fi
}
# Función para clonar repositorios
function clone_repository() {
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
# Función para actualizar la propiedad del directorio de destino y su contenido
function update_dir_ownership () {
    echo "Actualizando la propiedad del directorio $SCRIPT_DIR y su contenido..."
    if ! chown -R "$USER:$USER" "$SCRIPT_DIR"/*; then
        echo "No se pudo actualizar la propiedad del directorio $SCRIPT_DIR y su contenido. Por favor, revise los permisos del directorio y vuelva a intentarlo."
    fi
    echo "La propiedad del directorio $SCRIPT_DIR y su contenido fueron actualizados para $USER."
}

# Función para verificar si el paquete dos2unix está instalado y corregir todo el contenido y subdirectorios de SCRIPT_DIR
function check_dos2unix () {
    echo "Verificando si el paquete dos2unix está instalado..."
    if command -v dos2unix >/dev/null 2>&1; then
        echo "dos2unix está instalado. Se procederá a la corrección de los archivos en $SCRIPT_DIR y sus subdirectorios."
        find "$SCRIPT_DIR" -type f -exec dos2unix {} +
    else
        echo "dos2unix no está instalado. Instálalo para corregir los archivos en $SCRIPT_DIR y sus subdirectorios."
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
  local all_scripts_executed=true
  for script in "${scripts[@]}"; do
    echo "Compobando '$script' en: $SCRIPT_DIR/..."
    if [ -f "$SCRIPT_DIR/$script" ] && [ -x "$SCRIPT_DIR/$script" ]; then
      echo "Ejecutando script: $script"
      sudo bash "$SCRIPT_DIR/$script"
      echo "El script: '$script' fue ejecutado."
    else
      echo "Error: $script no existe o no tiene permiso de ejecución"
      all_scripts_executed=false
    fi
  done
  
  if $all_scripts_executed; then
    echo "Todos los subscripts en '$SCRIPT_DIR' se han ejecutado correctamente."
    return 0
  else
    echo "Algunos subscripts en '$SCRIPT_DIR' no se pudieron ejecutar."
    return 1
  fi
}
# Función para detener el logging y mostrar un mensaje de finalización
function stop_logging() {
    # Restaurar la redirección de la salida estándar y de error a la terminal
    exec &> /dev/tty
    if [ $? -ne 0 ]; then
        echo "Error al restaurar la redirección de la salida estándar y de error a la terminal."
    fi
    # Mostrar un mensaje de finalización
    echo "Registro de eventos finalizado a las $(date '+%Y-%m-%d %H:%M:%S')."
    echo "Ruta al registro de eventos: '$LOG_PATH'"
}
# Función principal
function get_scripts () {
    echo "**********GET & RUN SCRIPTS***********"
    create_log
    read_credentials
    check_directory
    update_dir_ownership
    check_dos2unix
    assign_execution_permissions
    create_symlinks
    create_symlinks2
    update_terminal_session
    validate_scripts
    run_scripts
    stop_logging
    echo "**************ALL DONE***************"
}
# Llamar a la función principal
get_scripts
