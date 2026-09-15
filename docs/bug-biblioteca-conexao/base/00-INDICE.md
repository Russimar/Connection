# Índice da base de conhecimento — bug-biblioteca-conexao

Feature: correção dos defeitos auditados na biblioteca `Connection` (Firebird/FireDAC),
no repositório de origem. Modo de ingestão: **INTERNO** (código do próprio repositório).
Fonte primária do pedido: `docs/bug-biblioteca-conexao.md` (SPEC de auditoria, 2026-09-15).

| Arquivo | Resumo |
|---|---|
| `01-provider-conexao.md` | `TConnection`: relê o INI e reatribui `Params` a cada chamada mesmo com conexão aberta (R-01, derruba transação); regra implícita `config.ini`/`parceiro.ini` (A-03); `ReportMemoryLeaksOnShutdown` no construtor (R-03). |
| `02-provider-gerenciadorconexao.md` | `TGerenciadorConexao`: pool por thread que vaza `TItemConexao` quando a conexão falha, e mantém ramo `else` morto que devolve `nil` (A-02). |
| `03-provider-arquivoini.md` | `TArquivoIni.BuscarParametro`: parsing das três situações de `Database`/`HostName`, defaults do INI, `Result` atribuído dentro do `finally` (A-05), Base64 rotulado como criptografia (R-02). Única lógica pura testável sem banco. |
| `04-provider-interfaces.md` | `iConnection` sem um único comentário: não diz se devolve `nil`, se levanta exceção, nem de quem é a posse do objeto (A-04) — causa-raiz de A-01 e A-02. |
| `05-provider-query.md` | `TQuery`: cast direto sobre `FParent.Connection` e fallback oculto para a TAG literal `'PDV'` (A-01); `ExecSQL` executa string crua sem parametrização. |
| `06-build-distribuicao-e-testes.md` | Repositório source-only distribuído por BOSS, tag atual `v1.0.8`; **nenhum teste automatizado existe**, o que torna a regra de TDD do método um pré-requisito de infraestrutura. |
| `07-documentacao-claude-md.md` | `CLAUDE.md` afirma que `Connection` devolve `nil` (falso) e referencia `plano_connection.md`, que não existe (A-00). |

## Correspondência achado → arquivo da base

| Achado (SPEC) | Severidade na lib | Arquivo da base |
|---|---|---|
| R-01 — reler INI derruba transação aberta | Alta | `01-provider-conexao.md` |
| A-00 — `CLAUDE.md` descreve defeito já corrigido | Alta | `07-documentacao-claude-md.md` |
| A-02 — pool vaza `TItemConexao` e reintroduz `nil` | Alta | `02-provider-gerenciadorconexao.md` |
| A-03 — `parceiro.ini` sobrepõe `config.ini` em silêncio | Média | `01-provider-conexao.md` |
| A-04 — `iConnection` sem contrato de falha | Média | `04-provider-interfaces.md` |
| A-01 — cast direto + fallback oculto `'PDV'` | Média | `05-provider-query.md` |
| A-05 — `Result` atribuído dentro do `finally` | Baixa | `03-provider-arquivoini.md` |
| R-02 — Base64 apresentado como criptografia | Média | `03-provider-arquivoini.md` |
| R-03 — lib altera `ReportMemoryLeaksOnShutdown` global | Média | `01-provider-conexao.md` |
