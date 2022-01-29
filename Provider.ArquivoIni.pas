unit Provider.ArquivoIni;

interface

uses
  System.IniFiles,
  Provider.DadosConexao;

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
    constructor create;
    destructor destroy; override;
    function NomeArquivo(const Value: string): IArquivoIni; overload;
    function NomeArquivo: string; overload;
    function Tag(const Value: string): IArquivoIni; overload;
    function Tag: string; overload;
    function BuscarParametro : TDadosConexao;
  end;

implementation

uses
  System.SysUtils, Vcl.Forms, Vcl.Dialogs;

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
    DadosConexao.UserName := Configuracoes.ReadString(FTag, 'UserName', '');
    DadosConexao.PassWord := Configuracoes.ReadString(FTag, 'PassWord', '');
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

destructor TArquivoIni.destroy;
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
