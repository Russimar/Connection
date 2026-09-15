unit Teste.Caracterizacao.Conexao;

{ R-01 CORRIGIDO (T-02.03).

  Antes, TConnection.Connection relia o INI e reatribuia TODOS os
  FConn.Params a cada chamada, mesmo com a conexao ja aberta — o que derrubava
  a transacao em curso silenciosamente, e o erro so aparecia no Commit com
  "-514 Transaction must be active", longe da causa.

  Agora Connection devolve a conexao existente quando ja conectada, sem tocar
  nos Params. Este teste exige o comportamento CORRIGIDO: a transacao
  permanece ativa e o Commit conclui. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTesteCaracterizacaoConexao = class
  public
    [Test]
    procedure SegundaChamadaDeConnectionPreservaTransacaoAberta;
  end;

implementation

uses
  System.SysUtils,
  Data.DB,
  FireDAC.Comp.Client,
  Provider.Interfaces,
  Provider.Conexao,
  Teste.Ambiente,
  Teste.BancoTemporario,
  Teste.IniTemporario;

{ TTesteCaracterizacaoConexao }

procedure TTesteCaracterizacaoConexao.SegundaChamadaDeConnectionPreservaTransacaoAberta;
var
  LLista : TListaAmbientes;
  LAmb   : TAmbienteFirebird;
  LBanco : TBancoTemporario;
  LIni   : TIniTemporario;
  LConn  : iConnection;
  LFDConn: TFDConnection;
  LAtivaAntes, LAtivaDepois: Boolean;
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

        LConn   := TConnection.New('TESTE');
        LFDConn := LConn.Connection as TFDConnection;

        LFDConn.StartTransaction;
        LAtivaAntes := LFDConn.InTransaction;

        { segunda chamada: rele o INI e reatribui os Params }
        LConn.Connection;
        LAtivaDepois := LFDConn.InTransaction;

        Assert.IsTrue(LAtivaAntes,
          'Pre-condicao falhou: a transacao nao ficou ativa apos StartTransaction');
        Assert.IsTrue(LAtivaDepois,
          'R-01: a segunda chamada a Connection NAO pode derrubar a transacao aberta');

        { o Commit precisa concluir: era aqui que aparecia o -514 }
        LFDConn.Commit;
        Assert.IsFalse(LFDConn.InTransaction,
          'Commit deveria ter encerrado a transacao');
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

TDUnitX.RegisterTestFixture(TTesteCaracterizacaoConexao);

end.
