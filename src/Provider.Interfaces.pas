unit Provider.Interfaces;

interface

uses
  System.JSON,
  Data.DB,
  FireDAC.Comp.Client;

type
  { Contrato de conexao da biblioteca.

    REGRAS QUE TODA IMPLEMENTACAO DEVE CUMPRIR:

    1. Connection NUNCA devolve nil. Falha de conexao e sinalizada por
       excecao EConnectionException (Provider.Excecoes), nunca por retorno
       nulo. O chamador nao precisa — e nao deve — testar o resultado.
    2. Connection pode ser chamado repetidamente. Com a conexao ja aberta,
       devolve a conexao existente SEM reler a configuracao e SEM reatribuir
       os Params; reatribuir Params derruba transacao em curso. Para trocar
       parametros em runtime existe Reconectar.
    3. O TCustomConnection devolvido PERTENCE a implementacao. O chamador
       nao deve liberar, fechar nem destruir o objeto recebido. }
  iConnection = interface
  ['{80499E92-59C8-4940-9089-60C0DB97273D}']
    { Conexao aberta e pronta para uso. Levanta EConnectionException em caso
      de falha; jamais devolve nil. }
    function Connection : TCustomConnection;

    { Define explicitamente qual arquivo .ini usar. Quando nao chamado, vale
      a regra de precedencia historica (parceiro.ini sobrepoe config.ini). }
    function ArquivoConfiguracao(const AValue: String): iConnection; overload;
    { Caminho do arquivo .ini efetivamente resolvido, disponivel antes mesmo
      de a conexao ser aberta — serve a telas de diagnostico. }
    function ArquivoConfiguracao: String; overload;

    { Rele a configuracao e reabre a conexao, aplicando parametros novos.
      E a unica forma suportada de trocar parametros com a conexao viva. }
    function Reconectar: iConnection;
  end;

  iQuery = interface
  ['{55678AD8-7FF0-4D5B-81C2-1EE4C775104F}']
    function SQL(Value : String) : iQuery;
    function Query : TFDQuery;
    function DataSet : TDataSet;
    function AddParam(Field : String; AValue : Variant) : iQuery;
    function Open : TFDQuery;
    function ExecSQL(AValue : String) : iQuery;
  end;

  iEntidade = interface
  ['{7BCC9612-7054-449A-954E-7C38E1E3C8CF}']
  function Listar(AValue : TDataSource): iEntidade;
  function ListarId(AId : Variant; AValue : TDataSource): iEntidade;
  function GravarId(Aid : Variant) : iEntidade;
  end;

implementation

end.
