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
    destructor destroy; override;
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
  vcl.Dialogs;

{ MinhaClasse }

function TQuery.AddParam(Field : String; AValue : Variant) : iQuery;
begin
  Result := Self;
  FQuery.ParamByName(Field).Value := AValue;
end;

constructor TQuery.create(Parent: iConnection);
begin
  FParent := Parent;
  if not Assigned(FParent) then
    FParent := TConnection.New('PDV');
  FQuery := TFDQuery.create(nil);
  FQuery.Connection := FParent.Connection as TFDCustomConnection;
end;

function TQuery.DataSet: TDataSet;
begin
  Result := FQuery;
end;

destructor TQuery.destroy;
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
end;

function TQuery.Query: TFDQuery;
begin
//  Result := Self.create();

end;

function TQuery.SQL(Value: String): iQuery;
begin
  Result := Self;
  FQuery.SQL.Clear;
  FQuery.SQL.Add(Value);
//  FQuery.Open;
end;

end.
