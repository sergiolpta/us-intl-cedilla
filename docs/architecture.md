# Arquitetura do projeto

## Visão geral

O projeto `us-intl-cedilla` adapta o layout de teclado **English (US, international, with dead keys)** para usuários que escrevem em português usando teclado físico ANSI americano.

A alteração pretendida é mínima: substituir somente os símbolos de terceiro e quarto níveis da tecla física `C`, identificada pelo código XKB `<AB03>`.

## Comportamento original

No arquivo de símbolos do teclado americano:

```text
/usr/share/X11/xkb/symbols/us
```

a variante `intl` contém a definição:

```xkb
key <AB03> { [ c, C, copyright, cent ] };
```

Os quatro níveis representam:

| Nível | Combinação          | Resultado |
| ----- | ------------------- | --------- |
| 1     | `C`                 | `c`       |
| 2     | `Shift + C`         | `C`       |
| 3     | `AltGr + C`         | `©`       |
| 4     | `AltGr + Shift + C` | `¢`       |

## Comportamento modificado

O projeto substitui essa definição por:

```xkb
key <AB03> { [ c, C, ccedilla, Ccedilla ] };
```

O comportamento passa a ser:

| Nível | Combinação          | Resultado |
| ----- | ------------------- | --------- |
| 1     | `C`                 | `c`       |
| 2     | `Shift + C`         | `C`       |
| 3     | `AltGr + C`         | `ç`       |
| 4     | `AltGr + Shift + C` | `Ç`       |

Os níveis 1 e 2 permanecem inalterados.

## Escopo

O projeto deve modificar exclusivamente a definição da tecla `<AB03>` dentro da variante `intl`.

Não fazem parte do escopo inicial:

* modificar outras teclas;
* modificar o comportamento das teclas mortas;
* criar um novo modelo físico de teclado;
* alterar arquivos XML de regras do XKB;
* alterar variantes diferentes de `us(intl)`;
* substituir o layout americano pelo layout ABNT ou ABNT2.

## Arquivo gerenciado pelo sistema

O arquivo:

```text
/usr/share/X11/xkb/symbols/us
```

pertence ao pacote `xkb-data` nas distribuições baseadas em Debian.

Por esse motivo, qualquer alteração deverá ser feita somente pelo instalador, com:

1. validação do ambiente;
2. confirmação da definição original;
3. backup do arquivo;
4. aplicação da mudança;
5. validação do resultado;
6. possibilidade de restauração.

Nenhum arquivo do sistema será modificado durante o desenvolvimento do projeto.

## Estratégia de instalação

O instalador deverá executar as seguintes etapas:

1. confirmar execução com privilégios administrativos;
2. detectar a distribuição por `/etc/os-release`;
3. verificar se a distribuição é suportada;
4. verificar a presença do pacote `xkb-data`;
5. registrar a versão instalada do pacote;
6. localizar o arquivo de símbolos `us`;
7. verificar se a definição original existe exatamente uma vez;
8. verificar se a definição modificada ainda não foi aplicada;
9. criar um backup com data e hora;
10. validar o backup;
11. aplicar a alteração;
12. confirmar que somente a definição esperada foi modificada;
13. validar a configuração XKB;
14. ativar o layout `us(intl)` na sessão atual;
15. informar o resultado ao usuário.

## Política de falha segura

O instalador deverá encerrar sem modificar o sistema se qualquer pré-condição falhar.

Se ocorrer uma falha depois da criação do backup, mas antes da conclusão da instalação, o instalador deverá tentar restaurar automaticamente o arquivo original.

Nenhuma falha deverá deixar o arquivo de símbolos parcialmente modificado.

## Backup

Os backups serão armazenados fora do repositório.

Diretório planejado:

```text
/var/backups/us-intl-cedilla/
```

Cada backup deverá conter:

* cópia completa do arquivo original;
* data e hora da criação;
* versão instalada do pacote `xkb-data`;
* checksum SHA-256;
* informações básicas da distribuição.

O formato definitivo será estabelecido durante a implementação.

## Restauração

O script `restore.sh` deverá:

1. localizar backups válidos;
2. selecionar o backup mais recente por padrão;
3. validar o checksum;
4. criar uma cópia de segurança do estado atual;
5. restaurar o arquivo original;
6. validar a configuração XKB;
7. reativar o layout oficial.

## Desinstalação

O script `uninstall.sh` deverá:

1. identificar se a alteração está instalada;
2. restaurar o arquivo original;
3. validar o layout restaurado;
4. ativar `us(intl)`;
5. remover arquivos de estado criados pelo projeto;
6. tratar a remoção de backups conforme a política definida.

A remoção de backups não deverá ocorrer antes de uma restauração comprovadamente bem-sucedida.

## Verificações

O arquivo `tests/verify.sh` deverá verificar:

* existência do arquivo XKB;
* presença da definição esperada;
* ausência de estados inconsistentes;
* existência e integridade do backup;
* validade da configuração;
* funcionamento do comando de ativação.

O arquivo `tests/regression.sh` deverá confirmar que a única alteração funcional é:

```diff
-key <AB03> { [ c, C, copyright, cent ] };
+key <AB03> { [ c, C, ccedilla, Ccedilla ] };
```

## Idempotência

Executar o instalador mais de uma vez não deverá:

* aplicar a alteração repetidamente;
* criar backups desnecessários;
* corromper o arquivo;
* produzir um estado diferente do esperado.

Se o layout já estiver corretamente instalado, o script deverá informar isso e terminar com sucesso.

## Atualizações do pacote

Uma atualização do pacote `xkb-data` poderá substituir o arquivo modificado.

O projeto deverá detectar esse cenário durante a verificação.

Uma integração automática com o gerenciador de pacotes poderá ser considerada futuramente, mas não faz parte da primeira versão.

## Arquivos XML

Os arquivos:

```text
/usr/share/X11/xkb/rules/evdev.xml
/usr/share/X11/xkb/rules/base.xml
```

não serão editados pelo projeto.

A experiência anterior demonstrou que alterações manuais incorretas nesses arquivos podem impedir o ambiente gráfico de carregar normalmente.

O projeto utilizará a variante oficial `us(intl)` e modificará somente a definição necessária no arquivo de símbolos.

## Estrutura do repositório

```text
us-intl-cedilla/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── config.sh
├── install.sh
├── uninstall.sh
├── restore.sh
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
    ├── ISSUE_TEMPLATE/
    └── workflows/
```

## Princípios

O projeto seguirá estes princípios:

* alteração mínima;
* comportamento previsível;
* validação antes da escrita;
* backup antes da alteração;
* rollback automático em caso de falha;
* scripts idempotentes;
* mensagens claras;
* nenhuma modificação silenciosa;
* código auditável;
* testes de regressão.
