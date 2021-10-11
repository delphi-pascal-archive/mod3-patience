unit M3Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls;

type
  TFMain = class(TForm)
    PBox: TPaintBox;
    BJouer: TButton;
    Pn3: TPanel;
    Pn1: TPanel;
    LbJg: TPanel;
    BRejouer: TButton;
    BAbandon: TButton;
    BQuitter: TButton;
    Inum: TImage;
    BScore: TButton;
    BRegles: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BAbandonClick(Sender: TObject);
    procedure BQuitterClick(Sender: TObject);
    procedure BJouerClick(Sender: TObject);
    procedure BRejouerClick(Sender: TObject);
    procedure PBoxPaint(Sender: TObject);
    procedure PBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Comptage;
    procedure Decharge;
    procedure Donne;
    procedure FinJeu;
    procedure NouveauRang;
    function QuellePile(x, y : integer) : byte;
    procedure AffichePile(pl : byte);
    procedure PoseCartes;
    procedure ChargeScore;
    procedure SauveScore;
    procedure AfficheGains;
    procedure BScoreClick(Sender: TObject);
    procedure BReglesClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);

  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  FMain: TFMain;

implementation

uses M3Car, M3Fin, M3Sco, M3Reg;

{$R *.dfm}

const
  nfsco = 'Mod3.sco';

 var
  pdeb, pfin : byte;                  // pile départ et arrivée carte déplacé
  fScore :  file;                     // fichier score
  pscore :array[1..65535] of byte;    // enregistrement du score
  maxnum,                             // jeu : numéro dernier jeu joué
  maxgan,                             //       nbre de jeu gagné
  numact : longint;                   //       numéro du jeu en cours
  ax,ay,dx,dy,sx,sy,nx,ny : integer;  // utilisés en déplacement de carte
  orct,orca,orfa,orfi : byte;         // origine : ctr,carte,famille,figure
  nbs,nbc : integer;                  // nbre de cartes sorties
  movOk : boolean = false;            // autorise le déplacement
  Mark : TShape;
//-----------------------------------------------------------------------------

procedure Trace(num : integer);
begin
  ShowMessage(IntToStr(num));
end;

procedure Trac2(n1,n2 : integer);
begin
  ShowMessage(IntToStr(n1)+' - '+IntToStr(n2));
end;

procedure TFMain.FormCreate(Sender: TObject);
var  i,j,p : byte;
begin
  ChargeScore;
  DoubleBuffered := true;
  KeyPreview := True;
  Initialise;
  InitialiseJeu;
  p := 0;
  for j := 1 to 4 do         // position des piles 1 à 32
    for i := 1 to 8 do       // et raz compteur de cartes
    begin
      inc(p);
      with pile[p] do
      begin
        px := kx[i];
        py := ky[j];
        ctr := 0;
      end;
    end;
  with pile[33] do          // idem pile 33 (les As)
  begin
    px := 830;
    py := 10;
    ctr := 0;
  end;
  with pile[34] do         // idem pile 34 (le talon)
  begin
    px := 830;
    py := 490;
    ctr := 0;
  end;
  for j := 1 to 8 do             // pour les piles 1 à 34, renseignement
    with pile[j] do              // des séquences de cartes autorisées
    begin
      fig[1] := 2;
      for i := 2 to 4 do
        fig[i] := fig[i-1]+3;
    end;
  for j := 9 to 16 do
    with pile[j] do
    begin
      fig[1] := 3;
      for i := 2 to 4 do
        fig[i] := fig[i-1]+3;
    end;
  for j := 17 to 24 do
    with pile[j] do
    begin
      fig[1] := 4;
      for i := 2 to 4 do
        fig[i] := fig[i-1]+3;
    end;
  Mark := TShape.Create(FMain);
    with Mark do
    begin
      Parent := FMain;
      Left := 860;
      Top := 470;
      Width := 40;
      Height := 40;
      Shape := stCircle;
      Brush.Color := $0000D7FF;
      Name := 'Mark';
      Visible := False;
    end;
end;

procedure TFMain.FormActivate(Sender: TObject);
begin
  AfficheGains;
end;

procedure TFMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SauveScore;
  Libere;
end;

procedure TFMain.BAbandonClick(Sender: TObject);
begin
  Finjeu;
end;

procedure TFMain.BQuitterClick(Sender: TObject);
begin
  Close;
end;

function MefNum(i : word) : string;
var  st : string;
begin
  st := IntToStr(i);
  while Length(st) < 6 do st := ' '+st;
  Result := st;
end;

procedure TFMain.BJouerClick(Sender: TObject);
begin
  EffaceJeu;
  numact := maxnum;
  Donne;
end;

procedure TFMain.BRejouerClick(Sender: TObject);
var ns, st : string;
    num : word;
begin
  ns := IntToStr(numact);
  st := 'Donnez le numéro du jeu...';
  if InputQuery('Rejouer une partie',st,ns) then
  begin
    num := StrToInt(ns);
    if (num > 0) and (num <= maxnum) then
    begin
      numact := num-1;
      EffaceJeu;
      Donne;
    end;
  end;
end;

procedure TFMain.Donne;             // distribution des cartes
var    ca,vi, vj, vp : byte;
begin
  Inc(numact);
  Pn1.Caption := 'Jeu  n° '+IntToStr(numact);
  RandSeed := numact;                       // on initialise la fonction Random
  if numact > maxnum then maxnum := numact; // avec le numéro du jeu
  for vi := 1 to 34 do pile[vi].ctr := 0;
  Melange;
  nbc := 104;
  with pile[34] do                  // Chargement du talon
    for vi := 1 to 104 do
    begin
      inc(ctr);
      ca := tbcar[vi];
      jeu104[ca].bdos := true;
      cart[vi] := ca;
      AfficheCarte(px,py,ca,false);
    end;
  Pbox.Repaint;
  vp := 0;
  for vj := 1 to 4 do              // distribution dans les piles et affichage
  begin
    for vi := 1 to 8 do
    begin
      inc(vp);
      ca := pile[34].cart[pile[34].ctr];
      dec(pile[34].ctr);
      jeu104[ca].bdos := false;
      with pile[vp] do
      begin
        ctr := 1;
        cart[1] := ca;
        fam := jeu104[ca].famille;
        dec(nbc);
        AfficheCarte(px,py,ca,true);
      end;
    end;
  end;
  Inum.Visible := true;   // affichage des séquences
  Decharge;
  Pn3.Caption := 'Reste '+IntToStr(pile[34].ctr)+' cartes';
end;

procedure TFMain.FinJeu;
begin
  if nbs = 24 then                 // jeu gagnant
  begin
    Inc(maxgan);
    pscore[numact] := 1;
    AfficheGains;
    DlgFin.Affiche(true);
    DlgFin.ShowModal;
  end
  else begin
         pscore[numact] := 9;
         AfficheGains;
         DlgFin.Affiche(false);
         DlgFin.ShowModal;
       end;
  Initialise;
end;

procedure TFMain.Comptage;        // séquences complètes
var  i : byte;
begin
  nbs := 0;
  for i := 1 to 24 do
    if pile[i].ctr = 4 then inc(nbs);
  if nbs = 24 then FinJeu;
end;

procedure TFMain.Decharge;      // mise à l'écart des As
var  i,ca,ec,ct : byte;
begin
  for i := 1 to 32 do
  begin
    ct := pile[i].ctr;
    if ct > 0 then
    begin
      ca := pile[i].cart[ct];
      if jeu104[ca].Figure = 1 then
      begin
        dec(pile[i].ctr);
        with pile[33] do
        begin
          inc(ctr);
          ec := (ctr-1)*20;
          MoveCarte(ca,px,py+ec);
          cart[ctr] := ca;              
        end;
      end;
    end;
  end;
end;

procedure TFMain.NouveauRang;       // affichage d'une nouvelle 4ème rangée
var i,ca,ct,n,p : byte;
begin
  if pile[34].ctr = 0 then exit;
  p := 0;
  for i := 25 to 32 do
    if pile[34].ctr > 0 then
    begin
      n := pile[i].ctr * 10;
      ct := pile[34].ctr;
      ca := pile[34].cart[ct];
      if jeu104[ca].Figure = 1 then p := i;
      jeu104[ca].bdos := false;
      MoveCarte(ca,kx[i-24],490+n);
      dec(pile[34].ctr);
      inc(pile[i].ctr);
      pile[i].cart[pile[i].ctr] := ca;
    end;
  if p > 0 then Decharge;
  Pn3.Caption := 'Reste '+IntToStr(pile[34].ctr)+' cartes';
end;

procedure TFMain.PBoxPaint(Sender: TObject);
begin
  Pbox.Canvas.Draw(0,0,Tapis);
end;

procedure TFMain.PBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  sx := X;
  sy := Y;
  pdeb := QuellePile(X,Y);
  if pdeb = 0 then exit;
  if pdeb = 34 then
  begin
    NouveauRang;
    exit;
  end;
  if pile[pdeb].ctr = 0 then        // pile vide
  begin
    pdeb := 0;
    Exit;
  end;
  with pile[pdeb] do
  begin
    orct := ctr;
    orca := cart[ctr];
  end;
  orfa := jeu104[orca].famille;
  orfi := jeu104[orca].figure;
  nx := jeu104[orca].cx;            // position actuelle de la carte
  ny := jeu104[orca].cy;
  ax := nx;
  ay := ny;
  dx := sx-nx;                     // décalage par rapport au curseur
  dy := sy-ny;
  movOk := true;
end;

procedure TFMain.PBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if not movOk then exit;
  nx := jeu104[orca].cx;
  ny := jeu104[orca].cy;
  sx := X-dx;                       // calcul nouvelle position
  sy := Y-dy;
  DeplaceCarte(orca,sx,sy);
end;

procedure TFMain.PBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then exit;
  pfin := QuellePile(X,Y);
  if pfin = 0 then movok := false;
  if not movOk then exit;
  PoseCartes;
  movOk := false;
  Decharge;
end;

procedure TFMain.PoseCartes; // affectation d'une carte à son nouvel emplacement
var  ca : byte;
     ok : boolean;
begin
  AfficheFond(orca);
  ok := false;
  with pile[pfin] do
  begin
    ca := cart[ctr];
    if pfin < 25 then     // contrôle de séquence pile 1 à 24
    begin
      if (ctr = 0) and (orfi = fig[1]) then
      begin
        fam := orfa;
        ok := true;
      end;
      if (ctr in[1..3]) and (orfi = fig[ctr+1]) and
         (fam = orfa) then
           if orfi = jeu104[ca].figure+3 then ok := true;
    end;
    if pfin in[25..32] then         // pile 4ème rangée autorisée si vide
      if ctr = 0 then ok := true;
    if ok then                      // si contrôle ok on affiche
    begin                           // la pile d'arrivée et de départ
      inc(ctr);
      cart[ctr] := orca;
      AfficheFond(orca);
      Affichepile(pfin);
      Dec(pile[pdeb].ctr);
      if pile[pdeb].ctr > 0 then AffichePile(pdeb)
      else
        AfficheCarte(pile[pdeb].px,pile[pdeb].py,107);
    end
    else
      begin                      // sinon
        AfficheFond(orca);         // effacement de la carte déplacée
        AffichePile(pdeb);         // réaffichage de la pile d'origine
        pdeb := 0;
        exit;
      end;
  end;
  pdeb := 0;
  Decharge;
  Comptage;
  Pn3.Caption := 'Reste '+IntToStr(pile[34].ctr)+' cartes';
end;

function TFMain.QuellePile(x, y : integer) : byte;
var     ix,iy : integer;
begin                              // détermination de la pile cliquée
  Result := 0;
  if x < 830 then
  begin
    ix := (X-10) div 100 + 1;
    iy := (y-10) div 160;
    Result := iy * 8 + ix;
  end
  else
    begin
      iy := (y-10) div 160+1;
      if iy = 1 then result := 33
      else if iy = 4 then result := 34;
    end;
end;

procedure TFMain.AffichePile(pl : byte);
var  i,ec : byte;
     x,y : integer;
begin
  with pile[pl] do
  begin
    if ctr = 0 then exit;
    ec := 10;                 // écart vertical entre deux cartes
    x := px;
    y := py;
    for i := 1 to ctr+1 do          // effacement de la pile
    begin
      AfficheCarte(x,y,107,false);
      inc(y,ec);
    end;
    x := px;
    y := py;
    for i := 1 to ctr do            // affichage
    begin
      jeu104[cart[i]].bdos := false;
      AfficheCarte(x,y,cart[i],false);
      inc(y,ec);
    end;
  end;
  PBox.Repaint;
end;

procedure TFMain.ChargeScore;
var     i,n : word;
begin
  maxnum := 0;
  maxgan := 0;
  numact := 0;
  FillChar(pscore, 65535, 0);
  AssignFile(fScore, nfsco);
{$i-}
  Reset(fScore, 1);
{$i+}
  if IOResult > 0 then exit;
  n := FileSize(fScore);
  BlockRead(fScore, pscore, n);
  CloseFile(fScore);
  i := 0;
  repeat
    Inc(i);
    if pscore[i] > 0 then
    begin
      Inc(maxnum);
      if pscore[i] = 1 then inc(maxgan);
    end;
  until pscore[i] = 0;
  numact := maxnum;
end;

procedure TFMain.SauveScore;
begin
  if numact > maxnum then maxnum := numact;
  AssignFile(fScore, nfsco);
  Rewrite(fScore, 1);
  BlockWrite(fScore, pscore, maxnum);
  CloseFile(fScore);
end;

procedure TFMain.AfficheGains;
var  st,lgs : string;
     n,i : integer;
     pc : real;
begin
  if (maxnum > 0) and (maxgan > 0) then
  begin
    pc := 100 / maxnum * maxgan;
    n := Round(pc * 100);
    st := FloatToStr(n / 100);
  end
  else st := '0';  
  LbJg.Caption := 'Gagné(s) '+ IntToStr(maxgan)+' - '+ st +' %';
  Score.Lisco.Clear;
  lgs := '';
  n:= 0;
  i := 0;
  while n < maxnum do    // mise en forme de la liste des jeux (unité M3Sco)
  begin
    inc(n);
    if pscore[n] = 1 then st := IntToStr(n)
    else st := '0';
    while length(st) < 6 do st := ' '+ st;
    lgs := lgs + st;
    inc(i);
    if i = 10 then
    begin
      Score.Lisco.Items.Add(lgs);
      lgs := '';
      i := 0;
    end;
  end;
  if i > 0 then
    Score.Lisco.Items.Add(lgs);
  Score.Lisco.Items.SaveToFile('Mod3.txt');
end;

procedure TFMain.BScoreClick(Sender: TObject);  // affiche la liste des jeux
var  fic : TextFile;
     rec : string;
     i, n : word;
begin
  Score.ShowModal;
end;

procedure TFMain.BReglesClick(Sender: TObject);
begin
  Regles.ShowModal;
end;

procedure TFMain.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
const ct : array[5..13] of byte = (1,1,1,2,2,2,3,3,3);
var  i,ca,fg1,fg2,fm1,fm2,cb,n : byte;
     nb : integer;

  procedure Marque(pl : byte);
  begin
    with pile[pl] do
    begin
      Mark.Left := px + 20;
      Mark.Top := py + 20;
      Mark.Visible := true;
      Mark.Repaint;
      Sleep(1000);
      Mark.Visible := false;
    end;
  end;

begin
  if Key <> 88 then exit;
  for i := 1 to 32 do
  begin
    if pile[i].ctr > 0 then
    begin
      with pile[i] do
      begin
        ca := cart[ctr];
        fm1 := jeu104[ca].famille;
        fg1 := jeu104[ca].figure;
        case fg1 of
          2 : for n := 1 to 8 do
                if (pile[n].ctr = 0) and (i in[9..32]) then Marque(i);
          3 : for n := 9 to 16 do
                if (pile[n].ctr = 0) and (i in[1..8,17..32]) then Marque(i);
          4 : for n := 17 to 24 do
                if (pile[n].ctr = 0) and (i in[1..16,25..32]) then Marque(i);
          5,8,11 : for n := 1 to 8 do
                   begin
                     nb := pile[n].ctr;
                     if nb = ct[fg1] then
                     begin
                       cb := pile[n].cart[nb];
                       fm2 := jeu104[cb].famille;
                       fg2 := jeu104[cb].figure;
                       if (fm2 = fm1) and (fg2 = fg1-3) then Marque(i);
                     end;
                   end;
          6,9,12 : for n := 9 to 16 do
                   begin
                     nb := pile[n].ctr;
                     if nb = ct[fg1] then
                     begin
                       cb := pile[n].cart[nb];
                       fm2 := jeu104[cb].famille;
                       fg2 := jeu104[cb].figure;
                       if (fm2 = fm1) and (fg2 = fg1-3) then Marque(i);
                     end;
                   end;
          7,10,13 : for n := 17 to 24 do
                   begin
                     nb := pile[n].ctr;
                     if nb = ct[fg1] then
                     begin
                      cb := pile[n].cart[nb];
                      fm2 := jeu104[cb].famille;
                       fg2 := jeu104[cb].figure;
                       if (fm2 = fm1) and (fg2 = fg1-3) then Marque(i);
                     end;
                   end;
        end;
      end;
    end;     // ctr = 0
  end;
end;

end.
