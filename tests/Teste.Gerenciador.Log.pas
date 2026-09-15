unit Teste.Gerenciador.Log;

{ T-02.09 — log de criacao e descarte no pool (D-34).

  TGravarLog escreve em <pasta do executavel>\Log\<data>.txt. O teste cria uma
  conexao real pelo pool e depois forca o descarte por Reconectar, entao le o
  arquivo de log e exige uma linha para cada evento, com o id da thread. }

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
  Provider.Interfaces,
  Provider.GerenciadorConexao,
  Teste.Ambiente,
  Teste.BancoTemporario,
  Teste.IniTemporario;

function LerLogDoDia: String;
var
  LPasta   : String;
  LArquivo : String;
  LLinhas  : TStringList;
begin
  Result := EmptyStr;
  LPasta := TPath.Combine(ExtractFilePath(ParamStr(0)), 'Log');
  if not TDirectory.Exists(LPasta) then
    Exit;
  for LArquivo in TDirectory.GetFiles(LPasta, '*.txt') do
  begin
    LLinhas := TStringList.Create;
    try
      LLinhas.LoadFromFile(LArquivo);
      Result := Result + LLinhas.Text;
    finally
      LLinhas.Free;
    end;
  end;
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

        LLog      := LerLogDoDia;
        LIdThread := IntToStr(TThread.CurrentThread.ThreadID);

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
