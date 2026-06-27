#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(
    cd "$(dirname "${BASH_SOURCE[0]}")" &&
    pwd
)"

# shellcheck source=./config.sh
source "$PROJECT_ROOT/config.sh"

info() {
    printf 'INFO: %s\n' "$1"
}

success() {
    printf 'OK: %s\n' "$1"
}

fail() {
    printf 'ERRO: %s\n' "$1" >&2
    exit 1
}

require_root() {
    [[ "$EUID" -eq 0 ]] \
        || fail "execute com sudo: sudo ./uninstall.sh"

    success "privilégios administrativos confirmados"
}

require_command() {
    local command_name="$1"

    command -v "$command_name" >/dev/null 2>&1 \
        || fail "comando obrigatório não encontrado: $command_name"

    success "comando disponível: $command_name"
}

detect_layout_state() {
    local file_path="$1"

    python3 - "$file_path" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])

try:
    text = path.read_text(encoding="utf-8")
except (OSError, UnicodeError):
    print("unreadable")
    raise SystemExit(0)

variant_match = re.search(
    r'xkb_symbols\s+"intl"\s*\{(?P<body>.*?)^\};',
    text,
    flags=re.DOTALL | re.MULTILINE,
)

if variant_match is None:
    print("missing-variant")
    raise SystemExit(0)

body = variant_match.group("body")

original_pattern = re.compile(
    r'key\s+<AB03>\s*\{\s*\[\s*'
    r'c\s*,\s*C\s*,\s*copyright\s*,\s*cent\s*'
    r'\]\s*\};'
)

modified_pattern = re.compile(
    r'key\s+<AB03>\s*\{\s*\[\s*'
    r'c\s*,\s*C\s*,\s*ccedilla\s*,\s*Ccedilla\s*'
    r'\]\s*\};'
)

original_count = len(original_pattern.findall(body))
modified_count = len(modified_pattern.findall(body))

if original_count == 1 and modified_count == 0:
    print("original")
elif original_count == 0 and modified_count == 1:
    print("modified")
else:
    print(
        f"inconsistent:"
        f"original={original_count},"
        f"modified={modified_count}"
    )
PY
}

validate_removal_path() {
    local path="$1"
    local label="$2"

    [[ -n "$path" ]] \
        || fail "$label está vazio"

    [[ "$path" == /* ]] \
        || fail "$label não é um caminho absoluto: $path"

    case "$path" in
        /|/bin|/boot|/dev|/etc|/home|/lib|/lib64|/media|/mnt|/opt|/proc|/root|/run|/sbin|/srv|/sys|/tmp|/usr|/var)
            fail "$label aponta para um diretório protegido: $path"
            ;;
    esac

    [[ "$path" != "$PROJECT_ROOT" ]] \
        || fail "$label não pode apontar para o repositório"

    [[ ! -L "$path" ]] \
        || fail "$label não pode ser um link simbólico: $path"
}

remove_project_directory() {
    local path="$1"
    local label="$2"

    validate_removal_path "$path" "$label"

    if [[ -e "$path" ]]; then
        rm -rf -- "$path"
        success "$label removido: $path"
    else
        info "$label já está ausente: $path"
    fi
}

printf '%s\n' "Desinstalação do $PROJECT_NAME"
printf '%s\n\n' "----------------------------------------"

require_root
require_command python3
require_command rm

[[ -f "$XKB_SYMBOLS_FILE" ]] \
    || fail "arquivo XKB não encontrado: $XKB_SYMBOLS_FILE"

[[ ! -L "$XKB_SYMBOLS_FILE" ]] \
    || fail "o arquivo XKB não pode ser um link simbólico"

[[ -r "$XKB_SYMBOLS_FILE" ]] \
    || fail "arquivo XKB não pode ser lido"

CURRENT_STATE="$(detect_layout_state "$XKB_SYMBOLS_FILE")"

case "$CURRENT_STATE" in
    original)
        success "layout original já está ativo"
        ;;
    modified)
        RESTORE_SCRIPT="$PROJECT_ROOT/restore.sh"

        [[ -f "$RESTORE_SCRIPT" ]] \
            || fail "script de restauração não encontrado: $RESTORE_SCRIPT"

        [[ -x "$RESTORE_SCRIPT" ]] \
            || fail "script de restauração não é executável: $RESTORE_SCRIPT"

        info "layout modificado detectado; iniciando restauração"
        "$RESTORE_SCRIPT"

        FINAL_STATE="$(detect_layout_state "$XKB_SYMBOLS_FILE")"

        [[ "$FINAL_STATE" == "original" ]] \
            || fail "a restauração não deixou o layout no estado original"

        success "layout original confirmado após restauração"
        ;;
    missing-variant)
        fail "variante xkb_symbols \"intl\" não encontrada"
        ;;
    unreadable)
        fail "não foi possível ler o arquivo XKB"
        ;;
    inconsistent:*)
        fail "estado XKB inconsistente: ${CURRENT_STATE#inconsistent:}"
        ;;
    *)
        fail "resultado inesperado ao analisar o arquivo XKB: $CURRENT_STATE"
        ;;
esac

remove_project_directory "$BACKUP_DIR" "diretório de backups"
remove_project_directory "$STATE_DIR" "diretório de estado"

success "desinstalação concluída com sucesso"
info "o repositório local foi preservado"
