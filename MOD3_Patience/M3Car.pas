unit M3Car;     // Gestion du jeu de cartes
                { Le jeu est chargé en stream mémoire à partir du fichier
                  Jeu104.pak, contenant 2 fois 52 cartes plus quelques images
                  suppléméntaires tel que dos de carte, joker, emplacement
                  marqué et vide. Ce fichier a été créé à l'aide de
                http://www.delphifr.com/codes/GESTION-BANQUE-IMAGE_48789.aspx }
interface

uses
  Windows, SysUtils, Classes, Graphics, Controls, StdCtrls, ExtCtrls,
  Dialogs, Jpeg;

const             // à adapter au jeu
  kc_lg = 89;     // largeur d'une carte
  kc_ht = 120;    // hauteur d'une carte
  kt_lg = 940;    // largeur du tapis
  kt_ht = 660;    // hauteur du tapis
  kp_nb = 34;     // nbre de piles
  kx : array[1..9] of integer =(10,110,210,310,410,510,610,710,830);
  ky : array[1..4] of integer =(10,170,330,490);

type
  TPile = record
            ctr  : byte;      // nbre de cartes dans la pile
            px,py : integer;  // Position
            fam  : byte;
            fig  : array[1..4] of byte;
            cart : array[1..104] of byte;  // n° des cartes
          end;
  TCarte = record              // Définition d'une carte
             face,
             figure,           // 1 = As..13 = Roi
             famille,          // 1 = pique, 2 = coeur, 3 = trèfle, 4 = carreau
             couleur,          // 1,3 = noir - 2,4 = rouge
             valeur : byte;    // par défaut = figure
             bdos : boolean;   // sens : true = dos, false = face
             cx,cy : integer;  // position coin supérieur
             fond : TBitmap;   // sauvegarde du fond sous la carte
           end;
  TParima = record               // Paramètres image
              posima : integer;      // position de l'image dans le stream
              taille : integer;      // taille de l'image
              ftype  : integer;      // 0 = bitmap - 1 = jpeg
              imx    : integer;
              imy    : integer;
              nom    : string[11];
            end;
  TJeu104 = array[0..107] of TCarte;  // Le jeu de 52104 cartes

var
  Jpgim : TJPEGImage;
  ImaStrm : TMemoryStream;
  ImaFile : TFileName;
  FileStrm : TFileStream;
  Nbima : integer;
  tbPima : array[0..107] of TParima;

  Jeu104 : TJeu104;    // le jeu de 2 fois 52 cartes
  Tapis : TBitmap;     // image du tapis de jeu
  Tbcar : array[1..104] of byte;  // jeu mélangé
  pile : array[1..kp_nb] of TPile;

  procedure Initialise;
  procedure Libere;
  procedure ChargerLePaquet;
  procedure LaCarte(no : byte; var bmp : TBitmap);
  procedure InitialiseJeu;
  procedure EffaceJeu;
  procedure Melange;
  procedure SauveFond(x,y : integer; ca : byte);
  procedure AfficheCarte(x,y : integer; ca : byte; aff : boolean = true);
  procedure RetourneCarte(ca : byte);
  procedure AfficheFond(ca : byte);
  procedure DeplaceCarte(ca : byte; x,y : integer);
  procedure MoveCarte(ca : byte; x,y : integer);

implementation

uses M3Main;

var
  nompk : string = 'Jeu104.pak';
  rec : TRect;     // dimensions d'une carte

procedure Initialise;
begin
  Jpgim := TJPEGImage.Create;
  ImaStrm := TMemoryStream.Create;
  ChargerLePaquet;
end;

procedure Libere;
var  i : byte;
begin
  Jpgim.Free;
  ImaStrm.Free;
  for i := 1 to 104 do jeu104[i].fond.Free;
end;

procedure ChargerLePaquet;
var  lg : integer;
begin
  try
    FileStrm := TFileStream.Create(nompk,fmOpenRead); // initialise en lecture
    FileStrm.ReadBuffer(Nbima,SizeOf(integer));
    for lg := 0 to 107 do                     // table des paramètres images
      FileStrm.ReadBuffer(tbPima[lg],SizeOf(TParima));
    FileStrm.ReadBuffer(lg,SizeOf(integer));    // longueur du stream d'images
    ImaStrm.Clear;
    Imastrm.Position := 0;
    ImaStrm.CopyFrom(FileStrm,lg);              // stream d'images
  finally
    FileStrm.Free;
  end;
end;

procedure LaCarte(no : byte; var bmp : TBitmap);  // Lecture à partir du stream
var  MemS : TMemoryStream;                        // no : numéro de la carte
begin                                             // bmp : reçoit l'image
  ImaStrm.Position := tbPima[no].posima;
  MemS := TMemoryStream.Create;
  try
    MemS.SetSize(tbPima[no].taille);
    MemS.CopyFrom(ImaStrm,tbPima[no].taille);
    MemS.Position := 0;
    jpgim.LoadFromStream(Mems);
    bmp.Assign(jpgim);
  finally
    MemS.Free;
  end;
end;

procedure InitialiseJeu;
var  ca : byte;
begin
  Randomize;
  rec := Rect(0,0,kc_lg,kc_ht);
  for ca := 1 to 104 do    // initialisation des cartes
  begin
    with Jeu104[ca] do
    begin
      face := ca;
      fond := TBitmap.Create;
      fond.Height := kc_ht;
      fond.Width := kc_lg;
      case ca of
         1..13 : begin
                   figure := ca;
                   famille := 1;
                   couleur := 1;
                 end;
        14..26 : begin
                   figure := ca-13;
                   famille := 2;
                   couleur := 2;
                  end;
        27..39 : begin
                   figure := ca-26;
                   famille := 3;
                   couleur := 1;
                 end;
        40..52 : begin
                   figure := ca-39;
                   famille := 4;
                   couleur := 2;
                 end;
        53..65 : begin
                   figure := ca-52;
                   famille := 1;
                   couleur := 1;
                 end;
        66..78 : begin
                   figure := ca-65;
                   famille := 2;
                   couleur := 2;
                  end;
        79..91 : begin
                   figure := ca-78;
                   famille := 3;
                   couleur := 1;
                 end;
        92..104 : begin
                   figure := ca-91;
                   famille := 4;
                   couleur := 2;
                 end;
      end;
      valeur := figure;
      bdos := false;
      cx := 0;
      cy := 0;
    end;
  end;
end;

procedure EffaceJeu;
begin
  Tapis := TBitmap.Create;
  Tapis.Width := kt_lg;
  Tapis.Height := kt_ht;
  Tapis.Canvas.Pen.Color := clGreen;
  Tapis.Canvas.Brush.Color := clGreen;
  Tapis.Canvas.Rectangle(Rect(0,0,kt_lg,kt_ht));
end;

procedure Melange;
var  i,c,n : byte;
begin
  for i := 1 to 104 do Tbcar[i] := i;     // on charge la table avec les
                                          // valeurs 1..104 (rang dans le jeu),
  for i := 1 to 104 do                    // puis on mélange le tout.
  begin
    n := Random(i)+1;
    c := Tbcar[n];
    Tbcar[n] := Tbcar[i];
    Tbcar[i] := c;
    Jeu104[i].bdos := false;
  end;
end;

procedure SauveFond(x,y : integer; ca : byte); // avant affichage d'une carte
begin
  with Jeu104[ca] do
    fond.Canvas.CopyRect(rec,Tapis.Canvas,Rect(x,y,x+kc_lg,y+kc_ht));
end;

procedure AfficheCarte(x,y : integer; ca : byte; aff : boolean = true);
var  bmp : TBitmap;
begin
  bmp := TBitmap.Create;
  case ca of                       // ca :rang de la carte
    0 : LaCarte(0,bmp);            // Dos
    1..104 : with Jeu104[ca] do
             begin
               cx := x;
               cy := y;
               SauveFond(x,y,ca);
               if bdos then LaCarte(0,bmp)
               else LaCarte(ca,bmp);

             end;
    105 : LaCarte(105,bmp);    // joker
    106 : LaCarte(106,bmp);    // emplacement
    107 : LaCarte(107,bmp);    // vide
  end;
  Tapis.Canvas.Draw(x,y,bmp);
  bmp.Free;
//--------------------------------------------------------------
  if aff then FMain.PBox.Repaint;     // à adapter à Form.PaintBox utilisé
//--------------------------------------------------------------
end;

procedure RetourneCarte(ca : byte);
begin                      // retourne une carte côté face ou dos
  with Jeu104[ca] do        // ca :rang de la carte (1..104)
  begin
    bdos := not bdos;
    AfficheCarte(cx,cy,ca,true);
  end;
end;

procedure AfficheFond(ca : byte);  // ca :rang de la carte (1..104)
begin
  with Jeu104[ca] do
    Tapis.Canvas.Draw(cx,cy,fond);
end;

procedure DeplaceCarte(ca : byte; x,y : integer);
begin                           // ca :rang de la carte (1..104)
  with Jeu104[ca] do             // x,y : nouvelle position
  begin
    AfficheFond(ca);
    AfficheCarte(x,y,ca,true);
  end;
end;

procedure MoveCarte(ca : byte; x,y : integer);
var  ecx,ecy,
     xa,ya,xd,yd,pas : integer;
begin
  xa := x;      // position finale
  ya := y;
  xd := Jeu104[ca].cx;          // position initiale de la pièce
  yd := Jeu104[ca].cy;
  pas := 15;
  repeat
    ecx := (xa-xd) div pas;    // longueur d'un pas
    ecy := (ya-yd) div pas;
    xd := xd+ecx;
    yd := yd+ecy;
    DeplaceCarte(ca,xd,yd);
    dec(pas);
    sleep(10);
  until pas = 0;
end;

end.
