program ConnectionTests;

{$IFNDEF TESTINSIGHT}
{$APPTYPE CONSOLE}
{$ENDIF}
{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  DUnitX.TestFramework,
  Teste.Sentinela in 'Teste.Sentinela.pas',
  Teste.Ambiente in 'Teste.Ambiente.pas',
  Teste.BancoTemporario in 'Teste.BancoTemporario.pas',
  Teste.IniTemporario in 'Teste.IniTemporario.pas',
  Teste.Caracterizacao.Conexao in 'Teste.Caracterizacao.Conexao.pas',
  Teste.Caracterizacao.ArquivoIni in 'Teste.Caracterizacao.ArquivoIni.pas',
  Teste.Caracterizacao.Gerenciador in 'Teste.Caracterizacao.Gerenciador.pas',
  Teste.Caracterizacao.Query in 'Teste.Caracterizacao.Query.pas',
  Teste.Excecoes in 'Teste.Excecoes.pas',
  Teste.Conexao in 'Teste.Conexao.pas',
  Teste.ArquivoIni.Resultado in 'Teste.ArquivoIni.Resultado.pas',
  Teste.Gerenciador.Log in 'Teste.Gerenciador.Log.pas';

var
  LRunner   : ITestRunner;
  LResultado: IRunResults;
  LLogger   : ITestLogger;
  LNUnitLog : ITestLogger;

begin
  try
    { --firebird=X e consumido por TDetectorFirebird.VersaoAlvo (D-29);
      o DUnitX nao conhece esse parametro, entao a linha de comando dele
      e desativada para que nao o rejeite. }
    TDUnitX.Options.ExitBehavior := TDUnitXExitBehavior.Continue;

    LRunner := TDUnitX.CreateRunner;
    LRunner.UseRTTI := True;
    LRunner.FailsOnNoAsserts := False;

    LLogger := TDUnitXConsoleLogger.Create(True);
    LRunner.AddLogger(LLogger);

    LNUnitLog := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    LRunner.AddLogger(LNUnitLog);

    LResultado := LRunner.Execute;

    if not LResultado.AllPassed then
      System.ExitCode := 1
    else
      System.ExitCode := 0;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      System.ExitCode := 2;
    end;
  end;
end.
