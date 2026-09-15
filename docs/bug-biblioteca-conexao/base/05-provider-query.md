# Provider.Query.pas — TQuery (consumidor de `iConnection`)

## Contrato de entrada

- `TQuery.New(Parent: iConnection): iQuery` / `create(Parent: iConnection)`
  (`src/Query/Provider.Query.pas:27-28`, `:51-58`). O parâmetro `Parent` **aceita `nil`**:
  nesse caso o construtor cria `TConnection.New('PDV')` (`:54-55`).
- `SQL(Value: String)` substitui o SQL inteiro (`FQuery.SQL.Clear` + `Add`, `:96-97`).
- `AddParam(Field: String; AValue: Variant)` faz `FQuery.ParamByName(Field).Value := AValue`
  (`:48`) — parâmetro nomeado, portanto sem concatenação de SQL nesse caminho.
- `ExecSQL(AValue: String)` chama `FQuery.ExecSQL(AValue)` (`:74`) — executa a string
  recebida diretamente, **sem parametrização**.

## Contrato de saída

- `SQL`, `AddParam`, `ExecSQL` devolvem `Self` (`iQuery`) — fluente.
- `Query` e `Open` devolvem `TFDQuery`; `DataSet` devolve `TDataSet` — em todos os casos o
  mesmo `FQuery`, que é criado no construtor (`:56`) e destruído em `Destroy` com
  `FreeAndNil` (`:67`). A posse é do `TQuery`; o chamador recebe referência emprestada.
- `Open` chama `FQuery.Open()` e devolve `FQuery` (`:82-86`).

## Limites e cotas

`NÃO DOCUMENTADO` — nenhum limite de linhas, timeout de comando ou paginação é configurado;
`FQuery.FetchOptions`/`ResourceOptions` não são tocados (verificado: não aparecem no arquivo).

## Erros conhecidos e tratamento

- **Nenhum `try/except` em toda a unit** (verificado). Todas as exceções de FireDAC e da
  conexão propagam ao chamador.
- `FQuery.Connection := FParent.Connection as TFDCustomConnection` (`:57`) — o operador `as`
  sobre `nil` **não** levanta `EInvalidCast`: em Delphi, `nil as T` devolve `nil`
  silenciosamente. O sintoma real de um `Parent` que devolva `nil` é, portanto, um
  `TFDQuery` sem `Connection`, cujo erro só aparece no `Open`/`ExecSQL` posterior, longe
  da causa.
- `AddParam` sobre campo inexistente levanta a exceção de `ParamByName` do FireDAC, sem
  tratamento local.

## Riscos para a nossa implementação

1. **Cast direto sobre resultado de `iConnection`.** `:57` assume que `FParent.Connection`
   é um `TFDCustomConnection` não-nulo. Com `TConnection` isso vale (exceção antes); com
   `TGerenciadorConexao` não (`src/Provider.GerenciadorConexao.pas:181-185`). Achado
   **A-01**. Nota: a SPEC de origem afirma que o `as` sobre `nil` levantaria `EInvalidCast`
   (`docs/bug-biblioteca-conexao.md`, A-01); a semântica do Delphi é a oposta — `nil as T`
   é `nil`. **Divergência entre a SPEC e a linguagem — registrada em `00-LACUNAS.md`, a
   confirmar na F2.** O achado permanece válido (falha tardia e sem diagnóstico), mas o
   sintoma descrito muda.
2. **Fallback oculto para a TAG literal `'PDV'`.** `:54-55` conecta silenciosamente a um
   banco cujo nome está embutido no código da lib. Para um consumidor cuja TAG é outra
   (o AFSelf usa `AFSELF`), esse caminho conecta ao banco errado ou falha com mensagem
   que não menciona o fallback. Parte de **A-01**.
3. **`ExecSQL(AValue: String)` executa string crua.** Não há parametrização nesse caminho;
   se o consumidor montar a string por concatenação de entrada de usuário, é vetor de SQL
   injection. Não é defeito introduzido pela lib (a API oferece `AddParam` para o caminho
   seguro), mas a existência do método sem aviso favorece o uso inseguro. **Não consta da
   SPEC de origem** — item novo desta ingestão.
4. `SQL` tem `// FQuery.Open;` comentado (`:98`) — resíduo, sem efeito.

## Fonte

`src/Query/Provider.Query.pas` (arquivo completo, 101 linhas) — acessado em 2026-09-15.
`docs/bug-biblioteca-conexao.md` (achado A-01) — acessado em 2026-09-15.
