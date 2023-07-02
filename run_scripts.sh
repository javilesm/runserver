#!/bin/bash
# run_scripts.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # Obtener el directorio actual
CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)" # Obtener el directorio actual
STATE_FILE="$CURRENT_PATH/state.txt" # Archivo de estado
REPOSITORY="scripts" # Respositorio Github a clonar
SCRIPT_DIR="$CURRENT_PATH/$REPOSITORY" # Directorio final
DATE=$(date +"%Y%m%d_%H%M%S") # Obtener la fecha y hora actual para el nombre del archivo de registro
LOG_FILE="run_scripts_$DATE.log" # Nombre del archivo de registro
LOG_PATH="$CURRENT_DIR/$LOG_FILE" # Ruta al archivo de registro
# Vector de sub-scripts a ejecutar recursivamente
scripts=(
    "add_repositories.sh"
    "packages_install.sh"
    "Python/python_install.sh"
    "PHP/php_install.sh"
    "MySQL/mysql_config.sh"
    "PostgreSQL/postgresql_config.sh"
    "NGINX/nginx_config.sh"
    "NEXTCLOUD/nextcloud_install.sh"
    "Postfix/postfix_install.sh"
    "configure_postfixadmin.sh"
    "Dovecot/generate_certs.sh"
    "Dovecot/dovecot_config.sh"
    "LDAP/openldap_config.sh"
    "LDAP/generate_certs.sh"
    "clamav_config.sh"
    "AWS/aws_install.sh"
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
# Función para agregar una entrada al crontab para automatizar la ejecución del script tras cada reinicio
function add_cron_entry() {
  local cron_entry="@reboot bash $CURRENT_PATH/scripts/packages_install.sh"
  
  # agregar una entrada al crontab para automatizar la ejecución del script tras cada reinicio
  echo "Agregando una entrada al crontab para automatizar la ejecución del script tras cada reinicio..."
  
  # Verificar si la entrada ya existe en el crontab
  if sudo crontab -l | grep -q "$cron_entry"; then
    echo "La entrada ya existe en el crontab. No se realizará ninguna modificación."
  else
    # Agregar la entrada al crontab utilizando echo y redirección de entrada
    echo "$(sudo crontab -l 2>/dev/null; echo "$cron_entry")" | sudo crontab -
    echo "Se ha agregado la entrada al crontab para ejecutar el script tras cada reinicio."
  fi
}
# Función para solicitar un reinicio y continuar automáticamente después del reinicio
function reboot_and_continue() {
  echo "Se requiere un reinicio del sistema. El script se reanudará automáticamente después del reinicio."
  echo "Reiniciando el sistema..."
  sudo shutdown -r now
}

# Función para guardar el estado actual en el archivo de estado
function save_state() {
    echo "Guardando estado actual en el archivo de estado: $STATE_FILE"
    echo "current_script_index=$current_script_index" > "$STATE_FILE"
}

# Función para cargar el estado anterior desde el archivo de estado
function load_state() {
    echo "Cargando estado anterior desde el archivo de estado: $STATE_FILE"
    source "$STATE_FILE"
}

# Función para validar si cada script en el vector "scripts" existe y tiene permiso de ejecución
function validate_script() {
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
# Función para ejecutar los scripts uno por uno
function run_script() {
    load_state

    # Si el archivo de estado no existe o no contiene la variable current_script_index, comenzar desde el primer script
    if [ -z "$current_script_index" ]; then
        current_script_index=0
    fi

    for ((i=current_script_index; i<${#scripts[@]}; i++)); do
        script="${scripts[$i]}"
        echo "Ejecutando script: $script"
        if [ -f "$SCRIPT_DIR/$script" ] && [ -x "$SCRIPT_DIR/$script" ]; then
            sudo bash "$SCRIPT_DIR/$script"
            echo "El script: '$script' fue ejecutado."
        else
            echo "Error: $script no existe o no tiene permiso de ejecución"
            exit 1
        fi

        current_script_index=$((i + 1))
        save_state

        # Solicitar reinicio y continuar después de cada script
        #sudo shutdown -r now
    done

    # Eliminar el archivo de estado al finalizar todos los scripts
    #rm "$STATE_FILE"
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
function run_scripts() {
  echo "**********RUN SCRIPTS***********"
  create_log
  add_cron_entry
  validate_script
  run_script
  stop_logging
  echo "**************ALL DONE***************"
}
# Llamar a la función principal
run_scripts
