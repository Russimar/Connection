unit Teste.ArquivoIni.Resultado;

{ T-02.07 — A-05: Result fora do finally e record inicializado (D-19).

  Verificacao por nao-regressao mais inspecao estrutural (D-38): o efeito de
  A-05 no caminho de sucesso e indistinguivel, porque os defaults ja vinham
  de ReadString/ReadInteger. O que este teste garante e que o record volta
  preenchido por inteiro, sem campo com lixo. A prova estrutural (existencia
  de Default(TDadosConexao) e ausencia da atribuicao dentro do finally) esta
  no criterio de aceite da task. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTesteArquivoIniResultado = class
  public
    [Test]
    procedure RecordVoltaPreenchidoPorInteiroComIniMinimo;
  end;

implementation

uses
  System.SysUtils,
  Provider.ArquivoIni,
  Provider.DadosConexao,
  Teste.IniTemporario;

{ TTesteArquivoIniResultado }

procedure TTesteArquivoIniResultado.RecordVoltaPreenchidoPorInteiroComIniMinimo;
var
  LIni   : TIniTemporario;
  LDados : TDadosConexao;
begin
  LIni := TIniTemporario.Create('a05_minimo.ini', 'TESTE');
  try
    { INI com o minimo: sem UserName, sem CharacterSet, sem Tempo, sem Dialect }
    LIni.GravarBruto(
      '[TESTE]' + sLineBreak +
      'Database=C:/dados/Banco.fdb' + sLineBreak +
      'HostName=servidor' + sLineBreak +
      'Porta=3050' + sLineBreak);

    LDados := TArquivoIni.New.NomeArquivo('a05_minimo.ini').Tag('TESTE').BuscarParametro;

    { campos vindos do arquivo }
    Assert.AreEqual('C:/dados/Banco.fdb', LDados.DataBase, 'DataBase');
    Assert.AreEqual('servidor', LDados.HostName, 'HostName');
    Assert.AreEqual(3050, LDados.Porta, 'Porta');

    { campos ausentes do arquivo: valores definidos, nunca lixo }
    Assert.AreEqual('', LDados.UserName, 'UserName ausente deve vir vazio');
    Assert.AreEqual('', LDados.PassWord, 'PassWord ausente deve vir vazio');
    Assert.AreEqual('WIN1252', LDados.CharacterSet, 'CharacterSet default');
    Assert.AreEqual(10000, LDados.Timer, 'Timer default');
    Assert.AreEqual(3, LDados.Dialect, 'Dialect default');
  finally
    LIni.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TTesteArquivoIniResultado);

end.
