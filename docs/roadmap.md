# Roadmap

## Fase 1 — Fundação do projeto

- [x] Definir o objetivo.
- [x] Definir o nome `us-intl-cedilla`.
- [x] Criar a estrutura do repositório.
- [x] Adicionar licença MIT.
- [x] Criar o README inicial.
- [x] Documentar a arquitetura.
- [x] Criar o changelog inicial.
- [x] Fazer o primeiro commit local.
- [x] Publicar o repositório no GitHub.

## Fase 2 — Patch mínimo

- [x] Obter uma cópia limpa do arquivo de símbolos `us`.
- [x] Identificar exatamente a variante `intl`.
- [x] Criar uma cópia modificada apenas em `<AB03>`.
- [x] Gerar o patch unificado.
- [x] Confirmar que apenas uma linha funcional foi alterada.
- [x] Criar teste de regressão do patch.

## Fase 3 — Instalador

- [x] Detectar privilégios administrativos.
- [x] Detectar a distribuição.
- [x] Verificar compatibilidade.
- [x] Detectar a versão de `xkb-data`.
- [x] Validar o arquivo alvo.
- [x] Criar backup.
- [x] Gerar checksum SHA-256.
- [x] Aplicar a alteração.
- [x] Validar o resultado.
- [ ] Integrar ativação automática compatível com X11 e Wayland.
- [x] Implementar rollback automático em caso de falha.
- [x] Garantir idempotência.

## Fase 4 — Restauração e remoção

- [x] Implementar `restore.sh`.
- [x] Validar backups antes da restauração.
- [x] Preservar o estado anterior durante a operação de restauração.
- [x] Implementar `uninstall.sh`.
- [x] Restaurar o layout oficial.
- [x] Definir política segura para remoção de backups.
- [x] Garantir idempotência da restauração.
- [x] Garantir idempotência da desinstalação.

## Fase 5 — Testes

- [x] Implementar `tests/verify.sh`.
- [x] Implementar `tests/regression.sh`.
- [x] Validar sintaxe dos scripts com `bash -n`.
- [x] Adicionar ShellCheck.
- [x] Testar instalação repetida.
- [x] Testar restauração repetida.
- [x] Testar desinstalação repetida.
- [x] Testar falhas simuladas.
- [x] Confirmar que nenhuma outra tecla foi alterada.
- [x] Confirmar restauração byte a byte com `cmp`.

## Fase 6 — Compatibilidade

- [x] Testar no Linux Mint 22.3.
- [ ] Testar no Ubuntu.
- [ ] Testar no Debian.
- [ ] Testar no Pop!_OS.
- [ ] Documentar diferenças entre versões do pacote `xkb-data`.
- [ ] Avaliar suporte a outras distribuições.

## Fase 7 — GitHub e primeira versão

- [ ] Criar templates de issues.
- [ ] Criar template de pull request.
- [x] Configurar integração contínua.
- [ ] Publicar a versão `0.1.0`.
- [x] Criar instruções completas de instalação.
- [ ] Adicionar capturas de tela.
- [ ] Publicar a primeira release.

## Futuro

- [ ] Criar pacote `.deb`.
- [ ] Avaliar integração com atualizações de `xkb-data`.
- [ ] Avaliar instalação sem modificar diretamente arquivos do pacote.
- [ ] Adicionar suporte ampliado a Wayland.
- [ ] Estudar contribuição para o projeto oficial `xkeyboard-config`.
