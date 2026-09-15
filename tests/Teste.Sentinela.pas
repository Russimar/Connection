unit Teste.Sentinela;

{ Teste-sentinela: comprova que o runner DUnitX esta operante antes de
  qualquer teste da biblioteca. Se este teste nao aparece no sumario, o
  problema e do harness, nao do codigo sob teste. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTesteSentinela = class
  public
    [Test]
    procedure RunnerEstaOperante;
  end;

implementation

{ TTesteSentinela }

procedure TTesteSentinela.RunnerEstaOperante;
begin
  Assert.AreEqual(2, 1 + 1, 'O runner DUnitX nao esta executando asserts');
end;

initialization

TDUnitX.RegisterTestFixture(TTesteSentinela);

end.
