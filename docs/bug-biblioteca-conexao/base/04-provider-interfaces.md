# Provider.Interfaces.pas — contratos `iConnection`, `iQuery`, `iEntidade`

## Contrato de entrada

- `iConnection` — GUID `{80499E92-59C8-4940-9089-60C0DB97273D}`, um único método:
  `function Connection: TCustomConnection;` sem parâmetros
  (`src/Provider.Interfaces.pas:11-14`).
- `iQuery` — GUID `{55678AD8-7FF0-4D5B-81C2-1EE4C775104F}`: `SQL(Value: String): iQuery`,
  `Query: TFDQuery`, `DataSet: TDataSet`, `AddParam(Field: String; AValue: Variant): iQuery`,
  `Open: TFDQuery`, `ExecSQL(AValue: String): iQuery` (`:16-24`).
- `iEntidade` — GUID `{7BCC9612-7054-449A-954E-7C38E1E3C8CF}`: `Listar`, `ListarId`,
  `GravarId` (`:26-31`). **Sem implementação neste repositório** (confirmado no
  `CLAUDE.md`; é contrato para o consumidor implementar).

## Contrato de saída

- `iConnection.Connection` declara retorno `TCustomConnection` (`Data.DB`). **Não há um
  único comentário no arquivo** (verificado: nenhuma linha de comentário em
  `src/Provider.Interfaces.pas`) — o contrato não diz:
  - se `Connection` pode devolver `nil`;
  - se falha é sinalizada por exceção e de qual tipo;
  - se pode ser chamado repetidamente e o que acontece com uma conexão já aberta;
  - de quem é a posse do `TCustomConnection` devolvido.
- Consumidores fazem *downcast* para `TFDConnection`/`TFDCustomConnection`
  (`src/Query/Provider.Query.pas:57`, `src/Provider.GerenciadorConexao.pas:180`), o que é
  requisito de fato não expresso no tipo de retorno.

## Limites e cotas

`NÃO DOCUMENTADO` — a unit declara apenas tipos; não há limites, timeouts nem cotas.

## Erros conhecidos e tratamento

`NÃO DOCUMENTADO` — nenhuma exceção é declarada ou documentada nesta unit. Não existe tipo
de exceção próprio da biblioteca em `src/` (verificado: nenhuma declaração de classe de
exceção em nenhuma unit do repositório).

## Riscos para a nossa implementação

1. **É a causa-raiz documental de A-01 e A-02.** O silêncio do contrato permitiu que duas
   implementações da mesma interface divergissem no ponto mais importante:
   `TConnection.Connection` levanta exceção (`src/Provider.Conexao.pas:90`), enquanto
   `TGerenciadorConexao.Connection` pode devolver `nil`
   (`src/Provider.GerenciadorConexao.pas:181-185`). Enquanto o contrato não for explícito,
   qualquer implementação nova repete a divergência. Achado **A-04**.
2. **Ausência de exceção tipada.** Como tudo é `Exception` genérica, o consumidor não
   distingue falha de infraestrutura (banco fora, INI ausente) de erro de programação
   (tag vazia) a não ser pelo texto da mensagem. A SPEC de origem propõe
   `EConnectionException` (`docs/bug-biblioteca-conexao.md`, A-04).
3. **Alterar a interface é mudança de API pública consumida por outros projetos.** Esta lib
   é distribuída por BOSS (`boss.json`); adicionar métodos a `iConnection` quebra qualquer
   implementação externa de `iConnection` fora deste repositório, que não temos como
   enumerar. Comentar a interface e/ou adicionar tipo de exceção novo são mudanças
   compatíveis; acrescentar método à interface, não.
4. A convenção de prefixo é inconsistente no repositório (`iConnection`/`iQuery` minúsculo
   aqui; `IArquivoIni` maiúsculo em `Provider.ArquivoIni.pas:14`) — o `CLAUDE.md` manda
   preservar o prefixo já usado por cada arquivo em vez de normalizar.

## Fonte

`src/Provider.Interfaces.pas` (arquivo completo, 35 linhas) — acessado em 2026-09-15.
`src/Provider.Conexao.pas:90`, `src/Provider.GerenciadorConexao.pas:179-185`,
`src/Query/Provider.Query.pas:57` — acessado em 2026-09-15.
`docs/bug-biblioteca-conexao.md` (achado A-04) — acessado em 2026-09-15.
