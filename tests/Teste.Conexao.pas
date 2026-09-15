unit Teste.Conexao;

{ Testes das correcoes em TConnection:
    T-02.04 — Reconectar (R-01)
    T-02.05 — INI explicito, caminho resolvido e log (A-03)
    T-02.06 — a biblioteca nao altera mais estado global do processo (R-03) }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTesteConexao = class
  public
    [Test]
    procedure ReconectarAplicaParametrosNovosDoIni;
    [Test]
    procedure ArquivoExplicitoVenceAPrecedenciaHistorica;
    [Test]
    procedure SemChamadaExplicitaResolvePelaPrecedencia;
    [Test]
    procedure ConstrutorNaoAlteraEstadoGlobalDoProcesso;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  FireDAC.Comp.Client,
  Provider.Interfaces,
  Provider.Conexao,
  Teste.Ambiente,
  Teste.BancoTemporario,
  Teste.IniTemporario;

{ TTesteConexao }

procedure TTesteConexao.ReconectarAplicaParametrosNovosDoIni;
var
  LLista  : TListaAmbientes;
  LAmb    : TAmbienteFirebird;
  LBanco1 : TBancoTemporario;
  LBanco2 : TBancoTemporario;
  LIni    : TIniTemporario;
  LConn   : iConnection;
  LFDConn : TFDConnection;
  LAntes  : String;
  LDepois : String;
begin
  LLista := TDetectorFirebird.Detectar;
  try
    Assert.IsTrue(LLista.Count > 0, 'Nenhum ambiente Firebird detectado');
    LAmb    := LLista[0];
    LBanco1 := TBancoTemporario.Create(LAmb);
    LBanco2 := nil;
    try
      Assert.IsTrue(LBanco1.Criar, 'Falhou ao criar o primeiro banco');
      LIni := TIniTemporario.Create('config.ini', 'TESTE');
      try
        LIni.Gravar(LAmb, LBanco1.Arquivo);
        LConn   := TConnection.New('TESTE');
        LFDConn := LConn.Connection as TFDConnection;
        LAntes  := LFDConn.Params.Values['DataBase'];

        { troca o banco no INI com a conexao viva }
        LBanco2 := TBancoTemporario.Create(LAmb);
        Assert.IsTrue(LBanco2.Criar, 'Falhou ao criar o segundo banco');
        LIni.Gravar(LAmb, LBanco2.Arquivo);

        { Connection sozinho NAO releva o INI — e o que corrige R-01 }
        LConn.Connection;
        Assert.AreEqual(LAntes, LFDConn.Params.Values['DataBase'],
          'Connection nao pode reler o INI com a conexao aberta');

        { Reconectar e a forma suportada de aplicar parametros novos }
        LConn.Reconectar;
        LDepois := (LConn.Connection as TFDConnection).Params.Values['DataBase'];
        Assert.AreEqual(LBanco2.Arquivo, LDepois,
          'Reconectar deveria ter aplicado o banco novo do INI');
      finally
        LIni.Free;
      end;
    finally
      LBanco1.Free;
      LBanco2.Free;
    end;
  finally
    LLista.Free;
  end;
end;

procedure TTesteConexao.ArquivoExplicitoVenceAPrecedenciaHistorica;
var
  LParceiro : TIniTemporario;
  LOutro    : TIniTemporario;
  LConn     : iConnection;
begin
  { parceiro.ini presente: sem escolha explicita, ele venceria }
  LParceiro := TIniTemporario.Create('parceiro.ini', 'TESTE');
  LOutro    := TIniTemporario.Create('escolhido.ini', 'TESTE');
  try
    LParceiro.GravarBruto('[TESTE]' + sLineBreak + 'Database=C:/do_parceiro.fdb' + sLineBreak);
    LOutro.GravarBruto('[TESTE]' + sLineBreak + 'Database=C:/do_escolhido.fdb' + sLineBreak);

    LConn := TConnection.New('TESTE');
    LConn.ArquivoConfiguracao('escolhido.ini');

    Assert.EndsWith('escolhido.ini', LConn.ArquivoConfiguracao,
      'A escolha explicita do consumidor deve vencer a precedencia historica');
  finally
    LParceiro.Free;
    LOutro.Free;
  end;
end;

procedure TTesteConexao.SemChamadaExplicitaResolvePelaPrecedencia;
var
  LParceiro : TIniTemporario;
  LConfig   : TIniTemporario;
  LConn     : iConnection;
begin
  LConfig   := TIniTemporario.Create('config.ini', 'TESTE');
  LParceiro := TIniTemporario.Create('parceiro.ini', 'TESTE');
  try
    LConfig.GravarBruto('[TESTE]' + sLineBreak + 'Database=C:/do_config.fdb' + sLineBreak);
    LParceiro.GravarBruto('[TESTE]' + sLineBreak + 'Database=C:/do_parceiro.fdb' + sLineBreak);

    LConn := TConnection.New('TESTE');
    Assert.EndsWith('parceiro.ini', LConn.ArquivoConfiguracao,
      'Sem escolha explicita, parceiro.ini mantem a precedencia historica');
  finally
    LParceiro.Free;
    LConfig.Free;
  end;
end;

procedure TTesteConexao.ConstrutorNaoAlteraEstadoGlobalDoProcesso;
var
  LAntes  : Boolean;
  LDepois : Boolean;
  LConn   : iConnection;
begin
  { R-03: a lib nao pode mexer na configuracao global de deteccao de
    vazamentos. Grava um valor conhecido, instancia, rele. }
  LAntes := ReportMemoryLeaksOnShutdown;
  try
    ReportMemoryLeaksOnShutdown := False;
    LConn  := TConnection.New('TESTE');
    LDepois := ReportMemoryLeaksOnShutdown;
    Assert.IsFalse(LDepois,
      'R-03: instanciar TConnection nao pode alterar estado global do processo');
    Assert.IsNotNull(LConn, 'TConnection deveria ter sido criado');
  finally
    ReportMemoryLeaksOnShutdown := LAntes;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TTesteConexao);

end.
