unit Teste.BancoTemporario;

{ Cria e remove o banco Firebird temporario de cada execucao (D-26, D-27).

  A criacao usa o isql.exe da versao alvo, invocado por linha de comando:
  um processo Delphi carrega um unico fbclient.dll, e cliente 2.5 nao
  conversa com servidor 5.0 — por isso o banco nao e criado via FireDAC.

  O caminho e sempre montado com barra normal (D-37): barra invertida
  seguida de letra vira escape no script SQL e quebra a criacao. }

interface

uses
  DUnitX.TestFramework,
  Teste.Ambiente;

type
  TBancoTemporario = class
  private
    FArquivo  : String;
    FAmbiente : TAmbienteFirebird;
    function ExecutarIsql(const AScript: String): Boolean;
  public
    constructor Create(const AAmbiente: TAmbienteFirebird);
    destructor Destroy; override;
    function Criar: Boolean;
    procedure Remover;
    class function SenhaSysdba: String;
    property Arquivo: String read FArquivo;
    property Ambiente: TAmbienteFirebird read FAmbiente;
  end;

  [TestFixture]
  TTesteBancoTemporario = class
  public
    [Test]
    procedure CriaERemoveEmTodaVersaoDetectada;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  Winapi.Windows,
  Winapi.ShellAPI;

{ TBancoTemporario }

constructor TBancoTemporario.Create(const AAmbiente: TAmbienteFirebird);
begin
  inherited Create;
  FAmbiente := AAmbiente;
  FArquivo  := TPath.Combine(TPath.GetTempPath,
    Format('conn_test_%s_%d.fdb',
      [StringReplace(AAmbiente.Versao, '.', '', [rfReplaceAll]),
       GetCurrentProcessId]));
end;

destructor TBancoTemporario.Destroy;
begin
  Remover;
  inherited;
end;

class function TBancoTemporario.SenhaSysdba: String;
begin
  { D-32: senha padrao, confirmada nas tres instancias locais.
    Override por variavel de ambiente para outras maquinas — nunca versionada. }
  Result := GetEnvironmentVariable('FB_TEST_PASSWORD');
  if Result = EmptyStr then
    Result := 'masterkey';
end;

function TBancoTemporario.ExecutarIsql(const AScript: String): Boolean;
var
  LArqSql : String;
  LLinhas : TStringList;
  LInfo   : TShellExecuteInfo;
begin
  LArqSql := TPath.Combine(TPath.GetTempPath,
    Format('conn_test_%d.sql', [GetCurrentProcessId]));
  LLinhas := TStringList.Create;
  try
    LLinhas.Text := AScript;
    LLinhas.SaveToFile(LArqSql, TEncoding.ANSI);
  finally
    LLinhas.Free;
  end;

  try
    FillChar(LInfo, SizeOf(LInfo), 0);
    LInfo.cbSize       := SizeOf(LInfo);
    LInfo.fMask        := SEE_MASK_NOCLOSEPROCESS;
    LInfo.lpFile       := PChar(FAmbiente.Isql);
    LInfo.lpParameters := PChar(Format('-q -i "%s"', [LArqSql]));
    LInfo.nShow        := SW_HIDE;
    Result := ShellExecuteEx(@LInfo);
    if Result then
    begin
      WaitForSingleObject(LInfo.hProcess, 30000);
      CloseHandle(LInfo.hProcess);
    end;
  finally
    if TFile.Exists(LArqSql) then
      TFile.Delete(LArqSql);
  end;
end;

function TBancoTemporario.Criar: Boolean;
var
  LCaminho : String;
  LScript  : String;
begin
  Remover;
  { D-37: barra normal, sempre }
  LCaminho := StringReplace(FArquivo, '\', '/', [rfReplaceAll]);
  LScript :=
    Format('CREATE DATABASE ''localhost/%d:%s'' USER ''SYSDBA'' PASSWORD ''%s'';' + sLineBreak,
      [FAmbiente.Porta, LCaminho, SenhaSysdba]) +
    'CREATE TABLE PRODUTO (ID INTEGER NOT NULL PRIMARY KEY, NOME VARCHAR(60));' + sLineBreak +
    'COMMIT;' + sLineBreak +
    'QUIT;' + sLineBreak;
  ExecutarIsql(LScript);
  Result := TFile.Exists(FArquivo);
end;

procedure TBancoTemporario.Remover;
begin
  if (FArquivo <> EmptyStr) and TFile.Exists(FArquivo) then
  try
    TFile.Delete(FArquivo);
  except
    { banco ainda em uso pelo servidor: ignora, a limpeza do runner tenta de novo }
  end;
end;

{ TTesteBancoTemporario }

procedure TTesteBancoTemporario.CriaERemoveEmTodaVersaoDetectada;
var
  LLista : TListaAmbientes;
  LAmb   : TAmbienteFirebird;
  LBanco : TBancoTemporario;
begin
  LLista := TDetectorFirebird.Detectar;
  try
    Assert.IsTrue(LLista.Count > 0,
      'Nenhum ambiente Firebird detectado — pre-condicao de ambiente (D-25)');
    for LAmb in LLista do
    begin
      LBanco := TBancoTemporario.Create(LAmb);
      try
        Assert.IsTrue(LBanco.Criar,
          Format('Falhou ao criar banco no Firebird %s (porta %d)',
            [LAmb.Versao, LAmb.Porta]));
        Assert.IsTrue(FileExists(LBanco.Arquivo),
          'Banco criado mas arquivo nao existe: ' + LBanco.Arquivo);
        LBanco.Remover;
        Assert.IsFalse(FileExists(LBanco.Arquivo),
          'Banco nao foi removido: ' + LBanco.Arquivo);
      finally
        LBanco.Free;
      end;
    end;
  finally
    LLista.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TTesteBancoTemporario);

end.
