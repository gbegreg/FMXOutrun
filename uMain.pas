unit uMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  System.Math, System.Generics.Collections, system.Math.Vectors, System.IOUtils,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.Layouts, system.UIConsts, uUtils,
  FMX.Ani, FMX.Effects
  {$IFDEF ANDROID}
    , uAndroidUtils
  {$ENDIF};

type
  TfMain = class(TForm)
    PaintBox: TPaintBox;
    imgPlayer: TImage;
    aniOffRoad: TFloatAnimation;
    layHUD: TLayout;
    lblSpeed: TLabel;
    layOptions: TLayout;
    recOptions: TRectangle;
    chkShowLines: TCheckBox;
    chkShowOpponents: TCheckBox;
    chkShowRumbles: TCheckBox;
    chkShowSprites: TCheckBox;
    chkShowLane: TCheckBox;
    tbDrawDistance: TTrackBar;
    lblDrawDistance: TLabel;
    chkRoadside: TCheckBox;
    tGameloop: TTimer;
    chkBackgrounds: TCheckBox;
    chkScanlines: TCheckBox;
    layIHMMobile: TLayout;
    layDPad: TLayout;
    Layout2: TLayout;
    btnLeft: TRectangle;
    Image5: TImage;
    GlowEffect2: TGlowEffect;
    Layout4: TLayout;
    btnRight: TRectangle;
    Image6: TImage;
    GlowEffect1: TGlowEffect;
    btnAccelerate: TRectangle;
    Image4: TImage;
    GlowEffect4: TGlowEffect;
    btnBrake: TRectangle;
    Image2: TImage;
    GlowEffect3: TGlowEffect;
    layLine1: TLayout;
    procedure btnAccelerateMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure btnBrakeMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure btnLeftMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure btnRightMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure chkScanlinesChange(Sender: TObject);
    procedure chkBackgroundsChange(Sender: TObject);
    procedure chkRoadsideChange(Sender: TObject);
    procedure chkShowLaneChange(Sender: TObject);
    procedure chkShowLinesChange(Sender: TObject);
    procedure chkShowOpponentsChange(Sender: TObject);
    procedure chkShowRumblesChange(Sender: TObject);
    procedure chkShowSpritesChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure FormTouch(Sender: TObject; const Touches: TTouches; const Action: TTouchAction);
    procedure PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
    procedure tbDrawDistanceChange(Sender: TObject);
    procedure tGameloopTimer(Sender: TObject);
  private
    { Déclarations privées }
    // Configuration
    FWidth, FHeight, FDrawDistance, FRumbleLength: Integer;
    FCameraHeight, FCameraDepth, FRoadWidth, FSegmentLength: Single;

    // État du jeu
    FPosition, FPlayerX, FPlayerWorldX, FSpeed,
    FMaxSpeed, FAccel, FDecel, FBraking, FCentrifugal: Single;
    FLastCarImage: string;

    // Opions d'affichage
    FShowOpponents, FShowSprites, FShowRumbles,
    FShowLines, FShowLane, FShowRoadside, FShowBackgrounds, FShowScanlines : boolean;

    // Contrôles
    FKeyLeft, FKeyRight, FKeyUp, FKeyDown: Boolean;

    // Route
    FRoadSegments: TArray<TRoadSegment>;
    FSprites: TArray<TSprite>;
    FTrackLength: Integer;
    climb: boolean;

    // Sprites images
    FTreeImage,FTree2Image, FRightImage, FLeftImage, FSign1Image,
    FSign2Image, FSign3Image, FStartImage: TBitmap;

    // Background
    FBackgroundImages: TArray<TBitmap>; // Images du background
    FBackgroundOffset: integer;  // Décalage horizontal du background1 en pixels

    {$IFDEF ANDROID}
      FTouchMap: array[0..MAXTOUCHPOINTS-1] of TTouchInfo;
    {$ENDIF}

    FOpponentCars: TArray<TOpponentCar>;
    FOpponentCarImages: TArray<TBitmap>;
    procedure InitializeRoad;
    procedure AddRoad(Enter, Leave, Curve, Y: Single);
    procedure AddSprite(N: Integer; SpriteType: TSpriteType; Offset: Single);
    function FindSegment(Z: Single): Integer;
    procedure InitializeOpponents;
    procedure UpdateOpponents(const DeltaTime: Single);
    procedure RenderOpponent(Canvas: TCanvas; const Opponent: TOpponentCar; CamX, CamY, CamZ: Single; const ProjectedSegments: array of TRoadSegment; BaseSegment: Integer; const SegmentClipY: array of Single);
    procedure drawHUD;
    procedure RenderSprite(Canvas: TCanvas; const Sprite: TSprite; const Segment: TRoadSegment; CamX, CamY, CamZ, ClipY: Single);
    procedure RenderGame(Canvas: TCanvas);
    procedure UpdateGame(const DeltaTime: Single);
    procedure drawPlayerCar;
    {$IFDEF ANDROID}
    procedure PressButton(iTouch: TTouch);
    procedure ReleaseButton(iTouch: TTouch);
    function detectButtonTouched(iTouch: TTouch): integer;
    {$ENDIF}
  public
    { Déclarations publiques }
  end;

var
  fMain: TfMain;

const
  {$IFDEF ANDROID}
    NBOPPONENTS = 12;
    DRAWDISTANCE = 100;
  {$ELSE}
    NBOPPONENTS = 20;
    DRAWDISTANCE = 150;
  {$ENDIF}

implementation

{$R *.fmx}

procedure TfMain.FormDestroy(Sender: TObject);
begin
  FTreeImage.Free;
  FTree2Image.free;
  FSign1Image.Free;
  FSign2Image.free;
  FSign3Image.free;
  FStartImage.free;
  FRightImage.free;
  FLeftImage.free;

  for var i := 0 to High(FBackgroundImages) do
    FBackgroundImages[i].Free;
  for var i := 0 to High(FOpponentCarImages) do
    FOpponentCarImages[i].Free;

  {$IFDEF ANDROID}
    quitAndroid;
  {$ENDIF}
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  FShowSprites := true;
  FShowOpponents := true;
  FShowRumbles := true;
  FShowLines := true;
  FShowLane := true;
  FShowRoadside := true;
  FShowBackgrounds := true;
  FShowScanlines := false;
  var aGradient := TGradient.Create;
  aGradient.Color := TAlphaColorrec.Darkturquoise;
  aGradient.Color1 := TAlphaColorrec.Aqua;
  fMain.Fill.Gradient := aGradient;
  fMain.Fill.Kind := TBrushKind.Gradient;
  {$IFDEF ANDROID}
    FWidth := 640;
    FHeight := 400;
    ClientWidth := FWidth;
    ClientHeight := FHeight;
    layIHMMobile.visible := true;
    for var i := 0 to MAXTOUCHPOINTS-1 do
       FTouchMap[i].Active := False;
    imgPlayer.Position.X := (FWidth - imgPlayer.Width) * 0.5;
  {$ELSE}
    FWidth := 1024;
    FHeight := 768;
    ClientWidth := FWidth;
    ClientHeight := FHeight;
    layIHMMobile.visible := false;
  {$ENDIF}

  // Configuration caméra
  FCameraHeight := 500;
  FCameraDepth := 1 / Tan((60 / 2) * Pi / 180);
  FDrawDistance := DRAWDISTANCE;

  // Configuration route
  FRoadWidth := 1000;
  FSegmentLength := 500;
  FRumbleLength := 1;

  // Configuration joueur
  FPosition := 0;
  FPlayerWorldX := 0;
  FPlayerX := 0;
  FSpeed := 0;
  FMaxSpeed := FSegmentLength / (1/60); // Vitesse max
  FAccel := FMaxSpeed / 4;
  FDecel := -FMaxSpeed / 6;
  FBraking := -FMaxSpeed;
  FCentrifugal := 0.3;

  imgPlayer.Position.X := (FWidth - imgPlayer.Width) * 0.5;
  imgPlayer.Position.Y := FHeight - imgPlayer.Height;
  imgPlayer.Visible := True;

  // Contrôles
  FKeyLeft := False;
  FKeyRight := False;
  FKeyUp := False;
  FKeyDown := False;

  // Charger les images des sprites
  FTreeImage := TBitmap.Create;
  FTree2Image := TBitmap.Create;
  FSign1Image := TBitmap.Create;
  FSign2Image := TBitmap.Create;
  FSign3Image := TBitmap.Create;
  FStartImage := TBitmap.create;
  FRightImage := TBitmap.Create;
  FLeftImage := TBitmap.Create;

  // Charger depuis les ressources (ajustez les noms selon vos fichiers)
  loadImage(FTreeImage, 'tree');
  loadImage(FTree2Image, 'tree2');
  loadImage(FSign1Image, 'sign3');
  loadImage(FSign2Image, 'sign2');
  loadImage(FSign3Image, 'sign5');
  loadImage(FLeftImage, 'left');
  loadImage(FRightImage, 'right');
  loadImage(FStartImage, 'start');
  SetLength(FOpponentCarImages, 3);  // 3 types de voitures adverses

  FOpponentCarImages[0] := TBitmap.Create;
  FOpponentCarImages[1] := TBitmap.Create;
  FOpponentCarImages[2] := TBitmap.Create;

  loadImage(FOpponentCarImages[0], 'opponentcar1');
  loadImage(FOpponentCarImages[1], 'opponentcar2');
  loadImage(FOpponentCarImages[2], 'opponentcar3');

  SetLength(FBackgroundImages, 3);  // 3 niveaux de background

  FBackgroundImages[0] := TBitmap.Create;
  FBackgroundImages[1] := TBitmap.Create;
  FBackgroundImages[2] := TBitmap.Create;

  loadImage(FBackgroundImages[0], 'background1');
  loadImage(FBackgroundImages[1], 'background2');
  loadImage(FBackgroundImages[2], 'background3');
  InitializeRoad;
  FPlayerWorldX := FRoadSegments[0].World.X;

  InitializeOpponents;

  tGameloop.Interval := 16; // ~60 FPS
  tGameloop.Enabled := True;
end;

procedure TfMain.InitializeRoad;
begin
  SetLength(FRoadSegments, 0);
  SetLength(FSprites, 0);

  // Création de la route avec virages et collines
  AddRoad(30, 30, 0, 0);       // Ligne droite de départ
  AddRoad(40, 30, -0.5, 0);    // Virage à gauche
  AddRoad(20, 20, 0, 0);       // Ligne droite
  AddRoad(80, 150, 0, 9000);   // forte montée puis descente moins inclinée en ligne droite
  AddRoad(40, 10, -0.5, 0);    // virage gauche
  AddRoad(20, 20, 0, 0);       // petite ligne droite
  AddRoad(10, 40, 0.5, 0);     // virage droite
  AddRoad(40, 30, 0.5, -1700); // virage droite avec légère descente puis remontée
  AddRoad(20, 20, -0.5, 0);    // virage gauche
  AddRoad(20, 20, 0.5, 0);     // virage droite

  FTrackLength := Length(FRoadSegments) * Round(FSegmentLength);

  // Calculer les positions X cumulatives basées sur les courbures
  FRoadSegments[0].World.X := 0;
  for var I := 1 to Length(FRoadSegments) - 1 do
    FRoadSegments[I].World.X := FRoadSegments[I-1].World.X + FRoadSegments[I-1].Curve * FSegmentLength;

  // Ajout des décors
  for var I := 0 to Length(FRoadSegments) - 1 do begin
    // arbres
    if (i > 10) and (i < 55) then begin
      if (I mod 3 = 0) then begin
        AddSprite(I, stTree1, 2);
      end;
    end;
    if (i > 100) and (i < 175) then begin
      if (I mod 3 = 0) then begin
        AddSprite(I, stTree1, -2);
      end;
      if i > 130 then begin
        if (I mod 6 = 0) then begin
          AddSprite(I, stTree2, 2);
        end;
      end;
    end;
    if (i > 175) and (i < 350) then begin
      if (I mod 3 = 0) then begin
        AddSprite(I, stTree1, -4);
        AddSprite(I, stTree1, 4);
      end;
      if (I mod 6 = 0) then begin
        AddSprite(I, stTree1, -3);
        AddSprite(I, stTree1, 3);
      end;
      if (I mod 15 = 0) then begin
        AddSprite(I, stTree2, 2.3);
      end;
      if (I mod 12 = 0) then begin
        AddSprite(I, stTree2, -2.3);
      end;
    end;

    if (i > 500) and (i < 690) then begin
      if (I mod 5 = 0) then begin
        AddSprite(I, stTree1, -4);
        AddSprite(I, stTree1, 4);
      end;
    end;

    // pubs
    if (i > 12) and (i < 60) then begin
      if i mod 9 = 0 then begin
        AddSprite(i, stsign1, -2);
      end;
    end;

    if (i = 200) or (i = 300) or (i = 470) then begin
      AddSprite(i, stsign2, -2);
      AddSprite(i, stsign2, 2);
    end;

    if (i > 360) and (i < 390) then begin
      if i mod 8 = 0 then begin
        AddSprite(i, stsign3, -2);
        AddSprite(i, stsign3, 2);
      end;
    end;

    if (i > 0) and (i < 9) then begin
      if i mod 9 = 0 then begin
        AddSprite(i, stsign1, 2);
      end;
    end;
    if (i > 660) and (i < 700) then begin
      if i mod 9 = 0 then begin
        AddSprite(i, stsign1, 2);
      end;
    end;

    // arche départ
    if i = 10 then begin
      AddSprite(I, stStart, -0);
    end;

    // Panneaux
    if (i > 65) and (i < 110) then begin
      if i mod 4 = 0 then
        AddSprite(i, stLeft, 1.7);
    end;
    if (i > 400) and (i < 440) then begin
      if i mod 4 = 0 then
        AddSprite(i, stLeft, 1.7);
    end;
    if (i > 490) and (i < 510) then begin
      if i mod 4 = 0 then
        AddSprite(i, stRight, -1.7);
    end;
    if (i > 530) and (i < 570) then begin
      if i mod 4 = 0 then
        AddSprite(i, stRight, -1.7);
    end;
    if (i > 600) and (i < 640) then begin
      if i mod 4 = 0 then
        AddSprite(i, stLeft, 1.7);
    end;
    if (i > 650) and (i < 675) then begin
      if i mod 4 = 0 then
        AddSprite(i, stRight, -1.7);
    end;
  end;
end;

procedure TfMain.AddRoad(Enter, Leave, Curve, Y: Single);
begin
  // Segments d'entrée
  for var I := 0 to Round(Enter) - 1 do begin
    SetLength(FRoadSegments, Length(FRoadSegments) + 1);
    var N := Length(FRoadSegments) - 1;
    FRoadSegments[N].Index := N;
    FRoadSegments[N].World.X := 0;
    FRoadSegments[N].World.Z := N * FSegmentLength;
    var T := I / Enter;
    FRoadSegments[N].Curve := Interpolate(0, Curve, T);
    FRoadSegments[N].world.Y := Interpolate(0, Y, InterpolationInOutCubic(T));
  end;

  // Segments de sortie
  for var I := 0 to Round(Leave) - 1 do begin
    SetLength(FRoadSegments, Length(FRoadSegments) + 1);
    var N := Length(FRoadSegments) - 1;
    FRoadSegments[N].Index := N;
    FRoadSegments[N].World.X := 0;
    FRoadSegments[N].World.Z := N * FSegmentLength;
    var T := I / Leave;
    FRoadSegments[N].Curve := Interpolate(Curve, 0, T);
    FRoadSegments[N].world.Y := Interpolate(Y, 0, InterpolationInOutCubic(T));
  end;
end;

procedure TfMain.AddSprite(N: Integer; SpriteType: TSpriteType; Offset: Single);
begin
  if (N < 0) or (N >= Length(FRoadSegments)) then Exit;

  var Idx := Length(FSprites);
  SetLength(FSprites, Idx + 1);
  FSprites[Idx].SegmentIndex := N;
  FSprites[Idx].Offset := Offset;
  FSprites[Idx].SpriteType := SpriteType;
end;

procedure TfMain.btnAccelerateMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FKeyUp := false;
end;

procedure TfMain.btnBrakeMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FKeyDown := false;
end;

procedure TfMain.btnLeftMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FkeyLeft := false;
end;

procedure TfMain.btnRightMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  FKeyRight := false;
end;

procedure TfMain.chkScanlinesChange(Sender: TObject);
begin
  FShowScanlines := chkScanlines.IsChecked;
end;

procedure TfMain.chkBackgroundsChange(Sender: TObject);
begin
  FShowBackgrounds := chkBackgrounds.IsChecked;
end;

procedure TfMain.chkRoadsideChange(Sender: TObject);
begin
  FShowRoadside := chkRoadside.IsChecked;
end;

procedure TfMain.chkShowLaneChange(Sender: TObject);
begin
  FShowLane := chkShowLane.IsChecked;
end;

procedure TfMain.chkShowLinesChange(Sender: TObject);
begin
  FShowLines := chkShowLines.IsChecked;
end;

procedure TfMain.chkShowOpponentsChange(Sender: TObject);
begin
  FShowOpponents := chkShowOpponents.IsChecked;
end;

procedure TfMain.chkShowRumblesChange(Sender: TObject);
begin
  FShowRumbles := chkShowRumbles.IsChecked;
end;

procedure TfMain.chkShowSpritesChange(Sender: TObject);
begin
  FShowSprites := chkShowSprites.IsChecked;
end;

function TfMain.FindSegment(Z: Single): Integer;
begin
  Result := Floor(Z / FSegmentLength) mod Length(FRoadSegments);
  if Result < 0 then
    Result := Result + Length(FRoadSegments);
end;

procedure TfMain.InitializeOpponents;
begin
  // Créer quelques voitures adverses réparties sur la piste
  SetLength(FOpponentCars,  NBOPPONENTS);  // 20 voitures adverses sur PC, 12 sur Android
  randomize;

  for var i := 0 to High(FOpponentCars) do begin
    FOpponentCars[i].Position := (i + 500) * (FTrackLength / 12);
    FOpponentCars[i].X := (Random * 1.6) - 0.8;  // Entre -0.8 et 0.8
    FOpponentCars[i].BaseSpeed := FMaxSpeed * (0.5 + Random * 0.4);  // 50% à 90%
    FOpponentCars[i].Speed := FOpponentCars[i].BaseSpeed;
    FOpponentCars[i].Image := FOpponentCarImages[Random(3)];
    FOpponentCars[i].TargetX := FOpponentCars[i].X;
    FOpponentCars[i].LaneChangeTimer := Random * 5.0;  // Timer aléatoire de départ
  end;
end;

procedure TfMain.UpdateOpponents(const DeltaTime: Single);
begin
  for var i := 0 to High(FOpponentCars) do begin
    // Détection de collision avec le joueur
    var PlayerRelativeZ := FPosition - FOpponentCars[i].Position;

    // Gérer le bouclage pour la distance
    if PlayerRelativeZ < -FTrackLength * 0.5 then
      PlayerRelativeZ := PlayerRelativeZ + FTrackLength
    else if PlayerRelativeZ > FTrackLength * 0.5 then
      PlayerRelativeZ := PlayerRelativeZ - FTrackLength;

    // Collision si proche en Z (±200) et en X (distance < 0.3)
    if (Abs(PlayerRelativeZ) < 200) and (Abs(FPlayerX - FOpponentCars[i].X) < 0.3) then begin
      // Ralentir le joueur
      FSpeed := FSpeed * 0.5;

      // Pousser l'adversaire sur le côté
      FOpponentCars[i].X := if FPlayerX < FOpponentCars[i].X then FOpponentCars[i].X + 0.1
                                                             else FOpponentCars[i].X - 0.1;

      // Pousser le joueur aussi
      FPlayerX := if FPlayerX < FOpponentCars[i].X then FPlayerX - 0.05
                                                   else FPlayerX + 0.05;
    end;

    // Avancement
    FOpponentCars[i].Position := FOpponentCars[i].Position + (FOpponentCars[i].Speed * DeltaTime);

    // Bouclage
    if FOpponentCars[i].Position >= FTrackLength then
      FOpponentCars[i].Position := FOpponentCars[i].Position - FTrackLength;

    // IA des opposants
    // Récupérer le segment et calculer position interpolée
    var SegmentIndex := FindSegment(FOpponentCars[i].Position);
    var OpponentSegment := FRoadSegments[SegmentIndex];

    // Dépassement - Détecter les adversaires devant
    var IsBlocked := False;
    var NeedToOvertake := False;
    var OvertakeDirection := 0.0;  // -1 = gauche, +1 = droite

    for var j := 0 to High(FOpponentCars) do begin
      if i <> j then begin
        var RelativeZ := FOpponentCars[i].Position - FOpponentCars[j].Position;

        // Gérer le bouclage
        if RelativeZ < -FTrackLength * 0.5 then
          RelativeZ := RelativeZ + FTrackLength
        else if RelativeZ > FTrackLength * 0.5 then
          RelativeZ := RelativeZ - FTrackLength;

        // Si adversaire devant dans une distance de 1000 unités
        if (RelativeZ > 0) and (RelativeZ < 1500) then begin
          var LateralDistance := Abs(FOpponentCars[i].X - FOpponentCars[j].X);

          // Si sur la même voie (distance latérale < 0.35)
          if LateralDistance < 0.35 then begin
            IsBlocked := True;

            // Si on va plus vite que lui, on doit doubler
            if FOpponentCars[i].Speed > FOpponentCars[j].Speed + 50 then begin
              NeedToOvertake := True;

              // Décider de quel côté doubler
              // Priorité : doubler du côté qui a le plus d'espace
              var SpaceLeft := Abs(FOpponentCars[j].X - (-1.0));   // Espace vers la gauche
              var SpaceRight := Abs(FOpponentCars[j].X - 1.0);     // Espace vers la droite

              OvertakeDirection := if SpaceLeft > SpaceRight then -1.0  // Doubler à gauche
                                                             else 1.0;  // Doubler à droite

              // Si l'adversaire est déjà sur un bord, doubler de l'autre côté
              if FOpponentCars[j].X < -0.5 then
                OvertakeDirection := 1.0   // Il est à gauche, doubler à droite
              else if FOpponentCars[j].X > 0.5 then
                OvertakeDirection := -1.0;  // Il est à droite, doubler à gauche
            end
            else begin
              // Si on ne va pas plus vite, ralentir et suivre
              FOpponentCars[i].Speed := if FOpponentCars[i].Speed > FOpponentCars[j].Speed then FOpponentCars[i].Speed * 0.1
                                                                                           else FOpponentCars[j].Speed;
            end;
          end;

          // Si adversaire très proche devant (< 500) sur n'importe quelle voie, éviter
          if (RelativeZ < 800) and (LateralDistance < 0.5) then begin
            // Ralentir d'urgence
            FOpponentCars[i].Speed := if FOpponentCars[i].Speed > FOpponentCars[j].Speed then FOpponentCars[i].Speed * 0.1
                                                                                         else FOpponentCars[j].Speed;
          end;
        end;
      end;
    end;

    // Dépassement
    if NeedToOvertake then begin
      // Position cible pour le dépassement
      var CurrentLane := FOpponentCars[i].X;

      FOpponentCars[i].TargetX := if OvertakeDirection < 0 then  CurrentLane - 0.8  // Doubler à gauche
                                                           else  CurrentLane + 0.8; // Doubler à droite

      // Déplacement rapide pour doubler
      var DiffX := FOpponentCars[i].TargetX - FOpponentCars[i].X;
      if Abs(DiffX) > 0.01 then
        FOpponentCars[i].X := FOpponentCars[i].X + (DiffX * DeltaTime * 1.5);  // Plus rapide pendant le dépassement
    end else begin
      if not IsBlocked then begin
      // Changements de voie aléatoires (pour rendre ça vivant)
      FOpponentCars[i].LaneChangeTimer := FOpponentCars[i].LaneChangeTimer - DeltaTime;

      if FOpponentCars[i].LaneChangeTimer <= 0 then begin
        // Choisir une nouvelle position cible aléatoire
        FOpponentCars[i].TargetX := (Random * 1.8) - 0.9;  // Entre -0.9 et 0.9
        FOpponentCars[i].LaneChangeTimer := 3.0 + Random * 4.0;  // Nouveau timer 3-7 sec
      end;

      // Aller progressivement vers la position cible
      var DiffX := FOpponentCars[i].TargetX - FOpponentCars[i].X;
      if Abs(DiffX) > 0.01 then
        FOpponentCars[i].X := FOpponentCars[i].X + (DiffX * DeltaTime * 0.5);  // Déplacement doux
      end
    end;

    // Éviter de sortir de la route
    if FOpponentCars[i].X < -1.3 then begin
      FOpponentCars[i].X := -1.3;
      FOpponentCars[i].TargetX := -0.5;  // Revenir vers l'intérieur
      FOpponentCars[i].Speed := FOpponentCars[i].Speed * 0.85;  // Ralentir
    end else if FOpponentCars[i].X > 1.3 then begin
      FOpponentCars[i].X := 1.3;
      FOpponentCars[i].TargetX := 0.5;
      FOpponentCars[i].Speed := FOpponentCars[i].Speed * 0.85;
    end;

    // Récupération progressive de la vitesse de base de l'opposant
    if FOpponentCars[i].Speed < FOpponentCars[i].BaseSpeed then
      FOpponentCars[i].Speed := FOpponentCars[i].Speed + (DeltaTime * FAccel * 0.5);

    if FOpponentCars[i].Speed > FOpponentCars[i].BaseSpeed then
      FOpponentCars[i].Speed := FOpponentCars[i].BaseSpeed;
  end;
end;

procedure TfMain.RenderOpponent(Canvas: TCanvas; const Opponent: TOpponentCar;
  CamX, CamY, CamZ: Single; const ProjectedSegments: array of TRoadSegment;
  BaseSegment: Integer; const SegmentClipY: array of Single);
begin
  if Opponent.Image = nil then Exit;

  var SegmentA, SegmentB: TRoadSegment;
  var ProjectedIndex := 0;

  // Trouver le segment de l'adversaire
  var SegmentIndex := FindSegment(Opponent.Position);

  // Calculer la progression dans le segment
  var DistanceInSegment := Opponent.Position - (SegmentIndex * FSegmentLength);
  var OpponentSegmentProgress := DistanceInSegment / FSegmentLength;

  // Chercher le segment dans les segments projetés
  var FoundInProjected := False;

  for var N := 0 to FDrawDistance do begin
    var I := (BaseSegment + N) mod Length(FRoadSegments);

    if I = SegmentIndex then begin
      SegmentA := ProjectedSegments[N];

      if N < FDrawDistance then
        SegmentB := ProjectedSegments[N + 1]
      else
        Exit;

      FoundInProjected := True;
      ProjectedIndex := N;
      Break;
    end;
  end;

  if not FoundInProjected then Exit;

  // Interpoler les positions
  var InterpolatedRoadX := SegmentA.World.X +
                           (SegmentB.World.X - SegmentA.World.X) * OpponentSegmentProgress;

  var InterpolatedRoadY := SegmentA.world.Y +
                           (SegmentB.world.Y - SegmentA.world.Y) * OpponentSegmentProgress;

  var OpponentWorldX := InterpolatedRoadX + (Opponent.X * FRoadWidth);
  var OpponentWorldZ := SegmentA.World.Z +
                    (SegmentB.World.Z - SegmentA.World.Z) * OpponentSegmentProgress;

  var DeltaX := OpponentWorldX - CamX;
  var DeltaY := InterpolatedRoadY - CamY;
  var DeltaZ := OpponentWorldZ - CamZ;

  if DeltaZ <= FCameraDepth then Exit;

  // Projection
  var OpponentScale := FCameraDepth / DeltaZ;
  var OpponentScreenX := FWidth * 0.5 + (OpponentScale * DeltaX * FWidth * 0.5);
  var OpponentScreenY := FHeight * 0.5 - (OpponentScale * DeltaY * FHeight * 0.5);

  // Taille
  var OpponentW := Opponent.Image.Width * OpponentScale * 3000;
  var OpponentH := Opponent.Image.Height * OpponentScale * 3000;

  // Rectangle de destination
  var DestRect := RectF(
    OpponentScreenX - OpponentW * 0.5,
    OpponentScreenY - OpponentH,
    OpponentScreenX + OpponentW * 0.5,
    OpponentScreenY
  );

  // Utiliser le ClipY du tableau
  var ClipY: Single := FHeight;
  if (ProjectedIndex >= 0) and (ProjectedIndex <= High(SegmentClipY)) then
    ClipY := SegmentClipY[ProjectedIndex];

  drawSprite(canvas, DestRect, Opponent.Image, clipY, FWidth, FHeight);
end;

procedure TfMain.drawHUD;
begin
  var SpeedPercent := Round((FSpeed / FMaxSpeed) * 250);
  lblSpeed.text := Format('%d km/h', [SpeedPercent]);
end;

procedure TfMain.FormKeyDown(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  case Key of
    vkLeft: FKeyLeft := True;
    vkRight: FKeyRight := True;
    vkUp:    FKeyUp := True;
    vkDown:  FKeyDown := True;
  end;
end;

procedure TfMain.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
begin
  case Key of
    vkLeft: FKeyLeft := False;
    vkRight: FKeyRight := False;
    vkUp:    FKeyUp := False;
    vkDown:  FKeyDown := False;
  end;
end;

procedure TfMain.FormResize(Sender: TObject);
begin
  {$IFNDEF ANDROID}
    FWidth := fMain.Width;
    FHeight := fMain.height;

    imgPlayer.width := 77 * 3 * FWidth / 800;
    imgPlayer.height := 41 * 3 * FHeight / 600;

    imgPlayer.Position.X := (FWidth - imgPlayer.Width) * 0.5;
    imgPlayer.Position.Y := FHeight - imgPlayer.Height - 30;
  {$ENDIF}
end;

procedure TfMain.PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
begin
  Canvas.BeginScene;
  RenderGame(Canvas);
  if FShowScanlines then drawScanline(canvas, FWidth, FHeight);
  Canvas.EndScene;
end;

procedure TfMain.RenderSprite(Canvas: TCanvas; const Sprite: TSprite; const Segment: TRoadSegment; CamX, CamY, CamZ, ClipY: Single);
begin
  var SpriteImage: TBitmap;
  var SizeMultiplier: Single;
  // Sélectionner l'image selon le type
  case Sprite.SpriteType of
    stTree1: begin
      SpriteImage := FTreeImage;
      SizeMultiplier := 5000;
    end;
    stTree2: begin
      SpriteImage := FTree2Image;
      SizeMultiplier := 5000;
    end;
    stSign1: begin
      SpriteImage := FSign1Image;
      SizeMultiplier := 4000;
    end;
    stSign2: begin
      SpriteImage := FSign2Image;
      SizeMultiplier := 4000;
    end;
    stSign3: begin
      SpriteImage := FSign3Image;
      SizeMultiplier := 4000;
    end;
    stLeft: begin
      SpriteImage := FLeftImage;
      SizeMultiplier := 4000;
    end;
    stRight: begin
      SpriteImage := FRightImage;
      SizeMultiplier := 4000;
    end;
    stStart: begin
      SpriteImage := FStartImage;
      SizeMultiplier := 4000;
    end;
  else
    Exit;
  end;

  if (SpriteImage = nil) or (SpriteImage.Width = 0) then Exit;

  // Position du sprite dans le monde
  var SpriteWorldX := Segment.World.X + (Sprite.Offset * FRoadWidth);
  var SpriteWorldZ := Segment.World.Z;

  // Position relative à la caméra
  var DeltaX := SpriteWorldX - CamX;
  var DeltaY := Segment.world.Y - CamY;
  var DeltaZ := SpriteWorldZ - CamZ;

  // Ne pas afficher si derrière la caméra
  if DeltaZ <= FCameraDepth then Exit;

  // Projection
  var SpriteScale := FCameraDepth / DeltaZ;
  var SpriteScreenX := FWidth * 0.5 + (SpriteScale * DeltaX * FWidth * 0.5);
  var SpriteScreenY := FHeight * 0.5 - (SpriteScale * DeltaY * FHeight * 0.5);

  // Taille du sprite
  var SpriteW := SpriteImage.Width * SpriteScale * SizeMultiplier;
  var SpriteH := SpriteImage.Height * SpriteScale * SizeMultiplier;

  // Centrer le sprite horizontalement, positionner en bas verticalement
  var DestRect := RectF(
    SpriteScreenX - SpriteW * 0.5,
    SpriteScreenY - SpriteH,
    SpriteScreenX + SpriteW * 0.5,
    SpriteScreenY
  );

  drawSprite(Canvas, DestRect, SpriteImage, clipY, FWidth, FHeight);
end;

procedure TfMain.RenderGame(Canvas: TCanvas);
begin
  var Grass, Rumble, Rumble2, Road, Lane, lines, Roadside: TAlphaColor;
  var ProjectedSegments: array of TRoadSegment;
  var SegmentClipY: array of Single;  // Tableau pour stocker le ClipY de chaque segment

  // Position caméra avec interpolation
  var BaseSegment := FindSegment(FPosition);
  var CurrentSegment := FRoadSegments[BaseSegment];

  // Calculer la progression dans le segment actuel (0 à 1)
  var DistanceInSegment := FPosition - (BaseSegment * FSegmentLength);
  var SegmentProgress := DistanceInSegment / FSegmentLength;

  // Segment suivant
  var NextSegmentIndex := (BaseSegment + 1) mod Length(FRoadSegments);
  var NextSegment := FRoadSegments[NextSegmentIndex];

  // Interpoler la hauteur Y entre le segment actuel et le suivant
  var InterpolatedY := CurrentSegment.world.Y + (NextSegment.world.Y - CurrentSegment.world.Y) * SegmentProgress;

  // Horizon dynamique selon la hauteur
  var HorizonY := (FHeight * 0.5) - (InterpolatedY * 0.02);

  // Afficher les images de fond avec scrolling paralaxe
  if FShowBackgrounds then begin
    for var i := 0 to length(FBackgroundImages) -1 do
      drawBackground(FBackgroundImages[i], FBackgroundOffset * i, canvas, FWidth, FHeight);
  end else begin
    // Sinon, simple affichage d'une couleur bleue pour le ciel et verte pour le sol
    Canvas.Fill.Color := $FF72D7EE;
    Canvas.FillRect(RectF(0, 0, FWidth, HorizonY), 0, 0, [], 1);
    Canvas.Fill.Color := $FF4A9A4A;
    Canvas.FillRect(RectF(0, HorizonY, FWidth, FHeight), 0, 0, [], 1);
  end;

  climb := round(NextSegment.world.Y - CurrentSegment.world.Y) > 70;
  drawPlayerCar;

  var CamX := FPlayerWorldX;
  var CamY := FCameraHeight + InterpolatedY;
  var CamZ := FPosition - (FCameraDepth * 500);  // Reculer la caméra

  var MaxY : single := FHeight;

  SetLength(SegmentClipY, FDrawDistance + 1);
  for var N := 0 to FDrawDistance do
    SegmentClipY[N] := FHeight;

  // Projection des segments visibles dans un tableau temporaire
  SetLength(ProjectedSegments, FDrawDistance + 1);

  for var N := 0 to FDrawDistance do begin
    var SegIndex := (BaseSegment + N) mod Length(FRoadSegments);
    ProjectedSegments[N] := FRoadSegments[SegIndex];

    // Ajuster World.Z (position Z) pour gérer le bouclage
    ProjectedSegments[N].World.Z := (BaseSegment + N) * FSegmentLength;
    Project(ProjectedSegments[N], CamX, CamY, CamZ, FWidth, FHeight, FCameraDepth);
  end;

  // Rendu de la route
  for var N := 1 to FDrawDistance do begin
    var Segment := ProjectedSegments[N];
    var PrevSegment := ProjectedSegments[N - 1];
    var I := (BaseSegment + N) mod Length(FRoadSegments);

    if Segment.Point.Y < MaxY then begin
      MaxY := Segment.Point.Y;
      SegmentClipY[N] := MaxY;

      if (I div FRumbleLength) mod 2 = 0 then begin
        Grass := COLORS[7];
        Rumble := COLORS[2];
        Rumble2 := COLORS[4];
        Road := COLORS[0];
        Lane := COLORS[3];
        lines := COLORS[3];
        Roadside := COLORS[6];
      end else begin
        Grass := COLORS[8];
        Rumble := COLORS[3];
        Rumble2 := COLORS[5];
        Road := COLORS[1];
        Lane := COLORS[1];
        lines := COLORS[3];
        Roadside := COLORS[6];
      end;

      // Largeur des différentes zone du segment proportionnellement à la largeur de la route
      var RoadsideW := FRoadWidth * 1.8;
      var RumbleW := FRoadWidth * 1.35;
      var RumbleW2 := FRoadWidth * 1.2;
      var roadLinesW := FRoadWidth * 1.13;
      var linesW := FRoadWidth * 1.05;
      var LaneW := FRoadWidth * 0.03;

      // dessin de l'herbe
      Canvas.Fill.Color := Grass;
      Canvas.FillRect(RectF(0, PrevSegment.Point.Y, FWidth, Segment.Point.Y), 0, 0, [], 1);

      // dessin bords de route
      if FShowRoadside then
         drawPolygon(Canvas, Roadside, PrevSegment, Segment, RoadsideW, FWidth);

      // dessin vibreurs en virage seulement
      if FShowRumbles then begin
        if Segment.Curve <> 0 then begin
          drawPolygon(Canvas, Rumble, PrevSegment, Segment, RumbleW, FWidth);
          drawPolygon(Canvas, Rumble2, PrevSegment, Segment, RumbleW2, FWidth);
        end;
      end;

      // dessin route entre vibreurs et lignes
      drawPolygon(Canvas, Road, PrevSegment, Segment, roadLinesW, FWidth);

      // dessin lignes exterieures
      if FShowLines then drawPolygon(Canvas, lines, PrevSegment, Segment, linesW, FWidth);

      // dessine la route
      drawPolygon(Canvas, Road, PrevSegment, Segment, FRoadWidth, FWidth);

      // dessin ligne centrale (tous les 4 segments)
      if FShowLane then begin
        if (i mod 4) = 0 then
          drawPolygon(Canvas, Lane, PrevSegment, Segment, LaneW, FWidth);
      end;
    end else SegmentClipY[N] := MaxY;
  end;

  // dessin des sprites et des voitures adverses par segment : du plus loin au plus proche
  // ceci pour
  for var N := FDrawDistance downto 1 do begin
    var Segment := ProjectedSegments[N];
    var I := (BaseSegment + N) mod Length(FRoadSegments);

    if (Segment.Scale > 0) and (Segment.Point.Y < FHeight) then begin
      var ClipY: Single := FHeight;
      if N > 0 then
        ClipY := SegmentClipY[N];

      // 1. Sprites de ce segment
      if FShowSprites then begin
        for var S := 0 to Length(FSprites) - 1 do begin
          if FSprites[S].SegmentIndex = I then begin
            RenderSprite(Canvas, FSprites[S], Segment, CamX, CamY, CamZ, ClipY);
          end;
        end;
      end;

      // 2. Voitures de ce segment
      if FShowOpponents then begin
        SortOpponentCars(FOpponentCars);
        for var OpIdx := 0 to High(FOpponentCars) do begin
          var OpponentSegmentIndex := FindSegment(FOpponentCars[OpIdx].Position);

          if OpponentSegmentIndex = I then begin
            RenderOpponent(Canvas, FOpponentCars[OpIdx], CamX, CamY, CamZ,
                          ProjectedSegments, BaseSegment, SegmentClipY);
          end;
        end;
      end;
    end;
  end;

  // HUD
  drawHUD;
end;

procedure TfMain.tGameloopTimer(Sender: TObject);
begin
  UpdateGame(1/60);
  PaintBox.Repaint;
end;

procedure TfMain.UpdateGame(const DeltaTime: Single);
begin
  // Accélération/Freinage
  if FKeyUp then
    FSpeed := Accelerate(FSpeed, FAccel, DeltaTime)
  else if FKeyDown then
    FSpeed := Accelerate(FSpeed, FBraking, DeltaTime)
  else
    FSpeed := Accelerate(FSpeed, FDecel, DeltaTime);

  // Limites de vitesse
  if FSpeed < 0 then FSpeed := 0;
  if FSpeed > FMaxSpeed then FSpeed := FMaxSpeed;

  // Avancement sur la route
  FPosition := FPosition + (FSpeed * DeltaTime);

  // Boucle de la piste
  if FPosition >= FTrackLength then
    FPosition := FPosition - FTrackLength;

  // Trouver le segment actuel
  var SegmentIndex := FindSegment(FPosition);
  var PlayerSegment := FRoadSegments[SegmentIndex];

  // Calculer la progression dans le segment
  var DistanceInSegment := FPosition - (SegmentIndex * FSegmentLength);
  var SegmentProgress := DistanceInSegment / FSegmentLength;

  // Segment suivant
  var NextSegmentIndex := (SegmentIndex + 1) mod Length(FRoadSegments);
  var NextPlayerSegment := FRoadSegments[NextSegmentIndex];

  // Interpoler la position X du centre de la route
  var InterpolatedRoadX := PlayerSegment.World.X +
                       (NextPlayerSegment.World.X - PlayerSegment.World.X) * SegmentProgress;

  // Vitesse en pourcentage
  var SpeedPercent := FSpeed / FMaxSpeed;

  // Capturer l'input de direction
  var SteeringInput : single := 0;

  if FKeyLeft then
    SteeringInput := -DeltaTime * 4.0 * SpeedPercent;

  if FKeyRight then
    SteeringInput := +DeltaTime * 4.0 * SpeedPercent;

  FPlayerX := FPlayerX + SteeringInput;

  // Effet centrifuge
  FPlayerX := FPlayerX - (DeltaTime * SpeedPercent * PlayerSegment.Curve * 16.0);

  // Mettre à jour le background offset basé sur la courbure et le braquage
  // La courbure de la route fait tourner le background
  var BackgroundScrollSpeed := -PlayerSegment.Curve * DeltaTime * FSpeed * 0.01;
  FBackgroundOffset := round(FBackgroundOffset + BackgroundScrollSpeed);

  // Détection off-road
  if (FPlayerX < -1.2) or (FPlayerX > 1.2) then begin
    var OffRoadAmount := Abs(Abs(FPlayerX) - 1.2);
    var SlowdownFactor := 1.0 - (OffRoadAmount * 0.05);
    FSpeed := FSpeed * SlowdownFactor;
    if not(aniOffRoad.Running) then begin
      aniOffRoad.StartValue := imgPlayer.Position.Y;
      aniOffRoad.StopValue := imgPlayer.Position.Y-7;
      aniOffRoad.start;
    end;
    if FSpeed = 0 then begin
      aniOffRoad.stop;
      imgPlayer.Position.Y := FHeight - imgPlayer.Height - 30;
    end;
  end else begin
    aniOffRoad.stop;
    imgPlayer.Position.Y := FHeight - imgPlayer.Height - 30;
  end;

  var RoadCenterX := InterpolatedRoadX;
  FPlayerWorldX := RoadCenterX + (FPlayerX * FRoadWidth);

  if FShowOpponents then UpdateOpponents(DeltaTime);
end;

procedure TfMain.drawPlayerCar;
begin
  // Déterminer quelle image utiliser
  var NewImage := 'outrun';  // Valeur par défaut

  if FKeyLeft then
      NewImage := if climb then 'outrunmonteeleft' else 'outrunleft'
  else begin
    if FKeyRight then NewImage := if climb then 'outrunmonteeright' else 'outrunright'
    else
      if climb then NewImage := 'outrunmontee';
  end;

  // Charger seulement si l'image a changé
  if NewImage <> FLastCarImage then begin
    loadImage(imgPlayer.Bitmap, NewImage);
    FLastCarImage := NewImage;
  end;
end;

procedure TfMain.tbDrawDistanceChange(Sender: TObject);
begin
  FDrawDistance := round(tbDrawDistance.value);
end;

procedure TfMain.FormTouch(Sender: TObject; const Touches: TTouches; const Action: TTouchAction);
begin
  {$IFDEF ANDROID}
  case action of
    TTouchAction.Down, TTouchAction.Move: begin
                                            for var iTouch in Touches do begin
                                                PressButton(iTouch);
                                            end;
                                          end;
    else begin
           for var iTouch in Touches do begin
              if iTouch.action = TTouchAction.Up then ReleaseButton(iTouch);
           end;
         end;
  end;
  {$ENDIF}
end;

{$IFDEF ANDROID}
procedure TfMain.PressButton(iTouch: TTouch);
begin
  if (iTouch.id < 0) or (iTouch.id >= MAXTOUCHPOINTS) then Exit;
  // Mémoriser l’association doigt/bouton
  FTouchMap[iTouch.id].Active := true;
  FTouchMap[iTouch.id].BtnId := detectButtonTouched(iTouch);
  FTouchMap[iTouch.id].x := iTouch.Location.X;
  FTouchMap[iTouch.id].y := iTouch.Location.Y;

  // Définir l’état du bouton
  case FTouchMap[iTouch.id].BtnId of
    1: FKeyRight := True;
    2: FKeyLeft := True;
    3: FKeyUp := True;
    4: FKeyDown := True;
  end;
end;
{$ENDIF}

{$IFDEF ANDROID}
procedure TfMain.ReleaseButton(iTouch: TTouch);
begin

  if (iTouch.id < 0) or (iTouch.id >= MAXTOUCHPOINTS) then Exit;
  if not(FTouchMap[iTouch.id].Active) then Exit;

  case FTouchMap[iTouch.ID].BtnId of
    1: FKeyRight := false;
    2: FKeyLeft := false;
    3: FKeyUp := false;
    4: FKeyDown := false;
  end;

  FTouchMap[iTouch.ID].active := false;
end;
{$ENDIF}

{$IFDEF ANDROID}
function TfMain.detectButtonTouched(iTouch : TTouch):integer;
begin
  var x := btnRight.Position.x + layIHMMobile.Position.x + layDPad.Position.x + Layout4.Position.x;
  var y := btnRight.Position.y + layIHMMobile.Position.y + layDPad.Position.y + Layout4.Position.y;
  if (iTouch.Location.x >= x) and // Si l'utilisateur appuie sur le bouton droit
     (iTouch.Location.x <= x + btnRight.Width) and (iTouch.Location.y >= y) and (iTouch.Location.y <= (y + btnRight.Height)) then
    exit(1);
  x := btnLeft.Position.x + layIHMMobile.Position.x + layDPad.Position.x + Layout2.Position.x;
  y := btnLeft.Position.y + layIHMMobile.Position.y + layDPad.Position.y + Layout2.Position.y;
  if (iTouch.Location.x >= x) and // Si l'utilisateur appuie sur le bouton gauche
     (iTouch.Location.x <= x + btnLeft.Width) and (iTouch.Location.y >= y) and (iTouch.Location.y <= (y + btnLeft.Height)) then
     exit(2);
  x := btnAccelerate.Position.x + layIHMMobile.Position.x;
  y := btnAccelerate.Position.y + layIHMMobile.Position.y;
  if (iTouch.Location.x >= x) and // Si l'utilisateur appuie sur le bouton de saut
    (iTouch.Location.x <= (x + btnAccelerate.Width)) and (iTouch.Location.y >= y) and (iTouch.Location.y <= (y + btnAccelerate.Height)) then
      exit(3);
  x := btnBrake.Position.x + layIHMMobile.Position.x;
  y := btnBrake.Position.y + layIHMMobile.Position.y;
  if (iTouch.Location.x >= x) and // Si l'utilisateur appuie sur le bouton de saut
    (iTouch.Location.x <= (x + btnBrake.Width)) and (iTouch.Location.y >= y) and (iTouch.Location.y <= (y + btnBrake.Height)) then
      exit(4);
  result := 0;
end;
{$ENDIF}

end.
