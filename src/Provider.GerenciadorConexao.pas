unit Provider.GerenciadorConexao;

{ Pool de conexões thread-local com limpeza automática por inatividade.

  Cada thread do servidor HTTP (Indy) obtém sua própria conexão Firebird.
  Não há bloqueio entre threads — sem contenção, sem fila de espera.

  Conexões inativas por mais de MaxIdleSegundos são fechadas automaticamente
  por TThreadLimpeza, liberando recursos sem intervenção manual.

  Baseado em Core.Connection do ClientIntegrador, evoluído para pool por thread.

  USO: substituir TConnection.New('TAG') por TGerenciadorConexao.New('TAG') no Bootstrap.
  TConnection, TQuery e todos os demais arquivos permanecem sem alteração. }

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.SyncObjs,
  System.Classes,
  Provider.Interfaces,
  Provider.Conexao,
  FireDAC.Comp.Client, Data.DB,
  GravarLog;

type
  { Item mantido no pool: uma conexão Firebird por thread }
  TItemConexao = class
  public
    Conexao   : iConnection;    { TConnection — dono do TFDConnection }
    FDConn    : TFDConnection;  { referência cacheada para checagem rápida }
    UltimoUso : TDateTime;
  end;

  { Thread de limpeza — fecha conexões inativas periodicamente }
  TThreadLimpeza = class(TThread)
  private
    FGerenciador : TObject;   { TGerenciadorConexao — evita dependência de tipo circular }
    FEvento      : TEvent;    { sinalizado no SolicitarParada para acordar imediatamente }
    FIntervaloMs : Cardinal;
  protected
    procedure Execute; override;
  public
    constructor Create(AGerenciador: TObject; AIntervaloMs: Cardinal);
    destructor Destroy; override;
    procedure SolicitarParada;
  end;

  { Pool thread-local de conexões Firebird.
    Implementa iConnection para ser injetado no lugar de TConnection no Bootstrap. }
  TGerenciadorConexao = class(TInterfacedObject, iConnection)
  strict private
    FTag             : String;
    FMaxIdleSegundos : Integer;
    FLock            : TCriticalSection;
    FPool            : TDictionary<Cardinal, TItemConexao>;
    FThreadLimpeza   : TThreadLimpeza;
  protected
    procedure LimparInativas;
  public
    class function New(const ATag: String;
                       AMaxIdleSegundos: Integer = 60): iConnection;
    constructor Create(const ATag: String; AMaxIdleSegundos: Integer);
    destructor Destroy; override;
    function Connection: TCustomConnection;
    function ArquivoConfiguracao(const AValue: String): iConnection; overload;
    function ArquivoConfiguracao: String; overload;
    function Reconectar: iConnection;
  end;

implementation

uses
  System.DateUtils,
  Provider.Excecoes;

{ TThreadLimpeza }

constructor TThreadLimpeza.Create(AGerenciador: TObject; AIntervaloMs: Cardinal);
begin
  FGerenciador    := AGerenciador;
  FIntervaloMs    := AIntervaloMs;
  FEvento         := TEvent.Create(nil, False, False, '');
  FreeOnTerminate := False;
  inherited Create(False);
end;

destructor TThreadLimpeza.Destroy;
begin
  FEvento.Free;
  inherited;
end;

procedure TThreadLimpeza.SolicitarParada;
begin
  Terminate;
  FEvento.SetEvent;   { acorda o WaitFor imediatamente }
end;

procedure TThreadLimpeza.Execute;
begin
  while not Terminated do
  begin
    FEvento.WaitFor(FIntervaloMs);   { aguarda intervalo OU sinalização de parada }
    if not Terminated then
      TGerenciadorConexao(FGerenciador).LimparInativas;
  end;
end;

{ TGerenciadorConexao }

class function TGerenciadorConexao.New(const ATag: String;
  AMaxIdleSegundos: Integer): iConnection;
begin
  Result := Self.Create(ATag, AMaxIdleSegundos);
end;

constructor TGerenciadorConexao.Create(const ATag: String; AMaxIdleSegundos: Integer);
begin
  inherited Create;
  FTag             := ATag;
  FMaxIdleSegundos := AMaxIdleSegundos;
  FLock            := TCriticalSection.Create;
  FPool            := TDictionary<Cardinal, TItemConexao>.Create;
  { Limpeza a cada 30 segundos (metade do tempo máximo de inatividade padrão) }
  FThreadLimpeza   := TThreadLimpeza.Create(Self, 30000);
end;

destructor TGerenciadorConexao.Destroy;
var
  LItem: TItemConexao;
begin
  FThreadLimpeza.SolicitarParada;
  FThreadLimpeza.WaitFor;
  FreeAndNil(FThreadLimpeza);

  FLock.Enter;
  try
    for LItem in FPool.Values do
    begin
      LItem.Conexao := nil;  { libera iConnection -> TConnection.Destroy -> FConn.Free }
      LItem.Free;
    end;
    FreeAndNil(FPool);
  finally
    FLock.Leave;
  end;
  FreeAndNil(FLock);
  inherited;
end;

function TGerenciadorConexao.Connection: TCustomConnection;
var
  LThreadID : Cardinal;
  LItem     : TItemConexao;
  LConn     : TCustomConnection;
begin
  LThreadID := TThread.CurrentThread.ThreadID;

  FLock.Enter;
  try
    { Caminho rápido: conexão existente para esta thread e ainda ativa }
    if FPool.TryGetValue(LThreadID, LItem) then
    begin
      if Assigned(LItem.FDConn) and LItem.FDConn.Connected then
      begin
        LItem.UltimoUso := Now;
        Result := LItem.FDConn;
        Exit;
      end;
      { Conexão caiu — remove do pool e cria nova abaixo }
      LItem.Conexao := nil;
      LItem.Free;
      FPool.Remove(LThreadID);
    end;

    { Nova conexao para esta thread.

      A-02: a criacao vai dentro de try/except porque TConnection.Connection
      levanta excecao em vez de devolver nil. Sem isso, a excecao subia entre
      o TItemConexao.Create e o FPool.Add, e o item recem-criado nunca era
      adicionado ao pool nem liberado - vazava a cada tentativa falha. }
    LItem := TItemConexao.Create;
    try
      LItem.Conexao := TConnection.New(FTag);
      LConn         := LItem.Conexao.Connection;
      LItem.FDConn  := LConn as TFDConnection;
    except
      LItem.Conexao := nil;
      LItem.Free;
      raise;   { repropaga a excecao original, sem mascarar a causa }
    end;
    LItem.UltimoUso := Now;
    FPool.Add(LThreadID, LItem);
    TGravarLog.New.doSaveLog(Format('Pool: conexao criada para a thread %d (TAG "%s")',
      [LThreadID, FTag]));
    Result := LItem.FDConn;
  finally
    FLock.Leave;
  end;
end;

function TGerenciadorConexao.ArquivoConfiguracao(const AValue: String): iConnection;
begin
  { O pool nao guarda configuracao propria: cada TConnection do pool resolve o
    seu arquivo. Definir aqui valeria so para as conexoes criadas a seguir, o
    que seria uma armadilha - por isso o pool recusa a chamada. }
  Result := Self;
  raise EConnectionException.Create(
    'TGerenciadorConexao nao aceita arquivo de configuracao explicito; ' +
    'use TConnection diretamente quando precisar escolher o arquivo.');
end;

function TGerenciadorConexao.ArquivoConfiguracao: String;
var
  LConnAux : iConnection;
begin
  { Resolve pela mesma regra que as conexoes do pool usarao. }
  LConnAux := TConnection.New(FTag);
  Result   := LConnAux.ArquivoConfiguracao;
end;

function TGerenciadorConexao.Reconectar: iConnection;
var
  LThreadID : Cardinal;
  LItem     : TItemConexao;
begin
  Result    := Self;
  LThreadID := TThread.CurrentThread.ThreadID;
  FLock.Enter;
  try
    if FPool.TryGetValue(LThreadID, LItem) then
    begin
      LItem.Conexao := nil;
      LItem.Free;
      FPool.Remove(LThreadID);
      TGravarLog.New.doSaveLog(
        Format('Pool: conexao descartada por Reconectar na thread %d (TAG "%s")',
          [LThreadID, FTag]));
    end;
  finally
    FLock.Leave;
  end;
  Connection;   { recria ja com a configuracao relida }
end;

procedure TGerenciadorConexao.LimparInativas;
var
  LParaRemover : TList<Cardinal>;
  LThreadID    : Cardinal;
  LItem        : TItemConexao;
  LLimite      : TDateTime;
begin
  LLimite      := Now - FMaxIdleSegundos / SecsPerDay;
  LParaRemover := TList<Cardinal>.Create;
  try
    FLock.Enter;
    try
      for LThreadID in FPool.Keys do
        if FPool[LThreadID].UltimoUso < LLimite then
          LParaRemover.Add(LThreadID);

      for LThreadID in LParaRemover do
      begin
        LItem         := FPool[LThreadID];
        LItem.Conexao := nil;   { fecha a conexão Firebird }
        LItem.Free;
        FPool.Remove(LThreadID);
        TGravarLog.New.doSaveLog(
          Format('Pool: conexao descartada por inatividade na thread %d (TAG "%s")',
            [LThreadID, FTag]));
      end;
    finally
      FLock.Leave;
    end;
  finally
    LParaRemover.Free;
  end;
end;

end.
