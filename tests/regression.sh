#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCH_FILE="$PROJECT_ROOT/patches/us-intl-cedilla.patch"

EXPECTED_OLD='-    key <AB03> { [	   c,          C,     copyright,             cent ] };'
EXPECTED_NEW='+    key <AB03> { [	   c,          C,      ccedilla,         Ccedilla ] };'

fail() {
    printf 'ERRO: %s\n' "$1" >&2
    exit 1
}

[[ -f "$PATCH_FILE" ]] || fail "arquivo de patch não encontrado"
[[ -s "$PATCH_FILE" ]] || fail "arquivo de patch está vazio"

removed_lines="$(grep -c '^-' "$PATCH_FILE" || true)"
added_lines="$(grep -c '^+' "$PATCH_FILE" || true)"

[[ "$removed_lines" -eq 2 ]] || fail "quantidade inesperada de linhas removidas"
[[ "$added_lines" -eq 2 ]] || fail "quantidade inesperada de linhas adicionadas"

grep -Fqx -- "$EXPECTED_OLD" "$PATCH_FILE" \
    || fail "linha original esperada não encontrada"

grep -Fqx -- "$EXPECTED_NEW" "$PATCH_FILE" \
    || fail "linha modificada esperada não encontrada"

functional_changes="$(
    grep -E '^[+-][[:space:]]+key <' "$PATCH_FILE" | wc -l
)"

[[ "$functional_changes" -eq 2 ]] \
    || fail "o patch contém alterações funcionais adicionais"

printf 'OK: o patch altera somente a tecla <AB03>.\n'
