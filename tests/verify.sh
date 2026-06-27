#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(
    cd "$(dirname "${BASH_SOURCE[0]}")/.." &&
    pwd
)"

# shellcheck disable=SC1091 # Caminho calculado dinamicamente a partir de PROJECT_ROOT.
source "$PROJECT_ROOT/config.sh"

pass() {
    printf 'OK: %s\n' "$1"
}

fail() {
    printf 'ERRO: %s\n' "$1" >&2
    exit 1
}

require_command() {
    local command_name="$1"

    command -v "$command_name" >/dev/null 2>&1 \
        || fail "comando obrigatório não encontrado: $command_name"

    pass "comando disponível: $command_name"
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

printf '%s\n' "Verificação do $PROJECT_NAME"
printf '%s\n\n' "----------------------------------------"

require_command python3
require_command patch
require_command sha256sum
require_command dpkg-query
require_command mktemp

[[ -r /etc/os-release ]] \
    || fail "não foi possível ler /etc/os-release"

# shellcheck disable=SC1091
source /etc/os-release

DISTRO_ID="${ID:-unknown}"
DISTRO_ID_LIKE="${ID_LIKE:-}"

printf 'Distribuição detectada: %s\n' "${PRETTY_NAME:-$DISTRO_ID}"

is_supported_distribution "$DISTRO_ID" "$DISTRO_ID_LIKE" \
    || fail "distribuição ainda não suportada"

pass "distribuição compatível"

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

pass "pacote $XKB_PACKAGE instalado: $PACKAGE_VERSION"

[[ -f "$XKB_SYMBOLS_FILE" ]] \
    || fail "arquivo XKB não encontrado: $XKB_SYMBOLS_FILE"

[[ -r "$XKB_SYMBOLS_FILE" ]] \
    || fail "arquivo XKB não pode ser lido: $XKB_SYMBOLS_FILE"

pass "arquivo XKB encontrado"

[[ -f "$PATCH_FILE" ]] \
    || fail "arquivo de patch não encontrado: $PATCH_FILE"

[[ -s "$PATCH_FILE" ]] \
    || fail "arquivo de patch está vazio"

pass "arquivo de patch encontrado"

LAYOUT_STATE="$(
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
)"

case "$LAYOUT_STATE" in
    original)
        pass "layout oficial detectado em us(intl)"
        ;;
    modified)
        pass "layout us-intl-cedilla já está aplicado"
        ;;
    missing-variant)
        fail "variante xkb_symbols \"intl\" não encontrada"
        ;;
    inconsistent:*)
        fail "estado XKB inconsistente: ${LAYOUT_STATE#inconsistent:}"
        ;;
    *)
        fail "resultado inesperado na análise do layout: $LAYOUT_STATE"
        ;;
esac

TEMP_FILE="$(mktemp)"
trap 'rm -f "$TEMP_FILE"' EXIT

cp "$XKB_SYMBOLS_FILE" "$TEMP_FILE"

if [[ "$LAYOUT_STATE" == "original" ]]; then
    patch \
        --silent \
        --dry-run \
        "$TEMP_FILE" \
        < "$PATCH_FILE" \
        || fail "o patch não pode ser aplicado ao arquivo atual"

    pass "patch aplicável ao arquivo atual"
else
    patch \
        --silent \
        --reverse \
        --dry-run \
        "$TEMP_FILE" \
        < "$PATCH_FILE" \
        || fail "o patch instalado não pode ser revertido"

    pass "patch instalado pode ser revertido"
fi

CURRENT_CHECKSUM="$(sha256sum "$XKB_SYMBOLS_FILE" | awk '{print $1}')"

printf 'Checksum SHA-256: %s\n' "$CURRENT_CHECKSUM"
printf 'Estado do layout: %s\n' "$LAYOUT_STATE"
printf '\n%s\n' "Todas as verificações foram concluídas com sucesso."
