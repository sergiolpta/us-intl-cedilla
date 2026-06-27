#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(
    cd "$(dirname "${BASH_SOURCE[0]}")" &&
    pwd
)"

# shellcheck source=./config.sh
source "$PROJECT_ROOT/config.sh"

TEMP_FILE=""
ROLLBACK_FILE=""
TARGET_REPLACED=0

info() {
    printf 'INFO: %s\n' "$1"
}

success() {
    printf 'OK: %s\n' "$1"
}

warning() {
    printf 'AVISO: %s\n' "$1" >&2
}

fail() {
    printf 'ERRO: %s\n' "$1" >&2
    exit 1
}

cleanup() {
    if [[ -n "$TEMP_FILE" && -e "$TEMP_FILE" ]]; then
        rm -f -- "$TEMP_FILE"
    fi

    if [[ -n "$ROLLBACK_FILE" && -e "$ROLLBACK_FILE" ]]; then
        rm -f -- "$ROLLBACK_FILE"
    fi
}

handle_error() {
    local exit_code=$?

    trap - ERR

    if [[ "$TARGET_REPLACED" -eq 1 &&
          -n "$ROLLBACK_FILE" &&
          -f "$ROLLBACK_FILE" ]]; then
        printf '%s\n' \
            "AVISO: falha após a substituição; tentando reverter o arquivo XKB." \
            >&2

        if mv -f -- "$ROLLBACK_FILE" "$XKB_SYMBOLS_FILE"; then
            ROLLBACK_FILE=""
            printf '%s\n' \
                "OK: arquivo XKB anterior restaurado automaticamente." \
                >&2
        else
            printf '%s\n' \
                "ERRO CRÍTICO: não foi possível executar o rollback automático." \
                >&2
        fi
    fi

    cleanup
    exit "$exit_code"
}

trap handle_error ERR
trap cleanup EXIT

require_root() {
    [[ "$EUID" -eq 0 ]] \
        || fail "execute com sudo: sudo ./restore.sh"

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

validate_backup_candidate() {
    local metadata_file="$1"
    local backup_file="${metadata_file%.metadata}.backup"

    local metadata_project=""
    local metadata_source_file=""
    local metadata_sha256=""
    local project_count=0
    local source_file_count=0
    local sha256_count=0
    local key
    local value
    local actual_checksum
    local backup_state

    [[ -f "$metadata_file" && ! -L "$metadata_file" ]] \
        || return 1

    [[ -f "$backup_file" && ! -L "$backup_file" ]] \
        || return 1

    while IFS='=' read -r key value || [[ -n "$key" ]]; do
        case "$key" in
            project)
                metadata_project="$value"
                ((project_count += 1))
                ;;
            source_file)
                metadata_source_file="$value"
                ((source_file_count += 1))
                ;;
            sha256)
                metadata_sha256="$value"
                ((sha256_count += 1))
                ;;
        esac
    done < "$metadata_file"

    [[ "$project_count" -eq 1 ]] || return 1
    [[ "$source_file_count" -eq 1 ]] || return 1
    [[ "$sha256_count" -eq 1 ]] || return 1
    [[ "$metadata_project" == "$PROJECT_NAME" ]] || return 1
    [[ "$metadata_source_file" == "$XKB_SYMBOLS_FILE" ]] || return 1
    [[ "$metadata_sha256" =~ ^[[:xdigit:]]{64}$ ]] || return 1

    actual_checksum="$(
        sha256sum "$backup_file" | awk '{print $1}'
    )"

    [[ "${actual_checksum,,}" == "${metadata_sha256,,}" ]] \
        || return 1

    backup_state="$(detect_layout_state "$backup_file")"

    [[ "$backup_state" == "original" ]] \
        || return 1

    SELECTED_METADATA="$metadata_file"
    SELECTED_BACKUP="$backup_file"
    SELECTED_CHECKSUM="$actual_checksum"

    return 0
}

select_latest_valid_backup() {
    local metadata_files=()
    local metadata_file
    local index

    SELECTED_METADATA=""
    SELECTED_BACKUP=""
    SELECTED_CHECKSUM=""

    shopt -s nullglob
    metadata_files=("$BACKUP_DIR"/us.*.metadata)
    shopt -u nullglob

    [[ "${#metadata_files[@]}" -gt 0 ]] \
        || fail "nenhum metadata de backup encontrado em: $BACKUP_DIR"

    for ((index=${#metadata_files[@]} - 1; index >= 0; index--)); do
        metadata_file="${metadata_files[$index]}"

        if validate_backup_candidate "$metadata_file"; then
            return 0
        fi

        warning "backup ignorado por falha de validação: $metadata_file"
    done

    fail "nenhum backup válido foi encontrado em: $BACKUP_DIR"
}

printf '%s\n' "Restauração do $PROJECT_NAME"
printf '%s\n\n' "----------------------------------------"

require_root
require_command python3
require_command sha256sum
require_command awk
require_command install
require_command mktemp
require_command mv

[[ -d "$BACKUP_DIR" ]] \
    || fail "diretório de backups não encontrado: $BACKUP_DIR"

[[ -r "$BACKUP_DIR" ]] \
    || fail "diretório de backups não pode ser lido: $BACKUP_DIR"

[[ -f "$XKB_SYMBOLS_FILE" ]] \
    || fail "arquivo XKB não encontrado: $XKB_SYMBOLS_FILE"

[[ ! -L "$XKB_SYMBOLS_FILE" ]] \
    || fail "o arquivo XKB não pode ser um link simbólico"

[[ -r "$XKB_SYMBOLS_FILE" ]] \
    || fail "arquivo XKB não pode ser lido"

[[ -w "$XKB_SYMBOLS_FILE" ]] \
    || fail "arquivo XKB não pode ser gravado"

CURRENT_STATE="$(detect_layout_state "$XKB_SYMBOLS_FILE")"

case "$CURRENT_STATE" in
    original)
        success "layout original já está restaurado"
        exit 0
        ;;
    modified)
        success "layout modificado detectado"
        ;;
    missing-variant)
        fail "variante xkb_symbols \"intl\" não encontrada no arquivo atual"
        ;;
    unreadable)
        fail "não foi possível ler o arquivo XKB atual"
        ;;
    inconsistent:*)
        fail "estado XKB inconsistente: ${CURRENT_STATE#inconsistent:}"
        ;;
    *)
        fail "resultado inesperado ao analisar o arquivo atual: $CURRENT_STATE"
        ;;
esac

select_latest_valid_backup

success "backup validado: $SELECTED_BACKUP"
info "metadata utilizado: $SELECTED_METADATA"
info "SHA-256 confirmado: $SELECTED_CHECKSUM"

TARGET_DIR="$(dirname "$XKB_SYMBOLS_FILE")"

TEMP_FILE="$(
    mktemp \
        --tmpdir="$TARGET_DIR" \
        ".${PROJECT_NAME}.restore.XXXXXX"
)"

ROLLBACK_FILE="$(
    mktemp \
        --tmpdir="$TARGET_DIR" \
        ".${PROJECT_NAME}.rollback.XXXXXX"
)"

install \
    --mode=0644 \
    --owner=root \
    --group=root \
    "$XKB_SYMBOLS_FILE" \
    "$ROLLBACK_FILE"

install \
    --mode=0644 \
    --owner=root \
    --group=root \
    "$SELECTED_BACKUP" \
    "$TEMP_FILE"

TEMP_STATE="$(detect_layout_state "$TEMP_FILE")"

[[ "$TEMP_STATE" == "original" ]] \
    || fail "arquivo temporário de restauração não passou na validação"

TEMP_CHECKSUM="$(
    sha256sum "$TEMP_FILE" | awk '{print $1}'
)"

[[ "${TEMP_CHECKSUM,,}" == "${SELECTED_CHECKSUM,,}" ]] \
    || fail "checksum do arquivo temporário não corresponde ao backup"

mv -f -- "$TEMP_FILE" "$XKB_SYMBOLS_FILE"
TEMP_FILE=""
TARGET_REPLACED=1

FINAL_STATE="$(detect_layout_state "$XKB_SYMBOLS_FILE")"

if [[ "$FINAL_STATE" != "original" ]]; then
    warning "o arquivo restaurado não corresponde ao estado original"

    if mv -f -- "$ROLLBACK_FILE" "$XKB_SYMBOLS_FILE"; then
        ROLLBACK_FILE=""
        TARGET_REPLACED=0
        fail "restauração rejeitada; o arquivo anterior foi recolocado"
    fi

    fail "restauração inválida e rollback automático não concluído"
fi

FINAL_CHECKSUM="$(
    sha256sum "$XKB_SYMBOLS_FILE" | awk '{print $1}'
)"

if [[ "${FINAL_CHECKSUM,,}" != "${SELECTED_CHECKSUM,,}" ]]; then
    warning "checksum final não corresponde ao backup validado"

    if mv -f -- "$ROLLBACK_FILE" "$XKB_SYMBOLS_FILE"; then
        ROLLBACK_FILE=""
        TARGET_REPLACED=0
        fail "restauração rejeitada; o arquivo anterior foi recolocado"
    fi

    fail "checksum final inválido e rollback automático não concluído"
fi

TARGET_REPLACED=0
rm -f -- "$ROLLBACK_FILE"
ROLLBACK_FILE=""

success "layout original restaurado com sucesso"
info "backup utilizado: $SELECTED_BACKUP"
info "reinicie a sessão gráfica ou recarregue o layout do teclado"
