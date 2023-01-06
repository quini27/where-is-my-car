program Where_Is_my_car;

uses
  System.StartUpCopy,
  FMX.Forms,
  UnitCar in 'UnitCar.pas' {Form5};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm5, Form5);
  Application.Run;
end.
