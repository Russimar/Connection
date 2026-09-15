# Orquestrador — bug-biblioteca-conexao

> Porta de entrada da execução. Escrito para quem abriu o repositório agora e não sabe nada. Só caminhos relativos; nunca o valor de um segredo.

## 1. Objetivo

Corrigir os 9 defeitos auditados na biblioteca `Connection` (conectividade Firebird via FireDAC), no repositório de origem que os distribui por BOSS. O mais grave derruba silenciosamente transações abertas; os demais vão de vazamento de memória no pool a documentação que descreve comportamento inexistente. Como a biblioteca nunca teve teste automatizado, a primeira sprint entrega a capacidade de testar — projeto DUnitX que cria seu próprio banco temporário e roda contra todas as versões de Firebird instaladas na máquina.

## 2. Mapa e ordem de leitura

1. Este arquivo (`ORQUESTRADOR.md`)
2. `00-DECISOES.md` — as 37 decisões que governam o plano; nada no plano pode contrariá-las
3. `base/00-INDICE.md` — e os 7 arquivos da base que ele lista, com o código lido linha a linha
4. `base/00-LACUNAS.md` — o que não foi encontrado na ingestão e como cada lacuna foi tratada
5. `sprint-01/sprint.md` → `fases.md` → `tasks.md`
6. `sprint-02/sprint.md` → `fases.md` → `tasks.md`
7. `sprint-03/sprint.md` → `fases.md` → `tasks.md`
8. `00-BLOQUEIOS.md` — bloqueios registrados durante a execução
9. `00-AUDITORIA.md` — achados MÉDIA/BAIXA que permanecem válidos (criado na F5)

Fonte original do pedido, fora desta pasta: `docs/bug-biblioteca-conexao.md` (SPEC de auditoria).

## 3. Rota de execução

- **Sprint 01** (capacidade de testar): F-01.1 → F-01.2 → F-01.3. Nenhuma fase roda em paralelo.
  - `T-01.09` é paralelizável já a partir de `T-01.03`: não abre conexão, lê apenas arquivos INI em disco.
  - Dentro de F-01.3, três tasks rodam **em paralelo** após `T-01.07`: `T-01.08`, `T-01.10`, `T-01.11`. Escrevem em arquivos distintos, sem conflito.
- **Sprint 02** (contrato e código): F-02.1 → F-02.2 → F-02.3. Nenhuma fase roda em paralelo, mas há paralelismo **dentro** das fases, a partir de `T-02.02` (o contrato):
  - `T-02.07` (e na sequência `T-02.11`) altera `Provider.ArquivoIni.pas`/`Provider.DadosConexao.pas`, arquivos que nenhuma outra task da sprint toca.
  - `T-02.10` altera `Query/Provider.Query.pas`, também exclusivo.
  - Ambas correm em paralelo com a cadeia `T-02.03 → T-02.04 → T-02.05 → T-02.06 → T-02.08 → T-02.09`, que é serial por disputar `Provider.Conexao.pas` e depois `Provider.GerenciadorConexao.pas`.
- **Sprint 03** (documentação e release): F-03.1 → F-03.2. Nenhuma fase roda em paralelo.

As sprints são estritamente sequenciais: `T-02.01` depende das quatro tasks de caracterização da sprint-01, e `T-03.01` depende das três folhas da sprint-02 (`T-02.09`, `T-02.10`, `T-02.11`) — ou seja, a sprint-03 só começa com a sprint-02 inteira concluída. Isso é deliberado: a sprint-02 comprova cada correção invertendo um teste que só existe depois da sprint-01, e a sprint-03 documenta correções que precisam existir.

**Caminho crítico** (16 das 26 tasks):

`T-01.01 → T-01.02 → T-01.03 → T-01.04 → T-01.05 → T-01.06 → T-01.07 → T-01.08 → T-02.01 → T-02.02 → T-02.03 → T-02.04 → T-02.05 → T-02.06 → T-02.08 → T-02.09`

Depois de `T-02.09` fecham as folhas paralelas e segue a sprint-03 (`T-03.01 → T-03.02 → T-03.03 → T-03.04`). Ficam fora do caminho crítico `T-01.09`, `T-01.10`, `T-01.11`, `T-02.07`, `T-02.10` e `T-02.11`.

## 4. Ferramentas

- **MCPs / SDKs:** nenhum além do padrão. A execução é local: compilador Delphi, servidores Firebird instalados e Git.
- **Build:** `tests\build.bat` — chama `rsvars.bat` do Delphi 10.4 (Studio 21.0) e compila por MSBuild. Criado em `T-01.02`; não existe antes disso.
- **Testes:** `tests\run.bat` — executa a suíte uma vez por versão de Firebird detectada. Criado em `T-01.07`. Retorna `ERRORLEVEL 0` só se todas as execuções passarem.
- **Lint:** NÃO EXISTE NO PROJETO.
- **Typecheck:** NÃO EXISTE NO PROJETO — a compilação por `tests\build.bat` cumpre esse papel.
- **Segredos:** nenhum segredo real é usado nem versionado. Os testes criam banco temporário com `SYSDBA` e a senha padrão, confirmada nas três instâncias locais (D-36). Para máquinas onde a senha divirja, o harness lê a variável de ambiente `FB_TEST_PASSWORD`, definida localmente pelo operador e nunca versionada. NUNCA escreva o valor em arquivo do repositório.
- **Ambientes de banco detectados automaticamente** (D-31), nesta máquina: Firebird 2.5 na porta 3050, 4.0 na 3051, 5.0 na 3052. Versão ausente é marcada como *skipped* sem reprovar a suíte (D-30).
- **Pré-requisitos externos por versão de Firebird:** cada versão detectada precisa do seu `isql.exe` acessível — é ele que cria o banco temporário de cada teste (D-27) — e do `fbclient.dll` correspondente, já que um processo carrega um único cliente e um cliente 2.5 não conversa com servidor 5.0 (D-29). A ausência de qualquer um dos dois torna aquela versão *skipped*, nunca falha da suíte. Nesta máquina ambos existem nas três instalações.

## 5. Agentes

- **Implementador** — escreve primeiro os dois testes da task, vê ambos falharem, só então implementa até passarem.
- **Revisor de testes** — antes de aceitar o verde, responde: este teste falharia com uma implementação errada? Se não, o teste volta. Crítico nesta feature: as tasks da sprint-02 **invertem** testes da sprint-01, então o revisor confere que o teste invertido reprova o código antigo.
- **Auditor de aceite** — verifica de fato o `criterio_aceite` da task antes de permitir `status: concluida`. Vários critérios aqui são verificáveis por busca textual em `src/` (ausência de `ReportMemoryLeaksOnShutdown`, da literal `PDV`, dos campos `Usuario`/`Senha`); o auditor executa a busca, não presume.

**Agente único:** assume os três papéis em sequência dentro de cada task, nesta ordem, tratando cada papel como um portão — não avança ao papel seguinte sem fechar o anterior.

## 6. Regras de autonomia

1. Não pergunte nada; não peça autorização para nada.
2. O teste vem antes do código, sempre.
3. Task só é `concluida` com teste de integração E funcional passando e `criterio_aceite` verificado. Não existe "concluído com ressalva".
4. Dúvida nova ou pré-requisito faltando: registrar em `00-BLOQUEIOS.md` (`B-NN | task | bloqueio | o que destravaria`), marcar a task `bloqueada`, pular para a próxima paralelizável. Nunca parar e esperar.
5. Só rode em paralelo o que o plano declarou paralelizável; a execução nunca decide paralelismo. Neste plano isso significa: `T-01.09` (a partir de `T-01.03`); `T-01.08`, `T-01.10` e `T-01.11` (a partir de `T-01.07`); `T-02.07` e `T-02.10` (a partir de `T-02.02`).
6. Atualize `status` em `tasks.md` a cada transição; ao concluir, acrescente data e resultado da suíte.
7. Critério de saída de fase/sprint não atendido = não avança.
8. **Não commitar e não criar tag** (D-24): a execução termina com a árvore de trabalho suja, para o usuário validar antes de publicar.
9. Arquivos-fonte estão em Win1252 com acentuação em literais e comentários; preserve o encoding de cada arquivo editado.

## 7. Definição de pronto global

- [ ] `tests\build.bat` compila com `ERRORLEVEL 0`.
- [ ] `tests\run.bat` retorna `ERRORLEVEL 0`, executando a suíte contra todas as versões de Firebird detectadas na máquina.
- [ ] Nenhum arquivo `.fdb` ou `.ini` temporário permanece em disco após a execução da suíte.
- [ ] Os 9 achados da auditoria estão corrigidos: R-01, R-02, R-03, A-00, A-01, A-02, A-03, A-04, A-05.
- [ ] Os testes de caracterização de R-01, A-01 e A-02 foram invertidos e passam afirmando o comportamento corrigido.
- [ ] A-05 verificado por inspeção estrutural (D-38): `src/Provider.ArquivoIni.pas` contém `Default(TDadosConexao)` e não tem a atribuição do resultado dentro do bloco `finally`, com a suíte de `T-01.09` permanecendo verde.
- [ ] Nenhuma ocorrência em `src/` de: `ReportMemoryLeaksOnShutdown`, da literal `'PDV'`, dos campos `Usuario`/`Senha` de `TDadosConexao`, ou de atribuição de `nil` a `FDConn`.
- [ ] `CLAUDE.md` não contém `returns nil` nem `plano_connection.md`, e descreve `EConnectionException` e `Reconectar`.
- [ ] `boss.json` é JSON válido com `version` igual a `1.0.9`.
- [ ] `docs/bug-biblioteca-conexao/00-ENTREGA.md` existe, listando os 9 achados com o teste que comprova cada um.
- [ ] `git log` não contém commit criado pela execução; a árvore fica suja para validação do usuário.

## 8. Como retomar uma sessão interrompida

1. Leia este arquivo inteiro.
2. Leia o `status` de cada task em cada `sprint-NN/tasks.md`.
3. Leia `00-BLOQUEIOS.md`.
4. Continue da primeira task `pendente` ou `em_andamento` cujas dependências (`depende_de`) estão todas `concluida`. Ignore as `bloqueada` até que o bloqueio registrado seja resolvido.
