unit Teste.IniTemporario;

{ Geracao do .ini de teste apontando para o banco temporario (D-26, D-33).

  O arquivo e escrito ao lado do executavel de teste, porque
  TArquivoIni.BuscarParametro resolve o caminho como
  ExtractFilePath(ParamStr(0)) + NomeArquivo. E apagado ao fim: nenhuma
  credencial de teste fica em disco nem e versionada. }

interface

uses
  DUnitX.TestFramework,
  Teste.Ambiente;

type
  TIniTemporario = class
  private
    FArquivo : String;
    FTag     : String;
  public
    constructor Create(const ANomeArquivo, ATag: String);
    destructor Destroy; override;
    procedure Gravar(const AAmbiente: TAmbienteFirebird; const ABanco: String);
    procedure GravarBruto(const AConteudo: String);
    procedure Remover;
    property Arquivo: String read FArquivo;
    property Tag: String read FTag;
  end;

  [TestFixture]
  TTesteIniTemporario = class
  public
    [Test]
    procedure ArquivoIniLeOsValoresGravados;
    [Test]
    procedure ArquivoNaoExisteAposRemocao;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  Provider.ArquivoIni,
  Provider.DadosConexao,
  Teste.BancoTemporario;

{ TIniTemporario }

constructor TIniTemporario.Create(const ANomeArquivo, ATag: String);
begin
  inherited Create;
  FTag     := ATag;
  FArquivo := TPath.Combine(ExtractFilePath(ParamStr(0)), ANomeArquivo);
end;

destructor TIniTemporario.Destroy;
begin
  Remover;
  inherited;
end;

procedure TIniTemporario.Gravar(const AAmbiente: TAmbienteFirebird;
  const ABanco: String);
var
  LConteudo : String;
begin
  LConteudo :=
    '[' + FTag + ']' + sLineBreak +
    'Database=' + ABanco + sLineBreak +
    'HostName=localhost' + sLineBreak +
    'Porta=' + IntToStr(AAmbiente.Porta) + sLineBreak +
    'UserName=SYSDBA' + sLineBreak +
    'PassWord=' + TBancoTemporario.SenhaSysdba + sLineBreak +
    'Dialect=3' + sLineBreak +
    'CharacterSet=WIN1252' + sLineBreak;
  GravarBruto(LConteudo);
end;

procedure TIniTemporario.GravarBruto(const AConteudo: String);
var
  LLinhas : TStringList;
begin
  LLinhas := TStringList.Create;
  try
    LLinhas.Text := AConteudo;
    LLinhas.SaveToFile(FArquivo, TEncoding.ANSI);
  finally
    LLinhas.Free;
  end;
end;

procedure TIniTemporario.Remover;
begin
  if (FArquivo <> EmptyStr) and TFile.Exists(FArquivo) then
    TFile.Delete(FArquivo);
end;

{ TTesteIniTemporario }

procedure TTesteIniTemporario.ArquivoIniLeOsValoresGravados;
var
  LLista  : TListaAmbientes;
  LAmb    : TAmbienteFirebird;
  LIni    : TIniTemporario;
  LBanco  : TBancoTemporario;
  LDados  : TDadosConexao;
begin
  LLista := TDetectorFirebird.Detectar;
  try
    Assert.IsTrue(LLista.Count > 0, 'Nenhum ambiente Firebird detectado');
    LAmb   := LLista[0];
    LBanco := TBancoTemporario.Create(LAmb);
    try
      LIni := TIniTemporario.Create('teste_conn.ini', 'TESTE');
      try
        LIni.Gravar(LAmb, LBanco.Arquivo);

        LDados := TArquivoIni
                    .New
                    .NomeArquivo('teste_conn.ini')
                    .Tag('TESTE')
                    .BuscarParametro;

        Assert.AreEqual(LBanco.Arquivo, LDados.DataBase, 'DataBase divergente');
        Assert.AreEqual('localhost', LDados.HostName, 'HostName divergente');
        Assert.AreEqual(LAmb.Porta, LDados.Porta, 'Porta divergente');
      finally
        LIni.Free;
      end;
    finally
      LBanco.Free;
    end;
  finally
    LLista.Free;
  end;
end;

procedure TTesteIniTemporario.ArquivoNaoExisteAposRemocao;
var
  LIni     : TIniTemporario;
  LCaminho : String;
begin
  LIni := TIniTemporario.Create('teste_remocao.ini', 'TESTE');
  try
    LIni.GravarBruto('[TESTE]' + sLineBreak + 'Database=x.fdb' + sLineBreak);
    LCaminho := LIni.Arquivo;
    Assert.IsTrue(FileExists(LCaminho), 'INI nao foi criado');
    LIni.Remover;
    Assert.IsFalse(FileExists(LCaminho), 'INI nao foi removido: ' + LCaminho);
  finally
    LIni.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TTesteIniTemporario);

end.
