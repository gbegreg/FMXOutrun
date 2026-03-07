unit uAndroidUtils;

interface

{$IFDEF ANDROID}
uses System.sysutils, Androidapi.Helpers;
  type TTouchInfo = record
    Active: Boolean;   // Un doigt est actif ?
    BtnId: Integer;    // Numéro du bouton associé
    x, y : single;
  end;

  procedure quitAndroid;

  const MAXTOUCHPOINTS = 10;
{$ENDIF}

implementation

{$IFDEF ANDROID}
procedure quitAndroid;
begin
  if TOSVersion.Check(5) then
    TAndroidHelper.Activity.finishAndRemoveTask
  else
    TAndroidHelper.Activity.finish;
end;
{$ENDIF}

end.
