# Tasks — Sprint 03

> Um bloco por task, todos os campos preenchidos. Na execução (F6) a linha `status` é atualizada em cada transição; ao concluir, acrescente data e resultado da suíte.

---

```yaml
id: T-03.01
titulo: A-00 — corrigir o CLAUDE.md
objetivo: Substituir a afirmação falsa sobre retorno nil, remover a referência a plano_connection.md e descrever o contrato novo, conforme D-21.
arquivos:
  cria: []
  altera: [CLAUDE.md]
teste_integracao: Buscar no CLAUDE.md as strings proibidas e as obrigatórias após a edição.
teste_funcional: O documento descreve que Connection levanta EConnectionException e nunca devolve nil, e não cita plano_connection.md.
criterio_aceite: As strings returns nil e plano_connection.md não existem no CLAUDE.md, e as strings EConnectionException e Reconectar existem.
depende_de: [T-02.09, T-02.10, T-02.11]
paralelizavel: false
status: concluida  # 2026-09-15 · strings proibidas: 0; EConnectionException e Reconectar presentes
```

---

```yaml
id: T-03.02
titulo: Documentar o harness de teste
objetivo: Registrar no CLAUDE.md como compilar e rodar a suíte, incluindo a matriz multi-versão e a política de ambiente ausente, conforme D-25, D-30 e D-31.
arquivos:
  cria: []
  altera: [CLAUDE.md]
teste_integracao: Extrair do CLAUDE.md os comandos citados e executá-los a partir da raiz do repositório.
teste_funcional: Cada comando citado no CLAUDE.md existe como arquivo no repositório e retorna ERRORLEVEL 0 quando executado da raiz.
criterio_aceite: O CLAUDE.md cita tests\build.bat e tests\run.bat e afirma que versão ausente é marcada como skipped.
depende_de: [T-03.01]
paralelizavel: false
status: concluida  # 2026-09-15 · build.bat e run.bat citados e com ERRORLEVEL 0 a partir da raiz
```

---

```yaml
id: T-03.03
titulo: Atualizar a versão no boss.json
objetivo: Alinhar o campo version do boss.json com a versão a ser publicada, conforme D-23 e a lacuna L-07.
arquivos:
  cria: []
  altera: [boss.json]
teste_integracao: Ler o boss.json após a alteração e validar que continua sendo JSON válido.
teste_funcional: O campo version passa a conter 1.0.9 e o restante do arquivo permanece inalterado.
criterio_aceite: O boss.json é JSON válido e seu campo version é igual a 1.0.9.
depende_de: [T-03.02]
paralelizavel: false
status: concluida  # 2026-09-15 · boss.json JSON válido com version 1.0.9
```

---

```yaml
id: T-03.04
titulo: Verificação final sem commit
objetivo: Rodar a suíte completa, conferir os critérios de pronto e parar com a árvore de trabalho suja para validação do usuário, conforme D-23 e D-24.
arquivos:
  cria: [docs/bug-biblioteca-conexao/00-ENTREGA.md]
  altera: []
teste_integracao: Executar tests\run.bat em todas as versões detectadas e registrar o resultado no relatório de entrega.
teste_funcional: O relatório lista os 9 achados com o teste que comprova cada um e o resultado da suíte por versão de Firebird.
criterio_aceite: tests\run.bat retorna ERRORLEVEL 0, o relatório existe listando os 9 achados, e git log não contém commit novo.
depende_de: [T-03.03]
paralelizavel: false
status: concluida  # 2026-09-15 · matriz: 24 passed × 3 versões, 0 failed · relatório em 00-ENTREGA.md, sem commit
```
