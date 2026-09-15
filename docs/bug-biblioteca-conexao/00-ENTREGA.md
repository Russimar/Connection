# Entrega — bug-biblioteca-conexao

Data: 2026-09-15
Suíte: 24 testes × 3 versões de Firebird (2.5, 4.0, 5.0) = 72 execuções, 0 failed, ERRORLEVEL 0.

## Os 9 achados e o que comprova cada um

| Achado | Correção aplicada | Teste que comprova |
|---|---|---|
| **R-01** — reler o INI a cada `Connection` derrubava a transação aberta (erro `-514` no `Commit`) | `TConnection.Connection` devolve a conexão existente quando já conectada, sem tocar nos `Params`; recarga explícita por `Reconectar` | `Teste.Caracterizacao.Conexao` — transação permanece ativa após a 2ª chamada e o `Commit` conclui. O teste foi escrito primeiro afirmando o defeito, **reproduziu o `-514` contra o Firebird 5.0 real**, e foi invertido pela correção |
| **A-00** — `CLAUDE.md` afirmava retorno `nil` e citava `plano_connection.md` inexistente | Documento reescrito: contrato de falha, `Reconectar`, INI explícito, Base64, harness de teste | `T-03.01` — strings `returns nil` e `plano_connection.md`: 0 ocorrências; `EConnectionException` e `Reconectar` presentes |
| **A-01** — `TQuery` caía para a TAG literal `'PDV'` e fazia cast direto | `Parent` obrigatório (exceção se `nil`); `Assigned` validado antes do cast | `Teste.Caracterizacao.Query` — exceção exige o `Parent` e não cita `PDV`; 0 ocorrências da literal em `src/` |
| **A-02** — pool vazava `TItemConexao` a cada falha e podia devolver `nil` | Criação em `try/except` que libera o item e repropaga a exceção original; ramo `else` morto removido | `Teste.Caracterizacao.Gerenciador` — 50 tentativas falhas sem acumular no pool; 0 atribuições de `nil` a `FDConn` |
| **A-03** — `parceiro.ini` sobrepunha `config.ini` em silêncio | `ArquivoConfiguracao(valor)` deixa o consumidor escolher; sem chamada, a precedência histórica é mantida **e registrada em log**; caminho resolvido exposto | `Teste.Conexao` — arquivo explícito vence; sem chamada, `parceiro.ini` mantém a precedência |
| **A-04** — `iConnection` sem contrato de falha | Interface documentada (nunca `nil`, falha por exceção, posse do objeto) e `EConnectionException` com `Tag`, `ArquivoIni` e `DataBase` | `Teste.Excecoes` — capturável como `Exception` e como tipo próprio; três campos lidos de volta |
| **A-05** — `Result` atribuído dentro do `finally`, record não inicializado | `Default(TDadosConexao)` no início; `Result` no fim do `try`; `finally` só libera | `Teste.ArquivoIni.Resultado` — record volta preenchido por inteiro. Verificação estrutural por D-38 |
| **R-02** — Base64 apresentado como criptografia | Documentado no código e no `CLAUDE.md`; `Descriptografar` **intacto**, byte a byte | `T-02.11` — `diff` do `Descriptografar` contra o `HEAD`: idêntico |
| **R-03** — lib alterava `ReportMemoryLeaksOnShutdown` global | Linha removida do construtor | `Teste.Conexao` — valor global inalterado após instanciar; 0 ocorrências em `src/` |

## Resultado por versão de Firebird

| Versão | Porta | Testes | Resultado |
|---|---|---|---|
| Firebird 2.5 | 3050 | 24 | 24 passed, 0 failed |
| Firebird 4.0 | 3051 | 24 | 24 passed, 0 failed |
| Firebird 5.0 | 3052 | 24 | 24 passed, 0 failed |

## Como validar

```
tests\build.bat     REM compila (MSBuild, com queda para dcc32)
tests\run.bat       REM roda uma vez por versão de Firebird instalada
```

## Estado para publicação

Nada foi commitado nem tagueado, conforme D-24 — a árvore de trabalho está suja para validação. Depois de validar, a publicação prevista é a tag `v1.0.9` (`boss.json` já atualizado para `1.0.9`).

**Quebras intencionais de compatibilidade**, ambas decididas em F2:

- `TQuery.New(nil)` passa a levantar exceção em vez de conectar à TAG `'PDV'` (D-06).
- `iConnection` ganhou `ArquivoConfiguracao` e `Reconectar`: qualquer implementação externa da interface deixa de compilar até ser ajustada (D-09, D-10, D-15).
