unit Teste.Ambiente;

{ Deteccao automatica dos ambientes Firebird instalados na maquina (D-31).

  Varre a pasta de instalacao do Firebird por diretorios Firebird_*, le
  RemoteServicePort de cada firebird.conf e localiza o isql.exe da versao.
  Versao ausente nao entra na lista — quem consome marca como skipped (D-30). }

interface

uses
  DUnitX.TestFramework,
  System.Generics.Collections;

type
  TAmbienteFirebird = record
    Versao   : String;   { '2.5', '4.0', '5.0' }
    Porta    : Integer;  { lido de RemoteServicePort; 3050 se ausente }
    Isql     : String;   { caminho completo do isql.exe }
    Pasta    : String;   { raiz da instalacao }
  end;

  TListaAmbientes = TList<TAmbienteFirebird>;

  TDetectorFirebird = class
  public
    class function Detectar: TListaAmbientes;
    class function RaizInstalacao: String;
    { Versao alvo vinda de --firebird=2_5 na linha de comando (D-29).
      Vazio = todas as versoes detectadas. }
    class function VersaoAlvo: String;
  end;

  [TestFixture]
  TTesteAmbiente = class
  public
    [Test]
    procedure DetectaSomenteVersoesPresentesEmDisco;
    [Test]
    procedure CadaAmbienteTemVersaoPortaEIsql;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.StrUtils,
  System.Classes;

{ TDetectorFirebird }

class function TDetectorFirebird.RaizInstalacao: String;
begin
  { Num processo 32 bits ProgramFiles aponta para "Program Files (x86)",
    onde o Firebird nao esta. ProgramW6432 da sempre o diretorio de 64 bits. }
  Result := GetEnvironmentVariable('ProgramW6432');
  if Result = EmptyStr then
    Result := GetEnvironmentVariable('ProgramFiles');
  Result := IncludeTrailingPathDelimiter(Result) + 'Firebird';
  if not TDirectory.Exists(Result) then
    Result := 'C:\Program Files\Firebird';
end;

class function TDetectorFirebird.VersaoAlvo: String;
var
  I      : Integer;
  LParam : String;
begin
  Result := EmptyStr;
  for I := 1 to ParamCount do
  begin
    LParam := ParamStr(I);
    if StartsText('--firebird=', LParam) then
    begin
      { '--firebird=2_5' -> '2.5' }
      Result := StringReplace(Copy(LParam, 12, MaxInt), '_', '.', [rfReplaceAll]);
      Exit;
    end;
  end;
end;

class function TDetectorFirebird.Detectar: TListaAmbientes;
var
  LRaiz     : String;
  LPasta    : String;
  LNome     : String;
  LConf     : String;
  LIsql     : String;
  LLinhas   : TStringList;
  I         : Integer;
  LLinha    : String;
  LAmbiente : TAmbienteFirebird;
begin
  Result := TListaAmbientes.Create;
  LRaiz  := RaizInstalacao;
  if not TDirectory.Exists(LRaiz) then
    Exit;

  for LPasta in TDirectory.GetDirectories(LRaiz, 'Firebird_*') do
  begin
    LNome := ExtractFileName(LPasta);
    { 'Firebird_2_5' -> '2.5' }
    LAmbiente.Versao := StringReplace(Copy(LNome, 10, MaxInt), '_', '.', [rfReplaceAll]);
    LAmbiente.Pasta  := LPasta;

    { isql fica na raiz (4.0/5.0) ou em bin\ (2.5) }
    LIsql := TPath.Combine(LPasta, 'isql.exe');
    if not TFile.Exists(LIsql) then
      LIsql := TPath.Combine(TPath.Combine(LPasta, 'bin'), 'isql.exe');
    if not TFile.Exists(LIsql) then
      Continue;   { sem isql, a versao nao e utilizavel (D-27) }
    LAmbiente.Isql := LIsql;

    { porta: RemoteServicePort do firebird.conf, default 3050 }
    LAmbiente.Porta := 3050;
    LConf := TPath.Combine(LPasta, 'firebird.conf');
    if TFile.Exists(LConf) then
    begin
      LLinhas := TStringList.Create;
      try
        LLinhas.LoadFromFile(LConf);
        for I := 0 to LLinhas.Count - 1 do
        begin
          LLinha := Trim(LLinhas[I]);
          if (LLinha = EmptyStr) or StartsText('#', LLinha) then
            Continue;
          if StartsText('RemoteServicePort', LLinha) then
          begin
            LAmbiente.Porta := StrToIntDef(
              Trim(Copy(LLinha, Pos('=', LLinha) + 1, MaxInt)), 3050);
            Break;
          end;
        end;
      finally
        LLinhas.Free;
      end;
    end;

    if (VersaoAlvo = EmptyStr) or SameText(VersaoAlvo, LAmbiente.Versao) then
      Result.Add(LAmbiente);
  end;
end;

{ TTesteAmbiente }

procedure TTesteAmbiente.DetectaSomenteVersoesPresentesEmDisco;
var
  LLista : TListaAmbientes;
  LAmb   : TAmbienteFirebird;
begin
  LLista := TDetectorFirebird.Detectar;
  try
    for LAmb in LLista do
    begin
      Assert.IsTrue(DirectoryExists(LAmb.Pasta),
        'Ambiente detectado aponta para pasta inexistente: ' + LAmb.Pasta);
      Assert.IsTrue(FileExists(LAmb.Isql),
        'Ambiente detectado sem isql.exe: ' + LAmb.Isql);
    end;
  finally
    LLista.Free;
  end;
end;

procedure TTesteAmbiente.CadaAmbienteTemVersaoPortaEIsql;
var
  LLista : TListaAmbientes;
  LAmb   : TAmbienteFirebird;
begin
  LLista := TDetectorFirebird.Detectar;
  try
    for LAmb in LLista do
    begin
      Assert.IsNotEmpty(LAmb.Versao, 'Versao vazia no ambiente ' + LAmb.Pasta);
      Assert.IsTrue(LAmb.Porta > 0,
        Format('Porta invalida (%d) no ambiente %s', [LAmb.Porta, LAmb.Versao]));
      Assert.IsNotEmpty(LAmb.Isql, 'Caminho do isql vazio em ' + LAmb.Versao);
    end;
  finally
    LLista.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TTesteAmbiente);

end.
