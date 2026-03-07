program FMXOutrun;

{$R *.dres}

uses
  System.StartUpCopy,
  FMX.Forms,
  uMain in 'uMain.pas' {fMain},
  uUtils in 'uUtils.pas',
  uAndroidUtils in 'uAndroidUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.FormFactor.Orientations := [TFormOrientation.Landscape];
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.
