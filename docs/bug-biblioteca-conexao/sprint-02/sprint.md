# Sprint 02 — Correção do contrato e dos defeitos de código

## Objetivo

Fechar o contrato de `iConnection` (exceção tipada, proibição de `nil`, INI explícito, `Reconectar`) e aplicar as oito correções de código da auditoria: R-01, R-02, R-03, A-01, A-02, A-03, A-04 e A-05. Cada correção inverte o teste de caracterização correspondente da sprint-01.

## Fases

| Fase | Título | Roda em paralelo com |
|---|---|---|
| F-02.1 | Contrato: exceção tipada e interface | nenhuma |
| F-02.2 | Correções em TConnection e TArquivoIni | nenhuma (mas T-02.07/T-02.11 correm em paralelo com a cadeia de Provider.Conexao.pas) |
| F-02.3 | Correções em TGerenciadorConexao e TQuery | nenhuma (mas T-02.10 corre em paralelo com a cadeia T-02.08 → T-02.09) |

Detalhe de cada fase em `fases.md`; tasks em `tasks.md`.

## Critério de saída

`tests\run.bat` retorna ERRORLEVEL 0 em todas as versões de Firebird detectadas, com os testes de caracterização de R-01, A-01 e A-02 já invertidos para afirmar o comportamento corrigido, e nenhuma ocorrência de `ReportMemoryLeaksOnShutdown` nem da string literal `'PDV'` permanece em `src/`.

## Riscos conhecidos

- D-09 e D-15 acrescentam métodos a `iConnection`, o que quebra em compilação qualquer implementação externa da interface; os consumidores não são enumeráveis daqui (PENDENTE-01, lacuna L-08). D-10 autoriza seguir assim.
- D-06 remove o fallback para a TAG `'PDV'`: consumidores que hoje chamam `TQuery.New(nil)` passam a receber exceção. Quebra intencional, aceita pelo usuário.
- A SPEC erra ao prever `EInvalidCast` no cast sobre `nil` (D-22): em Object Pascal o cast devolve `nil` silenciosamente, então o teste de A-01 comprova falha tardia, não `EInvalidCast`.
- R-01 só se comprova com transação explícita contra banco real (`base/06-build-distribuicao-e-testes.md`, lacuna L-04); depende da infraestrutura entregue na sprint-01.
- As três fases alteram arquivos que se sobrepõem (`Provider.Interfaces.pas` é base de todas), por isso nenhuma fase roda em paralelo com outra. Dentro das fases há paralelismo declarado: `T-02.07`/`T-02.11` e `T-02.10` tocam arquivos exclusivos e partem de `T-02.02`.
