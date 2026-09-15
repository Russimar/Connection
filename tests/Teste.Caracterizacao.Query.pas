unit Teste.Caracterizacao.Query;

{ A-01 CORRIGIDO (T-02.10).

  Antes, TQuery.create com Parent nil recorria a TConnection.New('PDV'): a TAG
  estava gravada no codigo da biblioteca, e um consumidor que nunca pediu
  'PDV' recebia erro citando uma TAG alheia — ou conectava ao banco errado se
  a secao existisse.

  Agora o Parent e obrigatorio e a excecao diz exatamente isso.

  Nota (D-22): a SPEC afirmava que o cast sobre nil levantaria EInvalidCast.
  Em Object Pascal, nil as T devolve nil silenciosamente, e o sintoma real
  seria falha tardia no Open - por isso a correcao valida Assigned antes do
  cast, em vez de confiar no operador as. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTesteCaracterizacaoQuery = class
  public
    [Test]
    procedure ParentNilLevantaExcecaoExigindoOParent;
  end;

implementation

uses
  System.SysUtils,
  Provider.Interfaces,
  Provider.Query,
  Teste.IniTemporario;

{ TTesteCaracterizacaoQuery }

procedure TTesteCaracterizacaoQuery.ParentNilLevantaExcecaoExigindoOParent;
var
  LIni      : TIniTemporario;
  LMensagem : String;
begin
  LIni := TIniTemporario.Create('config.ini', 'TESTE');
  try
    { INI valido, sem a secao PDV }
    LIni.GravarBruto(
      '[TESTE]' + sLineBreak +
      'Database=C:/dados/Banco.fdb' + sLineBreak);

    LMensagem := EmptyStr;
    try
      TQuery.New(nil);
    except
      on E: Exception do
        LMensagem := E.Message;
    end;

    Assert.IsNotEmpty(LMensagem,
      'Esperada excecao ao construir TQuery sem Parent');
    Assert.Contains(LMensagem, 'Parent',
      'A-01: a excecao deve exigir o Parent. Mensagem recebida: ' + LMensagem);
    Assert.DoesNotContain(LMensagem, 'PDV',
      'A-01: a mensagem nao pode mais citar a TAG literal PDV. ' +
      'Mensagem recebida: ' + LMensagem);
  finally
    LIni.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TTesteCaracterizacaoQuery);

end.
