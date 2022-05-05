unit Provider.ArquivoIni;

interface

uses
  System.IniFiles,
  Provider.DadosConexao,
  IdCoderMIME;

type
  IArquivoIni = Interface
   ['{966C06E0-0B9D-48D9-BF60-2783159AC203}']
    function NomeArquivo(const Value: string): IArquivoIni; overload;
    function NomeArquivo: string; overload;
    function Tag(const Value: string): IArquivoIni; overload;
    function Tag: string; overload;
    function BuscarParametro : TDadosConexao;
  End;

  TArquivoIni = class(TInterfacedObject, IArquivoIni)
  private
    FNomeArquivo : String;
    FTag : String;
  public
    class function New: IArquivoIni;
    constructor Create;
    destructor Destroy; override;
    function NomeArquivo(const Value: string): IArquivoIni; overload;
    function NomeArquivo: string; overload;
    function Tag(const Value: string): IArquivoIni; overload;
    function Tag: string; overload;
    function BuscarParametro : TDadosConexao;
    function Descriptografar(const aValue : String) : String;
  end;

implementation

uses
  System.SysUtils,
  System.UITypes,
  Vcl.Forms,
  Vcl.Dialogs;

{ MinhaClasse }

function TArquivoIni.BuscarParametro: TDadosConexao;
var
  ArquivoIni : String;
  Configuracoes: TIniFile;
  DadosConexao : TDadosConexao;
begin
   ArquivoIni := ExtractFilePath(Application.ExeName) + FNomeArquivo;
  if not FileExists(ArquivoIni) then
  begin
    MessageDlg('Arquivo '+ FNomeArquivo + ' não encontrado!', mtInformation,
      [mbOK], 0);
    Exit;
  end;

  Configuracoes := TIniFile.Create(ArquivoIni);
  try
    DadosConexao.DataBase := Configuracoes.ReadString(FTag, 'Database', '');
    if DadosConexao.DataBase = EmptyStr then
      DadosConexao.DataBase := Configuracoes.ReadString(FTag, 'Database_PDV', '');
    DadosConexao.UserName := Configuracoes.ReadString(FTag, 'UserName', '');
    DadosConexao.PassWord := Configuracoes.ReadString(FTag, 'PassWord', '');
    if Configuracoes.ReadString(FTag, 'usaCriptografia', '') = 'S' then
      DadosConexao.PassWord := Descriptografar(DadosConexao.PassWord);
    DadosConexao.Porta    := Configuracoes.ReadInteger(FTag, 'Porta', 3050);
    DadosConexao.Timer := StrToInt(Configuracoes.ReadString(FTag, 'Tempo', '10000'));
  finally
    BuscarParametro := DadosConexao;
    Configuracoes.Free;
  end;

end;

constructor TArquivoIni.create;
begin

end;

function TArquivoIni.Descriptografar(const aValue : String) : String;
var
  Decoder64: TIdDecoderMIME;
begin
  Decoder64 := TIdDecoderMIME.Create(nil);
  try
    Result := Decoder64.DecodeString(aValue);
  finally
    Decoder64.Free;
  end;
end;

destructor TArquivoIni.Destroy;
begin

  inherited;
end;

class function TArquivoIni.New: IArquivoIni;
begin
  Result := Self.create;
end;

function TArquivoIni.NomeArquivo(const Value: string): IArquivoIni;
begin
  Result := Self;
  FNomeArquivo := Value;
end;

function TArquivoIni.NomeArquivo: string;
begin
  Result := FNomeArquivo;
end;

function TArquivoIni.Tag: string;
begin
  Result := FTag;
end;

function TArquivoIni.Tag(const Value: string): IArquivoIni;
begin
  Result := Self;
  FTag := Value;
end;

end.
