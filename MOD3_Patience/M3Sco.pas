unit M3Sco;      // Affiche la liste des parties jouées

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TScore = class(TForm)
    Lisco: TListBox;
    procedure FormShow(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  Score: TScore;

implementation

{$R *.DFM}

procedure TScore.FormShow(Sender: TObject);
begin
  Lisco.Items.LoadFromFile('Mod3.txt');
end;

end.
