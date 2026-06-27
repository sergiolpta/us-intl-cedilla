# Roadmap

## Fase 1 — Fundação do projeto

* [x] Definir o objetivo.
* [x] Definir o nome `us-intl-cedilla`.
* [x] Criar a estrutura do repositório.
* [x] Adicionar licença MIT.
* [x] Criar o README inicial.
* [x] Documentar a arquitetura.
* [x] Criar o changelog inicial.
* [ ] Fazer o primeiro commit local.
* [ ] Publicar o repositório no GitHub.

## Fase 2 — Patch mínimo

* [ ] Obter uma cópia limpa do arquivo de símbolos `us`.
* [ ] Identificar exatamente a variante `intl`.
* [ ] Criar uma cópia modificada apenas em `<AB03>`.
* [ ] Gerar o patch unificado.
* [ ] Confirmar que apenas uma linha funcional foi alterada.
* [ ] Criar teste de regressão do patch.

## Fase 3 — Instalador

* [ ] Detectar privilégios administrativos.
* [ ] Detectar a distribuição.
* [ ] Verificar compatibilidade.
* [ ] Detectar a versão de `xkb-data`.
* [ ] Validar o arquivo alvo.
* [ ] Criar backup.
* [ ] Gerar checksum SHA-256.
* [ ] Aplicar a alteração.
* [ ] Validar o resultado.
* [ ] Ativar `us(intl)`.
* [ ] Implementar rollback automático em caso de falha.
* [ ] Garantir idempotência.

## Fase 4 — Restauração e remoção

* [ ] Implementar `restore.sh`.
* [ ] Validar backups antes da restauração.
* [ ] Preservar o estado atual antes de restaurar.
* [ ] Implementar `uninstall.sh`.
* [ ] Restaurar o layout oficial.
* [ ] Definir política segura para remoção de backups.

## Fase 5 — Testes

* [ ] Implementar `tests/verify.sh`.
* [ ] Implementar `tests/regression.sh`.
* [ ] Validar sintaxe dos scripts com `bash -n`.
* [ ] Adicionar ShellCheck.
* [ ] Testar instalação repetida.
* [ ] Testar restauração repetida.
* [ ] Testar falhas simuladas.
* [ ] Confirmar que nenhuma outra tecla foi alterada.

## Fase 6 — Compatibilidade

* [ ] Testar no Linux Mint.
* [ ] Testar no Ubuntu.
* [ ] Testar no Debian.
* [ ] Testar no Pop!_OS.
* [ ] Documentar diferenças entre versões do pacote `xkb-data`.
* [ ] Avaliar suporte a outras distribuições.

## Fase 7 — GitHub e primeira versão

* [ ] Criar templates de issues.
* [ ] Criar template de pull request.
* [ ] Configurar integração contínua.
* [ ] Publicar a versão `0.1.0`.
* [ ] Criar instruções completas de instalação.
* [ ] Adicionar capturas de tela.
* [ ] Publicar a primeira release estável.

## Futuro

* [ ] Criar pacote `.deb`.
* [ ] Avaliar integração com atualizações de `xkb-data`.
* [ ] Avaliar instalação sem modificar diretamente arquivos do pacote.
* [ ] Adicionar suporte ampliado a Wayland.
* [ ] Estudar contribuição para o projeto oficial `xkeyboard-config`.
