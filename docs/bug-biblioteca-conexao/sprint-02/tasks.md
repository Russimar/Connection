# Tasks — Sprint 02

> Um bloco por task, todos os campos preenchidos. Na execução (F6) a linha `status` é atualizada em cada transição; ao concluir, acrescente data e resultado da suíte.

---

```yaml
id: T-02.01
titulo: EConnectionException com campos de diagnóstico
objetivo: Criar a exceção tipada da biblioteca, herdando de Exception, com TAG, arquivo INI e database, conforme D-11.
arquivos:
  cria: [src/Provider.Excecoes.pas]
  altera: []
teste_integracao: Levantar a exceção no projeto de teste e capturá-la tanto como EConnectionException quanto como Exception.
teste_funcional: Dada uma exceção criada com TAG, INI e database, os três campos são lidos de volta com os mesmos valores.
criterio_aceite: A exceção é capturável como Exception e expõe as propriedades Tag, ArquivoIni e DataBase com os valores informados.
depende_de: [T-01.08, T-01.09, T-01.10, T-01.11]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 18 passed, 0 failed
```

---

```yaml
id: T-02.02
titulo: Contrato de iConnection documentado e ampliado
objetivo: Declarar em iConnection os métodos de INI explícito, caminho resolvido e Reconectar, com comentário fixando que Connection nunca devolve nil, conforme D-09, D-15 e A-04.
arquivos:
  cria: []
  altera: [src/Provider.Interfaces.pas]
teste_integracao: Compilar o projeto de teste com TConnection e TGerenciadorConexao implementando a interface ampliada.
teste_funcional: Uma variável iConnection apontando para TConnection devolve o caminho do INI resolvido antes de qualquer conexão ser aberta.
criterio_aceite: O projeto de teste compila com ERRORLEVEL 0 e a interface declara os métodos novos com o comentário de contrato.
depende_de: [T-02.01]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 18 passed, 0 failed · iConnection ampliada, 2 implementações compilam
```

---

```yaml
id: T-02.03
titulo: R-01 — não reatribuir Params com conexão aberta
objetivo: Fazer Connection devolver a conexão existente sem reler o INI quando FConn.Connected já for True, conforme D-13.
arquivos:
  cria: []
  altera: [src/Provider.Conexao.pas]
teste_integracao: Inverter o teste de caracterização T-01.08 para exigir transação ativa após a segunda chamada a Connection.
teste_funcional: Após StartTransaction e segunda chamada a Connection, a transação permanece ativa e o Commit conclui sem erro.
criterio_aceite: O teste passa afirmando que a transação está ativa após a segunda chamada e que o Commit não levanta exceção.
depende_de: [T-02.02]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 22 passed, 0 failed · R-01 corrigido: transação preservada, Commit conclui
```

---

```yaml
id: T-02.04
titulo: R-01 — método Reconectar
objetivo: Implementar Reconectar em TConnection, que relê o INI e reabre a conexão sob demanda, conforme D-14.
arquivos:
  cria: []
  altera: [src/Provider.Conexao.pas]
teste_integracao: Alterar o INI temporário entre duas chamadas e verificar que só Reconectar aplica o novo valor.
teste_funcional: Dado um INI alterado após a conexão aberta, Connection mantém os parâmetros antigos e Reconectar passa a refletir os novos.
criterio_aceite: Após Reconectar, o parâmetro DataBase da conexão é igual ao novo valor do INI.
depende_de: [T-02.03]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 22 passed, 0 failed · Reconectar aplica INI novo; Connection não relê
```

---

```yaml
id: T-02.05
titulo: A-03 — INI explícito, caminho resolvido e log
objetivo: Permitir que o consumidor informe qual arquivo INI usar, mantendo a precedência atual quando não informado, e registrar em log o arquivo resolvido, conforme D-08, D-09 e D-34.
arquivos:
  cria: []
  altera: [src/Provider.Conexao.pas]
teste_integracao: Resolver o INI com e sem o método explícito, contra arquivos temporários distintos, conferindo o caminho devolvido.
teste_funcional: Sem chamada explícita, resolve parceiro.ini quando ele existe; com chamada explícita informando outro arquivo, resolve o informado.
criterio_aceite: O caminho resolvido devolvido é igual ao arquivo informado quando há chamada explícita, e igual à regra de precedência quando não há.
depende_de: [T-02.04]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 22 passed, 0 failed · INI explícito vence; sem chamada, precedência mantida; log OK
```

---

```yaml
id: T-02.06
titulo: R-03 — remover ReportMemoryLeaksOnShutdown
objetivo: Retirar do construtor de TConnection a alteração da configuração global do processo, conforme D-12.
arquivos:
  cria: []
  altera: [src/Provider.Conexao.pas]
teste_integracao: Gravar um valor conhecido em ReportMemoryLeaksOnShutdown, instanciar TConnection e reler a variável global.
teste_funcional: Com ReportMemoryLeaksOnShutdown definido como False antes da instanciação, o valor continua False depois de criar TConnection.
criterio_aceite: O valor relido é igual ao gravado antes da instanciação e nenhuma ocorrência de ReportMemoryLeaksOnShutdown existe em src/.
depende_de: [T-02.05]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 22 passed, 0 failed · estado global do processo intacto; 0 ocorrências em src/
```

---

```yaml
id: T-02.07
titulo: A-05 — Result fora do finally e record inicializado
objetivo: Inicializar DadosConexao com Default, mover a atribuição do Result para o fim do try e deixar o finally apenas com Configuracoes.Free, conforme D-19; verificação por não-regressão e inspeção estrutural, conforme D-38.
arquivos:
  cria: [tests/Teste.ArquivoIni.Resultado.pas]
  altera: [src/Provider.ArquivoIni.pas]
teste_integracao: Rodar a suíte de T-01.09 inteira após a refatoração e conferir que nenhum caso mudou de resultado.
teste_funcional: Com INI que omite UserName e CharacterSet, o record devolvido traz UserName vazio e CharacterSet igual a WIN1252, provando que é preenchido por inteiro.
criterio_aceite: T-01.09 permanece com 0 failed, e em src/Provider.ArquivoIni.pas existe a string Default(TDadosConexao) e a string BuscarParametro := não aparece entre as palavras finally e end do bloco.
depende_de: [T-02.02]
paralelizavel: true
status: concluida  # 2026-09-15 · suíte: 23 passed, 0 failed · Default(TDadosConexao) presente, Result fora do finally
```

---

```yaml
id: T-02.11
titulo: D-20 e R-02 — remover campos obsoletos e documentar o Base64
objetivo: Remover os campos Usuario e Senha de TDadosConexao e acrescentar em Provider.ArquivoIni.pas um comentário de que usaCriptografia aciona apenas Base64, sem tocar em Descriptografar nem na leitura da chave, conforme D-20 e D-18; verificação por não-regressão e inspeção estrutural, conforme D-38.
arquivos:
  cria: []
  altera: [src/Provider.DadosConexao.pas, src/Provider.ArquivoIni.pas]
teste_integracao: Compilar e rodar a suíte inteira após a remoção dos campos e conferir que nenhum caso mudou de resultado.
teste_funcional: O corpo de Descriptografar permanece idêntico ao original linha a linha e existe comentário citando Base64 na declaração da chave usaCriptografia.
criterio_aceite: A suíte compila com ERRORLEVEL 0 e permanece com 0 failed, nenhuma ocorrência dos identificadores Usuario ou Senha existe em src/Provider.DadosConexao.pas, e a string Base64 existe em src/Provider.ArquivoIni.pas.
depende_de: [T-02.07]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 23 passed, 0 failed · campos removidos, Descriptografar idêntico ao original, Base64 documentado
```

---

```yaml
id: T-02.08
titulo: A-02 — pool sem vazamento e sem nil
objetivo: Envolver a criação do item em try/except que libera o TItemConexao e repropaga a exceção, removendo o ramo else morto, conforme D-16.
arquivos:
  cria: []
  altera: [src/Provider.GerenciadorConexao.pas]
teste_integracao: Inverter o teste T-01.10 para exigir que falhas repetidas não acumulem itens no pool.
teste_funcional: Após 50 tentativas de conexão com TAG inexistente, o pool continua vazio e cada tentativa levanta exceção.
criterio_aceite: O teste passa afirmando pool vazio após 50 falhas e nenhuma ocorrência de atribuição de nil a FDConn permanece no arquivo.
depende_de: [T-02.06]
paralelizavel: false
status: concluida  # 2026-09-15 · matriz: 24 passed × 3 versões, 0 failed · A-02 corrigido: 50 falhas sem acumular no pool
```

---

```yaml
id: T-02.09
titulo: A-02 — log de criação e descarte no pool
objetivo: Registrar em log a criação e o descarte de conexões do pool, conforme D-34.
arquivos:
  cria: []
  altera: [src/Provider.GerenciadorConexao.pas]
teste_integracao: Executar criação e limpeza por inatividade e inspecionar o arquivo de log gerado.
teste_funcional: Após uma criação e um descarte, o log contém uma linha para cada evento com o identificador da thread.
criterio_aceite: O arquivo de log contém pelo menos uma linha de criação e uma de descarte após o cenário executado.
depende_de: [T-02.08]
paralelizavel: false
status: concluida  # 2026-09-15 · matriz: 24 passed × 3 versões, 0 failed · log de criação e descarte com id da thread
```

---

```yaml
id: T-02.10
titulo: A-01 — TQuery exige parent e valida antes do cast
objetivo: Remover o fallback para a TAG PDV e validar Assigned antes do cast, conforme D-06, D-07 e D-22.
arquivos:
  cria: []
  altera: [src/Query/Provider.Query.pas]
teste_integracao: Inverter o teste T-01.11 para exigir exceção quando o parent é nil.
teste_funcional: TQuery.New(nil) levanta EConnectionException cuja mensagem exige o parent e não menciona PDV.
criterio_aceite: O teste passa afirmando que a exceção é levantada e que a mensagem não contém a string PDV, e nenhuma ocorrência da literal PDV existe em src/.
depende_de: [T-02.02]
paralelizavel: true
status: concluida  # 2026-09-15 · matriz: 24 passed × 3 versões, 0 failed · A-01 corrigido: exige Parent, não cita PDV
```
