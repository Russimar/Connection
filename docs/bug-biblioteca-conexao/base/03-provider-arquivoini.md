# Provider.ArquivoIni.pas — TArquivoIni / IArquivoIni (parsing do INI)

## Contrato de entrada

- Fluente: `TArquivoIni.New.NomeArquivo(const Value: string).Tag(const Value: string)`
  (`src/Provider.ArquivoIni.pas:194-214`). Ambos os setters devolvem `IArquivoIni`; há
  overloads getters sem parâmetro.
- `BuscarParametro: TDadosConexao` — sem parâmetros. Resolve o caminho como
  `ExtractFilePath(ParamStr(0)) + FNomeArquivo` (`:100`), ou seja, **sempre ao lado do
  executável**; não aceita caminho absoluto de fora dessa pasta.
- Chaves lidas da seção `FTag`:

| Chave | Tipo | Default | Linha |
|---|---|---|---|
| `Database` | String | `''` | `:110` |
| `Database_PDV` | String | `''` (fallback se `Database` vazio) | `:111-112` |
| `HostName` | String | `''` | `:113` |
| `Porta` | Integer | `3050` | `:114` |
| `UserName` | String | `''` | `:153` |
| `PassWord` | String | `''` | `:154` |
| `usaCriptografia` | String | `''` (ativa se `= 'S'`) | `:155-156` |
| `Tempo` | String→Int | `10000` | `:157` |
| `Dialect` | Integer | `3` | `:158` |
| `CharacterSet` | String | `WIN1252` | `:159` |

## Contrato de saída

- Devolve `TDadosConexao` (record, `src/Provider.DadosConexao.pas:6-17`) com os campos
  `DataBase`, `HostName`, `Porta`, `UserName`, `PassWord`, `Timer`, `Dialect`, `CharacterSet`
  preenchidos (`:150-159`).
- Os campos `Usuario` e `Senha` do record **nunca são atribuídos** por `BuscarParametro`
  (verificado: não aparecem no arquivo) — permanecem com o conteúdo que o record local tiver.
- Três formatos de `Database`/`HostName` são normalizados (`:116-145`):
  - **Situação 1** — `HostName` vazio e `Database` no formato `host:porta:caminho` ou
    `host:caminho`. Exige `Length(LPartes) >= 2` e `Length(LPartes[0]) > 1` (`:121`) — o
    teste `> 1` é o que evita confundir a letra de unidade `C:` com um host.
  - **Situação 2** — `HostName` no formato `host:porta`, aplicada só se `Length(LPartes) = 2`
    e porta > 0 (`:134-143`).
  - **Situação 3** — já separados, nenhuma ação (`:145`).
- `Descriptografar` devolve o Base64 decodificado via `TIdDecoderMIME` (`:171-181`).

## Limites e cotas

- Porta default **3050** (`:114`); `Tempo` default **10000** (`:157`); `Dialect` default
  **3** (`:158`); `CharacterSet` default **WIN1252** (`:159`).
- `SplitStr` (`:52-72`) e `JoinStr` (`:74-85`) são implementações locais, sem limite de
  tamanho declarado.
- Nenhum limite de tamanho de arquivo ou de número de seções — `NÃO DOCUMENTADO`.

## Erros conhecidos e tratamento

| Condição | Comportamento |
|---|---|
| Arquivo inexistente | `raise Exception.CreateFmt('Arquivo de configuração não encontrado: %s', [ArquivoIni])` (`:101-102`) — antes de qualquer leitura |
| Seção `FTag` inexistente | `raise Exception.CreateFmt('TAG [%s] não encontrada em %s', ...)` (`:106-107`) |
| `Database` e `Database_PDV` vazios | `raise Exception.CreateFmt('Parâmetro Database (ou Database_PDV) ausente/vazio na TAG [%s] de %s', ...)` (`:147-148`) |
| Porta não numérica | `StrToIntDef(..., 0)` (`:124`, `:138`) — sem exceção; 0 faz o parser tratar a parte como caminho, não como porta |
| `Tempo` não numérico | `StrToIntDef(..., 10000)` (`:157`) |

Nenhum `try/except` protege a criação do `TIniFile` (`:104`); o `try/finally` cobre da
linha `:105` à `:163`.

## Riscos para a nossa implementação

1. **`Result` atribuído dentro do `finally`.** `BuscarParametro := DadosConexao` está em
   `:161`, dentro do bloco `finally` (`:160-163`), que executa **também no caminho de
   exceção**. Nesse caminho `DadosConexao` é record local nunca inicializado — hoje
   inofensivo porque a exceção descarta o retorno, mas qualquer refatoração que capture a
   exceção e leia o resultado passa a ler lixo de pilha. Agravado por `Usuario`/`Senha`, que
   nunca são preenchidos em caminho nenhum. Achado **A-05**.
2. **`DadosConexao` não é inicializado** com `Default(TDadosConexao)` em nenhum ponto
   (verificado: não há `Default(` no arquivo).
3. **Base64 apresentado como criptografia.** `usaCriptografia=S` aciona
   `Descriptografar`, que é apenas `TIdDecoderMIME.DecodeString` (`:177`) — Base64 é
   ofuscação reversível trivialmente por qualquer um que tenha o arquivo, não proteção
   criptográfica. O nome da chave induz a erro sobre a segurança do INI. Achado **R-02**.
4. **Esta unit é a única lógica pura testável sem banco.** Todo o parsing das três situações
   de `Database`/`HostName` é manipulação de string; a SPEC de origem já aponta
   `BuscarParametro` como candidato natural a teste automatizado
   (`docs/bug-biblioteca-conexao.md`, "Pontos em aberto" nº 3). Restrição: depende de
   `ParamStr(0)` e de arquivo físico em disco (`:100`), o que condiciona qualquer teste a
   criar um INI real ao lado do executável de teste.
5. Acentuação Win1252 nas mensagens de exceção (`:102`, `:107`, `:148`) — preservar encoding
   ao editar.

## Fonte

`src/Provider.ArquivoIni.pas` (linhas citadas acima) — acessado em 2026-09-15.
`src/Provider.DadosConexao.pas:6-17` — acessado em 2026-09-15.
`docs/bug-biblioteca-conexao.md` (achados A-05, R-02) — acessado em 2026-09-15.
