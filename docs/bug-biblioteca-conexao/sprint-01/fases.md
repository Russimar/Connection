# Fases — Sprint 01

> Um bloco por fase. O paralelismo declarado aqui é definitivo: a execução nunca decide paralelismo sozinha.

---

## F-01.1 — Esqueleto do projeto de teste

**Objetivo:** ter um projeto DUnitX de console que compila e roda, ainda sem testar a biblioteca.

**Tasks que a compõem:** T-01.01, T-01.02, T-01.03

**Critério de saída:** `tests\build.bat` termina com código 0 e o executável gerado, quando executado, imprime o sumário do DUnitX com pelo menos 1 teste passando.

**Roda em paralelo com:** nenhuma

---

## F-01.2 — Harness de ambiente e fixtures

**Objetivo:** detectar as versões de Firebird instaladas e criar/derrubar banco e INI temporários por execução.

**Tasks que a compõem:** T-01.04, T-01.05, T-01.06, T-01.07

**Critério de saída:** executando o runner com o parâmetro de versão, um `.fdb` e um `.ini` são criados em pasta temporária, os testes acessam ambos, e nenhum dos dois existe em disco após o término.

**Roda em paralelo com:** nenhuma

---

## F-01.3 — Testes de caracterização do comportamento atual

**Objetivo:** fixar em teste o comportamento defeituoso de hoje, para que a correção da sprint-02 seja comprovável por inversão do resultado.

**Tasks que a compõem:** T-01.08, T-01.09, T-01.10, T-01.11

**Critério de saída:** a suíte roda em todas as versões detectadas com 0 failed, e cada teste de caracterização documenta em seu nome e comentário qual achado (R-01, A-01, A-02, A-05) ele fixa.

**Roda em paralelo com:** nenhuma
