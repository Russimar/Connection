unit Provider.Interfaces;

interface

uses
  System.JSON,
  Data.DB;

type
  iConnection = interface
  ['{80499E92-59C8-4940-9089-60C0DB97273D}']
    function Connection : TCustomConnection;
  end;

implementation

end.
