# Build, distribuição por BOSS e infraestrutura de testes

## Contrato de entrada

- O repositório é **source-only**: não há `.dpr`, `.dproj` nem `.dpk` versionado na raiz
  (verificado: `ls *.dpk *.dproj *.dpr` não retorna nada). Existem apenas resíduos ignorados
  pelo Git: `Connection.dproj.local`, `Connection.identcache` e `__history/Connection.dpk.~1~`,
  `~2~`.
- `boss.json` declara `"mainsrc": "./src"`, `"projects": []` e a dependência
  `"github.com/russimar/log": "^v1.0.2"`.
- O consumidor materializa a lib em `modules/connection/` via `boss install`; a pasta
  `modules/` está no `.gitignore` do consumidor, **e também no `.gitignore` deste repositório**
  (linha final: `modules/`, junto de `boss-lock.json`).

## Contrato de saída

- A lib é consumida referenciando as units de `src/` diretamente; não há binário publicado.
- Versionamento por tag Git. Tags existentes: `v0.2.0-alpha`, `v0.2.1`, `v1.0.0` … `v1.0.8`,
  mais uma tag anômala chamada `Conexão`. **Última versão: `v1.0.8`**, que é a versão
  auditada pela SPEC de origem e corresponde ao `HEAD` atual (`main`, commit `d497f21`).
- **Divergência de versão registrada, não resolvida**: `boss.json:4` deste repositório declara
  `"version": "1.0.0"`, enquanto a tag publicada é `v1.0.8` — o campo `version` do
  `boss.json` não acompanha as tags.
- `boss-lock.json` deste repositório está desatualizado frente ao consumidor: aqui registra
  `log v1.0.2`, atualizado em `2025-04-09`; a SPEC do consumidor cita `log v1.0.10` instalado
  em 2026-09-03 (`docs/bug-biblioteca-conexao.md`, seção "Fonte"). O `boss-lock.json` está
  no `.gitignore`, embora presente no repositório.

## Limites e cotas

- **Não existe nenhum teste automatizado neste repositório** (verificado: nenhum arquivo cujo
  nome contenha "test" ou "dunit" em toda a árvore, excluindo `.git`). A SPEC de origem
  confirma: "A lib não tem suíte de testes própria (`modules/log` tem `tests/`,
  `modules/connection` não). Nenhuma das correções acima é verificável automaticamente hoje"
  (`docs/bug-biblioteca-conexao.md`, "Pontos em aberto" nº 3).
- Não há build, lint ou comando de teste neste repositório — afirmado no `CLAUDE.md`
  ("there is no standalone build, lint, or test command in this repo") e confirmado pela
  ausência de `.dproj`/`.dpk`.
- A dependência `GravarLog` expõe `TGravarLog.New.doSaveLog(aValue)` e
  `doSaveLog(aValue, AFileName)` (`modules/log/GravarLog.pas:10-12`); grava em
  `ExtractFilePath(ParamStr(0)) + '/Log'`, criando o diretório se preciso
  (`modules/log/GravarLog.pas:35`, `:49-58`).

## Erros conhecidos e tratamento

- Sem suíte de testes, não há mecanismo de regressão: as correções de A-01…A-05, R-01…R-03
  são hoje **não verificáveis automaticamente**.
- `GravarLog.doSaveLog` faz `Exit` silencioso se não conseguir criar o diretório de log
  (`modules/log/GravarLog.pas:52-55`) — falha de log nunca propaga, mas também nunca avisa.

## Riscos para a nossa implementação

1. **A regra de TDD do sprint^x esbarra na ausência total de infraestrutura de teste.** Não
   existe projeto de teste, framework declarado, runner nem fixture. Pela regra 13 do método
   ("a primeira sprint entrega a capacidade de testar"), criar essa infraestrutura
   (`.dproj` de testes DUnitX, harness, fixture de INI) é pré-requisito de qualquer correção
   de código — e é trabalho maior que várias das correções em si.
2. **Nem todo achado é testável sem banco.** `BuscarParametro` é lógica pura de string
   (testável com INI em disco). Já R-01 (transação derrubada por reatribuição de `Params`) só
   se comprova contra um Firebird real — a SPEC afirma que foi reproduzido em bancada com
   `Diag2.dpr`, **arquivo que não existe neste repositório**. A-02 (vazamento de
   `TItemConexao`) é testável com uma tag inválida, que força a exceção sem precisar de banco
   ativo.
3. **Toda correção precisa sair como nova tag/versão** (`v1.0.9`+) para chegar aos
   consumidores via `boss update`; corrigir dentro de `modules/` do consumidor é perdido no
   próximo `boss install` (`docs/bug-biblioteca-conexao.md`, seção "Fonte").
4. **Permissão de commit em `github.com/russimar/connection` é ponto em aberto na SPEC**
   (item 1 de "Pontos em aberto"). O diretório de trabalho atual **é** um clone desse
   repositório com `main` limpo, o que sugere acesso, mas a permissão de *push* não foi
   verificada.
5. Arquivos-fonte em Win1252 com acentuação em literais e comentários; existe a skill
   `win1252-fix` no ambiente para normalização. Qualquer arquivo novo deve seguir o mesmo
   encoding dos existentes.

## Fonte

`boss.json`, `boss-lock.json`, `.gitignore`, `README.md`, `CLAUDE.md` — acessado em 2026-09-15.
`git tag -l` e `git log` (HEAD `d497f21` em `main`, árvore limpa) — acessado em 2026-09-15.
`modules/log/GravarLog.pas:1-60` — acessado em 2026-09-15.
`docs/bug-biblioteca-conexao.md` ("Fonte", "Pontos em aberto") — acessado em 2026-09-15.
