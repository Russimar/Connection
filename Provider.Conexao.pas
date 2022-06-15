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
  FireDAC.VCLUI.Wait,
  FireDAC.FMXUI.Wait,
  FireDAC.Comp.UI,
  FireDAC.Phys.IBBase,
  FireDAC.Phys.FB,
  Data.DB,
  FireDAC.Comp.Client,
  System.Generics.Collections,
  Provider.DadosConexao,
  Provider.ArquivoIni;

type
  TConnection = class(TInterfacedObject, iConnection)
  private
    FTag : String;
    FConn : TFDConnection;
    DadosConexao : TDadosConexao;
  public
    class function New(aTag : String): iConnection;
    constructor Create(aTag : String);
    destructor Destroy; override;
    function Connection : TCustomConnection;
    function Config : String;
  end;

implementation

uses
  System.SysUtils;

{ TConnection }

function TConnection.Config: String;
begin
  Result := 'config.ini';
  if FileExists(ExtractFilePath(ParamStr(0)) + 'parceiro.ini') then
    Result := 'parceiro.ini';
end;

function TConnection.Connection: TCustomConnection;
begin
  DadosConexao := TArquivoIni
                     .New
                     .NomeArquivo(CONFIG)
                     .Tag(FTag)
                     .BuscarParametro;
  FConn.Params.Clear;
  FConn.DriverName                 := 'FB';
  FConn.Params.Values['DriveId']   := 'FB';
  FConn.Params.Values['DataBase']  := DadosConexao.DataBase;
  FConn.Params.Values['User_Name'] := DadosConexao.UserName;
  FConn.Params.Values['Password']  := DadosConexao.PassWord;
  FConn.Params.Values['Server']    := DadosConexao.HostName;
  FConn.Params.Values['Port']      := IntToStr(DadosConexao.Porta);
  try
    FConn.Connected := True;
    Result := FConn;
  except
    on E : Exception do
    begin
      Result := nil;
      exit;
    end;
  end;
end;

constructor TConnection.create(aTag : String);
begin
  FConn := TFDConnection.Create(nil);
  if aTag = EmptyStr then
    raise Exception.Create('Informar a taga para acesso no banco');
  FTag := aTag;
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
