program client;

uses
  madExcept,
  madLinkDisAsm,
  madListModules,
  {fastmm4,} //your choice
  Forms,
  Unit1 in 'Unit1.pas' {Form1},
  LibEWFUnit in 'LibEWFUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
