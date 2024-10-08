unit PestObsGroupUnit;

interface

uses
  GoPhastTypes, System.Classes, System.SysUtils, ObsInterfaceUnit,
  OrderedCollectionUnit;

type
  TPestObservationGroup = class(TOrderedItem, IObservationGroup)
  private
    FObsGroupName: string;
    FUseGroupTarget: Boolean;
    FAbsoluteCorrelationFileName: string;
    FStoredGroupTarget: TRealStorage;
    FIsRegularizationGroup: Boolean;
    function GetRelativCorrelationFileName: string;
    procedure SetAbsoluteCorrelationFileName(const Value: string);
    procedure SetObsGroupName(Value: string);
    procedure SetRelativCorrelationFileName(const Value: string);
    procedure SetStoredGroupTarget(const Value: TRealStorage);
    procedure SetUseGroupTarget(const Value: Boolean);
    function GetGroupTarget: Double;
    procedure SetGroupTarget(const Value: Double);
    function GetObsGroupName: string;
    function GetUseGroupTarget: Boolean;
    function GetAbsoluteCorrelationFileName: string;
    procedure SetIsRegularizationGroup(const Value: Boolean);
    function GetExportedGroupName: string;
  protected
    function IsSame(AnotherItem: TOrderedItem): boolean; override;
  public
    constructor Create(Collection: TCollection); override;
    destructor Destroy; override;
    procedure Assign(Source: TPersistent); override;
    // COVFLE]
    property AbsoluteCorrelationFileName: string
      read GetAbsoluteCorrelationFileName write SetAbsoluteCorrelationFileName;
    // GTARG
    property GroupTarget: Double read GetGroupTarget write SetGroupTarget;
    property ExportedGroupName: string read GetExportedGroupName;
  published
    // OBGNME
    property ObsGroupName: string read GetObsGroupName write SetObsGroupName;
    // GTARG
    property UseGroupTarget: Boolean read GetUseGroupTarget
      write SetUseGroupTarget;
    // GTARG
    property StoredGroupTarget: TRealStorage read FStoredGroupTarget
      write SetStoredGroupTarget;
    // COVFLE]
    property RelativCorrelationFileName: string
      read GetRelativCorrelationFileName write SetRelativCorrelationFileName;
    property IsRegularizationGroup: Boolean read FIsRegularizationGroup
      write SetIsRegularizationGroup;
  end;

  TPestObservationGroups = class(TEnhancedOrderedCollection)
  private
    function GetParamGroup(Index: Integer): TPestObservationGroup;
    procedure SetParamGroup(Index: Integer; const Value: TPestObservationGroup);
  public
    constructor Create(Model: TBaseModel);
    function Add: TPestObservationGroup;
    property Items[Index: Integer]: TPestObservationGroup read GetParamGroup
      write SetParamGroup; default;
    function GetObsGroupByName(ObsGroupName: string): TPestObservationGroup;
    procedure ReleaseFreedObsGroupReferences;
  end;

  function ValidObsGroupName(Value: string): string;

resourcestring
  StrUnnamedObservation = 'Unnamed observation or prior information group';
  StrAtLeastOneObserva = 'At least one observation group or prior informatio' +
  'n group has not been assigned a name.';

const
  AllowableGroupNameLength = 12;
  StrRegul = 'regul_';

implementation

uses
  frmGoPhastUnit, PhastModelUnit, System.Generics.Collections,
  ModflowParameterUnit, System.Generics.Defaults, frmErrorsAndWarningsUnit;

function ValidObsGroupName(Value: string): string;
const
  MaxLength = 12;
  ValidCharacters = ['A'..'Z', 'a'..'z', '0'..'9',
    '_', '.', ':', '!', '@', '#',  '$', '%', '^', '&', '*', '(', ')', '-', '+',
    '=', '?', '/', '<', '>'];
var
  AChar: Char;
  CharIndex: Integer;
begin
  result := Copy(Value, 1, MaxLength);
  for CharIndex := 1 to Length(result) do
  begin
    AChar := result[CharIndex];
    if not CharInSet(AChar, ValidCharacters) then
    begin
      AChar := '_';
      result[CharIndex] := AChar;
    end;
  end;
end;

{ TPestObservationGroup }

procedure TPestObservationGroup.Assign(Source: TPersistent);
var
  SourceGroup: TPestObservationGroup;
begin
  if Source is TPestObservationGroup then
  begin
    SourceGroup := TPestObservationGroup(Source);
    ObsGroupName := SourceGroup.ObsGroupName;
    UseGroupTarget := SourceGroup.UseGroupTarget;
    GroupTarget := SourceGroup.GroupTarget;
    AbsoluteCorrelationFileName := SourceGroup.AbsoluteCorrelationFileName;
    IsRegularizationGroup := SourceGroup.IsRegularizationGroup;
  end
  else
  begin
    inherited;
  end;
end;

constructor TPestObservationGroup.Create(Collection: TCollection);
begin
  inherited;
  FStoredGroupTarget := TRealStorage.Create;
  FStoredGroupTarget.OnChange := OnInvalidateModelEvent;
end;

destructor TPestObservationGroup.Destroy;
begin
//  frmGoPhast.PhastModel.NotifyPestObsGroupNameDestroy(self);
  FStoredGroupTarget.Free;
  inherited;
end;

function TPestObservationGroup.GetAbsoluteCorrelationFileName: string;
begin
  result := FAbsoluteCorrelationFileName;
end;

function TPestObservationGroup.GetExportedGroupName: string;
begin
  if ObsGroupName = '' then
  begin
    frmErrorsAndWarnings.AddError(frmGoPhast.PhastModel, StrUnnamedObservation,
      StrAtLeastOneObserva);
  end;
  if IsRegularizationGroup then
  begin
    result := StrRegul + ObsGroupName;
    result := Copy(result, 1, AllowableGroupNameLength);
  end
  else
  begin
    result := ObsGroupName;
  end;
end;

function TPestObservationGroup.GetGroupTarget: Double;
begin
  result := FStoredGroupTarget.Value;
end;

function TPestObservationGroup.GetObsGroupName: string;
begin
  result := FObsGroupName;
end;

function TPestObservationGroup.GetRelativCorrelationFileName: string;
begin
  if AbsoluteCorrelationFileName <> '' then
  begin
    result := ExtractRelativePath(frmGoPhast.PhastModel.ModelFileName,
      AbsoluteCorrelationFileName);
  end
  else
  begin
    result := ''
  end;
end;

function TPestObservationGroup.GetUseGroupTarget: Boolean;
begin
  result := FUseGroupTarget;
end;

function TPestObservationGroup.IsSame(AnotherItem: TOrderedItem): boolean;
var
  OtherItem: TPestObservationGroup;
begin
  result := AnotherItem is TPestObservationGroup;
  if result then
  begin
    OtherItem := TPestObservationGroup(AnotherItem);
    result :=
      (OtherItem.ObsGroupName = ObsGroupName)
      and (OtherItem.GroupTarget = GroupTarget)
      and (OtherItem.AbsoluteCorrelationFileName = AbsoluteCorrelationFileName)
      and (OtherItem.UseGroupTarget = UseGroupTarget)
      and (OtherItem.IsRegularizationGroup = IsRegularizationGroup)
  end;
end;

procedure TPestObservationGroup.SetAbsoluteCorrelationFileName(
  const Value: string);
begin
  SetCaseSensitiveStringProperty(FAbsoluteCorrelationFileName, Value);
end;

procedure TPestObservationGroup.SetGroupTarget(const Value: Double);
begin
  FStoredGroupTarget.Value := Value;
end;

procedure TPestObservationGroup.SetIsRegularizationGroup(const Value: Boolean);
begin
  SetBooleanProperty(FIsRegularizationGroup, Value);
end;

procedure TPestObservationGroup.SetObsGroupName(Value: string);
begin
  SetCaseSensitiveStringProperty(FObsGroupName, ValidObsGroupName(Value));
end;

procedure TPestObservationGroup.SetRelativCorrelationFileName(
  const Value: string);
begin
  if Value <> '' then
  begin
    AbsoluteCorrelationFileName := ExpandFileName(Value)
  end
  else
  begin
    AbsoluteCorrelationFileName := '';
  end;
end;

procedure TPestObservationGroup.SetStoredGroupTarget(const Value: TRealStorage);
begin
  FStoredGroupTarget.Assign(Value);
end;

procedure TPestObservationGroup.SetUseGroupTarget(const Value: Boolean);
begin
  SetBooleanProperty(FUseGroupTarget, Value);
end;

{ TPestObservationGroups }

function TPestObservationGroups.Add: TPestObservationGroup;
begin
  result := inherited Add as TPestObservationGroup
end;

constructor TPestObservationGroups.Create(Model: TBaseModel);
begin
  inherited Create(TPestObservationGroup, Model as TCustomModel);
end;

function TPestObservationGroups.GetObsGroupByName(
  ObsGroupName: string): TPestObservationGroup;
var
  Index: Integer;
  AnItem: TPestObservationGroup;
begin
  result := nil;
  for Index := 0 to Count - 1 do
  begin
    AnItem :=Items[Index];
    if SameText(AnItem.ObsGroupName, ObsGroupName) then
    begin
      result := AnItem;
      Exit;
    end;
  end;
end;

procedure TPestObservationGroups.ReleaseFreedObsGroupReferences;
var
  List: System.Generics.Collections.TList<TObject>;
  ItemIndex: Integer;
  LocalModel: TCustomModel;
  ParamIndex: Integer;
  AParam: TModflowSteadyParameter;
  ObItem: TPilotPointObsGrp;
begin
  if Model <> nil then
  begin
    List := TList<TObject>.Create;
    try
      for ItemIndex := 0 to Count - 1 do
      begin
        List.Add(Items[ItemIndex]);
      end;
      //      List.Sort(
      //        TComparer<TObject>.Construct(
      //          function(const A, B: TObject): Integer
      //          begin
      //            Result := NativeUInt(A) - NativeUInt(B);
      //          end
      //        )
      //      );
      LocalModel := Model as TCustomModel;
      for ParamIndex := 0 to LocalModel.ModflowSteadyParameters.Count - 1 do
      begin
        AParam := LocalModel.ModflowSteadyParameters[ParamIndex];
        for ItemIndex := AParam.PilotPointObsGrpCollection.Count - 1 downto 0 do
        begin
          ObItem := AParam.PilotPointObsGrpCollection[ItemIndex];
          if List.IndexOf(ObItem.ObsGroup as TPestObservationGroup) < 0 then
          begin
            ObItem.Free;
          end;
        end;
      end;
    finally
      List.Free;
    end;
  end;
end;

function TPestObservationGroups.GetParamGroup(
  Index: Integer): TPestObservationGroup;
begin
  result := inherited Items[Index] as TPestObservationGroup;
end;

procedure TPestObservationGroups.SetParamGroup(Index: Integer;
  const Value: TPestObservationGroup);
begin
  inherited Items[Index] := Value;
end;

end.
