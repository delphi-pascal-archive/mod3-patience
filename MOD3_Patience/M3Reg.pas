unit M3Reg;         // R�gles du jeu

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
    { D�clarations priv�es }
  public
    { D�clarations publiques }
  end;

var
  Regles: TRegles;

implementation

{$R *.DFM}

end.
