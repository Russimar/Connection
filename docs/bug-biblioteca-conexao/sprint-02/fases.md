# Fases — Sprint 02

> Um bloco por fase. O paralelismo declarado aqui é definitivo: a execução nunca decide paralelismo sozinha.

---

## F-02.1 — Contrato: exceção tipada e interface

**Objetivo:** criar `EConnectionException` e fixar em `iConnection` o contrato de falha, o INI explícito e o `Reconectar`, antes de qualquer implementação mudar.

**Tasks que a compõem:** T-02.01, T-02.02

**Critério de saída:** `Provider.Interfaces.pas` declara os métodos novos com comentário de contrato, `EConnectionException` existe com os campos de diagnóstico, e o projeto de teste compila com as duas implementações da interface atualizadas.

**Roda em paralelo com:** nenhuma

---

## F-02.2 — Correções em TConnection e TArquivoIni

**Objetivo:** corrigir R-01, R-03, A-03, A-05 e documentar R-02, na conexão direta e no parsing do INI.

**Tasks que a compõem:** T-02.03, T-02.04, T-02.05, T-02.06, T-02.07, T-02.11

**Critério de saída:** o teste de caracterização de R-01 passa afirmando que a transação permanece ativa após a segunda chamada a `Connection`, `ReportMemoryLeaksOnShutdown` não aparece mais em `src/`, e os campos `Usuario`/`Senha` não existem mais em `TDadosConexao`.

**Paralelismo interno:** `T-02.07` roda em paralelo com a cadeia `T-02.03 → T-02.06` (arquivos distintos); `T-02.11` depende de `T-02.07`.

**Roda em paralelo com:** nenhuma

---

## F-02.3 — Correções em TGerenciadorConexao e TQuery

**Objetivo:** corrigir A-02 (vazamento e `nil` do pool) e A-01 (fallback `'PDV'` e cast direto).

**Tasks que a compõem:** T-02.08, T-02.09, T-02.10

**Critério de saída:** o teste de A-02 passa afirmando que o pool não retém item após falha, o teste de A-01 passa afirmando que `TQuery.New(nil)` levanta exceção, e a string literal `'PDV'` não aparece mais em `src/`.

**Paralelismo interno:** `T-02.10` roda em paralelo com a cadeia `T-02.08 → T-02.09` (arquivos distintos).

**Roda em paralelo com:** nenhuma
