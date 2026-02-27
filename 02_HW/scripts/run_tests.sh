#!/usr/bin/env bash

# usage:
#   ./run_tests.sh tests_dir template compare count [nums...]
#
# примеры:
#   ./run_tests.sh ./tests ./template.txt ./compare.txt 0
#   ./run_tests.sh ./tests ./template.txt ./compare.txt 3 1 4 7

set -u
shopt -s nullglob

T=' ;:!?'   # фиксированный t
M='2'       # фиксированный m для задачи 1

die() { echo "error: $*" >&2; exit 2; }

strip_cr() {
  # убираем \r (если файлы с Windows CRLF)
  local s="$1"
  printf '%s' "${s%$'\r'}"
}

is_int() { [[ "${1:-}" =~ ^[0-9]+$ ]]; }

# -------- parse args --------
[[ $# -ge 4 ]] || die "нужно минимум 4 аргумента: tests_dir template compare count [nums...]"

tests_dir="$1"
template_file="$2"
compare_file="$3"
count="$4"
shift 4

[[ -d "$tests_dir" ]] || die "tests_dir не существует или не папка: $tests_dir"
[[ -f "$template_file" ]] || die "template не существует: $template_file"
[[ -f "$compare_file" ]] || die "compare не существует: $compare_file"
is_int "$count" || die "count должен быть числом"

# -------- выбрать программы --------
declare -a programs=()
declare -A seen=()

if [[ "$count" -eq 0 ]]; then
  programs=(1 2 3 4 5 6 7 8 9)
else
  [[ "$count" -ge 1 && "$count" -le 9 ]] || die "count должен быть 0 или 1..9"
  [[ $# -eq "$count" ]] || die "ожидалось $count номеров программ после count, получено $#"

  for n in "$@"; do
    is_int "$n" || die "номер программы не число: $n"
    [[ "$n" -ge 1 && "$n" -le 9 ]] || die "номер программы вне диапазона 1..9: $n"
    [[ -z "${seen[$n]+x}" ]] || die "номер программы повторяется: $n"
    seen[$n]=1
    programs+=("$n")
  done
fi

# -------- прочитать template и compare --------
mapfile -t tmpl_lines < "$template_file"
mapfile -t cmp_lines  < "$compare_file"

# нормализуем CRLF
for i in "${!tmpl_lines[@]}"; do tmpl_lines[$i]="$(strip_cr "${tmpl_lines[$i]}")"; done
for i in "${!cmp_lines[@]}";  do cmp_lines[$i]="$(strip_cr "${cmp_lines[$i]}")";  done

# -------- лог --------
mkdir -p logs logs/out logs/run

log_file="logs/$(date +%Y%m%d_%H%M%S).log"
: > "$log_file" || die "не удалось создать лог: $log_file"

log() { printf '%s\n' "$*" >> "$log_file"; }

# -------- список входных файлов --------
# только файлы в корне tests_dir
mapfile -d '' -t fin_files < <(find "$tests_dir" -maxdepth 1 -type f -print0 | LC_ALL=C sort -z)

if [[ "${#fin_files[@]}" -eq 0 ]]; then
  die "в tests_dir нет файлов: $tests_dir"
fi

# -------- runner --------
run_one() {
  local n="$1"
  local fin="$2"
  local tpl_idx="$3"
  local s="$4"
  local x="$5"

  local exe
  exe=$(printf 'a%02d.out' "$n")

  local fin_base fin_tag fout run_out run_err
  fin_base="$(basename "$fin")"
  fin_tag="${fin_base// /_}"

  fout="logs/out/${exe%.out}_${fin_tag}_tpl$(printf '%04d' "$tpl_idx").out"
  run_out="logs/run/${exe%.out}_${fin_tag}_tpl$(printf '%04d' "$tpl_idx").stdout"
  run_err="logs/run/${exe%.out}_${fin_tag}_tpl$(printf '%04d' "$tpl_idx").stderr"

  log "--- N = $n ---"
  log "time: $(date '+%Y-%m-%d %H:%M:%S')"
  log "fin: $fin"
  log "fout: $fout"

  if [[ ! -x "./$exe" ]]; then
    log "cmd: ./$exe (НЕ НАЙДЕН или НЕ ИСПОЛНЯЕМЫЙ)"
    log ""
    return 0
  fi

  # собираем команду по формату задачи
  local -a cmd=()
  case "$n" in
    1)
      cmd=( "./$exe" "$fin" "$fout" "$s" "$T" "$M" )
      ;;
    2|6|7|8|9)
      cmd=( "./$exe" "$fin" "$fout" "$s" "$T" )
      ;;
    3|4|5)
      cmd=( "./$exe" "$fin" "$fout" "$s" "$T" "$x" )
      ;;
    *)
      log "cmd: ./$exe (неизвестный номер задачи)"
      log ""
      return 0
      ;;
  esac

  # логируем команду в виде, который можно копировать в терминал
  local cmd_pretty=""
  for a in "${cmd[@]}"; do
    a=${a//\\/\\\\}   # \  -> \\
    a=${a//\"/\\\"}   # "  -> \"
    cmd_pretty+="\"$a\" "
  done
  log "cmd: ${cmd_pretty% }"

  # запуск (и не роняем весь прогон, даже если возврат != 0)
  : > "$run_out"
  : > "$run_err"
  "${cmd[@]}" >"$run_out" 2>"$run_err"
  local rc=$?

  log "exit_code: $rc"

  # stderr/stdout самой программы (если есть)
  if [[ -s "$run_out" ]]; then
    log "=== program stdout ==="
    cat "$run_out" >> "$log_file"
    log ""
  fi
  if [[ -s "$run_err" ]]; then
    log "=== program stderr ==="
    cat "$run_err" >> "$log_file"
    log ""
  fi

  # содержимое fout после запуска
  log "=== out file content ==="
  if [[ -f "$fout" ]]; then
    cat "$fout" >> "$log_file"
    log ""
  else
    log "(out file не создан)"
    log ""
  fi
}

# -------- main loop --------
tpl_total="${#tmpl_lines[@]}"
if [[ "$tpl_total" -eq 0 ]]; then
  die "template пустой: $template_file"
fi

for fin in "${fin_files[@]}"; do
  for p in "${programs[@]}"; do
    for ((i=0; i<tpl_total; i++)); do
      s="${tmpl_lines[$i]}"
      x="${cmp_lines[$i]:-}"
      run_one "$p" "$fin" "$((i+1))" "$s" "$x"
    done
  done
done

echo "log: $log_file"
