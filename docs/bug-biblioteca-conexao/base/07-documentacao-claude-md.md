# CLAUDE.md da biblioteca — documentação desatualizada (alvo do achado A-00)

## Contrato de entrada

`CLAUDE.md` na raiz do repositório é o documento lido por qualquer agente ou desenvolvedor
antes de mexer na lib. Descreve as três camadas de resolução de conexão, a camada `TQuery`,
e mantém uma seção "Known issues / active plan".

## Contrato de saída

Duas afirmações do documento estão **factualmente erradas** frente ao código do `HEAD`:

1. **`CLAUDE.md:17`** — *"On connect failure it logs via `TGravarLog` and **returns `nil`**
   rather than propagating the exception — callers must check for `nil`."*
   O código faz o oposto: `src/Provider.Conexao.pas:85-91` loga **e** levanta
   `Exception.CreateFmt('Falha ao conectar em "%s": %s', ...)`. Nenhum caminho de
   `TConnection.Connection` devolve `nil`.

2. **`CLAUDE.md:17` e `:27`** — ambas referenciam `plano_connection.md` como documento vivo
   ("This is a known issue tracked in `plano_connection.md`"; "read it before touching
   `Provider.ArquivoIni.pas` or `Provider.Conexao.pas`"). **O arquivo não existe no
   repositório** (verificado: `ls plano_connection.md` → *No such file or directory*; nenhuma
   ocorrência do nome na árvore fora do próprio `CLAUDE.md`).

3. **`CLAUDE.md:27`** lista como abertos cinco defeitos que a SPEC de auditoria classifica
   como já corrigidos na v1.0.8: `MessageDlg` bloqueante, record não inicializado com `.ini`
   ausente, `StrToInt` sem guarda, falta de validação de `Database`/seção, e o retorno `nil`.
   Conferido contra o código:

| Defeito descrito no CLAUDE.md | Situação no HEAD |
|---|---|
| `MessageDlg` bloqueante | Não existe `MessageDlg`, `ShowMessage` nem `Dialogs` em `src/` (verificado por varredura) |
| Record não inicializado com `.ini` ausente | `src/Provider.ArquivoIni.pas:101-102` levanta exceção antes de qualquer leitura |
| `StrToInt` sem guarda | Usa `StrToIntDef` em `:124`, `:138`, `:157` |
| Falta de validação de `Database`/seção | `:106-107` valida a seção; `:147-148` valida `Database` |
| `Connection` devolve `nil` | `src/Provider.Conexao.pas:90` levanta exceção |

## Limites e cotas

`NÃO DOCUMENTADO` — não se aplica a um artefato documental.

## Erros conhecidos e tratamento

O documento não tem processo de atualização declarado; nada no repositório vincula
`CLAUDE.md` ao estado do código (sem CI, sem teste, sem hook).

## Riscos para a nossa implementação

1. **Custo direto no consumidor.** Quem lê o `CLAUDE.md` hoje escreve guarda de `nil` que
   nunca dispara, mascarando o tratamento de exceção correto. Foi exatamente o que aconteceu:
   a SPEC `docs/specs/acesso-banco.md` do AFSelf decidiu criar camada defensiva contra um
   `nil` que não existe mais, e agora precisa ser emendada
   (`docs/bug-biblioteca-conexao.md`, "Impacto no AFSelf").
2. **Achado A-00, severidade Alta**, com a nota da SPEC de que é "documentação, custa minutos
   e evita que todo consumidor programe contra um comportamento inexistente".
3. **Decisão pendente sobre `plano_connection.md`**: a SPEC coloca duas saídas — restaurar o
   plano ou remover a referência — e registra em "Pontos em aberto" nº 2 que, se o arquivo
   existir em outro checkout, convém compará-lo com a auditoria antes de corrigir. Não há
   como resolver isso a partir deste repositório. Vai para `00-LACUNAS.md`.
4. **A seção "Conventions in this codebase" permanece válida** e deve ser preservada em
   qualquer reescrita: prefixo de interface preservado por arquivo, factory `New` em vez de
   `Create`, e `{$IFDEF FMX}` mantido em sincronia entre os dois ramos.
5. O `CLAUDE.md` também descreve `TGerenciadorConexao` sem mencionar que ele pode devolver
   `nil` — ou seja, o documento erra nos dois sentidos: atribui `nil` a quem não devolve, e
   omite `nil` de quem devolve.

## Fonte

`CLAUDE.md:17`, `:25-27` e seção "Conventions in this codebase" — acessado em 2026-09-15.
`src/Provider.Conexao.pas:85-91`, `src/Provider.ArquivoIni.pas:101-102`, `:106-107`,
`:124`, `:138`, `:147-148`, `:157` — acessado em 2026-09-15.
`ls plano_connection.md` → inexistente — verificado em 2026-09-15.
`docs/bug-biblioteca-conexao.md` (achado A-00) — acessado em 2026-09-15.
