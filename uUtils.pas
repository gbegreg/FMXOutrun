unit uUtils;

interface

uses FMX.Graphics, system.Types, system.Math, system.UITypes, system.Classes, System.IOUtils,
     system.math.Vectors;

type
  // Structure pour les voitures adverses
  TOpponentCar = record
    Position: Single;      // Position Z sur la route (comme FPosition)
    X: Single;             // Position latérale (-1 à 1, comme FPlayerX)
    Speed: Single;         // Vitesse de la voiture
    Image: TBitmap;        // Image de la voiture
    BaseSpeed: Single;     // Vitesse de base (pour revenir après collision)
    TargetX: Single;       // Position cible pour l'IA
    LaneChangeTimer: Single; // Timer pour changements de voie
  end;

  TRoadSegment = record
    Index: Integer;
    Point: TPointF;      // Position projetée à l'écran
    World: TPointF;      // Position dans le monde (X, Z)
    Scale: Single;       // Échelle de projection
    Curve: Single;       // Courbure
    Y: Single;           // Hauteur (collines)
    Clip: Single;        // Hauteur de clipping à l'écran
  end;

  TSpriteType = (stTree1, stTree2, stSign1, stSign2, stSign3, stStart, stLeft, stRight);

  TSprite = record
    SegmentIndex: Integer;
    Offset: Single;      // Décalage par rapport au centre de la route
    SpriteType: TSpriteType;
  end;

  procedure loadImage(anImage : TBitmap; name: string);
  function Accelerate(V, Accel, Dt: Single): Single;
  function Interpolate(A, B, Percent: Single): Single;
  function InterpolationInOutCubic(T: Single): Single;
  procedure drawPolygon(aCanvas: TCanvas; aColor: Talphacolor; prevSegment, segment : TRoadSegment; aWidth, FWidth :single);
  procedure SortOpponentCars(var Cars: TArray<TOpponentCar>);
  procedure drawSprite(Canvas: TCanvas; DestRect: TRectF; SpriteImage: TBitmap; ClipY, FWidth, FHeight: single);
  procedure Project(var Segment: TRoadSegment; CamX, CamY, CamZ, FWidth, FHeight, FCameraDepth: Single);

const
  COLORS: array[0..6] of TAlphaColor = (
    $FF6B6B6B,  // Route foncée
    $FF808080,  // Route claire
    $FFFF0000,  // Bord rouge
    $FFFFFFFF,  // Bord blanc
    $FFAA0000,  // Bord rouge foncé
    $FFBBBBBB,  // Bord blanc foncé
    $55BBEE88   // Fossé
  );

implementation

procedure loadImage(anImage : TBitmap; name: string);
begin
  var stream := TResourceStream.Create(HInstance, System.IOUtils.TPath.GetFileNameWithoutExtension(name), RT_RCDATA);
  anImage.LoadFromStream(stream);
  stream.Free;
end;

function Accelerate(V, Accel, Dt: Single): Single;
begin
  Result := V + (Accel * Dt);
end;

function Interpolate(A, B, Percent: Single): Single;
begin
  Result := A + (B - A) * Percent;
end;

function InterpolationInOutCubic(T: Single): Single;
begin
  result := if T < 0.5 then 4 * T * T * T
                       else 1 - Power(-2 * T + 2, 3) / 2;
end;

procedure drawPolygon(aCanvas: TCanvas; aColor: Talphacolor; prevSegment, segment : TRoadSegment; aWidth, FWidth :single);
begin
  aCanvas.Fill.Color := aColor;
  var X1 := prevSegment.Point.X - (prevSegment.Scale * aWidth * FWidth * 0.5);
  var W1 := prevSegment.Scale * aWidth * FWidth;
  var X2 := segment.Point.X - (segment.Scale * aWidth * FWidth * 0.5);
  var W2 := segment.Scale * aWidth * FWidth;

  var Polygon : TPolygon;
  SetLength(Polygon, 4);
  Polygon[0] := PointF(X1, prevSegment.Point.Y);
  Polygon[1] := PointF(X1 + W1, prevSegment.Point.Y);
  Polygon[2] := PointF(X2 + W2, segment.Point.Y);
  Polygon[3] := PointF(X2, segment.Point.Y);

  aCanvas.Stroke.Kind := TBrushKind.None;
  aCanvas.FillPolygon(Polygon, 1);
end;

procedure SortOpponentCars(var Cars: TArray<TOpponentCar>);
begin
  for var i := 1 to Length(Cars) -1 do begin
    var Key := Cars[i];
    var j := i - 1;

    while (j >= 0) and (Cars[j].Position < Key.Position) do begin
      Cars[j + 1] := Cars[j];
      Dec(j);
    end;

    Cars[j + 1] := Key;
  end;
end;

procedure drawSprite(Canvas: TCanvas; DestRect: TRectF; SpriteImage: TBitmap; ClipY, FWidth, FHeight: single);
begin
  // Le sprite ne doit être dessiné que si son BAS est AU-DESSUS de ClipY
  if DestRect.Bottom > ClipY then begin
    // Le sprite est partiellement ou totalement masqué par le terrain devant
    if DestRect.Top > ClipY then
      Exit;  // Complètement masqué (tout le sprite est en dessous de l'horizon)

    // Partiellement masqué : clipper la partie basse
    var ClipRatio := (DestRect.Bottom - ClipY) / (DestRect.Bottom - DestRect.Top);
    var SrcClipHeight := SpriteImage.Height * ClipRatio;

    Canvas.DrawBitmap(SpriteImage,
                      RectF(0, 0, SpriteImage.Width, SpriteImage.Height - SrcClipHeight),
                      RectF(DestRect.Left, DestRect.Top, DestRect.Right, ClipY),
                      1, False);
  end else begin
    // Sprite entièrement visible (son bas est au-dessus de l'horizon)
    if (DestRect.Bottom > 0) and (DestRect.Top < FHeight) and
       (DestRect.Right > 0) and (DestRect.Left < FWidth) then begin
      Canvas.DrawBitmap(SpriteImage,
                        RectF(0, 0, SpriteImage.Width, SpriteImage.Height),
                        DestRect, 1, False);
    end;
  end;
end;

procedure Project(var Segment: TRoadSegment; CamX, CamY, CamZ, FWidth, FHeight, FCameraDepth: Single);
begin
  var PosX := Segment.World.X - CamX;
  var PosY := Segment.Y - CamY;
  var PosZ := Segment.World.Y - CamZ;

  if PosZ <= FCameraDepth then begin
    Segment.Scale := 0;
    Exit;
  end;

  Segment.Scale := FCameraDepth / PosZ;
  Segment.Point.X := FWidth * 0.5 + (Segment.Scale * PosX * FWidth * 0.5);
  Segment.Point.Y := FHeight * 0.5 - (Segment.Scale * PosY * FHeight * 0.5);
  Segment.Clip := Segment.Point.Y;
end;

end.
