unit frmSimplifyObjectsCriteriaUnit;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, frmCustomGoPhastUnit, Vcl.StdCtrls,
  ArgusDataEntry, Vcl.Buttons, Vcl.ExtCtrls;

type
  TfrmSimplifyObjectsCriteria = class(TfrmCustomGoPhast)
    rdeAngle: TRbwDataEntry;
    rdeSpacing: TRbwDataEntry;
    lblAngle: TLabel;
    lblSpacing: TLabel;
    pnl1: TPanel;
    btnHelp: TBitBtn;
    btnOK: TBitBtn;
    btnCancel: TBitBtn;
    procedure EnableOK(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmSimplifyObjectsCriteria: TfrmSimplifyObjectsCriteria;

implementation

{$R *.dfm}

procedure TfrmSimplifyObjectsCriteria.EnableOK(Sender: TObject);
begin
  inherited;
  if ComponentState = [csFreeNotification] then
  begin
    btnOK.Enabled := (rdeAngle.RealValue > 0) or (rdeSpacing.RealValue > 0);
  end;
end;

end.
