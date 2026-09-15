# Sprint 03 — Documentação e preparação do release

## Objetivo

Fechar o achado A-00 — corrigir o `CLAUDE.md`, que hoje afirma um comportamento que o código não tem e referencia um arquivo inexistente — e deixar a árvore de trabalho pronta para o usuário validar e publicar a `v1.0.9`, sem commitar nem criar a tag.

## Fases

| Fase | Título | Roda em paralelo com |
|---|---|---|
| F-03.1 | Correção documental | nenhuma |
| F-03.2 | Preparação do release | nenhuma |

Detalhe de cada fase em `fases.md`; tasks em `tasks.md`.

## Critério de saída

O `CLAUDE.md` não contém mais a afirmação de retorno `nil` nem a referência a `plano_connection.md`, `tests\run.bat` retorna ERRORLEVEL 0 em todas as versões detectadas, e `git status` mostra as alterações na árvore de trabalho sem nenhum commit criado.

## Riscos conhecidos

- D-24 proíbe commitar e criar a tag: a execução para com a árvore suja, por decisão do usuário, que valida antes de publicar.
- O `CLAUDE.md` erra nos dois sentidos — atribui `nil` a `TConnection`, que não devolve, e omite o `nil` de `TGerenciadorConexao`, que devolvia (`base/07-documentacao-claude-md.md`); depois da sprint-02 nenhuma das duas devolve, e o texto precisa refletir isso.
- A seção "Conventions in this codebase" do `CLAUDE.md` permanece válida e não deve ser perdida na reescrita (`base/07-documentacao-claude-md.md`).
