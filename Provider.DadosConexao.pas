unit Provider.DadosConexao;

interface

type
  TDadosConexao = record
    DataBase : String;
    UserName : String;
    PassWord : String;
    Timer : Integer;
    Usuario : String;
    Senha : String;
    Porta : Integer;
  end;

  TDadosScanntech = record
    Terminal      : String;
    URLMovimento  : String;
    URLFechamento : String;
    URLPromocao   : String;
  end;

implementation

end.
