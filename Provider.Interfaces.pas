unit Provider.Interfaces;

interface

uses
  System.JSON,
  Data.DB,
  FireDAC.Comp.Client;

type
  iConnection = interface
  ['{80499E92-59C8-4940-9089-60C0DB97273D}']
    function Connection : TCustomConnection;
  end;

  iQuery = interface
  ['{55678AD8-7FF0-4D5B-81C2-1EE4C775104F}']
    function SQL(Value : String) : iQuery;
    function Query : TFDQuery;
    function DataSet : TDataSet;
    function AddParam(Field : String; AValue : Variant) : iQuery;
    function Open : TFDQuery;
    function ExecSQL(AValue : String) : iQuery;
  end;

  iEntidade = interface
  ['{7BCC9612-7054-449A-954E-7C38E1E3C8CF}']
  function Listar(AValue : TDataSource): iEntidade;
  function ListarId(AId : Variant; AValue : TDataSource): iEntidade;
  function GravarId(Aid : Variant) : iEntidade;
  end;

implementation

end.
