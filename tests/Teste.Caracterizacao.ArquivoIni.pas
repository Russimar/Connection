unit Teste.Caracterizacao.ArquivoIni;

{ CARACTERIZACAO do parsing de BuscarParametro (A-05 e as tres situacoes de
  Database/HostName). Nao abre conexao: usa apenas arquivos INI em disco.

  Fixa o comportamento atual para que a refatoracao de T-02.07 seja
  comprovada por nao-regressao (D-38). }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTesteCaracterizacaoArquivoIni = class
  public
    [Test]
    procedure Situacao1_DatabaseComHostEPorta;
    [Test]
    procedure Situacao2_HostNameComPorta;
    [Test]
    procedure Situacao3_HostNameEPortaSeparados;
    [Test]
    procedure ArquivoInexistenteLevantaExcecao;
    [Test]
    procedure TagInexistenteLevantaExcecao;
    [Test]
    procedure DatabaseVazioLevantaExcecao;
  end;

implementation

uses
  System.SysUtils,
  Provider.ArquivoIni,
  Provider.DadosConexao,
  Teste.IniTemporario;

{ TTesteCaracterizacaoArquivoIni }

procedure TTesteCaracterizacaoArquivoIni.Situacao1_DatabaseComHostEPorta;
var
  LIni   : TIniTemporario;
  LDados : TDadosConexao;
begin
  LIni := TIniTemporario.Create('carac_s1.ini', 'TESTE');
  try
    LIni.GravarBruto(
      '[TESTE]' + sLineBreak +
      'Database=192.168.1.10:3055:C:/dados/Banco.fdb' + sLineBreak);

    LDados := TArquivoIni.New.NomeArquivo('carac_s1.ini').Tag('TESTE').BuscarParametro;

    Assert.AreEqual('192.168.1.10', LDados.HostName, 'HostName');
    Assert.AreEqual(3055, LDados.Porta, 'Porta');
    Assert.AreEqual('C:/dados/Banco.fdb', LDados.DataBase, 'DataBase');
  finally
    LIni.Free;
  end;
end;

procedure TTesteCaracterizacaoArquivoIni.Situacao2_HostNameComPorta;
var
  LIni   : TIniTemporario;
  LDados : TDadosConexao;
begin
  LIni := TIniTemporario.Create('carac_s2.ini', 'TESTE');
  try
    LIni.GravarBruto(
      '[TESTE]' + sLineBreak +
      'Database=C:/dados/Banco.fdb' + sLineBreak +
      'HostName=192.168.1.20:3060' + sLineBreak);

    LDados := TArquivoIni.New.NomeArquivo('carac_s2.ini').Tag('TESTE').BuscarParametro;

    Assert.AreEqual('192.168.1.20', LDados.HostName, 'HostName');
    Assert.AreEqual(3060, LDados.Porta, 'Porta');
    Assert.AreEqual('C:/dados/Banco.fdb', LDados.DataBase, 'DataBase');
  finally
    LIni.Free;
  end;
end;

procedure TTesteCaracterizacaoArquivoIni.Situacao3_HostNameEPortaSeparados;
var
  LIni   : TIniTemporario;
  LDados : TDadosConexao;
begin
  LIni := TIniTemporario.Create('carac_s3.ini', 'TESTE');
  try
    LIni.GravarBruto(
      '[TESTE]' + sLineBreak +
      'Database=C:/dados/Banco.fdb' + sLineBreak +
      'HostName=servidor' + sLineBreak +
      'Porta=3070' + sLineBreak);

    LDados := TArquivoIni.New.NomeArquivo('carac_s3.ini').Tag('TESTE').BuscarParametro;

    Assert.AreEqual('servidor', LDados.HostName, 'HostName');
    Assert.AreEqual(3070, LDados.Porta, 'Porta');
    Assert.AreEqual('C:/dados/Banco.fdb', LDados.DataBase, 'DataBase');
  finally
    LIni.Free;
  end;
end;

procedure TTesteCaracterizacaoArquivoIni.ArquivoInexistenteLevantaExcecao;
begin
  Assert.WillRaise(
    procedure
    begin
      TArquivoIni.New.NomeArquivo('nao_existe_jamais.ini').Tag('TESTE').BuscarParametro;
    end,
    Exception,
    'Esperada excecao para arquivo INI inexistente');
end;

procedure TTesteCaracterizacaoArquivoIni.TagInexistenteLevantaExcecao;
var
  LIni : TIniTemporario;
begin
  LIni := TIniTemporario.Create('carac_tag.ini', 'TESTE');
  try
    LIni.GravarBruto('[OUTRA]' + sLineBreak + 'Database=C:/x.fdb' + sLineBreak);
    Assert.WillRaise(
      procedure
      begin
        TArquivoIni.New.NomeArquivo('carac_tag.ini').Tag('TESTE').BuscarParametro;
      end,
      Exception,
      'Esperada excecao para TAG inexistente');
  finally
    LIni.Free;
  end;
end;

procedure TTesteCaracterizacaoArquivoIni.DatabaseVazioLevantaExcecao;
var
  LIni : TIniTemporario;
begin
  LIni := TIniTemporario.Create('carac_db.ini', 'TESTE');
  try
    LIni.GravarBruto('[TESTE]' + sLineBreak + 'HostName=servidor' + sLineBreak);
    Assert.WillRaise(
      procedure
      begin
        TArquivoIni.New.NomeArquivo('carac_db.ini').Tag('TESTE').BuscarParametro;
      end,
      Exception,
      'Esperada excecao para Database ausente/vazio');
  finally
    LIni.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TTesteCaracterizacaoArquivoIni);

end.
