unit M3Sco;      // Affiche la liste des parties jou�es

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TScore = class(TForm)
    Lisco: TListBox;
    procedure FormShow(Sender: TObject);
  private
    { D�clarations priv�es }
  public
    { D�clarations publiques }
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
