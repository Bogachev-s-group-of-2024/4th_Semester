#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") data_dir query_dir" >&2
  exit 2
}

[ $# -eq 2 ] || usage

data_dir="$1"
query_dir="$2"

[ -d "$data_dir" ] || { echo "data_dir is not a directory: $data_dir" >&2; exit 2; }
[ -d "$query_dir" ] || { echo "query_dir is not a directory: $query_dir" >&2; exit 2; }

# Папка, из которой запущен скрипт (там же тестируемая программа и logs)
base_dir="$(pwd -P)"
base_name="$(basename "$base_dir")"

logs_dir="$base_dir/logs"
mkdir -p "$logs_dir"

# Ищем тестируемую программу в папке запуска
prog=""
if [ -x "$base_dir/a.out" ]; then
  prog="$base_dir/a.out"
else
  script_name="$(basename "$0")"
  mapfile -t candidates < <(
    find "$base_dir" -maxdepth 1 -type f -perm -111 \
      ! -name "$script_name" \
      -printf '%p\n' | sort
  )
  if [ "${#candidates[@]}" -eq 1 ]; then
    prog="${candidates[0]}"
  else
    echo "Cannot find tested program in: $base_dir" >&2
    echo "Put executable a.out there, or leave only one executable file in that folder." >&2
    exit 3
  fi
fi

prog_abs="$(realpath -m "$prog")"

data_abs="$(realpath -m "$data_dir")"
query_abs="$(realpath -m "$query_dir")"
data_name="$(basename "$data_abs")"
query_name="$(basename "$query_abs")"

timestamp="$(date +%H-%M-%S)"

log_file="$logs_dir/${base_name}-${timestamp}-${data_name}-${query_name}.log"
: > "$log_file"

mapfile -d '' data_files < <(find "$data_dir" -maxdepth 1 -type f -print0 | sort -z)
mapfile -d '' query_files < <(find "$query_dir" -maxdepth 1 -type f -print0 | sort -z)

if [ "${#data_files[@]}" -eq 0 ]; then
  echo "No data files in: $data_dir" >> "$log_file"
  exit 0
fi

if [ "${#query_files[@]}" -eq 0 ]; then
  echo "No query files in: $query_dir" >> "$log_file"
  exit 0
fi

for data_file in "${data_files[@]}"; do
  for query_file in "${query_files[@]}"; do
    {
      echo "============================================================"
      echo "$(date '+%Y-%m-%d %H:%M:%S')"
      echo "Вид запуска программы"
      printf '%q %q < %q\n' "$prog_abs" "$data_file" "$query_file"
      echo "Файл с данными"
      echo "$data_file"
      echo "Файл с запросами"
      echo "$query_file"
      echo "----- output begin -----"
    } >> "$log_file"

    set +e
    "$prog_abs" "$data_file" < "$query_file" >> "$log_file" 2>&1
    rc=$?
    set -e

    {
      echo
      echo "----- output end -----"
      echo "Exit code"
      echo "$rc"
      echo
    } >> "$log_file"
  done
done

echo "Log saved to"
echo "$log_file"
