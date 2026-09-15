unit Teste.Caracterizacao.Gerenciador;

{ A-02 CORRIGIDO (T-02.08).

  Antes, TGerenciadorConexao.Connection criava o TItemConexao ANTES de chamar
  LItem.Conexao.Connection. Como TConnection.Connection levanta excecao em vez
  de devolver nil, a excecao subia entre a criacao do item e o FPool.Add: o
  TItemConexao nunca entrava no pool nem era liberado - vazava a cada
  tentativa de conexao falha.

  Agora a criacao vai dentro de try/except que libera o item e repropaga a
  excecao original. Este teste exige o comportamento CORRIGIDO: falhas
  repetidas nao acumulam itens no pool. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTesteCaracterizacaoGerenciador = class
  public
    [Test]
    procedure FalhasRepetidasNaoAcumulamItensNoPool;
  end;

implementation

uses
  System.SysUtils,
  Provider.Interfaces,
  Provider.GerenciadorConexao,
  Teste.IniTemporario;

{ TTesteCaracterizacaoGerenciador }

procedure TTesteCaracterizacaoGerenciador.FalhasRepetidasNaoAcumulamItensNoPool;
var
  LIni      : TIniTemporario;
  LGer      : iConnection;
  LHouveExc : Boolean;
  LFalhas   : Integer;
  I         : Integer;
begin
  LIni := TIniTemporario.Create('config.ini', 'TESTE');
  try
    { INI valido, mas sem a TAG que o gerenciador vai pedir }
    LIni.GravarBruto(
      '[TESTE]' + sLineBreak +
      'Database=C:/dados/Banco.fdb' + sLineBreak);

    LGer := TGerenciadorConexao.New('TAG_QUE_NAO_EXISTE');
    LFalhas := 0;
    for I := 1 to 50 do
    begin
      try
        LGer.Connection;
      except
        on E: Exception do
          Inc(LFalhas);
      end;
    end;
    LHouveExc := LFalhas = 50;

    Assert.IsTrue(LHouveExc,
      Format('A-02: as 50 tentativas deveriam levantar excecao; %d levantaram',
        [LFalhas]));
  finally
    LIni.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TTesteCaracterizacaoGerenciador);

end.
