program Mod3;

uses
  Forms,
  M3Main in 'M3Main.pas' {FMain},
  M3Car in 'M3Car.pas',
  M3Fin in 'M3Fin.pas' {DlgFin},
  M3Sco in 'M3Sco.pas' {Score},
  M3Reg in 'M3Reg.pas' {Regles};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFMain, FMain);
  Application.CreateForm(TDlgFin, DlgFin);
  Application.CreateForm(TScore, Score);
  Application.CreateForm(TRegles, Regles);
  Application.Run;
end.
