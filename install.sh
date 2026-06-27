#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(
    cd "$(dirname "${BASH_SOURCE[0]}")" &&
    pwd
)"

# shellcheck source=./config.sh
source "$PROJECT_ROOT/config.sh"

BACKUP_FILE=""
TEMP_FILE=""
INSTALL_COMPLETED=0

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

cleanup() {
    if [[ -n "$TEMP_FILE" && -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
}

rollback() {
    local exit_code=$?

    cleanup

    if [[ "$INSTALL_COMPLETED" -eq 0 && -n "$BACKUP_FILE" && -f "$BACKUP_FILE" ]]; then
        printf 'AVISO: falha detectada; restaurando backup.\n' >&2

        if cp --preserve=mode,ownership,timestamps \
            "$BACKUP_FILE" \
            "$XKB_SYMBOLS_FILE"; then
            printf 'OK: backup restaurado automaticamente.\n' >&2
        else
            printf 'ERRO CRÍTICO: não foi possível restaurar o backup.\n' >&2
        fi
    fi

    exit "$exit_code"
}

trap rollback ERR
trap cleanup EXIT

require_root() {
    [[ "$EUID" -eq 0 ]] \
        || fail "execute com sudo: sudo ./install.sh"

    success "privilégios administrativos confirmados"
}

require_command() {
    local command_name="$1"

    command -v "$command_name" >/dev/null 2>&1 \
        || fail "comando obrigatório não encontrado: $command_name"

    success "comando disponível: $command_name"
}

is_supported_distribution() {
    local current_id="$1"
    local current_id_like="$2"
    local supported

    for supported in "${SUPPORTED_DISTROS[@]}"; do
        if [[ "$current_id" == "$supported" ]]; then
            return 0
        fi

        if [[ " $current_id_like " == *" $supported "* ]]; then
            return 0
        fi
    done

    return 1
}

detect_layout_state() {
    python3 - "$XKB_SYMBOLS_FILE" <<'PY'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")

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

printf '%s\n' "Instalação do $PROJECT_NAME"
printf '%s\n\n' "----------------------------------------"

require_root

require_command python3
require_command patch
require_command sha256sum
require_command install
require_command mktemp
require_command dpkg-query

[[ -r /etc/os-release ]] \
    || fail "não foi possível ler /etc/os-release"

# shellcheck disable=SC1091
source /etc/os-release

DISTRO_ID="${ID:-unknown}"
DISTRO_ID_LIKE="${ID_LIKE:-}"

info "distribuição detectada: ${PRETTY_NAME:-$DISTRO_ID}"

is_supported_distribution "$DISTRO_ID" "$DISTRO_ID_LIKE" \
    || fail "distribuição ainda não suportada"

success "distribuição compatível"

PACKAGE_STATUS="$(
    dpkg-query \
        -W \
        -f='${db:Status-Status}' \
        "$XKB_PACKAGE" 2>/dev/null || true
)"

[[ "$PACKAGE_STATUS" == "installed" ]] \
    || fail "pacote $XKB_PACKAGE não está instalado"

PACKAGE_VERSION="$(
    dpkg-query \
        -W \
        -f='${Version}' \
        "$XKB_PACKAGE"
)"

success "pacote $XKB_PACKAGE instalado: $PACKAGE_VERSION"

[[ -f "$XKB_SYMBOLS_FILE" ]] \
    || fail "arquivo XKB não encontrado: $XKB_SYMBOLS_FILE"

[[ -r "$XKB_SYMBOLS_FILE" ]] \
    || fail "arquivo XKB não pode ser lido"

[[ -w "$XKB_SYMBOLS_FILE" ]] \
    || fail "arquivo XKB não pode ser gravado"

[[ -f "$PATCH_FILE" && -s "$PATCH_FILE" ]] \
    || fail "patch não encontrado ou vazio"

LAYOUT_STATE="$(detect_layout_state)"

case "$LAYOUT_STATE" in
    original)
        success "layout oficial detectado"
        ;;
    modified)
        success "layout já está instalado"
        exit 0
        ;;
    missing-variant)
        fail "variante xkb_symbols \"intl\" não encontrada"
        ;;
    inconsistent:*)
        fail "estado XKB inconsistente: ${LAYOUT_STATE#inconsistent:}"
        ;;
    *)
        fail "resultado inesperado: $LAYOUT_STATE"
        ;;
esac

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
BACKUP_FILE="$BACKUP_DIR/us.$TIMESTAMP.backup"
METADATA_FILE="$BACKUP_DIR/us.$TIMESTAMP.metadata"

install \
    --mode=0644 \
    --owner=root \
    --group=root \
    "$XKB_SYMBOLS_FILE" \
    "$BACKUP_FILE"

ORIGINAL_CHECKSUM="$(
    sha256sum "$XKB_SYMBOLS_FILE" | awk '{print $1}'
)"

BACKUP_CHECKSUM="$(
    sha256sum "$BACKUP_FILE" | awk '{print $1}'
)"

[[ "$ORIGINAL_CHECKSUM" == "$BACKUP_CHECKSUM" ]] \
    || fail "checksum do backup não corresponde ao original"

cat > "$METADATA_FILE" <<EOF
project=$PROJECT_NAME
created_at=$TIMESTAMP
distribution=${PRETTY_NAME:-$DISTRO_ID}
distribution_id=$DISTRO_ID
xkb_package=$XKB_PACKAGE
xkb_package_version=$PACKAGE_VERSION
source_file=$XKB_SYMBOLS_FILE
sha256=$BACKUP_CHECKSUM
EOF

chmod 600 "$METADATA_FILE"

success "backup criado: $BACKUP_FILE"

TEMP_FILE="$(mktemp)"
cp --preserve=mode,ownership,timestamps \
    "$XKB_SYMBOLS_FILE" \
    "$TEMP_FILE"

patch \
    --silent \
    "$TEMP_FILE" \
    < "$PATCH_FILE"

TEMP_STATE="$(
    python3 - "$TEMP_FILE" <<'PY'
from pathlib import Path
import re
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")

variant_match = re.search(
    r'xkb_symbols\s+"intl"\s*\{(?P<body>.*?)^\};',
    text,
    flags=re.DOTALL | re.MULTILINE,
)

if variant_match is None:
    print("invalid")
    raise SystemExit(0)

body = variant_match.group("body")

modified_pattern = re.compile(
    r'key\s+<AB03>\s*\{\s*\[\s*'
    r'c\s*,\s*C\s*,\s*ccedilla\s*,\s*Ccedilla\s*'
    r'\]\s*\};'
)

print("valid" if len(modified_pattern.findall(body)) == 1 else "invalid")
PY
)"

[[ "$TEMP_STATE" == "valid" ]] \
    || fail "arquivo temporário modificado não passou na validação"

install \
    --mode=0644 \
    --owner=root \
    --group=root \
    "$TEMP_FILE" \
    "$XKB_SYMBOLS_FILE"

FINAL_STATE="$(detect_layout_state)"

[[ "$FINAL_STATE" == "modified" ]] \
    || fail "o arquivo final não corresponde ao estado esperado"

INSTALL_COMPLETED=1

success "alteração instalada com sucesso"
info "backup preservado em: $BACKUP_FILE"
info "ative a sessão com: setxkbmap us intl"
