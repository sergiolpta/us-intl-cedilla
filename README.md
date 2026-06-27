# US International + Ç

Layout de teclado para Linux destinado a usuários de teclado físico ANSI americano que escrevem em português.

O projeto mantém o comportamento do layout **English (US, intl., with dead keys)** e altera somente as combinações `AltGr + C` e `AltGr + Shift + C`.

> **Aviso:** o projeto ainda está em desenvolvimento. Os scripts de instalação e remoção ainda não devem ser utilizados.

## Problema

O layout US International permite digitar normalmente caracteres acentuados:

| Combinação | Resultado |
| ---------- | --------- |
| `'` + `a`  | `á`       |
| `'` + `e`  | `é`       |
| `'` + `i`  | `í`       |
| `'` + `o`  | `ó`       |
| `'` + `u`  | `ú`       |
| `~` + `a`  | `ã`       |
| `~` + `o`  | `õ`       |
| `^` + `a`  | `â`       |
| `^` + `e`  | `ê`       |

Porém, a definição da tecla física `C` no layout `us(intl)` é:

```xkb
key <AB03> { [ c, C, copyright, cent ] };
```

Isso produz:

| Combinação          | Resultado padrão |
| ------------------- | ---------------- |
| `AltGr + C`         | `©`              |
| `AltGr + Shift + C` | `¢`              |

Essas combinações são pouco úteis para usuários que escrevem em português e precisam digitar `ç` e `Ç`.

## Solução

O projeto altera exclusivamente a definição da tecla `<AB03>` para:

```xkb
key <AB03> { [ c, C, ccedilla, Ccedilla ] };
```

O resultado será:

| Combinação          | Resultado |
| ------------------- | --------- |
| `AltGr + C`         | `ç`       |
| `AltGr + Shift + C` | `Ç`       |

Nenhuma outra tecla do layout US International deverá ser modificada.

## Objetivos

* Preservar a experiência do teclado ANSI americano para programação.
* Adicionar acesso direto a `ç` e `Ç`.
* Alterar somente a definição necessária.
* Fazer backup antes de qualquer modificação.
* Validar o arquivo antes e depois da instalação.
* Disponibilizar restauração e remoção seguras.
* Não editar manualmente os arquivos XML de regras do XKB.

## Compatibilidade planejada

O suporte inicial será voltado às seguintes distribuições:

* Linux Mint
* Ubuntu
* Debian
* Pop!_OS

## Instalação

A instalação pública ainda não está disponível.

Quando a primeira versão estável for publicada, o procedimento previsto será:

```bash
git clone https://github.com/USUARIO/us-intl-cedilla.git
cd us-intl-cedilla
sudo ./install.sh
```

O endereço será atualizado após a criação do repositório no GitHub.

## Verificação

```bash
./tests/verify.sh
```

## Restauração

```bash
sudo ./restore.sh
```

## Remoção

```bash
sudo ./uninstall.sh
```

## Segurança

O instalador deverá interromper a execução quando:

* a distribuição não for suportada;
* o pacote `xkb-data` não estiver instalado;
* o arquivo de símbolos esperado não existir;
* a definição original não for encontrada;
* a alteração estiver aplicada de maneira inconsistente;
* o backup não puder ser criado ou validado;
* o layout modificado não passar nas verificações.

O projeto não editará manualmente os arquivos `evdev.xml` ou `base.xml`.

## Estado do projeto

Projeto em desenvolvimento inicial.

Consulte também:

* [`CHANGELOG.md`](CHANGELOG.md)
* [`docs/architecture.md`](docs/architecture.md)
* [`docs/roadmap.md`](docs/roadmap.md)

## Contribuição

Relatos de erros, testes em outras distribuições e melhorias serão bem-vindos após a publicação do repositório.

Mudanças em outras teclas deverão ser discutidas separadamente, pois o escopo principal é modificar somente a tecla `<AB03>`.

## Licença

Distribuído sob a licença MIT. Consulte o arquivo [`LICENSE`](LICENSE).
