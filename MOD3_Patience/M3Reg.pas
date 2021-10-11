unit M3Reg;         // Règles du jeu

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls;

type
  TRegles = class(TForm)
    NulBox: TListBox;
    Label1: TLabel;
    Label10: TLabel;
    Image1: TImage;
    Panel1: TPanel;
    Image7: TImage;
    Label2: TLabel;
    Memo1: TMemo;
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  Regles: TRegles;

implementation

{$R *.DFM}

end.
