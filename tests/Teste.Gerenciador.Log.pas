unit Teste.Gerenciador.Log;

{ T-02.09 — log de criacao e descarte no pool (D-34).

  TGravarLog escreve em <pasta do executavel>\Log\<data>.txt. O teste cria uma
  conexao real pelo pool e depois forca o descarte por Reconectar, entao le o
  arquivo de log e exige uma linha para cada evento, com o id da thread.

  O log passa pela fila do TGravarLogManager (gravacao assincrona): o teste
  espera as linhas aparecerem, com prazo, em vez de ler uma vez so. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTesteGerenciadorLog = class
  public
    [Test]
    procedure RegistraCriacaoEDescarteComIdDaThread;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.Diagnostics,
  Provider.Interfaces,
  Provider.GerenciadorConexao,
  Teste.Ambiente,
  Teste.BancoTemporario,
  Teste.IniTemporario;

function LerLogDoDia: String;
var
  LPasta   : String;
  LArquivo : String;
  LStream  : TFileStream;
  LLeitor  : TStreamReader;
begin
  Result := EmptyStr;
  LPasta := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Log');
  if not TDirectory.Exists(LPasta) then
    Exit;
  for LArquivo in TDirectory.GetFiles(LPasta, '*.txt') do
  begin
    { fmShareDenyNone: a thread do Manager pode estar gravando agora. }
    LStream := TFileStream.Create(LArquivo, fmOpenRead or fmShareDenyNone);
    try
      LLeitor := TStreamReader.Create(LStream, TEncoding.ANSI);
      try
        Result := Result + LLeitor.ReadToEnd;
      finally
        LLeitor.Free;
      end;
    finally
      LStream.Free;
    end;
  end;
end;

{ Le o log ate todos os trechos aparecerem ou o prazo acabar; devolve o que
  leu por ultimo (o Assert do chamador mostra o que faltou). }
function EsperarLog(const ATrechos: array of String; APrazoMs: Integer): String;
var
  LCron    : TStopwatch;
  LTrecho  : String;
  LTodos   : Boolean;
begin
  LCron := TStopwatch.StartNew;
  repeat
    try
      Result := LerLogDoDia;
    except
      Result := EmptyStr;   { arquivo sendo criado agora: tenta de novo }
    end;
    LTodos := True;
    for LTrecho in ATrechos do
      if not Result.Contains(LTrecho) then
        LTodos := False;
    if LTodos then
      Exit;
    Sleep(50);
  until LCron.ElapsedMilliseconds > APrazoMs;
end;

{ TTesteGerenciadorLog }

procedure TTesteGerenciadorLog.RegistraCriacaoEDescarteComIdDaThread;
var
  LLista : TListaAmbientes;
  LAmb   : TAmbienteFirebird;
  LBanco : TBancoTemporario;
  LIni   : TIniTemporario;
  LGer   : iConnection;
  LLog   : String;
  LIdThread : String;
begin
  LLista := TDetectorFirebird.Detectar;
  try
    Assert.IsTrue(LLista.Count > 0, 'Nenhum ambiente Firebird detectado');
    LAmb   := LLista[0];
    LBanco := TBancoTemporario.Create(LAmb);
    try
      Assert.IsTrue(LBanco.Criar, 'Falhou ao criar banco temporario');
      LIni := TIniTemporario.Create('config.ini', 'TESTE');
      try
        LIni.Gravar(LAmb, LBanco.Arquivo);

        LGer := TGerenciadorConexao.New('TESTE');
        LGer.Connection;      { gera a linha de criacao }
        LGer.Reconectar;      { gera a linha de descarte }

        LIdThread := IntToStr(TThread.CurrentThread.ThreadID);
        LLog      := EsperarLog(['Pool: conexao criada', 'Pool: conexao descartada',
          LIdThread], 5000);

        Assert.IsTrue(LLog.Contains('Pool: conexao criada'),
          'O log deveria registrar a criacao de conexao no pool');
        Assert.IsTrue(LLog.Contains('Pool: conexao descartada'),
          'O log deveria registrar o descarte de conexao no pool');
        Assert.IsTrue(LLog.Contains(LIdThread),
          'As linhas do pool deveriam citar o id da thread ' + LIdThread);
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

initialization

TDUnitX.RegisterTestFixture(TTesteGerenciadorLog);

end.
