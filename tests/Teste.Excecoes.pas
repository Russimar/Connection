unit Teste.Excecoes;

{ T-02.01 — EConnectionException com campos de diagnostico (D-11, A-04). }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTesteExcecoes = class
  public
    [Test]
    procedure CapturavelComoExceptionEComoEConnectionException;
    [Test]
    procedure ExpoeTagArquivoIniEDataBase;
    [Test]
    procedure CreateFmtFormataMensagemEPreencheCampos;
  end;

implementation

uses
  System.SysUtils,
  Provider.Excecoes;

{ TTesteExcecoes }

procedure TTesteExcecoes.CapturavelComoExceptionEComoEConnectionException;
var
  LComoExcecaoGenerica : Boolean;
  LComoExcecaoTipada   : Boolean;
begin
  LComoExcecaoGenerica := False;
  try
    raise EConnectionException.Create('falha de teste');
  except
    on E: Exception do
      LComoExcecaoGenerica := True;
  end;

  LComoExcecaoTipada := False;
  try
    raise EConnectionException.Create('falha de teste');
  except
    on E: EConnectionException do
      LComoExcecaoTipada := True;
  end;

  Assert.IsTrue(LComoExcecaoGenerica,
    'EConnectionException deve ser capturavel como Exception, para nao quebrar consumidores');
  Assert.IsTrue(LComoExcecaoTipada,
    'EConnectionException deve ser capturavel pelo proprio tipo');
end;

procedure TTesteExcecoes.ExpoeTagArquivoIniEDataBase;
var
  LTag, LIni, LBanco : String;
begin
  LTag   := EmptyStr;
  LIni   := EmptyStr;
  LBanco := EmptyStr;
  try
    raise EConnectionException.Create('falha', 'AFSELF', 'C:/app/config.ini',
      'C:/dados/Banco.fdb');
  except
    on E: EConnectionException do
    begin
      LTag   := E.Tag;
      LIni   := E.ArquivoIni;
      LBanco := E.DataBase;
    end;
  end;

  Assert.AreEqual('AFSELF', LTag, 'Tag');
  Assert.AreEqual('C:/app/config.ini', LIni, 'ArquivoIni');
  Assert.AreEqual('C:/dados/Banco.fdb', LBanco, 'DataBase');
end;

procedure TTesteExcecoes.CreateFmtFormataMensagemEPreencheCampos;
var
  LMensagem, LTag : String;
begin
  LMensagem := EmptyStr;
  LTag      := EmptyStr;
  try
    raise EConnectionException.CreateFmt('Falha ao conectar em "%s": %s',
      ['Banco.fdb', 'servidor fora do ar'], 'PDV', 'config.ini', 'Banco.fdb');
  except
    on E: EConnectionException do
    begin
      LMensagem := E.Message;
      LTag      := E.Tag;
    end;
  end;

  Assert.AreEqual('Falha ao conectar em "Banco.fdb": servidor fora do ar', LMensagem,
    'Mensagem formatada');
  Assert.AreEqual('PDV', LTag, 'Tag preenchida pelo CreateFmt');
end;

initialization

TDUnitX.RegisterTestFixture(TTesteExcecoes);

end.
