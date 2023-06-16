#!/bin/bash
# run_scripts.sh
# Variables
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # Obtener el directorio actual
STATE_FILE="$CURRENT_PATH/state.txt" # Archivo de estado
REPOSITORY="scripts" # Respositorio Github a clonar
SCRIPT_DIR="$CURRENT_PATH/$REPOSITORY" # Directorio final
# Vector de sub-scripts a ejecutar recursivamente
scripts=(
    "add_repositories.sh"
    "update_system.sh"
    "packages_install.sh"
    "clamav_config.sh"
    "AWS/aws_install.sh"
    "Python/python_install.sh"
    "Python/run_django.sh"
    "PHP/php_install.sh"
    "MySQL/mysql_config.sh"
    "PostgreSQL/postgresql_config.sh"
    "NGINX/nginx_config.sh"
    "NEXTCLOUD/nextcloud_install.sh"
    "Postfix/postfix_install.sh"
    "Dovecot/generate_certs.sh"
    "Dovecot/dovecot_config.sh"
    "LDAP/openldap_config.sh"
    "LDAP/generate_certs.sh"
    "upgrade_system.sh"
    "clean_system.sh"
)
# Función para solicitar un reinicio y continuar automáticamente después del reinicio
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
        reboot_and_continue
    done

    # Eliminar el archivo de estado al finalizar todos los scripts
    rm "$STATE_FILE"
}
# Función principal
function run_scripts() {
    echo "**********RUN SCRIPTS***********"
    validate_script
    run_script
    echo "**************ALL DONE***************"
}
# Llamar a la función principal
run_scripts
