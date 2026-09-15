# Provider.Conexao.pas — TConnection (implementação de `iConnection`)

## Contrato de entrada

- `TConnection.New(aTag: String): iConnection` — factory pública; `Create(aTag)` levanta
  `Exception.Create('Informar a tag para acesso no banco')` se `aTag = EmptyStr`
  (`src/Provider.Conexao.pas:101-102`).
- `Connection: TCustomConnection` — sem parâmetros. A cada chamada relê o INI via
  `TArquivoIni.New.NomeArquivo(Self.Config).Tag(FTag).BuscarParametro`
  (`src/Provider.Conexao.pas:62-66`).
- `Config: String` — sem parâmetros. Retorna `'config.ini'`, ou `'parceiro.ini'` se este
  existir ao lado do executável (`src/Provider.Conexao.pas:53-58`).

## Contrato de saída

- `Connection` devolve `FConn` (`TFDConnection`) já com `Connected := True`
  (`src/Provider.Conexao.pas:83-84`). Em falha, **não** devolve `nil`: levanta exceção
  (ver "Erros conhecidos"). O `TFDConnection` é criado no construtor e liberado no
  destrutor (`src/Provider.Conexao.pas:100`, `:108-109`) — pertence à implementação.
- Parâmetros fixados em `FConn.Params` a cada chamada: `DriveId='FB'`, `Protocol='tcpIp'`,
  `DataBase`, `User_Name`, `Password`, `Server`, `Port`, `SQLDialect`, `CharacterSet`
  (`src/Provider.Conexao.pas:67-77`). `FConn.DriverName := 'FB'` (`:68`).
- `Config` devolve apenas o **nome** do arquivo, não o caminho resolvido; não há método
  que exponha qual arquivo foi efetivamente usado.

## Limites e cotas

- `FConn.Params.Clear` é executado **incondicionalmente** no início de `Connection`, antes
  de qualquer checagem de `Connected` (`src/Provider.Conexao.pas:67`). Não há caminho rápido
  para conexão já aberta.
- `DadosConexao.Timer` é lido do INI (chave `Tempo`, default `10000` —
  `src/Provider.ArquivoIni.pas:157`) mas **nunca é aplicado** a nenhum parâmetro de
  `FConn` em `Provider.Conexao.pas` (verificado: `Timer` não aparece no arquivo).
- Nenhum outro limite, timeout ou cota declarado — `NÃO DOCUMENTADO`.

## Erros conhecidos e tratamento

| Condição | Comportamento no código |
|---|---|
| `aTag` vazio no construtor | `raise Exception.Create('Informar a tag para acesso no banco')` (`:101-102`) |
| `HostName` vazio **e** arquivo de `DataBase` inexistente | `raise Exception.CreateFmt('Banco de dados não encontrado no caminho: %s', ...)` (`:79-80`) |
| Falha ao abrir a conexão | `FConn.Connected := False`; grava log via `TGravarLog.New.doSaveLog(E.Message + ' - ' + DataBase)`; `raise Exception.CreateFmt('Falha ao conectar em "%s": %s', ...)` (`:85-91`) |

A exceção levantada é `Exception` genérica — não há tipo próprio de exceção de conexão
nesta unit (verificado: nenhuma declaração `E...Exception = class`).

## Riscos para a nossa implementação

1. **Reatribuir `Params` com conexão aberta derruba transação em curso.** `Connection`
   executa `FConn.Params.Clear` e reatribui todos os `Params` mesmo quando `FConn.Connected`
   já é `True` (`:67-77`), sem nenhum teste de `Connected`. A SPEC de origem afirma que isso
   foi reproduzido em bancada contra Firebird 5.0, com `Active` indo silenciosamente a
   `False` e o `Commit` posterior falhando com `-514 Transaction [] must be active`
   (`docs/bug-biblioteca-conexao.md`, seção R-01). Achado **R-01, severidade Alta**.
2. **Regra implícita de dois arquivos de INI.** A mera existência de `parceiro.ini` ao lado
   do executável sobrepõe `config.ini` sem log e sem aviso (`:53-58`); não há como o
   consumidor descobrir qual arquivo foi usado. Achado **A-03**.
3. **Efeito colateral global no construtor.** `ReportMemoryLeaksOnShutdown := DebugHook <> 0`
   dentro de `TConnection.Create` (`:97-99`) altera configuração do processo inteiro a partir
   do construtor de um objeto de biblioteca. Achado **R-03**.
4. **Exceção genérica.** Consumidores não conseguem distinguir falha de infraestrutura de
   erro de programação por tipo, apenas por texto de mensagem. Relacionado a **A-04**.
5. Literais de mensagem contêm acentuação gravada em Win1252 no arquivo-fonte
   (`:80`, `:102`) — qualquer edição precisa preservar o encoding do arquivo.

## Fonte

`src/Provider.Conexao.pas` (linhas citadas individualmente acima) — acessado em 2026-09-15.
`docs/bug-biblioteca-conexao.md` (SPEC de auditoria, achados R-01/A-03/R-03) — acessado em 2026-09-15.
