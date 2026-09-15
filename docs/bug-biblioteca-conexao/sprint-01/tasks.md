# Tasks — Sprint 01

> Um bloco por task, todos os campos preenchidos. Na execução (F6) a linha `status` é atualizada em cada transição; ao concluir, acrescente data e resultado da suíte.

---

```yaml
id: T-01.01
titulo: Projeto DUnitX de console
objetivo: Criar o .dpr/.dproj de teste em tests/, alvo Delphi 10.4 Win32, com search path para src/ e para modules/log.
arquivos:
  cria: [tests/ConnectionTests.dpr, tests/ConnectionTests.dproj]
  altera: []
teste_integracao: Compilar o projeto com MSBuild e verificar que o .exe é gerado.
teste_funcional: Executar o .exe sem argumentos e verificar que imprime o sumário do DUnitX com 0 failed.
criterio_aceite: MSBuild retorna código 0 e o arquivo tests/Win32/Debug/ConnectionTests.exe existe.
depende_de: []
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 1 passed, 0 failed · build via tests/build.bat (dcc32), ver B-01
```

---

```yaml
id: T-01.02
titulo: Script de build
objetivo: Criar tests/build.bat que chama rsvars.bat e compila o projeto de teste por MSBuild.
arquivos:
  cria: [tests/build.bat]
  altera: []
teste_integracao: Rodar tests\build.bat em console limpo e conferir o código de saída.
teste_funcional: Com o .dproj presente, build.bat termina com ERRORLEVEL 0 e gera o executável.
criterio_aceite: tests\build.bat retorna ERRORLEVEL 0 e o executável existe após a execução.
depende_de: [T-01.01]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 1 passed, 0 failed
```

---

```yaml
id: T-01.03
titulo: Teste-sentinela do harness
objetivo: Incluir um teste trivial que comprova que o runner DUnitX está operante antes de qualquer teste da biblioteca.
arquivos:
  cria: [tests/Teste.Sentinela.pas]
  altera: [tests/ConnectionTests.dpr]
teste_integracao: Rodar o executável e verificar que o teste-sentinela aparece no sumário.
teste_funcional: O teste afirma que 1 + 1 = 2 e passa.
criterio_aceite: O sumário do DUnitX mostra pelo menos 1 teste executado e 0 failed.
depende_de: [T-01.02]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 1 passed, 0 failed
```

---

```yaml
id: T-01.04
titulo: Detector de ambientes Firebird
objetivo: Implementar a varredura da pasta de instalação do Firebird, lendo RemoteServicePort de cada firebird.conf, conforme D-31.
arquivos:
  cria: [tests/Teste.Ambiente.pas]
  altera: []
teste_integracao: Rodar o detector nesta máquina e comparar a lista devolvida com as instalações presentes em disco.
teste_funcional: Nesta máquina o detector devolve 3 ambientes com as portas 3050, 3051 e 3052; numa máquina só com o 2.5, devolve 1 ambiente com a porta 3050.
criterio_aceite: O detector devolve, para cada versão encontrada, a tripla versão/porta/caminho do isql.exe, e não devolve entrada para versão ausente.
depende_de: [T-01.03]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 3 passed, 0 failed · detectou 2.5/3050, 4.0/3051, 5.0/3052
```

---

```yaml
id: T-01.05
titulo: Criação e remoção do banco temporário
objetivo: Implementar a rotina que cria o .fdb temporário via isql.exe da versão alvo e o remove ao fim, conforme D-27 e D-37.
arquivos:
  cria: [tests/Teste.BancoTemporario.pas]
  altera: []
teste_integracao: Criar e remover um banco em cada versão detectada, verificando a existência do arquivo antes e depois.
teste_funcional: Dada a versão 2.5, cria o .fdb em pasta temporária com uma tabela e, após a limpeza, o arquivo não existe mais.
criterio_aceite: O arquivo .fdb existe após a criação e não existe após a limpeza, em toda versão detectada.
depende_de: [T-01.04]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 4 passed, 0 failed · criou/removeu banco em 2.5, 4.0 e 5.0
```

---

```yaml
id: T-01.06
titulo: Geração do INI temporário
objetivo: Implementar a geração do arquivo .ini de teste apontando para o banco temporário, apagado ao fim, conforme D-26 e D-33.
arquivos:
  cria: [tests/Teste.IniTemporario.pas]
  altera: []
teste_integracao: Gerar o INI ao lado do executável de teste e lê-lo com TArquivoIni, comparando os valores.
teste_funcional: Dado host localhost, porta da versão alvo e caminho do banco temporário, o INI gerado é lido por TArquivoIni devolvendo exatamente esses valores.
criterio_aceite: TArquivoIni.BuscarParametro devolve DataBase, HostName e Porta iguais aos escritos, e o arquivo .ini não existe após a limpeza.
depende_de: [T-01.05]
paralelizavel: false
status: concluida  # 2026-09-15 · suíte: 6 passed, 0 failed · TArquivoIni leu DataBase/HostName/Porta do INI gerado
```

---

```yaml
id: T-01.07
titulo: Runner da matriz multi-versão
objetivo: Criar tests/run.bat que executa o runner uma vez por versão detectada, passando a versão alvo por parâmetro, conforme D-29 e D-30.
arquivos:
  cria: [tests/run.bat]
  altera: [tests/ConnectionTests.dpr]
teste_integracao: Rodar tests\run.bat nesta máquina e conferir que houve uma execução por versão instalada.
teste_funcional: Nesta máquina produz 3 execuções (2.5, 4.0, 5.0); versão ausente é marcada como skipped sem zerar o código de saída.
criterio_aceite: tests\run.bat retorna ERRORLEVEL 0 quando todas as execuções passam e ERRORLEVEL diferente de 0 quando qualquer uma falha.
depende_de: [T-01.06]
paralelizavel: false
status: concluida  # 2026-09-15 · matriz: 3 execuções (2.5/4.0/5.0), 6 passed cada, 0 failed, ERRORLEVEL 0
```

---

```yaml
id: T-01.08
titulo: Caracterização de R-01 — transação derrubada
objetivo: Fixar em teste que hoje a segunda chamada a Connection com transação aberta derruba a transação.
arquivos:
  cria: [tests/Teste.Caracterizacao.Conexao.pas]
  altera: []
teste_integracao: Abrir transação explícita sobre TConnection, chamar Connection outra vez e conferir o estado da transação contra o banco temporário.
teste_funcional: Após StartTransaction e segunda chamada a Connection, o teste afirma que a transação ficou inativa — comportamento defeituoso atual.
criterio_aceite: O teste passa afirmando que a transação está inativa após a segunda chamada a Connection.
depende_de: [T-01.07]
paralelizavel: true
status: concluida  # 2026-09-15 · suíte: 7 passed, 0 failed · R-01 REPRODUZIDO: transação cai na 2a chamada (FB 5.0)
```

---

```yaml
id: T-01.09
titulo: Caracterização de A-05 e do parsing do INI
objetivo: Fixar em teste o comportamento atual de BuscarParametro nas três situações de Database/HostName; a task não abre conexão, usa apenas arquivos INI em disco.
arquivos:
  cria: [tests/Teste.Caracterizacao.ArquivoIni.pas]
  altera: []
teste_integracao: Ler INIs temporários nos três formatos e comparar o TDadosConexao devolvido.
teste_funcional: Dado Database no formato host:porta:caminho, devolve HostName, Porta e DataBase separados corretamente; dado INI inexistente, levanta exceção.
criterio_aceite: Os três formatos devolvem os valores esperados e as três condições de erro levantam exceção.
depende_de: [T-01.03]
paralelizavel: true
status: concluida  # 2026-09-15 · matriz: 15 passed × 3 versões, 0 failed · parsing das 3 situações + 3 exceções fixados
```

---

```yaml
id: T-01.10
titulo: Caracterização de A-02 — vazamento do pool
objetivo: Fixar em teste que hoje uma falha de conexão no pool propaga exceção sem liberar o TItemConexao criado.
arquivos:
  cria: [tests/Teste.Caracterizacao.Gerenciador.pas]
  altera: []
teste_integracao: Chamar Connection do gerenciador com TAG inexistente no INI e observar a exceção e o estado do pool.
teste_funcional: Com TAG inexistente, o teste afirma que a exceção é levantada e que o pool não registrou a thread — evidência do item órfão.
criterio_aceite: O teste passa afirmando que a exceção é levantada e que nenhuma entrada foi adicionada ao pool.
depende_de: [T-01.07]
paralelizavel: true
status: concluida  # 2026-09-15 · matriz: 15 passed × 3 versões, 0 failed · A-02 reproduzido: exceção sobe, nada no pool
```

---

```yaml
id: T-01.11
titulo: Caracterização de A-01 — TQuery sem parent
objetivo: Fixar em teste que hoje TQuery construído sem parent recorre à TAG literal PDV.
arquivos:
  cria: [tests/Teste.Caracterizacao.Query.pas]
  altera: []
teste_integracao: Construir TQuery com parent nil contra um INI temporário sem a seção PDV e observar o erro resultante.
teste_funcional: Com parent nil e INI sem a seção PDV, o teste afirma que a exceção menciona a TAG PDV, que o chamador nunca pediu.
criterio_aceite: O teste passa afirmando que a mensagem de exceção contém a string PDV.
depende_de: [T-01.07]
paralelizavel: true
status: concluida  # 2026-09-15 · matriz: 15 passed × 3 versões, 0 failed · A-01 reproduzido: mensagem cita a TAG PDV
```
