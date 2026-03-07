#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Использование: $(basename "$0") <файл>" >&2
    exit 1
fi

input_file="$1"

if [ ! -f "$input_file" ]; then
    echo "Ошибка: файл не найден: $input_file" >&2
    exit 1
fi

base_name="$(basename -- "$input_file")"
output_file="$(pwd)/result-$base_name"

awk '
    /Result[[:space:]]*=[[:space:]]*-?[0-9]+/ &&
    /Elapsed[[:space:]]*=[[:space:]]*[0-9]+([.][0-9]+)?/ {
        print
    }
' "$input_file" > "$output_file"

echo "Результат сохранён в: $output_file"