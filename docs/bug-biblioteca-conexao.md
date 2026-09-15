# SPEC — Correções na biblioteca `connection` (Firebird/FireDAC)

## Fonte

- **Repositório alvo**: `github.com/russimar/connection` — **não é este
  repositório**. O AFSelf consome a lib via BOSS (`boss.json`,
  `"github.com/russimar/connection": "^v1.0.8"`), materializada em
  `modules/connection/`, que é pasta de dependência (ignorada no
  `.gitignore` do AFSelf, linha `modules/`). Toda correção descrita aqui deve
  ser feita **no repositório de origem** e consumida por nova versão, nunca
  editada dentro de `modules/` — uma edição local é perdida no próximo
  `boss install` e não chega aos demais projetos da empresa que usam a mesma
  lib.
- **Versão auditada**: `connection` v1.0.8 + `log` v1.0.10, conforme
  `boss-lock.json` (instalado em 2026-09-03).
- **Código lido diretamente** (auditoria de 2026-09-15):
  - `modules/connection/src/Provider.Conexao.pas`
  - `modules/connection/src/Provider.ArquivoIni.pas`
  - `modules/connection/src/Provider.DadosConexao.pas`
  - `modules/connection/src/Provider.GerenciadorConexao.pas`
  - `modules/connection/src/Provider.Interfaces.pas`
  - `modules/connection/src/Query/Provider.Query.pas`
  - `modules/connection/CLAUDE.md`
- **Motivação no AFSelf**: `docs/specs/acesso-banco.md` decidiu isolar o
  AFSelf dos defeitos da lib em vez de corrigi-los do lado consumidor,
  registrando que a correção pertence ao repositório de origem. Esta SPEC é
  o documento que fecha aquela pendência, para que a correção aconteça lá.
- **Política de erro aplicável**: `docs/specs/padroes-codificacao.md` — falha
  de infraestrutura nunca vira resultado de negócio silencioso; é sempre
  exceção tipada. É essa regra que governa os achados A-01 e A-02 abaixo.
- Data da especificação: 2026-09-15
- Status: **Auditoria concluída — correções pendentes no repo de origem**

## Visão geral

Auditoria de correção da biblioteca `connection` na versão efetivamente
instalada, motivada pela necessidade do AFSelf de começar a consultar o
Firebird 5.0 real (Catálogo de produtos e Precificador).

**Achado principal da auditoria, que corrige o registro anterior**: a maior
parte dos defeitos historicamente documentados **já foi corrigida** na v1.0.8.
O `CLAUDE.md` da própria lib está desatualizado e descreve como presente um
comportamento que o código não tem mais. Detalhe em "Defeitos já corrigidos"
abaixo — e é por isso que a primeira ação desta SPEC é documental, não de
código: quem ler o `CLAUDE.md` hoje vai programar defensivamente contra um
`nil` que nunca mais vem.

Restam **4 defeitos reais** e **3 pontos de robustez**, nenhum deles bloqueante
para o AFSelf começar a consultar o banco. A severidade está calibrada para o
uso do AFSelf (aplicação desktop, um terminal, thread única, conexão local),
com nota onde o risco é maior para os outros consumidores da lib (servidores
HTTP multi-thread, que é o cenário do `TGerenciadorConexao`).

## Defeitos já corrigidos na v1.0.8 (não refazer)

Registrado aqui porque o `CLAUDE.md` da lib ainda os descreve como abertos, e
porque `docs/specs/acesso-banco.md` do AFSelf os cita de segunda mão.

| # | Defeito histórico | Situação real na v1.0.8 |
|---|---|---|
| 1 | `TConnection.Connection` retorna `nil` ao falhar, engolindo a exceção | **Corrigido.** `Provider.Conexao.pas` hoje loga e faz `raise Exception.CreateFmt('Falha ao conectar em "%s": %s', ...)`. |
| 2 | `MessageDlg` bloqueante sem sessão interativa | **Corrigido.** Não há nenhum `MessageDlg`, `ShowMessage` ou uso de `Dialogs` em `src/` (verificado por varredura). |
| 3 | Record `TDadosConexao` não inicializado quando o `.ini` não existe | **Corrigido.** `BuscarParametro` levanta exceção com o caminho do arquivo antes de qualquer leitura. |
| 4 | `StrToInt` sem guarda | **Corrigido.** Usa `StrToIntDef` nos pontos de parsing de porta e de `Tempo`. |
| 5 | Falta de validação de `Database`/seção vazios | **Corrigido.** Valida `SectionExists(FTag)` e `Database` vazio, com mensagem nomeando a TAG e o arquivo. |

**Ação documental obrigatória (A-00)**: atualizar a seção "Known issues /
active plan" do `CLAUDE.md` da lib, que hoje afirma *"On connect failure it
logs via TGravarLog and **returns nil** rather than propagating the exception —
callers must check for nil"*. Isso é **falso** na v1.0.8 e induz todo consumidor
a escrever uma guarda de `nil` que nunca dispara, mascarando o tratamento de
exceção correto. A mesma seção referencia `plano_connection.md`, **arquivo que
não existe no repositório** — ou o plano é restaurado, ou a referência sai.

---

## Defeitos a corrigir

### A-01 — `TQuery` continua tratando `Connection` como se pudesse devolver `nil`

- **Arquivo**: `src/Query/Provider.Query.pas`, construtor `TQuery.create`
- **Severidade**: **Média** — hoje mascarado, mas quebra em caso de falha real
- **Natureza**: resíduo da correção de `TConnection`

```pascal
FQuery.Connection := FParent.Connection as TFDCustomConnection;
```

Se `FParent.Connection` devolvesse `nil`, o `as` levantaria `EInvalidCast` —
uma exceção de tipagem que não diz nada sobre banco de dados. Hoje isso não
acontece com `TConnection` (que já levanta exceção descritiva antes), mas
**acontece com `TGerenciadorConexao`**, que ainda propaga `nil` — ver A-02.
O defeito é a combinação: uma implementação de `iConnection` que devolve `nil`
mais um consumidor que faz cast direto produz `EInvalidCast` em vez da causa
real.

**Correção esperada**: após A-02, nenhuma implementação de `iConnection` pode
devolver `nil` — e o contrato deve dizer isso explicitamente (ver A-04). Com o
contrato fechado, o `as` passa a ser seguro. Como defesa em profundidade,
validar `Assigned` antes do cast e levantar exceção nomeando a TAG.

**Ponto adicional no mesmo construtor**:

```pascal
FParent := Parent;
if not Assigned(FParent) then
  FParent := TConnection.New('PDV');
```

O *fallback* para a TAG literal `'PDV'` é uma dependência oculta: um `TQuery`
construído sem parent conecta silenciosamente a um banco cujo nome está
gravado no código da lib. Para o AFSelf, cuja TAG é `AFSELF`
(`config.ini.exemplo`), esse caminho conectaria ao banco errado ou falharia
com mensagem confusa. **Recomendação**: exigir `Parent`, levantando exceção se
vier `nil`, em vez de adivinhar. Se a compatibilidade com consumidores
existentes for necessária, manter o fallback mas torná-lo configurável por
constante pública, nunca literal embutido.

---

### A-02 — `TGerenciadorConexao` reintroduz o `nil` que `TConnection` deixou de ter

- **Arquivo**: `src/Provider.GerenciadorConexao.pas`, `Connection`
- **Severidade**: **Alta para consumidores multi-thread** / Baixa para o AFSelf
  (que não usa o pool)
- **Natureza**: correção incompleta — o pool não acompanhou a correção de `TConnection`

```pascal
LConn := LItem.Conexao.Connection;
if Assigned(LConn) then
  LItem.FDConn := LConn as TFDConnection
else
  LItem.FDConn := nil;
LItem.UltimoUso := Now;
FPool.Add(LThreadID, LItem);
Result := LItem.FDConn;
```

O ramo `else` é código morto herdado do comportamento antigo: `TConnection.New(FTag).Connection`
hoje **levanta exceção** em vez de devolver `nil`, então `LConn` nunca é `nil`
neste ponto. Isso tem duas consequências, e a segunda é a grave:

1. O `else` nunca executa — ruído que sugere ao leitor que `nil` é um retorno
   possível, propagando a crença errada que A-00 vem corrigir.
2. **Vazamento de item no pool em caso de falha**: quando `LItem.Conexao.Connection`
   levanta a exceção, ela sobe **depois** de `LItem := TItemConexao.Create` e
   **antes** de `FPool.Add`. O `TItemConexao` recém-criado nunca é adicionado
   ao pool nem liberado — vaza a cada tentativa de conexão falha. Num servidor
   que tenta reconectar em laço, isso acumula.

**Correção esperada**: envolver a criação em `try/except` que libera o
`TItemConexao` e repropaga a exceção original (`raise`, sem mascarar), e
remover o ramo `else`. A exceção deve chegar ao chamador, não virar `nil` —
caso contrário o pool volta a violar a política de erro.

**Observação de escopo**: o AFSelf usa `TConnection` diretamente, não o pool
(um terminal, thread única). Este achado é reportado porque a correção pertence
à lib compartilhada, e os projetos servidores da empresa dependem dele.

---

### A-03 — `Config` procura o `.ini` em dois lugares por regra implícita

- **Arquivo**: `src/Provider.Conexao.pas`, `TConnection.Config`
- **Severidade**: **Média** — risco de conectar ao banco errado sem aviso

```pascal
function TConnection.Config: String;
begin
  Result := 'config.ini';
  if FileExists(ExtractFilePath(ParamStr(0)) + 'parceiro.ini') then
    Result := 'parceiro.ini';
end;
```

A mera **existência** de um `parceiro.ini` ao lado do executável sobrepõe
silenciosamente o `config.ini`, sem log, sem aviso e sem forma de o consumidor
saber qual arquivo foi usado. Um `parceiro.ini` esquecido numa instalação
antiga faz o sistema conectar a outro banco sem nenhum sinal visível — e o
diagnóstico é caro, porque tudo "funciona", só que contra os dados errados.

Para o AFSelf isto é sensível: a arquitetura prevê banco **local por terminal**
(`docs/requisitos/decisoes-arquitetura.md`), e conectar ao banco de outro
terminal produziria venda gravada no lugar errado.

**Correção esperada**: manter a precedência (há consumidores dependendo dela),
mas **tornar a escolha observável** — registrar via `TGravarLog` qual arquivo
foi efetivamente carregado, e expor o caminho resolvido em método público da
interface para que o consumidor possa exibi-lo em tela de diagnóstico.

---

### A-04 — `iConnection` não documenta o contrato de falha

- **Arquivo**: `src/Provider.Interfaces.pas`
- **Severidade**: **Média** — é a causa-raiz documental de A-01 e A-02

```pascal
iConnection = interface
['{80499E92-59C8-4940-9089-60C0DB97273D}']
  function Connection : TCustomConnection;
end;
```

O contrato não diz se `Connection` pode devolver `nil`, se levanta exceção, se
pode ser chamado repetidamente, nem se o resultado pertence ao chamador. Foi
exatamente esse silêncio que permitiu duas implementações da mesma interface
divergirem: `TConnection` levanta exceção, `TGerenciadorConexao` devolve `nil`.
Enquanto o contrato não for explícito, qualquer implementação nova repete a
divergência.

**Correção esperada**: comentar a interface fixando que (a) `Connection`
**nunca** devolve `nil`; (b) falha de conexão é **exceção**; (c) o
`TCustomConnection` devolvido pertence à implementação e o chamador não deve
liberá-lo. Idealmente, criar exceção tipada própria (`EConnectionException`)
em vez do `Exception` genérico usado hoje, para que o consumidor distinga
falha de infraestrutura de erro de programação — o AFSelf precisa dessa
distinção para cumprir sua própria política de erro.

---

### A-05 — `BuscarParametro` atribui o resultado dentro do `finally`

- **Arquivo**: `src/Provider.ArquivoIni.pas`, `BuscarParametro`
- **Severidade**: **Baixa** (funciona) / **Média** como armadilha de manutenção

```pascal
  finally
    BuscarParametro := DadosConexao;
    Configuracoes.Free;
  end;
```

Atribuir ao resultado pelo nome da função dentro do `finally` funciona, mas é
frágil: o `finally` executa **também no caminho de exceção**, e nesse caminho
`DadosConexao` é um record local **não inicializado**. Hoje isso é inofensivo
porque a exceção descarta o valor de retorno — mas qualquer refatoração que
capture a exceção e leia o resultado passa a ler lixo de pilha. Some-se que
o record tem campos nunca preenchidos (`Usuario`, `Senha`, herdados de outro
uso) e o risco de lixo aumenta.

**Correção esperada**: inicializar o record no início (`DadosConexao := Default(TDadosConexao)`),
mover a atribuição do `Result` para o fim do bloco `try` (caminho de sucesso),
e deixar o `finally` apenas com `Configuracoes.Free`.

---

## Pontos de robustez (não são defeitos, mas afetam o AFSelf)

### R-01 — Reconexão a cada chamada de `Connection` — **PROMOVIDO A DEFEITO (Alta)**

**Atualização de 2026-09-15**: isto deixou de ser "ponto de robustez" e passou
a **defeito de correção comprovado em bancada** contra o Firebird 5.0 real,
durante a implementação de `IBancoDados`.

`TConnection.Connection` relê o `.ini` e reatribui **todos** os `FConn.Params`
a cada chamada, inclusive com a conexão já aberta. Reatribuir os `Params`
**derruba a transação em curso**. Consequência prática:

```
LTr := ...StartTransaction;   // Active = True
LIC.Connection;               // 2a chamada - reatribui Params
                              // Active = False, silenciosamente
LTr.Commit;                   // -514 Transaction [] must be active
```

Ou seja: **qualquer consumidor que use transação explícita e chame
`Connection` mais de uma vez perde a transação sem aviso** — e o erro só
aparece no `Commit`, longe da causa. Reproduzido com 15 linhas
(`Diag2.dpr`): basta `StartTransaction`, uma segunda chamada a `Connection`, e
o `Commit` falha.

Isso é grave além do AFSelf: qualquer projeto da empresa que faça
atomicidade multi-comando sobre esta lib está exposto. O sintoma "-514" é
tipicamente diagnosticado como erro do desenvolvedor, não da lib.

**Correção esperada**: se `FConn.Connected` já for `True`, devolver a conexão
existente sem reler o INI nem tocar nos `Params`; oferecer método explícito de
recarga para quem precisar trocar parâmetros em runtime.

**Mitigação já aplicada no AFSelf**: `TBancoDadosFirebird.ObterConexao`
resolve a conexão **uma única vez por instância** e reusa
(`src/Dados/Dados.BancoDadosFirebird.pas`). Sem isso, a transação explícita da
RN-04 de `acesso-banco.md` seria inutilizável.

### R-02 — Senha em Base64 é ofuscação, não criptografia

`Descriptografar` usa `TIdDecoderMIME` (Base64). `usaCriptografia=S` no INI é
nome enganoso: qualquer pessoa com o arquivo recupera a senha trivialmente.
Não é defeito de código — é expectativa mal nomeada. **Sugestão**: renomear a
chave para algo honesto (`senhaCodificada`) ou documentar explicitamente na
lib que não há proteção criptográfica, para que ninguém trate o INI como
seguro. Vale para o AFSelf: o `config.ini` **não** deve ser versionado
(já está no `.gitignore`) independentemente dessa chave.

### R-03 — `ReportMemoryLeaksOnShutdown` definido dentro do construtor

`TConnection.Create` executa `ReportMemoryLeaksOnShutdown := DebugHook <> 0;`.
Uma biblioteca alterar uma configuração **global do processo** a partir do
construtor de um objeto é efeito colateral inesperado — decisão que pertence
ao `.dpr` da aplicação. Impacta o AFSelf porque a suíte DUnitX depende de
controle próprio de detecção de leak (hoje 451 testes com `Tests Leaked : 0`).
**Sugestão**: remover a linha da lib e deixar a decisão com o consumidor.

---

## Resumo priorizado

| ID | Item | Severidade (AFSelf) | Severidade (lib) |
|---|---|---|---|
| R-01 | Reler INI a cada `Connection` **derruba transação aberta** (comprovado) | **Alta** | **Alta** |
| A-00 | `CLAUDE.md` descreve defeito já corrigido; `plano_connection.md` ausente | **Alta** | **Alta** |
| A-02 | Pool vaza `TItemConexao` em falha e reintroduz `nil` | Baixa (não usa pool) | **Alta** |
| A-03 | `parceiro.ini` sobrepõe `config.ini` em silêncio | **Média** | Média |
| A-04 | `iConnection` sem contrato de falha documentado | Média | **Média** |
| A-01 | `TQuery` faz cast direto + fallback oculto para TAG `'PDV'` | Média | Média |
| A-05 | `Result` atribuído dentro do `finally` | Baixa | Baixa |
| R-02 | Base64 apresentado como criptografia | Baixa | Média |
| R-03 | Lib altera `ReportMemoryLeaksOnShutdown` global | Baixa | Média |

**Ordem sugerida de ataque**: R-01 primeiro (é o único que causa perda
silenciosa de transação, e afeta todos os projetos da empresa que usam a lib
com atomicidade multi-comando), depois A-00 (é documentação, custa minutos e
evita que todo consumidor programe contra um comportamento inexistente), depois
A-04 (fecha o contrato que causou A-01/A-02), depois A-02 (o vazamento real),
e o resto por conveniência.

## Impacto no AFSelf — o que isto libera

**Nenhum destes achados bloqueia** o início da implementação de dados no
AFSelf. Concretamente:

- `TConnection` na v1.0.8 **já cumpre** a política de erro do AFSelf: falha de
  conexão chega como exceção com mensagem descritiva, não como `nil` silencioso.
  A premissa registrada em `docs/specs/acesso-banco.md` — de que o AFSelf
  precisaria de camada defensiva contra o `nil` — **não se aplica mais** e
  aquela SPEC deve ser emendada quando a implementação de `IBancoDados` começar.
- **A-02 pode estar no caminho, ao contrário do que a severidade sugere.**
  `docs/specs/README.md` (seção "Dados & retaguarda") registra que
  `IBancoDados` usará **`TGerenciadorConexao`, o pool por thread** — que é
  justamente a classe com o vazamento de A-02. O AFSelf é desktop de terminal
  único, então o pool por thread não lhe traz benefício algum; se a escolha
  for confirmada, A-02 sobe para **Alta** também no AFSelf. **Decidir na
  implementação de `IBancoDados`**: usar `TConnection` direto (recomendado —
  já corrigido, mais simples, coerente com terminal único) ou manter o pool e
  depender de A-02 estar corrigido antes.
- A-03 e R-01 merecem atenção na implementação de `IBancoDados`: a primeira
  porque conectar ao banco errado é falha cara e silenciosa; a segunda porque a
  consulta de catálogo roda a cada item bipado.

## Pontos em aberto

1. **[Processo]** Quem tem permissão de commit em `github.com/russimar/connection`?
   Esta SPEC assume que a correção sai por lá e volta como nova versão
   (`v1.0.9`+) consumida por `boss update`. Se o acesso não existir, a decisão
   alternativa — *vendorizar* a lib dentro do AFSelf — muda a arquitetura de
   dependências e precisa ser decidida pela equipe, não aqui.
2. **[Escopo]** Se `plano_connection.md` existir em algum lugar fora deste
   checkout, convém compará-lo com esta auditoria antes de corrigir: ele pode
   conter achados em arquivos que não são consumidos pelo AFSelf e que,
   portanto, não foram lidos aqui.
3. **[Verificação]** A lib não tem suíte de testes própria (`modules/log` tem
   `tests/`, `modules/connection` não). Nenhuma das correções acima é
   verificável automaticamente hoje. Vale decidir se a correção entra junto com
   um teste mínimo de `BuscarParametro` (que é lógica pura de parsing de string
   e testável sem banco).

## Referências

- `docs/specs/acesso-banco.md` — SPEC do `IBancoDados` do AFSelf, que motivou
  esta auditoria e precisa ser emendada conforme "Impacto no AFSelf".
- `docs/specs/padroes-codificacao.md` — política de erro que governa A-01/A-02/A-04.
- `docs/requisitos/decisoes-arquitetura.md` — banco local por terminal (A-03).
- `modules/connection/CLAUDE.md` — documento a ser corrigido por A-00.
