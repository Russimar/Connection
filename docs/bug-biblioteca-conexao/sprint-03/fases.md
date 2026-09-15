# Fases — Sprint 03

> Um bloco por fase. O paralelismo declarado aqui é definitivo: a execução nunca decide paralelismo sozinha.

---

## F-03.1 — Correção documental

**Objetivo:** corrigir o `CLAUDE.md` para descrever o comportamento real da biblioteca após a sprint-02 e eliminar a referência morta.

**Tasks que a compõem:** T-03.01, T-03.02

**Critério de saída:** o `CLAUDE.md` não contém as strings `returns nil` nem `plano_connection.md`, e descreve `EConnectionException`, `Reconectar` e o INI explícito.

**Roda em paralelo com:** nenhuma

---

## F-03.2 — Preparação do release

**Objetivo:** deixar a biblioteca pronta para o usuário publicar a `v1.0.9`, com a suíte verde e sem commit.

**Tasks que a compõem:** T-03.03, T-03.04

**Critério de saída:** `tests\run.bat` retorna ERRORLEVEL 0 em todas as versões detectadas e `git log` não registra nenhum commit novo criado pela execução.

**Roda em paralelo com:** nenhuma
