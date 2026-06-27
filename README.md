# US International + Ç

Layout de teclado para Linux destinado a usuários de teclado físico ANSI americano que escrevem em português.

O projeto preserva o comportamento do layout **English (US, intl., with dead keys)** e altera somente as combinações:

| Combinação | Resultado |
| --- | --- |
| `AltGr + C` | `ç` |
| `AltGr + Shift + C` | `Ç` |

## Estado do projeto

O projeto está em fase de pré-release.

Os scripts de instalação, restauração e desinstalação já foram implementados e testados em sandbox no Linux Mint 22.3 com o pacote:

```text
xkb-data 2.41-2ubuntu1.1
```

O sistema real usado no desenvolvimento permaneceu sem alterações durante os testes privilegiados.

Compatibilidade validada:

- Linux Mint 22.3

Compatibilidade planejada, mas ainda não validada em ambiente real:

- Ubuntu
- Debian
- Pop!_OS

## Problema

O layout US International permite digitar normalmente caracteres acentuados:

| Combinação | Resultado |
| --- | --- |
| `'` + `a` | `á` |
| `'` + `e` | `é` |
| `'` + `i` | `í` |
| `'` + `o` | `ó` |
| `'` + `u` | `ú` |
| `~` + `a` | `ã` |
| `~` + `o` | `õ` |
| `^` + `a` | `â` |
| `^` + `e` | `ê` |

Porém, a definição da tecla física `C` no layout `us(intl)` é:

```xkb
key <AB03> { [ c, C, copyright, cent ] };
```

Isso produz:

| Combinação | Resultado padrão |
| --- | --- |
| `AltGr + C` | `©` |
| `AltGr + Shift + C` | `¢` |

Essas combinações são pouco úteis para usuários que escrevem em português e precisam digitar `ç` e `Ç`.

## Solução

O projeto altera exclusivamente a definição da tecla `<AB03>` para:

```xkb
key <AB03> { [ c, C, ccedilla, Ccedilla ] };
```

Nenhuma outra tecla do layout US International deve ser modificada.

## Como funciona

O projeto trabalha diretamente sobre:

```text
/usr/share/X11/xkb/symbols/us
```

O instalador:

1. valida o sistema e o pacote `xkb-data`;
2. confirma o estado original do layout;
3. cria backup com metadata e checksum SHA-256;
4. aplica o patch em arquivo temporário;
5. valida o resultado;
6. substitui o arquivo somente após todas as verificações.

Os backups são armazenados em:

```text
/var/backups/us-intl-cedilla
```

O diretório é protegido e acessível somente pelo usuário `root`.

## Instalação

Clone o repositório:

```bash
git clone https://github.com/sergiolpta/us-intl-cedilla.git
cd us-intl-cedilla
```

Execute as verificações:

```bash
./tests/regression.sh
./tests/verify.sh
```

Instale:

```bash
sudo ./install.sh
```

Depois recarregue o layout ou reinicie a sessão gráfica:

```bash
setxkbmap us intl
```

> Em sessões Wayland, o comando `setxkbmap` pode não controlar diretamente o compositor. Nesse caso, encerre e inicie novamente a sessão ou selecione novamente o layout nas configurações do ambiente gráfico.

## Verificação

```bash
./tests/verify.sh
```

Quando instalado, o resultado deve indicar:

```text
Estado do layout: modified
```

Quando não instalado ou após restauração:

```text
Estado do layout: original
```

## Restauração

A restauração repõe o backup original validado e preserva os arquivos de backup:

```bash
sudo ./restore.sh
```

O script:

- seleciona o backup válido mais recente;
- valida metadata e checksum;
- confirma que o backup contém o layout original;
- executa substituição segura;
- confirma o estado final;
- é idempotente.

## Desinstalação

A desinstalação restaura o layout oficial e remove os dados persistentes do projeto:

```bash
sudo ./uninstall.sh
```

O script:

- restaura o layout quando necessário;
- confirma o estado original;
- remove o diretório de backups;
- remove o diretório de estado, caso exista;
- preserva o repositório clonado;
- é idempotente.

## Segurança

Os scripts interrompem a execução quando:

- não são executados com privilégios administrativos;
- comandos obrigatórios não estão disponíveis;
- o arquivo XKB esperado não existe ou não pode ser lido;
- o arquivo alvo é um link simbólico;
- a variante `intl` não é encontrada;
- o estado do layout é inconsistente;
- o backup ou metadata não passam nas validações;
- o checksum SHA-256 não corresponde;
- o resultado final não corresponde ao estado esperado.

O projeto não edita manualmente os arquivos:

```text
evdev.xml
base.xml
```

## Limitações atuais

- Alterações diretas em arquivos do pacote `xkb-data` podem ser sobrescritas por atualizações do sistema.
- O projeto ainda não possui integração contínua.
- ShellCheck ainda não está integrado ao fluxo.
- Ubuntu, Debian e Pop!_OS ainda precisam de validação real.
- Ainda não existe pacote `.deb`.

## Estrutura do projeto

```text
us-intl-cedilla/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── config.sh
├── install.sh
├── restore.sh
├── uninstall.sh
├── patches/
│   └── us-intl-cedilla.patch
├── tests/
│   ├── verify.sh
│   └── regression.sh
├── docs/
│   ├── architecture.md
│   ├── roadmap.md
│   └── screenshots/
└── .github/
```

## Contribuição

Relatos de erros, testes em outras distribuições e melhorias são bem-vindos.

Mudanças em outras teclas devem ser discutidas separadamente, pois o escopo principal é modificar somente a tecla `<AB03>`.

## Licença

Distribuído sob a licença MIT. Consulte o arquivo [`LICENSE`](LICENSE).
