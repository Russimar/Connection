unit Provider.ArquivoIni;

interface

uses
  {$IF CompilerVersion >= 23}
  System.IniFiles,
  {$ELSE}
  IniFiles,
  {$IFEND}
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
  {$IF CompilerVersion >= 23}
  System.SysUtils,
  {$ELSE}
  SysUtils,
  {$IFEND}
  IdCoderMIME;

type
  TStringPartes = array of string;

function SplitStr(const S: string; Delim: Char): TStringPartes;
var
  I, Start, Count: Integer;
begin
  Count := 1;
  for I := 1 to Length(S) do
    if S[I] = Delim then Inc(Count);
  SetLength(Result, Count);
  Count := 0;
  Start := 1;
  for I := 1 to Length(S) do
  begin
    if S[I] = Delim then
    begin
      Result[Count] := Copy(S, Start, I - Start);
      Inc(Count);
      Start := I + 1;
    end;
  end;
  Result[Count] := Copy(S, Start, Length(S) - Start + 1);
end;

function JoinStr(const AParts: TStringPartes; AStart: Integer; const ADelim: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := AStart to High(AParts) do
  begin
    if I > AStart then
      Result := Result + ADelim;
    Result := Result + AParts[I];
  end;
end;

{ TArquivoIni }

function TArquivoIni.BuscarParametro: TDadosConexao;
var
  ArquivoIni      : String;
  Configuracoes   : TIniFile;
  DadosConexao    : TDadosConexao;
  LDatabase       : String;
  LHostName       : String;
  LPorta          : Integer;
  LPartes         : TStringPartes;
  LPortaCandidata : Integer;
begin
  ArquivoIni := ExtractFilePath(ParamStr(0)) + FNomeArquivo;
  if not FileExists(ArquivoIni) then
    raise Exception.CreateFmt('Arquivo de configuração não encontrado: %s', [ArquivoIni]);

  Configuracoes := TIniFile.Create(ArquivoIni);
  try
    if not Configuracoes.SectionExists(FTag) then
      raise Exception.CreateFmt('TAG [%s] não encontrada em %s', [FTag, ArquivoIni]);

    // Leitura bruta dos valores do INI
    LDatabase := Configuracoes.ReadString(FTag, 'Database', '');
    if LDatabase = EmptyStr then
      LDatabase := Configuracoes.ReadString(FTag, 'Database_PDV', '');
    LHostName := Configuracoes.ReadString(FTag, 'HostName', '');
    LPorta    := Configuracoes.ReadInteger(FTag, 'Porta', 3050);

    if LHostName = EmptyStr then
    begin
      // Situacao 1: Database contem host (e opcionalmente porta)
      // Ex: "192.168.1.1:3050:C:/path/Banco.fdb" ou "192.168.1.1:C:/path/Banco.fdb"
      LPartes := SplitStr(LDatabase, ':');
      if (Length(LPartes) >= 2) and (Length(LPartes[0]) > 1) then
      begin
        LHostName       := LPartes[0];
        LPortaCandidata := StrToIntDef(LPartes[1], 0);
        if LPortaCandidata > 0 then
        begin
          LPorta    := LPortaCandidata;
          LDatabase := JoinStr(LPartes, 2, ':');
        end
        else
          LDatabase := JoinStr(LPartes, 1, ':');
      end;
    end
    else if Pos(':', LHostName) > 0 then
    begin
      // Situacao 2: HostName contem porta — Ex: "192.168.1.1:3050"
      LPartes         := SplitStr(LHostName, ':');
      LPortaCandidata := StrToIntDef(LPartes[1], 0);
      if (Length(LPartes) = 2) and (LPortaCandidata > 0) then
      begin
        LHostName := LPartes[0];
        LPorta    := LPortaCandidata;
      end;
    end;
    // Situacao 3: HostName e Porta ja estao separados — nenhuma acao necessaria

    if LDatabase = EmptyStr then
      raise Exception.CreateFmt('Parâmetro Database (ou Database_PDV) ausente/vazio na TAG [%s] de %s', [FTag, ArquivoIni]);

    DadosConexao.DataBase     := LDatabase;
    DadosConexao.HostName     := LHostName;
    DadosConexao.Porta        := LPorta;
    DadosConexao.UserName     := Configuracoes.ReadString(FTag, 'UserName', '');
    DadosConexao.PassWord     := Configuracoes.ReadString(FTag, 'PassWord', '');
    if Configuracoes.ReadString(FTag, 'usaCriptografia', '') = 'S' then
      DadosConexao.PassWord   := Descriptografar(DadosConexao.PassWord);
    DadosConexao.Timer        := StrToIntDef(Configuracoes.ReadString(FTag, 'Tempo', '10000'), 10000);
    DadosConexao.Dialect      := Configuracoes.ReadInteger(FTag, 'Dialect', 3);
    DadosConexao.CharacterSet := Configuracoes.ReadString(FTag, 'CharacterSet', 'WIN1252');
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
