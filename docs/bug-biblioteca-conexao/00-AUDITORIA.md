# Auditoria — bug-biblioteca-conexao

Data: 2026-09-15 (reauditoria — 4ª rodada, sobre o plano regerado na F3)

Auditoria do plano regerado, contra os 9 itens de verificação da F5. Nenhum arquivo do plano foi alterado nesta fase.

## Avaliação de D-38

A regeração introduziu D-38, que dispensa `T-02.07` e `T-02.11` de ter teste funcional que reprove o código atual. Como essa decisão foi tomada pela mesma autora do plano para destravar tasks que a auditoria vinha reprovando, ela foi verificada de forma independente, e não aceita pelo enunciado.

**Verificação executada contra o código real, não contra o texto do plano.** Cada condição do `criterio_aceite` das duas tasks foi rodada contra `src/` no estado atual:

| condição do criterio_aceite | resultado hoje | reprova o código atual? |
|---|---|---|
| `T-02.07` — existe `Default(TDadosConexao)` em `Provider.ArquivoIni.pas` | 0 ocorrências | sim |
| `T-02.07` — `BuscarParametro :=` fora do bloco `finally` | 1 ocorrência dentro do `finally` | sim |
| `T-02.11` — ausência de `Usuario`/`Senha` em `Provider.DadosConexao.pas` | 2 ocorrências | sim |
| `T-02.11` — string `Base64` em `Provider.ArquivoIni.pas` | 0 ocorrências | sim |

**Conclusão: D-38 é legítima.** A regra 4 do método exige que a task só seja concluída com o `criterio_aceite` verificado, e os quatro critérios dessas tasks discriminam objetivamente entre código corrigido e não corrigido — são binários, executáveis por inspeção e reprovam o estado atual. O que D-38 dispensa é a duplicação dessa prova no `teste_funcional`, para dois defeitos cujo efeito não é observável em runtime. A exceção é nomeada, justificada pelo histórico e limitada a duas tasks; as outras 24 seguem exigindo teste discriminante. Não é contorno da regra.

Ressalva registrada, sem severidade: o `teste_funcional` de `T-02.07` (INI omitindo `UserName`/`CharacterSet` devolve vazio e `WIN1252`) continua não discriminando, porque `ReadString` já aplica esses defaults hoje (`src/Provider.ArquivoIni.pas:153` e `:159`). Sob D-38 isso é admissível — ele cumpre o papel de não-regressão, e a discriminação fica no `criterio_aceite`. O `teste_funcional` de `T-02.11`, por outro lado, discrimina: não há comentário citando Base64 no código atual.

## Achados

| severidade | arquivo | problema | correção sugerida |
|---|---|---|---|
| MÉDIA | ORQUESTRADOR.md | A definição de pronto global, linha 80, ficou defasada: exige que "o teste de A-05 comprova que, no caminho de exceção, os campos numéricos do record devolvido por `BuscarParametro` valem zero". Esse é o teste da 1ª regeração, que a 2ª rodada de auditoria provou ser tecnicamente impossível em Delphi (função que termina por exceção não atribui o resultado ao chamador) e que `T-02.07` já não contém. Um executor que tome a definição de pronto como contrato tentará satisfazer um critério que nenhuma task implementa. | Substituir a linha pela verificação que `T-02.07` de fato entrega: `Provider.ArquivoIni.pas` contém `Default(TDadosConexao)` e não tem a atribuição do resultado dentro do bloco `finally`, com a suíte de `T-01.09` permanecendo verde. |

## Reverificação dos achados da 3ª rodada

| achado anterior | situação |
|---|---|
| ALTA — `T-02.07` com teste que não discrimina | endereçado sob D-38: a discriminação passou para o `criterio_aceite`, que foi verificado e reprova o código atual |
| ALTA — `T-02.11` com teste que não discrimina | endereçado: o `teste_funcional` novo (comentário Base64 + `Descriptografar` intacto) discrimina, e o `criterio_aceite` também |

Verificações estruturais, todas aprovadas: 26 ids únicos, sem órfãos, sem ciclos; nenhum conflito de arquivo entre tasks paralelas; `sprint-01` não toca `src/`; todo `status` inicial em `pendente`; todas as tasks citadas em `fases.md`; nenhum critério com adjetivo subjetivo; nenhuma decisão humana embutida; os 9 achados da SPEC seguem cobertos por task; pré-requisitos externos declarados no ORQUESTRADOR.

## Veredito

VEREDITO: SIM — o plano está pronto para execução autônoma.
