unit Teste.Conexao.LogConcorrente;

{ Regressao achada no AFSelf (2026-10-26): duas threads abrindo conexao ao
  mesmo tempo. AplicarParametros gravava "configuracao lida" direto no
  arquivo de log (TGravarLog.New.doSaveLog: AssignFile/Append, sem trava); o
  Append de uma thread colidia com o da outra e o EInOutError "I/O error 32"
  subia de dentro de Connection - a conexao falhava por causa do LOG. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTesteConexaoLogConcorrente = class
  public
    [Test]
    procedure ThreadsConectandoJuntasNaoFalhamPorCausaDoLog;
  end;

implementation

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  Provider.Interfaces,
  Provider.Conexao,
  Teste.Ambiente,
  Teste.BancoTemporario,
  Teste.IniTemporario;

const
  C_THREADS             = 4;
  C_CONEXOES_POR_THREAD = 25;

{ TTesteConexaoLogConcorrente }

procedure TTesteConexaoLogConcorrente.ThreadsConectandoJuntasNaoFalhamPorCausaDoLog;
var
  LLista    : TListaAmbientes;
  LAmb      : TAmbienteFirebird;
  LBanco    : TBancoTemporario;
  LIni      : TIniTemporario;
  LLargada  : TEvent;
  LTrava    : TCriticalSection;
  LThreads  : array of TThread;
  LFalhas   : Integer;
  LPrimeira : String;
  I         : Integer;
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

        LFalhas   := 0;
        LPrimeira := EmptyStr;
        LLargada  := TEvent.Create(nil, True, False, '');
        LTrava    := TCriticalSection.Create;
        try
          SetLength(LThreads, C_THREADS);
          for I := 0 to High(LThreads) do
          begin
            LThreads[I] := TThread.CreateAnonymousThread(
              procedure
              var
                J     : Integer;
                LConn : iConnection;
              begin
                { Todas largam juntas: a colisao acontece na abertura. }
                LLargada.WaitFor(INFINITE);
                for J := 1 to C_CONEXOES_POR_THREAD do
                  try
                    LConn := TConnection.New('TESTE');
                    LConn.Connection;
                    LConn := nil;
                  except
                    on E: Exception do
                    begin
                      TInterlocked.Increment(LFalhas);
                      LTrava.Enter;
                      try
                        if LPrimeira = EmptyStr then
                          LPrimeira := E.ClassName + ': ' + E.Message;
                      finally
                        LTrava.Leave;
                      end;
                    end;
                  end;
              end);
            LThreads[I].FreeOnTerminate := False;
            LThreads[I].Start;
          end;

          LLargada.SetEvent;
          for I := 0 to High(LThreads) do
          begin
            LThreads[I].WaitFor;
            LThreads[I].Free;
          end;

          Assert.AreEqual(0, LFalhas,
            Format('%d de %d conexoes falharam; a primeira: %s',
              [LFalhas, C_THREADS * C_CONEXOES_POR_THREAD, LPrimeira]));
        finally
          LTrava.Free;
          LLargada.Free;
        end;
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

TDUnitX.RegisterTestFixture(TTesteConexaoLogConcorrente);

end.
