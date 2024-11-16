#!/usr/bin/env bash

# Função para contar arquivos e somar tamanhos
count_files() {
   local pattern="$1"
   local dir="$2"
   local result

   result=$(find "$dir" -maxdepth 1 -type f -name "$pattern" -exec stat --format="%s" {} + 2>/dev/null | awk '{count++; sum+=$1} END {print count, sum}')
   echo $result
}

# Função para imprimir resumo
print_summary() {
   local dir="$1"
   
   read n_tmp d_tmp <<< $(count_files "*.tmp" "$dir")
   read n_log d_log <<< $(count_files "*.log" "$dir")
   read n_py d_py <<< $(count_files "*.py" "$dir")

   echo "$((n_tmp + 0)) tmp file(s), with total size of $((d_tmp + 0)) bytes"
   echo "$((n_log + 0)) log file(s), with total size of $((d_log + 0)) bytes"
   echo "$((n_py + 0)) py files(s), with total size of $((d_py + 0)) bytes"
}

# Função para realizar limpeza
perform_clean() {
    local dir="$1"
    MSG_OUT="Cleaning $dir..."

    # Deletar arquivos .log antigos
    MSG_OUT="Deleting old log files..."
    local log_count=$(find "$dir" -type f -name '*.log' -mtime +3 -exec rm -f {} \; -print | wc -l)
    echo "$MSG_OUT done! $log_count files have been deleted"

    # Deletar arquivos .tmp.'
    MSG_OUT="Deleting temporary files..."
    local tmp_count=$(find "$dir" -type f -name '*.tmp' -exec rm -f {} \; -print | wc -l)
    echo "$MSG_OUT done! $tmp_count files have been deleted"

    # Mover arquivos .py
    MSG_OUT="Moving python files..."
    if [[ -n $(find "$dir" -maxdepth 1 -type f -name '*.py') ]]; then
      mkdir -p "$dir/python_scripts"

    fi
    local py_count=$(find "$dir" -maxdepth 1 -type f -name '*.py' -exec mv -t "$dir/python_scripts" {} + -print | wc -l)
    echo "$MSG_OUT done! $py_count files have been moved"
    echo
    if [ $TARGET_DIR = "." ]; then
        echo "Clean up of the current directory is complete!"
    else
        echo "Clean up of the $dir is complete!"
    fi
}

echo "File Janitor, 2024"
echo "Powered by Bash"

# Verificação de opções

if [ -n "$1" -a "$1" = "help" ]; then
    cat file-janitor-help.txt
fi

SCRIPT_NAME="$0"

if [ -z "$1" -o "$1" != "list" ]; then
   MSG_HELP="Type $SCRIPT_NAME help to see available options"
fi

if [ "$1" = "list" ]; then
   MSG_HELP=""
   if [ -z "$2" ]; then
      echo "Listing files in the current directory"
      ls -Ax1
   elif [ -d "$2" ]; then
      echo "Listing files in $2"
      ls -A -U "$2"
   elif [ ! -e "$2" ]; then
      echo "$2 is not found"
   else
      echo "$2 is not a directory"
   fi
elif [ "$1" = "report" ]; then
   MSG_HELP=""
   if [ -z "$2" ]; then
      echo "The current directory contains:"
      print_summary "."
   else
      if [ -d "$2" ]; then
         echo "$2 contains:"
         print_summary "$2"
      else
         if [ -e "$2" ]; then
            echo "$2 is not a directory"
         else
            echo "$2 is not found"
         fi
      fi
   fi
elif [ "$1" = "clean" ]; then
    MSG_HELP=""
    TARGET_DIR="$2"
    MSG_OUT="Cleaning the current directory..."
    if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="."
        MSG_OUT="Cleaning the current directory..."
    elif [ -d "$TARGET_DIR" ]; then
       MSG_OUT="Cleaning $TARGET_DIR... "
    elif [ ! -e "$TARGET_DIR" ]; then
       MSG_OUT="$TARGET_DIR is not found"
       echo "$MSG_OUT"
       return
    else
       MSG_OUT="$TARGET_DIR is not a directory"
       echo "$MSG_OUT"
       return
    fi
    echo
    echo "$MSG_OUT"
    perform_clean "$TARGET_DIR"
else
   echo
   echo "$MSG_HELP"
   echo "Invalid option. $0 report [directory_path]"
fi