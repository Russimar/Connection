unit Provider.Excecoes;

{ Excecao tipada da biblioteca Connection (A-04).

  Herda de Exception, portanto continua sendo capturada por qualquer
  "except on E: Exception" existente — a adicao nao quebra consumidor algum.
  O que ela acrescenta e diagnostico: quem captura consegue distinguir falha
  de infraestrutura de erro de programacao e sabe QUAL tag, QUAL arquivo de
  configuracao e QUAL banco estavam envolvidos, sem depender de parsing da
  mensagem de texto. }

interface

uses
  System.SysUtils;

type
  EConnectionException = class(Exception)
  private
    FTag         : String;
    FArquivoIni  : String;
    FDataBase    : String;
  public
    constructor Create(const AMensagem: String); overload;
    constructor Create(const AMensagem, ATag, AArquivoIni, ADataBase: String); overload;
    constructor CreateFmt(const AMensagem: String; const AArgs: array of const;
      const ATag, AArquivoIni, ADataBase: String); overload;

    { TAG do banco pedida pelo consumidor; vazia quando nao se aplica. }
    property Tag: String read FTag;
    { Caminho do arquivo .ini efetivamente resolvido; vazio quando nao se aplica. }
    property ArquivoIni: String read FArquivoIni;
    { Caminho do banco de dados; vazio quando nao se aplica. }
    property DataBase: String read FDataBase;
  end;

implementation

{ EConnectionException }

constructor EConnectionException.Create(const AMensagem: String);
begin
  inherited Create(AMensagem);
  FTag        := EmptyStr;
  FArquivoIni := EmptyStr;
  FDataBase   := EmptyStr;
end;

constructor EConnectionException.Create(const AMensagem, ATag, AArquivoIni,
  ADataBase: String);
begin
  inherited Create(AMensagem);
  FTag        := ATag;
  FArquivoIni := AArquivoIni;
  FDataBase   := ADataBase;
end;

constructor EConnectionException.CreateFmt(const AMensagem: String;
  const AArgs: array of const; const ATag, AArquivoIni, ADataBase: String);
begin
  inherited CreateFmt(AMensagem, AArgs);
  FTag        := ATag;
  FArquivoIni := AArquivoIni;
  FDataBase   := ADataBase;
end;

end.
