# Changelog

Todas as mudanças relevantes deste projeto serão documentadas neste arquivo.

O formato segue a ideia do Keep a Changelog, e o projeto pretende adotar versionamento semântico a partir da primeira versão publicada.

## [Unreleased]

### Added

- Estrutura inicial do repositório.
- Licença MIT.
- Documentação da arquitetura e roadmap.
- Patch mínimo da tecla `<AB03>`.
- Teste de regressão que confirma que apenas `<AB03>` é alterada.
- Script de verificação do sistema e do estado XKB.
- Detecção de distribuição e versão do pacote `xkb-data`.
- Instalador com backup, metadata e checksum SHA-256.
- Aplicação do patch em arquivo temporário antes da substituição final.
- Rollback automático do instalador em caso de falha.
- Testes de falhas simuladas para estados XKB inválidos, variante `intl` ausente e rollback após falha de instalação.
- Workflow de integração contínua com validação de sintaxe Bash, ShellCheck e teste de regressão.
- Restauração com seleção e validação do backup mais recente.
- Validação do metadata, arquivo de origem e checksum na restauração.
- Desinstalação segura com restauração prévia do layout.
- Remoção idempotente dos diretórios de backup e estado.
- Proteção contra execução sem privilégios administrativos.
- Proteção contra caminhos críticos e links simbólicos.
- Testes privilegiados restritos a sandbox.
- Validação no Linux Mint 22.3 com `xkb-data 2.41-2ubuntu1.1`.

### Changed

- README atualizado para documentar instalação, restauração e desinstalação.
- Roadmap atualizado para refletir as etapas concluídas.
- Estado do projeto definido como pré-release em vez de desenvolvimento inicial.

### Remaining

- Validar no Ubuntu.
- Validar no Debian.
- Validar no Pop!_OS.
- Documentar diferenças entre versões do `xkb-data`.
- Publicar a versão `0.1.0`.
- Criar uma release no GitHub.
