unit Provider.Query;

interface

uses
  Provider.Interfaces,
  Provider.Conexao,
  FireDAC.Comp.Client,
  FireDAC.Stan.Intf,
  FireDAC.Stan.Option,
  FireDAC.Stan.Param,
  FireDAC.Stan.Error,
  FireDAC.DatS,
  FireDAC.Phys.Intf,
  FireDAC.DApt.Intf,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.Comp.DataSet,
  Data.DB;

type
  TQuery = class(TInterfacedObject, iQuery)
  private
    FParent: iConnection;
    FQuery: TFDQuery;
  public
    class function New(Parent: iConnection): iQuery;
    constructor create(Parent: iConnection);
    destructor Destroy; override;
    function SQL(Value: String): iQuery;
    function Query: TFDQuery;
    function DataSet: TDataSet;
    function AddParam(Field : String; AValue : Variant) : iQuery;
    function Open: TFDQuery;
    function ExecSQL(AValue : String) : iQuery;
  end;

implementation

uses
  System.SysUtils,
  Provider.Excecoes;

{ MinhaClasse }

function TQuery.AddParam(Field : String; AValue : Variant) : iQuery;
begin
  Result := Self;
  FQuery.ParamByName(Field).Value := AValue;
end;

constructor TQuery.create(Parent: iConnection);
var
  LConexao : TCustomConnection;
begin
  { A-01: o fallback para uma TAG literal gravada na biblioteca foi removido.
    Um TQuery construido sem Parent conectava silenciosamente a um banco que o
    chamador nunca pediu - e, quando falhava, a mensagem citava uma TAG alheia.
    Agora o Parent e obrigatorio. }
  if not Assigned(Parent) then
    raise EConnectionException.Create(
      'TQuery exige uma conexao (Parent). Informe TConnection.New(''SUA_TAG'') ' +
      'ou TGerenciadorConexao.New(''SUA_TAG'').');

  FParent := Parent;
  FQuery  := TFDQuery.create(nil);

  { Defesa em profundidade: pelo contrato de iConnection, Connection nunca
    devolve nil. Se uma implementacao violar o contrato, o cast direto
    devolveria nil silenciosamente (nil as T e nil em Object Pascal) e a falha
    so apareceria no Open, longe da causa. }
  LConexao := FParent.Connection;
  if not Assigned(LConexao) then
    raise EConnectionException.Create(
      'A implementacao de iConnection devolveu nil, violando o contrato: ' +
      'Connection deve levantar excecao em vez de devolver nil.');

  FQuery.Connection := LConexao as TFDCustomConnection;
end;

function TQuery.DataSet: TDataSet;
begin
  Result := FQuery;
end;

destructor TQuery.Destroy;
begin
  FreeAndNil(FQuery);
  inherited;
end;

function TQuery.ExecSQL(AValue : String) : iQuery;
begin
  Result := Self;
  FQuery.ExecSQL(AValue);
end;

class function TQuery.New(Parent: iConnection): iQuery;
begin
  Result := Self.create(Parent);
end;

function TQuery.Open: TFDQuery;
begin
  FQuery.Open();
  Result := FQuery;
end;

function TQuery.Query: TFDQuery;
begin
  Result := FQuery;
end;

function TQuery.SQL(Value: String): iQuery;
begin
  Result := Self;
  FQuery.SQL.Clear;
  FQuery.SQL.Add(Value);
//  FQuery.Open;
end;

end.
