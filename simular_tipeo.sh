#!/bin/bash
# simular_tipeo.sh
CURRENT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )" # Obtener el directorio actual

RUN_SCRIPT_FILE="run_scripts.sh"
RUN_SCRIPT_PATH="$CURRENT_PATH/$RUN_SCRIPT_FILE"

sleep 5
echo "$RUN_SCRIPT_PATH" | xargs -I {} bash -c "{}"
