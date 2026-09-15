# Sprint 01 — Capacidade de testar

## Objetivo

Entregar a infraestrutura que torna a biblioteca testável: projeto DUnitX de console em `tests/`, harness que detecta as versões de Firebird instaladas, cria banco e INI temporários, executa e limpa tudo ao fim, e o `.bat` que orquestra a matriz multi-versão. Nenhuma correção de defeito da biblioteca entra nesta sprint — apenas a capacidade de comprová-las.

## Fases

| Fase | Título | Roda em paralelo com |
|---|---|---|
| F-01.1 | Esqueleto do projeto de teste | nenhuma |
| F-01.2 | Harness de ambiente e fixtures | nenhuma |
| F-01.3 | Testes de caracterização do comportamento atual | nenhuma |

Detalhe de cada fase em `fases.md`; tasks em `tasks.md`.

## Critério de saída

`tests\build.bat` compila sem erro e `tests\run.bat` termina com código de saída 0, executando a suíte uma vez para cada versão de Firebird detectada na máquina, e nenhum arquivo `.fdb` ou `.ini` temporário permanece em disco após a execução.

## Riscos conhecidos

- Não existe `.dproj` nem `.dpk` no repositório e nunca houve build isolado desta lib (`base/06-build-distribuicao-e-testes.md`, lacunas L-01 e L-02) — o projeto de teste é o primeiro artefato compilável, então erros de search path de FireDAC só aparecem aqui.
- Um processo carrega um único `fbclient.dll`, e cliente 2.5 não conversa com servidor 5.0 (D-27) — por isso a matriz é uma execução por versão (D-29); se o runner tentar as três no mesmo processo, falha.
- Caminho de banco montado com barra invertida quebra a criação via `isql` (D-37, verificado na F3).
- Os testes de caracterização desta sprint fixam o comportamento **defeituoso** atual; eles serão intencionalmente invertidos na sprint-02, o que é esperado e não é regressão.
