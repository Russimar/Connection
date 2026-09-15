unit Provider.Conexao;

interface

uses
  Provider.Interfaces,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Error,
  FireDAC.UI.Intf,
  FireDAC.Phys.Intf,
  FireDAC.Stan.Def,
  FireDAC.Stan.Pool,
  FireDAC.Stan.Async,
  FireDAC.Phys,
  FireDAC.Phys.FBDef,
  {$If defined(FMX)}
  FireDAC.FMXUI.Wait,
  {$Else}
  FireDAC.VCLUI.Wait,
  {$ENDIF}
  FireDAC.Comp.UI,
  FireDAC.Phys.IBBase,
  FireDAC.Phys.FB,
  Data.DB,
  FireDAC.Comp.Client,
  System.Generics.Collections,
  Provider.DadosConexao,
  Provider.ArquivoIni,
  GravarLog;

type
  TConnection = class(TInterfacedObject, iConnection)
  private
    FTag : String;
    FConn : TFDConnection;
    FArquivoConfiguracao : String;
    DadosConexao : TDadosConexao;
    procedure AplicarParametros;
  public
    class function New(aTag : String): iConnection;
    constructor Create(aTag : String);
    destructor Destroy; override;
    function Connection : TCustomConnection;
    function Config : String;
    function ArquivoConfiguracao(const AValue: String): iConnection; overload;
    function ArquivoConfiguracao: String; overload;
    function Reconectar: iConnection;
  end;

implementation

uses
  System.SysUtils,
  Provider.Excecoes;

{ TConnection }

function TConnection.Config: String;
begin
  { A-03: quando o consumidor informa o arquivo explicitamente, ele manda.
    Sem chamada explicita, vale a precedencia historica — parceiro.ini
    sobrepoe config.ini —, agora registrada em log para deixar de ser
    silenciosa. }
  if FArquivoConfiguracao <> EmptyStr then
    Exit(FArquivoConfiguracao);

  Result := 'config.ini';
  if FileExists(ExtractFilePath(ParamStr(0)) + 'parceiro.ini') then
    Result := 'parceiro.ini';
end;

function TConnection.ArquivoConfiguracao(const AValue: String): iConnection;
begin
  Result := Self;
  FArquivoConfiguracao := AValue;
end;

function TConnection.ArquivoConfiguracao: String;
begin
  Result := ExtractFilePath(ParamStr(0)) + Self.Config;
end;

function TConnection.Reconectar: iConnection;
begin
  Result := Self;
  FConn.Connected := False;
  TGravarLog.New.doSaveLog(Format('Reconectar solicitado na TAG "%s"', [FTag]));
  Connection;
end;

procedure TConnection.AplicarParametros;
begin
  DadosConexao := TArquivoIni
                     .New
                     .NomeArquivo(Self.Config)
                     .Tag(FTag)
                     .BuscarParametro;

  TGravarLog.New.doSaveLog(Format('TAG "%s": configuracao lida de %s',
    [FTag, Self.ArquivoConfiguracao]));

  FConn.Params.Clear;
  FConn.DriverName                 := 'FB';
  FConn.Params.Values['DriveId']   := 'FB';
  FConn.Params.Values['Protocol']  := 'tcpIp';
  FConn.Params.Values['DataBase']  := DadosConexao.DataBase;
  FConn.Params.Values['User_Name'] := DadosConexao.UserName;
  FConn.Params.Values['Password']  := DadosConexao.PassWord;
  FConn.Params.Values['Server']    := DadosConexao.HostName;
  FConn.Params.Values['Port']      := IntToStr(DadosConexao.Porta);
  FConn.Params.Values['SQLDialect']:= IntToStr(DadosConexao.Dialect);
  FConn.Params.Values['CharacterSet'] := DadosConexao.CharacterSet;
end;

function TConnection.Connection: TCustomConnection;
begin
  { R-01: com a conexao ja aberta, devolve a existente sem reler o INI e sem
    reatribuir os Params. Reatribuir Params derruba a transacao em curso, e o
    erro so aparecia no Commit (-514), longe da causa. Para trocar parametros
    em runtime existe Reconectar. }
  if FConn.Connected then
    Exit(FConn);

  AplicarParametros;

  if (DadosConexao.HostName = EmptyStr) and not FileExists(DadosConexao.DataBase) then
    raise EConnectionException.CreateFmt('Banco de dados n�o encontrado no caminho: %s',
      [DadosConexao.DataBase], FTag, Self.ArquivoConfiguracao, DadosConexao.DataBase);

  try
    FConn.Connected := True;
    Result := FConn;
  except
    on E : Exception do
    begin
      FConn.Connected := False;
      TGravarLog.New.doSaveLog(E.Message + ' - ' + DadosConexao.DataBase);
      raise EConnectionException.CreateFmt('Falha ao conectar em "%s": %s',
        [DadosConexao.DataBase, E.Message], FTag, Self.ArquivoConfiguracao,
        DadosConexao.DataBase);
    end;
  end;
end;

constructor TConnection.create(aTag : String);
begin
  { R-03: a biblioteca NAO altera mais a configuracao global de deteccao de
    vazamentos do processo. Mexer em estado global a partir do construtor de
    um objeto e efeito colateral inesperado; a decisao pertence ao .dpr da
    aplicacao consumidora. }
  FConn := TFDConnection.Create(nil);
  if aTag = EmptyStr then
    raise EConnectionException.Create('Informar a tag para acesso no banco');
  FTag := aTag;
  FArquivoConfiguracao := EmptyStr;
end;

destructor TConnection.destroy;
begin
  FConn.Connected := False;
  FConn.Free;
  inherited;
end;

class function TConnection.New(aTag : String): iConnection;
begin
  Result := Self.create(aTag);
end;

end.
