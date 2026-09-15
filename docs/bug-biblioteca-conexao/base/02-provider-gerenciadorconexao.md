# Provider.GerenciadorConexao.pas — TGerenciadorConexao (pool thread-local)

## Contrato de entrada

- `TGerenciadorConexao.New(const ATag: String; AMaxIdleSegundos: Integer = 60): iConnection`
  (`src/Provider.GerenciadorConexao.pas:62-63`). Documentado como substituto drop-in de
  `TConnection.New('TAG')` no Bootstrap do consumidor (`:13-14`).
- `Connection: TCustomConnection` — sem parâmetros. Chaveado por
  `TThread.CurrentThread.ThreadID` (`:155`).
- `ATag` é repassado literalmente a `TConnection.New(FTag)` (`:177`) — **não é validado**
  nesta unit; a validação de tag vazia ocorre só dentro de `TConnection.Create`.

## Contrato de saída

- `Connection` devolve `LItem.FDConn` (`TFDConnection`), seja do cache (`:165`) ou recém-criado
  (`:185`). O `TFDConnection` pertence ao `TConnection` mantido em `LItem.Conexao`
  (`:31`), liberado ao zerar a referência de interface (`:138`, `:169`, `:210`).
- **Pode devolver `nil`**: o ramo `else` em `:181-182` atribui `LItem.FDConn := nil` e esse
  valor vira `Result` em `:185`. É a divergência de contrato frente a `TConnection`, que
  levanta exceção.

## Limites e cotas

- `AMaxIdleSegundos` default **60** (`src/Provider.GerenciadorConexao.pas:63`); conexões com
  `UltimoUso` anterior a `Now - FMaxIdleSegundos / SecsPerDay` são fechadas (`:198`, `:204`).
- Intervalo da thread de limpeza: **30000 ms**, fixo no construtor, comentado como "metade do
  tempo máximo de inatividade padrão" (`:122-123`).
- Uma conexão por `ThreadID`; nenhum limite máximo de itens no pool declarado —
  `NÃO DOCUMENTADO`.
- `FLock` (`TCriticalSection`) serializa todo o corpo de `Connection` (`:157`, `:186`),
  inclusive a abertura da conexão nova.

## Erros conhecidos e tratamento

- **Não há `try/except` em `TGerenciadorConexao.Connection`.** A exceção levantada por
  `LItem.Conexao.Connection` (`:178`) propaga para o chamador. O `finally` em `:186` garante
  apenas `FLock.Leave`, não a liberação de `LItem`.
- `LimparInativas` não trata exceções ao fechar conexões (`:191-220`).
- A thread de limpeza chama `TGerenciadorConexao(FGerenciador).LimparInativas` sem
  `try/except` em `Execute` (`:97-105`); exceção ali termina a thread.

## Riscos para a nossa implementação

1. **Vazamento de `TItemConexao` em falha de conexão.** `LItem := TItemConexao.Create` (`:176`)
   ocorre **antes** de `LItem.Conexao.Connection` (`:178`). Como `TConnection.Connection` hoje
   levanta exceção em vez de devolver `nil`, a exceção sobe entre a criação e o
   `FPool.Add` (`:184`): o objeto nunca entra no pool nem é liberado. Em servidor que
   reconecta em laço, acumula a cada tentativa falha. Achado **A-02, severidade Alta para
   consumidores multi-thread**.
2. **Ramo `else` é código morto que propaga contrato errado.** `:179-182` só faria sentido se
   `TConnection.Connection` pudesse devolver `nil`, o que não ocorre mais
   (`src/Provider.Conexao.pas:85-91`). Enquanto existir, sugere ao leitor que `nil` é retorno
   válido de `iConnection`. Parte de **A-02**, causa-raiz documental em **A-04**.
3. **Herda R-01 integralmente.** O caminho rápido (`:160-167`) evita reconectar, mas o item
   guardado é o mesmo `TConnection` cuja `Connection` reatribui `Params`; qualquer chamador que
   invoque `LItem.Conexao.Connection` diretamente continua exposto.
4. `TItemConexao` é `class` com campos públicos e sem destrutor próprio; a ordem
   `LItem.Conexao := nil; LItem.Free` é repetida em três lugares (`:138-139`, `:169-170`,
   `:210-211`) — qualquer correção precisa manter as três consistentes.

## Fonte

`src/Provider.GerenciadorConexao.pas` (linhas citadas acima) — acessado em 2026-09-15.
`docs/bug-biblioteca-conexao.md` (SPEC de auditoria, achado A-02) — acessado em 2026-09-15.
