# Como contribuir

Obrigado pelo interesse em contribuir com o **us-intl-cedilla**.

Este projeto altera o comportamento da tecla `<AB03>` na variante `us(intl)` do XKB para permitir a digitação de `ç` e `Ç`. Como a instalação pode modificar um arquivo do sistema, toda contribuição deve priorizar segurança, validação e possibilidade de restauração.

## Antes de começar

Leia:

- `README.md`
- `docs/architecture.md`
- `docs/roadmap.md`
- `CHANGELOG.md`

Verifique também as issues abertas antes de iniciar uma alteração.

## Preparação do ambiente

Clone o repositório:

```bash
git clone https://github.com/sergiolpta/us-intl-cedilla.git
cd us-intl-cedilla
```

Os principais comandos usados nos testes são:

- `bash`
- `python3`
- `patch`
- `sha256sum`
- `dpkg-query`
- `mktemp`
- `shellcheck`

Em distribuições baseadas em Debian ou Ubuntu, o ShellCheck pode ser instalado com:

```bash
sudo apt update
sudo apt install shellcheck
```

## Regras de segurança

Não execute testes de desenvolvimento diretamente sobre:

```text
/usr/share/X11/xkb/symbols/us
```

Testes que envolvam instalação, restauração, desinstalação ou falhas simuladas devem usar uma cópia em um diretório temporário, como `/tmp`.

Nunca inclua em commits:

- backups pessoais;
- arquivos XKB completos obtidos do sistema;
- senhas, tokens ou outros dados sensíveis;
- arquivos temporários gerados durante testes.

## Validação obrigatória

Antes de enviar uma contribuição, execute:

```bash
bash -n config.sh install.sh restore.sh uninstall.sh tests/*.sh
```

Depois execute o ShellCheck:

```bash
shellcheck -x config.sh install.sh restore.sh uninstall.sh tests/*.sh
```

Execute o teste de regressão:

```bash
./tests/regression.sh
```

Quando aplicável ao ambiente:

```bash
./tests/verify.sh
```

O teste de regressão deve confirmar que o patch altera somente a tecla `<AB03>`.

## Alterações no patch

Qualquer mudança em:

```text
patches/us-intl-cedilla.patch
```

deve ser mínima e justificada.

O patch não deve alterar outras teclas, variantes ou partes do arquivo XKB sem discussão prévia em uma issue.

## Como propor uma alteração

1. Crie ou escolha uma issue.
2. Crie uma branch a partir de `main`.
3. Faça uma alteração pequena e focada.
4. Execute todas as validações aplicáveis.
5. Registre mudanças relevantes no `CHANGELOG.md`.
6. Atualize a documentação quando necessário.
7. Envie um pull request usando o template do repositório.

Exemplo de branch:

```bash
git switch -c docs/melhorar-instrucoes
```

## Commits

Prefira mensagens curtas e objetivas, por exemplo:

```text
docs: clarify Ubuntu testing steps
test: add missing-variant scenario
fix: preserve original file after install failure
```

Evite misturar correções, documentação e novas funcionalidades no mesmo commit quando puderem ser separados.

## Relatos de testes em outras distribuições

Contribuições de validação no Ubuntu, Debian e Pop!_OS são bem-vindas.

Inclua no relato:

- nome e versão da distribuição;
- ambiente gráfico, X11 ou Wayland;
- versão do pacote `xkb-data`;
- resultado de `./tests/verify.sh`;
- resultado da instalação, restauração e desinstalação;
- mensagens de erro relevantes;
- confirmação de que o layout original pôde ser restaurado.

Não publique informações pessoais ou dados sensíveis.

## GitHub Actions

Todo push e pull request para `main` executa verificações automáticas de:

- sintaxe Bash;
- ShellCheck;
- teste de regressão.

Um pull request só deve ser considerado pronto quando essas verificações estiverem aprovadas.

## Dúvidas e propostas maiores

Antes de implementar mudanças amplas, como suporte expandido a Wayland, novos layouts, pacotes `.deb` ou mudanças na estratégia de instalação, abra uma issue para discussão.

Isso evita trabalho duplicado e permite avaliar riscos antes da implementação.
