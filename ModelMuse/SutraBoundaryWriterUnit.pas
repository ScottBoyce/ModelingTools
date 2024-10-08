unit SutraBoundaryWriterUnit;

interface

uses Windows,
  CustomModflowWriterUnit, GoPhastTypes, SutraBoundariesUnit,
  Generics.Collections, PhastModelUnit, DataSetUnit, SparseDataSets,
  SysUtils, RealListUnit, SutraBoundaryUnit, ModflowBoundaryUnit,
  System.Classes, SutraOptionsUnit;

type
  TBoundaryNodes = class(TDictionary<Integer, TBoundaryNode>, IBoundaryNodes)
  private
    FRefCount: Integer;
    function GetCount: Integer;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    procedure AddUnique(Node: TBoundaryNode);
    property Count: Integer read GetCount;
    function ToArray: TArray<TPair<Integer,TBoundaryNode>>; reintroduce;
  end;

  TSutraFluxCheckList = class(TCustomTimeList)
  protected
    procedure CheckSameModel(const Data: TDataArray); override;
  public
    procedure Initialize(Times: TRealList = nil); override;
  end;

  TLakeInteractionStringList = class(TStringList)
  private
    FLakeInteraction: TLakeBoundaryInteraction;
    procedure SetLakeInteraction(const Value: TLakeBoundaryInteraction);
  public
    constructor Create;
    property LakeInteraction: TLakeBoundaryInteraction read FLakeInteraction write SetLakeInteraction;
  end;

  TLakeInteractionStringLists = TObjectList<TLakeInteractionStringList>;

  TSutraBoundaryWriter = class(TCustomFileWriter)
  private
    FBoundaryType: TSutraBoundaryType;
    FPQTimeLists: TObjectList<TSutraTimeList>;
    FUTimeLists: TObjectList<TSutraTimeList>;
    FNodeNumbers: T3DSparseIntegerArray;
    FCount: Integer;
    FIBoundaryNodes: IBoundaryNodes;
    FTime1: Double;
    FBcsFileNames: TLakeInteractionStringList;
    FUseBctime: T3DSparseBooleanArray;
    FUFormulaUsed: TObjectList<T2DSparseBooleanArray>;
    // PEST
    FPQPestSeriesNames: TStringList;
    FPQPestSeriesMethods: TList<TPestParamMethod>;
    FPQPestNames: TStringListObjectList;
    FPQPestTimeFormulas: TObjectList<T3DSparseStringArray>;
    FPQFormulaUsed: TObjectList<T2DSparseBooleanArray>;

    FUPestSeriesNames: TStringList;
    FUPestSeriesMethods: TList<TPestParamMethod>;
    FUPestNames: TStringListObjectList;
    FUPestTimeFormulas: TObjectList<T3DSparseStringArray>;
    // @name is called by @link(UpdateMergeLists).
    procedure Evaluate;
    procedure WriteDataSet0;
    procedure WriteDataSet1;
    procedure WriteDataSet2(TimeIndex: integer; PQTimeList,
      UTimeList: TSutraMergedTimeList);
    procedure WriteDataSet3(TimeIndex: integer; PQTimeList,
      UTimeList: TSutraMergedTimeList);
    procedure WriteDataSet4(TimeIndex: integer; UTimeList: TSutraMergedTimeList);
    procedure WriteDataSet5(TimeIndex: integer; PQTimeList,
      UTimeList: TSutraMergedTimeList);
    procedure WriteDataSet6(TimeIndex: integer; UTimeList: TSutraMergedTimeList);
    procedure WriteFileInternal(BcsFileNames: TLakeInteractionStringList; FileRoot: string; FileName: string; UTimeList: TSutraMergedTimeList; PQTimeList: TSutraMergedTimeList);
  protected
    class function Extension: string; override;
  public
    constructor Create(Model: TCustomModel; EvaluationType: TEvaluationType;
      BoundaryType: TSutraBoundaryType); reintroduce;
    destructor Destroy; override;
    // @name calls @link(Evaluate).
    procedure UpdateMergeLists(PQTimeList, UTimeList: TSutraMergedTimeList);
    procedure WriteFile(FileName: string; BoundaryNodes: IBoundaryNodes;
      BcsFileNames: TLakeInteractionStringList);
  end;

function FixTime(AnItem: TCustomBoundaryItem; AllTimes: TRealList): double; overload;

const
  KFluidFlux = 'FluidFlux';
  KUFlux = 'UFlux';
  KSpecifiedP = 'SpecifiedP';
  KSpecifiedU = 'SpecifiedU';

implementation

uses
  ScreenObjectUnit,
  frmGoPhastUnit, SutraTimeScheduleUnit,
  RbwParser, SutraMeshUnit, SparseArrayUnit, Math, SutraFileWriterUnit,
  frmErrorsAndWarningsUnit, System.Generics.Defaults,
  ModflowCellUnit, CellLocationUnit, ModelMuseUtilities;

resourcestring
  StrFluidSource = 'Fluid Source';
  StrMassOrEnergySourc = 'Mass or Energy Source';
  StrSpecifiedPressureS = 'Specified Pressure Source';
  StrSpecifiedConcentrat = 'Specified Concentration or Temperature Source';
  StrErrorInDataSet3 = 'Error in Data Set 3, Check that the mesh is numbered' +
  ' properly.';
  StrErrorInLayer0d = 'Error in layer %0:d at node %1:d';
  StrErrorEvaluatingBou = 'Error evaluating boundary data; check that the me' +
  'sh is numbered properly';

{ TSutraBoundaryWriter }

constructor TSutraBoundaryWriter.Create(Model: TCustomModel;
  EvaluationType: TEvaluationType; BoundaryType: TSutraBoundaryType);
var
  Mesh: TSutraMesh3D;
  NumberOfLayers: Integer;
  NumberOfRows: Integer;
  NumberOfColumns: Integer;
  TimeOptions: TSutraTimeOptions;
begin
  inherited Create(Model, EvaluationType);
  FBcsFileNames := nil;
  TimeOptions := (Model as TPhastModel).SutraTimeOptions;
  TimeOptions.CalculateAllTimes;
  if TimeOptions.AllTimes.Count > 1 then
  begin
    FTime1 := TimeOptions.AllTimes[1];
  end
  else
  begin
    FTime1 := TimeOptions.AllTimes[0];
  end;
  FBoundaryType := BoundaryType;
  FPQTimeLists := TObjectList<TSutraTimeList>.Create;
  FUTimeLists := TObjectList<TSutraTimeList>.Create;

  FPQPestSeriesNames := TStringList.Create;
  FPQPestSeriesMethods := TList<TPestParamMethod>.Create;
  FPQPestNames := TStringListObjectList.Create;
  FPQPestTimeFormulas := TObjectList<T3DSparseStringArray>.Create;
  FPQFormulaUsed := TObjectList<T2DSparseBooleanArray>.Create;

  FUPestSeriesNames := TStringList.Create;
  FUPestSeriesMethods := TList<TPestParamMethod>.Create;
  FUPestNames := TStringListObjectList.Create;
  FUPestTimeFormulas := TObjectList<T3DSparseStringArray>.Create;
  FUFormulaUsed := TObjectList<T2DSparseBooleanArray>.Create;

  Mesh := Model.SutraMesh;
  if Mesh <> nil then
  begin

    if ((Model.Mesh as TSutraMesh3D).MeshType = mt3D)
//      and (EvaluatedAt = eaNodes)
      {and (Orientation = dso3D)} then
    begin
      NumberOfLayers := frmGoPhast.PhastModel.
        SutraLayerStructure.LayerCount+1;
    end
    else
    begin
      NumberOfLayers := frmGoPhast.PhastModel.
        SutraLayerStructure.LayerCount;
    end;
    NumberOfRows := 1;
//    case EvaluatedAt of
//      eaBlocks: NumberOfColumns := Mesh.Elements.Count;
      {eaNodes:} NumberOfColumns := Mesh.Mesh2D.Nodes.Count;
//      else Assert(False);
//    end;
  end
  else
  begin
    NumberOfLayers := 0;
    NumberOfRows := 0;
    NumberOfColumns := 0;
  end;
  FNodeNumbers := T3DSparseIntegerArray.Create(GetQuantum(NumberOfLayers),
    GetQuantum(NumberOfRows), GetQuantum(NumberOfColumns));
  FUseBctime := T3DSparseBooleanArray.Create(GetQuantum(NumberOfLayers),
    GetQuantum(NumberOfRows), GetQuantum(NumberOfColumns));
end;

destructor TSutraBoundaryWriter.Destroy;
begin
  FNodeNumbers.Free;
  FPQTimeLists.Free;
  FUTimeLists.Free;
  FUseBctime.Free;

  FPQPestSeriesNames.Free;
  FPQPestSeriesMethods.Free;
  FPQPestNames.Free;
  FUPestSeriesNames.Free;
  FUPestSeriesMethods.Free;
  FUPestNames.Free;
  FPQPestTimeFormulas.Free;
  FUPestTimeFormulas.Free;
  FPQFormulaUsed.Free;
  FUFormulaUsed.Free;

  inherited;
end;

function FixTime(AnItem:TCustomBoundaryItem; AllTimes: TRealList): double;
var
  ParentCollection: TCollection;
  NextItem: TCustomBoundaryItem;
  SimulationType: TSimulationType;
begin
  SimulationType := frmGoPhast.PhastModel.SutraOptions.SimulationType;
  result := AnItem.StartTime;
  if (SimulationType in [stSteadyFlowTransientTransport,
    stTransientFlowTransientTransport]) and (AnItem.Index = 0)
    and (AnItem.StartTime = AllTimes[0]) then
  begin
    ParentCollection := AnItem.Collection;// as TCustomSutraBoundaryCollection;
    if ParentCollection.Count = 1 then
    begin
      result := AllTimes[1];
    end
    else
    begin
      NextItem := ParentCollection.Items[1] as TCustomBoundaryItem;
      if NextItem.StartTime <> AllTimes[1] then
      begin
        result := AllTimes[1];
      end;
    end;
  end;
end;

procedure TSutraBoundaryWriter.Evaluate;
var
  ScreenObjectIndex: Integer;
  ScreenObject: TScreenObject;
  ABoundary: TSutraBoundary;
  TimeList: TSutraTimeList;
  BoundaryValues: TSutraBoundaryValueArray;
  DisplayTimeIndex: Integer;
  Item: TCustomSutraBoundaryItem;
  AssocItem: TCustomSutraAssociatedBoundaryItem;
  SutraTimeOptions: TSutraTimeOptions;
  DisplayTime: Double;
  TIndex: Integer;
  TimeIndex: Integer;
  AllTimes: TRealList;
  TransientAllowed: Boolean;
  SimulationType: TSimulationType;
  BoundaryIdentifier: string;
  RootError: string;
  CellIndex: Integer;
  ACell: TCellAssignment;
  CellList: TCellAssignmentList;
  ValuePestNames: TStringList;
  UPestNames: TStringList;
  ValueFormula: string;
begin
  TransientAllowed := False;
  SimulationType := Model.SutraOptions.SimulationType;
  SutraTimeOptions := frmGoPhast.PhastModel.SutraTimeOptions;
  SutraTimeOptions.CalculateAllTimes;
  AllTimes := SutraTimeOptions.AllTimes;
  if FEvaluationType = etDisplay then
  begin
    DisplayTime := Model.ThreeDDisplayTime;
    SetLength(BoundaryValues, 1);
  end
  else
  begin
    DisplayTime := 0;
  end;

  case FBoundaryType of
    sbtFluidSource:
    begin
      TransientAllowed := SimulationType = stTransientFlowTransientTransport;
      BoundaryIdentifier := StrFluidSource;
    end;
    sbtMassEnergySource:
    begin
      TransientAllowed := SimulationType in [stSteadyFlowTransientTransport,
        stTransientFlowTransientTransport];
      BoundaryIdentifier := StrMassOrEnergySourc;
    end;
    sbtSpecPress:
    begin
      TransientAllowed := SimulationType = stTransientFlowTransientTransport;
      BoundaryIdentifier := StrSpecifiedPressureS;
    end;
    sbtSpecConcTemp:
    begin
      TransientAllowed := SimulationType in [stSteadyFlowTransientTransport,
        stTransientFlowTransientTransport];
      BoundaryIdentifier := StrSpecifiedConcentrat;
    end;
  else
    Assert(False);
  end;
  RootError := Format(StrTheFollowingObjectSutra, [BoundaryIdentifier]);
  frmErrorsAndWarnings.RemoveWarningGroup(Model, RootError);

  for ScreenObjectIndex := 0 to Model.ScreenObjectCount - 1 do
  begin
    ScreenObject := Model.ScreenObjects[ScreenObjectIndex];
    if ScreenObject.Deleted then
    begin
      Continue;
    end;
    ABoundary := nil;
    case FBoundaryType of
      sbtFluidSource:
      begin
        ABoundary := ScreenObject.SutraBoundaries.FluidSource;
      end;
      sbtMassEnergySource:
      begin
        ABoundary := ScreenObject.SutraBoundaries.MassEnergySource;
      end;
      sbtSpecPress:
      begin
        ABoundary := ScreenObject.SutraBoundaries.SpecifiedPressure;
      end;
      sbtSpecConcTemp:
      begin
        ABoundary := ScreenObject.SutraBoundaries.SpecifiedConcTemp;
      end;
    else
      Assert(False);
    end;
    if ABoundary.Used then
    begin
      if (FBcsFileNames <> nil) and
        (FBcsFileNames.LakeInteraction <> ABoundary.LakeInteraction) then
      begin
        Continue;
      end;

      if not TransientAllowed and (ABoundary.Values.Count > 1) then
      begin
        frmErrorsAndWarnings.AddWarning(Model, RootError, ScreenObject.Name,
          ScreenObject);
      end;
      DisplayTimeIndex := 0;
      if FEvaluationType = etDisplay then
      begin
        for TIndex := 0 to ABoundary.Values.Count - 1 do
        begin
          Item := ABoundary.Values[TIndex] as TCustomSutraBoundaryItem;
          if Item.StartTime <= DisplayTime then
          begin
            DisplayTimeIndex := TIndex
          end
          else
          begin
            break;
          end;
        end;
      end
      else
      begin
        SetLength(BoundaryValues, ABoundary.Values.Count);
      end;

      if FBoundaryType in [sbtFluidSource, sbtSpecPress] then
      begin
        TimeList := TSutraTimeList.Create(Model, ScreenObject);
        FPQTimeLists.Add(TimeList);
        ValuePestNames := TStringList.Create;
        FPQPestNames.Add(ValuePestNames);
        FPQPestSeriesNames.Add(ABoundary.PestBoundaryValueFormula);
        FPQPestSeriesMethods.Add(ABoundary.PestBoundaryValueMethod);

        if FEvaluationType = etDisplay then
        begin
          AssocItem := ABoundary.Values[DisplayTimeIndex]
            as TCustomSutraAssociatedBoundaryItem;
          BoundaryValues[0].Time := AssocItem.StartTime;
          ValueFormula := AssocItem.PQFormula;
          AssignPestFormula(ValueFormula,
            ABoundary.PestBoundaryValueFormula,
            ABoundary.PestBoundaryValueMethod, ValuePestNames);
          BoundaryValues[0].UsedFormula := AssocItem.UsedFormula;
          BoundaryValues[0].Formula := ValueFormula;
        end
        else
        begin
          for TimeIndex := 0 to ABoundary.Values.Count - 1 do
          begin
            AssocItem := ABoundary.Values[TimeIndex]
              as TCustomSutraAssociatedBoundaryItem;
            BoundaryValues[TimeIndex].Time := FixTime(AssocItem, AllTimes);
            ValueFormula := AssocItem.PQFormula;
            AssignPestFormula(ValueFormula,
              ABoundary.PestBoundaryValueFormula,
              ABoundary.PestBoundaryValueMethod, ValuePestNames);
            BoundaryValues[TimeIndex].UsedFormula := AssocItem.UsedFormula;
            BoundaryValues[TimeIndex].Formula := ValueFormula;
          end;
        end;
        TimeList.Initialize(BoundaryValues);
      end;

      TimeList := TSutraTimeList.Create(Model, ScreenObject);
      FUTimeLists.Add(TimeList);
      UPestNames := TStringList.Create;
      FUPestNames.Add(UPestNames);
      FUPestSeriesNames.Add(ABoundary.PestAssociatedValueFormula);
      FUPestSeriesMethods.Add(ABoundary.PestAssociatedValueMethod);

      if FEvaluationType = etDisplay then
      begin
        Item := ABoundary.Values[DisplayTimeIndex] as TCustomSutraBoundaryItem;
        BoundaryValues[0].Time := Item.StartTime;
        ValueFormula := Item.UFormula;
        AssignPestFormula(ValueFormula,
          ABoundary.PestAssociatedValueFormula,
          ABoundary.PestAssociatedValueMethod, UPestNames);
        BoundaryValues[0].UsedFormula := Item.UsedFormula;
        BoundaryValues[0].Formula := ValueFormula;
      end
      else
      begin
        for TimeIndex := 0 to ABoundary.Values.Count - 1 do
        begin
          Item := ABoundary.Values[TimeIndex] as TCustomSutraBoundaryItem;
          BoundaryValues[TimeIndex].Time := FixTime(Item, AllTimes);
          ValueFormula := Item.UFormula;
          AssignPestFormula(ValueFormula,
            ABoundary.PestAssociatedValueFormula,
            ABoundary.PestAssociatedValueMethod, UPestNames);
          BoundaryValues[TimeIndex].UsedFormula := Item.UsedFormula;
          BoundaryValues[TimeIndex].Formula := ValueFormula;
        end;
      end;
      TimeList.Initialize(BoundaryValues);

      CellList := TCellAssignmentList.Create;
      try
        ScreenObject.GetCellsToAssign('0', nil, nil, CellList, alAll, Model);
        for CellIndex := 0 to CellList.Count -1 do
        begin
          ACell := CellList[CellIndex];
          FUseBctime.Items[ACell.Layer, ACell.Row, ACell.Column] :=
            ABoundary.UseBCTime;
        end;
      finally
        CellList.Free;
      end;
    end;
  end;
end;

class function TSutraBoundaryWriter.Extension: string;
begin
  Assert(False);
end;

procedure TSutraBoundaryWriter.UpdateMergeLists(PQTimeList,
  UTimeList: TSutraMergedTimeList);
var
  Times: TRealList;
  TimeIndex: Integer;
  AList: TSutraTimeList;
  ListIndex: Integer;
  DataArray: TTransientRealSparseDataSet;
  PQDataSet: TTransientRealSparseDataSet;
  StartTimeIndex: Integer;
  NextTimeIndex: Integer;
  TimeListIndex: Integer;
  DataSetIndex: Integer;
  APQTimeList: TSutraTimeList;
  AUTimeList: TSutraTimeList;
  MergedPQDataSet: TDataArray;
  MergedUDataSet: TDataArray;
  UDataSet: TTransientRealSparseDataSet;
  LayerIndex: Integer;
  RowIndex: Integer;
  ColIndex: Integer;
  PositiveFluxes: TSutraFluxCheckList;
  PositiveUFluxes: TSutraFluxCheckList;
  PositiveDataSet: TDataArray;
  PositiveUDataSet: TDataArray;
  Mesh: TSutraMesh3D;
  ANode: TSutraNode3D;
  ANode2D: TSutraNode2D;
  UFormulas: T3DSparseStringArray;
  UFormulasUsed: T2DSparseBooleanArray;
  PQFormulas: T3DSparseStringArray;
  PQFormulasUsed: T2DSparseBooleanArray;
  PQPestSeriesName: string;
  PQPestSeriesMethod: TPestParamMethod;
  PQPestNames: TStringList;
  UPestSeriesName: string;
  UPestSeriesMethod: TPestParamMethod;
  UPestNames: TStringList;
  PQPestName: string;
  UPestName: string;
  CellLocation: TCellLocation;
  CellLocationAddr: PCellLocation;
  PQFormula: string;
  UFormula: string;
  UsedDataArray: TDataArray;
  PositiveUsedFluxes: TSutraFluxCheckList;
  UsedDataSet: TBooleanSparseDataSet;
  MergedUsedDataArray: TDataArray;
  UsedBoundary: Boolean;
  MergedUsed: Boolean;
  OldDecimalSeparator: Char;
  procedure SaveFormulaOrValue(PestSeriesName, PestName: string;
    PestSeriesMethod: TPestParamMethod;
    DataSet: TDataArray; FormulasUsed: T2DSparseBooleanArray;
    Formulas: T3DSparseStringArray; const Multiplier: string = '');
  var
    Formula: string;
    ModifiedValue: double;
  begin
    if (PestSeriesName <> '') or (PestName <> '') then
    begin
      Formula := GetPestTemplateFormula(
        DataSet.RealData[LayerIndex, RowIndex,
        ColIndex], PestName, PestSeriesName,
        PestSeriesMethod, CellLocationAddr, nil, ModifiedValue);
      if Multiplier <> '' then
      begin
        Formula := Format('(%0:s) * (%1:s)', [Formula, Multiplier]);
      end;
      FormulasUsed[LayerIndex, ColIndex] := True;
      Formulas[LayerIndex, RowIndex, ColIndex] :=
        Formula;
    end
    else
    begin
      FormulasUsed[LayerIndex, ColIndex] := False;
      Formula := FortranFloatToStr(DataSet.RealData[LayerIndex,
        RowIndex, ColIndex]);
      if Multiplier <> '' then
      begin
        Formula := Format('(%0:s) * (%1:s)', [Formula, Multiplier]);
      end;
      Formulas[LayerIndex, RowIndex, ColIndex] := Formula;
    end;
  end;
  procedure SaveCombinedFormulaOrValue(PestSeriesName, PestName: string;
    PestSeriesMethod: TPestParamMethod;
    DataSet, MergedDataSet: TDataArray; FormulasUsed: T2DSparseBooleanArray;
    Formulas: T3DSparseStringArray; Out Formula: string;
    const Multiplier: string ='');
  var
    ModifiedValue: Double;
    OldDecimalSeparator: Char;
  begin
    if (PestSeriesName <> '') or (PestName <> '') then
    begin
      Formula := GetPestTemplateFormula(
        DataSet.RealData[LayerIndex, RowIndex,
        ColIndex], PestName, PestSeriesName,
        PestSeriesMethod, CellLocationAddr, nil, ModifiedValue);
      if Multiplier <> '' then
      begin
        Formula := Format('(%0:s) * (%1:s)', [Formula, Multiplier]);
      end;
      FormulasUsed[LayerIndex, ColIndex] := True;
      Formulas[LayerIndex, RowIndex, ColIndex] :=
        Format('(%0:s) + (%1:s)',
        [Formulas[LayerIndex, RowIndex, ColIndex], Formula]);
    end
    else
    begin
      if FormulasUsed[LayerIndex, ColIndex] then
      begin
        OldDecimalSeparator := FormatSettings.DecimalSeparator;
        FormatSettings.DecimalSeparator := '.';
        try
          Formulas[LayerIndex, RowIndex, ColIndex] :=
            Format('%0:s + (%1:g)',
            [Formulas[LayerIndex, RowIndex, ColIndex],
            DataSet.RealData[LayerIndex, RowIndex, ColIndex]]);
        finally
          FormatSettings.DecimalSeparator := OldDecimalSeparator;
        end;
      end
      else
      begin
        Formulas[LayerIndex, RowIndex, ColIndex] :=
          FortranFloatToStr(MergedDataSet.RealData[LayerIndex,
          RowIndex, ColIndex])
      end;
    end;
  end;
begin
  Evaluate;
  Mesh := frmGoPhast.PhastModel.Mesh as TSutraMesh3D;
  FNodeNumbers.Clear;
  Times := TRealList.Create;
  try
    Times.Sorted := True;
    for ListIndex := 0 to FPQTimeLists.Count - 1 do
    begin
      AList := FPQTimeLists[ListIndex];
      for TimeIndex := 0 to AList.Count - 1 do
      begin
        Times.AddUnique(AList.Times[TimeIndex]);
      end;
    end;
    PQTimeList.Clear;
    for TimeIndex := 0 to Times.Count - 1 do
    begin
      DataArray := TTransientRealSparseDataSet.Create(Model);
      DataArray.DataType := rdtDouble;
      DataArray.Orientation := dso3D;
      DataArray.UpdateDimensions(Mesh.LayerCount+1, 1, Mesh.Mesh2D.Nodes.Count);
//      DataArray.SetDimensions(False);

      UsedDataArray := TBooleanSparseDataSet.Create(Model);
      UsedDataArray.DataType := rdtBoolean;
      UsedDataArray.Orientation := dso3D;
      UsedDataArray.UpdateDimensions(Mesh.LayerCount+1, 1, Mesh.Mesh2D.Nodes.Count);

      PQTimeList.Add(Times[TimeIndex], DataArray, UsedDataArray)
    end;

    Times.Clear;
    Times.Sorted := True;
    for ListIndex := 0 to FUTimeLists.Count - 1 do
    begin
      AList := FUTimeLists[ListIndex];
      for TimeIndex := 0 to AList.Count - 1 do
      begin
        Times.AddUnique(AList.Times[TimeIndex]);
      end;
    end;
    UTimeList.Clear;
    for TimeIndex := 0 to Times.Count - 1 do
    begin
      DataArray := TTransientRealSparseDataSet.Create(Model);
      DataArray.DataType := rdtDouble;
      DataArray.Orientation := dso3D;
      DataArray.UpdateDimensions(Mesh.LayerCount+1, 1, Mesh.Mesh2D.Nodes.Count);

      UsedDataArray := TBooleanSparseDataSet.Create(Model);
      UsedDataArray.DataType := rdtBoolean;
      UsedDataArray.Orientation := dso3D;
      UsedDataArray.UpdateDimensions(Mesh.LayerCount+1, 1, Mesh.Mesh2D.Nodes.Count);

      UTimeList.Add(Times[TimeIndex], DataArray, UsedDataArray);
    end;

    if FBoundaryType in [sbtFluidSource, sbtSpecPress] then
    begin
      for TimeIndex := 0 to Times.Count - 1 do
      begin
        // PEST
        PQFormulas := T3DSparseStringArray.Create(
          GetQuantum(Mesh.LayerCount+1), GetQuantum(1),
          GetQuantum(Mesh.Mesh2D.Nodes.Count));
        FPQPestTimeFormulas.Add(PQFormulas);
        PQFormulasUsed := T2DSparseBooleanArray.Create(
          GetQuantum(Mesh.LayerCount+1),
          GetQuantum(Mesh.Mesh2D.Nodes.Count));
        FPQFormulaUsed.Add(PQFormulasUsed);
      end;
    end;

    for TimeIndex := 0 to Times.Count - 1 do
    begin
      // PEST
      UFormulas := T3DSparseStringArray.Create(
        GetQuantum(Mesh.LayerCount+1), GetQuantum(1),
        GetQuantum(Mesh.Mesh2D.Nodes.Count));
      FUPestTimeFormulas.Add(UFormulas);
      UFormulasUsed := T2DSparseBooleanArray.Create(
        GetQuantum(Mesh.LayerCount+1),
        GetQuantum(Mesh.Mesh2D.Nodes.Count));
      FUFormulaUsed.Add(UFormulasUsed);
    end;

    case FBoundaryType of
      sbtFluidSource:
        begin
          PositiveFluxes := TSutraFluxCheckList.Create(nil);
          PositiveUFluxes := TSutraFluxCheckList.Create(nil);
          PositiveUsedFluxes := TSutraFluxCheckList.Create(nil);
          try
            for TimeIndex := 0 to Times.Count - 1 do
            begin
              DataArray := TTransientRealSparseDataSet.Create(Model);
              DataArray.DataType := rdtDouble;
              PositiveFluxes.Add(Times[TimeIndex], DataArray);

              DataArray := TTransientRealSparseDataSet.Create(Model);
              DataArray.DataType := rdtDouble;
              PositiveUFluxes.Add(Times[TimeIndex], DataArray);

              UsedDataArray := TBooleanSparseDataSet.Create(Model);
              UsedDataArray.DataType := rdtBoolean;
              PositiveUsedFluxes.Add(Times[TimeIndex], UsedDataArray);
            end;

            Assert(PQTimeList.Count = UTimeList.Count);
            for TimeListIndex := 0 to FPQTimeLists.Count - 1 do
            begin
              APQTimeList := FPQTimeLists[TimeListIndex];
              AUTimeList := FUTimeLists[TimeListIndex];

              PQPestSeriesName := FPQPestSeriesNames[TimeListIndex];
              PQPestSeriesMethod := FPQPestSeriesMethods[TimeListIndex];
              PQPestNames := FPQPestNames[TimeListIndex];

              UPestSeriesName := FUPestSeriesNames[TimeListIndex];
              UPestSeriesMethod := FUPestSeriesMethods[TimeListIndex];
              UPestNames := FUPestNames[TimeListIndex];

              Assert(APQTimeList.Count = AUTimeList.Count);
              for DataSetIndex := 0 to APQTimeList.Count - 1 do
              begin
                Assert(APQTimeList.Times[DataSetIndex] = AUTimeList.Times
                  [DataSetIndex]);
                PQDataSet := APQTimeList[DataSetIndex]
                  as TTransientRealSparseDataSet;
                UDataSet := AUTimeList[DataSetIndex]
                  as TTransientRealSparseDataSet;
                UsedDataSet := AUTimeList.UsedItems[DataSetIndex]
                  as TBooleanSparseDataSet;

                Assert(PQDataSet <> nil);
                Assert(UDataSet <> nil);

                StartTimeIndex :=
                  Times.IndexOf(APQTimeList.Times[DataSetIndex]);
                if DataSetIndex < APQTimeList.Count - 1 then
                begin
                  NextTimeIndex :=
                    Times.IndexOf(APQTimeList.Times[DataSetIndex + 1])-1;
                end
                else
                begin
                  NextTimeIndex := Times.Count-1;
                end;

                for TimeIndex := StartTimeIndex to NextTimeIndex do
                begin
                  MergedPQDataSet := PQTimeList[TimeIndex];
                  MergedUDataSet := UTimeList[TimeIndex];
                  PositiveDataSet := PositiveFluxes[TimeIndex];
                  PositiveUDataSet := PositiveUFluxes[TimeIndex];

                  MergedUsedDataArray := PQTimeList.UsedItems[TimeIndex];

                  PQFormulas := FPQPestTimeFormulas[TimeIndex];
                  PQFormulasUsed := FPQFormulaUsed[TimeIndex];
                  UFormulas := FUPestTimeFormulas[TimeIndex];
                  UFormulasUsed := FUFormulaUsed[TimeIndex];

                  PQPestName := PQPestNames[DataSetIndex];
                  UPestName := UPestNames[DataSetIndex];

                  for LayerIndex := PQDataSet.MinLayer to PQDataSet.MaxLayer do
                  begin
                    CellLocation.Layer := LayerIndex;
                    for RowIndex := PQDataSet.MinRow to PQDataSet.MaxRow do
                    begin
                      CellLocation.Row := RowIndex;
                      for ColIndex := PQDataSet.MinColumn to PQDataSet.MaxColumn do
                      begin
                        CellLocation.Column := ColIndex;
                        CellLocationAddr := Addr(CellLocation);
                        Assert(PQDataSet.IsValue[LayerIndex, RowIndex, ColIndex]
                          = UDataSet.IsValue[LayerIndex, RowIndex, ColIndex]);
                        if PQDataSet.IsValue[LayerIndex, RowIndex, ColIndex]
                        then
                        begin
                          UsedBoundary := UsedDataSet.BooleanData[
                            LayerIndex, RowIndex, ColIndex];
                          MergedUsed := MergedUsedDataArray.IsValue[
                            LayerIndex, RowIndex, ColIndex]
                            and MergedUsedDataArray.BooleanData[
                            LayerIndex, RowIndex, ColIndex];
                          if not UDataSet.IsValue[LayerIndex, RowIndex,ColIndex] then
                          begin
                            frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                              Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                            Exit;
                          end;
                          Assert(UDataSet.IsValue[LayerIndex, RowIndex,
                            ColIndex]);
                          FNodeNumbers[LayerIndex, RowIndex, ColIndex] := 1;
                          if MergedPQDataSet.IsValue[LayerIndex, RowIndex,
                            ColIndex] and UsedBoundary and MergedUsed then
                          begin
                            MergedPQDataSet.RealData[LayerIndex, RowIndex,
                              ColIndex] := MergedPQDataSet.RealData
                              [LayerIndex, RowIndex, ColIndex] +
                              PQDataSet.RealData[LayerIndex, RowIndex,
                              ColIndex];
                            MergedPQDataSet.Annotation[LayerIndex, RowIndex,
                              ColIndex] := MergedPQDataSet.Annotation
                              [LayerIndex, RowIndex, ColIndex] + ' plus ' +
                              PQDataSet.Annotation[LayerIndex, RowIndex,
                              ColIndex];
                            MergedUDataSet.RealData[LayerIndex, RowIndex,
                              ColIndex] := MergedUDataSet.RealData
                              [LayerIndex, RowIndex, ColIndex] +
                              UDataSet.RealData[LayerIndex, RowIndex, ColIndex];
                            MergedUDataSet.Annotation[LayerIndex, RowIndex,
                              ColIndex] := MergedUDataSet.Annotation
                              [LayerIndex, RowIndex, ColIndex] + ' plus ' +
                              UDataSet.Annotation[LayerIndex, RowIndex,
                              ColIndex];

                            SaveCombinedFormulaOrValue(PQPestSeriesName,
                              PQPestName, PQPestSeriesMethod, PQDataSet,
                              MergedPQDataSet, PQFormulasUsed, PQFormulas, PQFormula);

                            SaveCombinedFormulaOrValue(UPestSeriesName,
                              UPestName, UPestSeriesMethod, UDataSet,
                              MergedUDataSet, UFormulasUsed, UFormulas, UFormula,
                              PQFormula);
                          end
                          else
                          begin
                            MergedPQDataSet.RealData[LayerIndex, RowIndex,
                              ColIndex] := PQDataSet.RealData
                              [LayerIndex, RowIndex, ColIndex];
                            MergedPQDataSet.Annotation[LayerIndex, RowIndex,
                              ColIndex] := PQDataSet.Annotation
                              [LayerIndex, RowIndex, ColIndex];
                            MergedUDataSet.RealData[LayerIndex, RowIndex,
                              ColIndex] := UDataSet.RealData[LayerIndex,
                              RowIndex, ColIndex];
                            MergedUDataSet.Annotation[LayerIndex, RowIndex,
                              ColIndex] := UDataSet.Annotation
                              [LayerIndex, RowIndex, ColIndex];

                            MergedUsedDataArray.BooleanData[
                              LayerIndex, RowIndex, ColIndex] := UsedBoundary;
                            MergedUsedDataArray.Annotation[
                              LayerIndex, RowIndex, ColIndex] := 'Assigned';

                            SaveFormulaOrValue(PQPestSeriesName, PQPestName,
                              PQPestSeriesMethod, PQDataSet, PQFormulasUsed,
                              PQFormulas);

                            SaveFormulaOrValue(UPestSeriesName, UPestName,
                              UPestSeriesMethod, UDataSet, UFormulasUsed,
                              UFormulas, PQFormulas[LayerIndex, RowIndex, ColIndex]);
                          end;
                          if (PQDataSet.RealData[LayerIndex, RowIndex,
                            ColIndex] > 0) and UsedBoundary then
                          begin
                            Assert(PositiveDataSet.IsValue[LayerIndex, RowIndex,
                              ColIndex] = PositiveUDataSet.IsValue[LayerIndex,
                              RowIndex, ColIndex]);
                            if PositiveDataSet.IsValue[LayerIndex, RowIndex,
                              ColIndex] then
                            begin
                              PositiveDataSet.RealData[LayerIndex, RowIndex,
                                ColIndex] := PositiveDataSet.RealData
                                [LayerIndex, RowIndex, ColIndex] +
                                PQDataSet.RealData[LayerIndex, RowIndex,
                                ColIndex];
                              PositiveDataSet.Annotation[LayerIndex, RowIndex,
                                ColIndex] := PositiveDataSet.Annotation
                                [LayerIndex, RowIndex, ColIndex] + ' plus ' +
                                PQDataSet.Annotation[LayerIndex, RowIndex,
                                ColIndex];

                              PositiveUDataSet.RealData[LayerIndex, RowIndex,
                                ColIndex] := PositiveUDataSet.RealData
                                [LayerIndex, RowIndex, ColIndex] +
                                PQDataSet.RealData[LayerIndex, RowIndex,
                                ColIndex] * UDataSet.RealData
                                [LayerIndex, RowIndex, ColIndex];
                              PositiveUDataSet.Annotation[LayerIndex, RowIndex,
                                ColIndex] := PositiveUDataSet.Annotation
                                [LayerIndex, RowIndex, ColIndex] + ' plus ' +
                                UDataSet.Annotation[LayerIndex, RowIndex,
                                ColIndex];
                            end
                            else
                            begin
                              PositiveDataSet.RealData[LayerIndex, RowIndex,
                                ColIndex] := PQDataSet.RealData
                                [LayerIndex, RowIndex, ColIndex];
                              PositiveDataSet.Annotation[LayerIndex, RowIndex,
                                ColIndex] := PQDataSet.Annotation
                                [LayerIndex, RowIndex, ColIndex];
                              PositiveUDataSet.RealData[LayerIndex, RowIndex,
                                ColIndex] := PQDataSet.RealData
                                [LayerIndex, RowIndex, ColIndex] *
                                UDataSet.RealData[LayerIndex, RowIndex,
                                ColIndex];
                              PositiveUDataSet.Annotation[LayerIndex, RowIndex,
                                ColIndex] := UDataSet.Annotation
                                [LayerIndex, RowIndex, ColIndex];
                            end;
                          end;
                        end
                        else
                        begin
                          Assert(not UDataSet.IsValue[LayerIndex, RowIndex,
                            ColIndex])
                        end;
                      end;
                    end;
                  end;
                end;
              end;
            end;

            for TimeIndex := 0 to PQTimeList.Count - 1 do
            begin
              MergedPQDataSet := PQTimeList[TimeIndex];
              MergedUDataSet := UTimeList[TimeIndex];
              Assert(MergedPQDataSet <> nil);
              Assert(MergedUDataSet <> nil);
              PositiveDataSet := PositiveFluxes[TimeIndex];
              PositiveUDataSet := PositiveUFluxes[TimeIndex];
              Assert(PositiveDataSet <> nil);
              Assert(PositiveUDataSet <> nil);

              PQFormulas := FPQPestTimeFormulas[TimeIndex];
              PQFormulasUsed := FPQFormulaUsed[TimeIndex];
              UFormulas := FUPestTimeFormulas[TimeIndex];
              UFormulasUsed := FUFormulaUsed[TimeIndex];

              for LayerIndex := 0 to MergedPQDataSet.LayerCount - 1 do
              begin
                CellLocation.Layer := LayerIndex;
                for RowIndex := 0 to MergedPQDataSet.RowCount - 1 do
                begin
                  CellLocation.Row := RowIndex;
                  for ColIndex := 0 to MergedPQDataSet.ColumnCount - 1 do
                  begin
                    CellLocation.Column := ColIndex;
                    CellLocationAddr := Addr(CellLocation);
                    Assert(MergedPQDataSet.IsValue[LayerIndex, RowIndex,
                      ColIndex] = MergedUDataSet.IsValue[LayerIndex, RowIndex,
                      ColIndex]);
                    if MergedPQDataSet.IsValue[LayerIndex, RowIndex, ColIndex]
                      and (MergedPQDataSet.RealData[LayerIndex, RowIndex,
                      ColIndex] > 0) then
                    begin
                      if not PositiveDataSet.IsValue[LayerIndex, RowIndex,ColIndex] then
                      begin
                        frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                          Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                        Exit;
                      end;
                      Assert(PositiveDataSet.IsValue[LayerIndex, RowIndex,
                        ColIndex]);
                      if not PositiveUDataSet.IsValue[LayerIndex, RowIndex,ColIndex] then
                      begin
                        frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                          Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                        Exit;
                      end;
                      Assert(PositiveUDataSet.IsValue[LayerIndex, RowIndex,
                        ColIndex]);
                      MergedUDataSet.RealData[LayerIndex, RowIndex, ColIndex] :=
                        PositiveUDataSet.RealData[LayerIndex, RowIndex,
                        ColIndex] / PositiveDataSet.RealData[LayerIndex,
                        RowIndex, ColIndex];
                      MergedUDataSet.Annotation[LayerIndex, RowIndex, ColIndex]
                        := PositiveUDataSet.Annotation[LayerIndex,
                        RowIndex, ColIndex];
                      if UFormulasUsed[LayerIndex, ColIndex] then
                      begin
                        if PQFormulasUsed[LayerIndex, ColIndex] then
                        begin
                          UFormula := UFormulas[LayerIndex, RowIndex, ColIndex];
                          PQFormula := PQFormulas[LayerIndex, RowIndex, ColIndex];
                          UFormulas[LayerIndex, RowIndex, ColIndex]
                            := Format('(%0:s) / (%1:s)', [UFormula, PQFormula]);
                        end
                        else
                        begin
                          OldDecimalSeparator := FormatSettings.DecimalSeparator;
                          FormatSettings.DecimalSeparator := '.';
                          try
                            UFormulas[LayerIndex, RowIndex, ColIndex]
                              := Format('(%0:s) / %1:g',
                              [UFormulas[LayerIndex, RowIndex, ColIndex],
                              PositiveDataSet.RealData[LayerIndex, RowIndex, ColIndex]]);
                          finally
                            FormatSettings.DecimalSeparator := OldDecimalSeparator;
                          end;
                        end;

                      end;
                    end;
                  end;
                end;
              end;
            end;
          finally
            PositiveUsedFluxes.Free;
            PositiveUFluxes.Free;
            PositiveFluxes.Free;
          end;
        end;
      sbtMassEnergySource:
        begin
          Assert(PQTimeList.Count = 0);
          for TimeListIndex := 0 to FUTimeLists.Count - 1 do
          begin
            AUTimeList := FUTimeLists[TimeListIndex];

            UPestSeriesName := FUPestSeriesNames[TimeListIndex];
            UPestSeriesMethod := FUPestSeriesMethods[TimeListIndex];
            UPestNames := FUPestNames[TimeListIndex];

            for DataSetIndex := 0 to AUTimeList.Count - 1 do
            begin
              UDataSet := AUTimeList[DataSetIndex]
                as TTransientRealSparseDataSet;
              UsedDataSet := AUTimeList.UsedItems[DataSetIndex]
                as TBooleanSparseDataSet;

              UFormulas := FUPestTimeFormulas[DataSetIndex];
              UFormulasUsed := FUFormulaUsed[DataSetIndex];

              Assert(UDataSet <> nil);
              StartTimeIndex := Times.IndexOf(AUTimeList.Times[DataSetIndex]);
              if DataSetIndex < AUTimeList.Count - 1 then
              begin
                NextTimeIndex :=
                  Times.IndexOf(AUTimeList.Times[DataSetIndex + 1])-1;
              end
              else
              begin
                NextTimeIndex := Times.Count-1;
              end;

              for TimeIndex := StartTimeIndex to NextTimeIndex do
              begin
                MergedUDataSet := UTimeList[TimeIndex];
                MergedUsedDataArray := UTimeList.UsedItems[TimeIndex];

                UPestName := UPestNames[TimeIndex];
                for LayerIndex := UDataSet.MinLayer to UDataSet.MaxLayer do
                begin
                  CellLocation.Layer := LayerIndex;
                  for RowIndex := UDataSet.MinRow to UDataSet.MaxRow do
                  begin
                    CellLocation.Row := RowIndex;
                    for ColIndex := UDataSet.MinColumn to UDataSet.MaxColumn do
                    begin
                      CellLocation.Column := ColIndex;
                      CellLocationAddr := Addr(CellLocation);
                      if UDataSet.IsValue[LayerIndex, RowIndex, ColIndex] then
                      begin
                        FNodeNumbers[LayerIndex, RowIndex, ColIndex] := 1;
                        UsedBoundary := UsedDataSet.BooleanData[
                          LayerIndex, RowIndex, ColIndex];
                        MergedUsed := MergedUsedDataArray.IsValue[
                          LayerIndex, RowIndex, ColIndex]
                          and MergedUsedDataArray.BooleanData[
                          LayerIndex, RowIndex, ColIndex];
                        if MergedUDataSet.IsValue[LayerIndex, RowIndex, ColIndex]
                          and UsedBoundary and MergedUsed then
                        begin

                          MergedUDataSet.RealData[LayerIndex, RowIndex,
                            ColIndex] := MergedUDataSet.RealData
                            [LayerIndex, RowIndex, ColIndex] + UDataSet.RealData
                            [LayerIndex, RowIndex, ColIndex];
                          MergedUDataSet.Annotation[LayerIndex, RowIndex,
                            ColIndex] := MergedUDataSet.Annotation
                            [LayerIndex, RowIndex, ColIndex] + ' plus ' +
                            UDataSet.Annotation[LayerIndex, RowIndex, ColIndex];
                          SaveCombinedFormulaOrValue(UPestSeriesName,
                            UPestName, UPestSeriesMethod, UDataSet,
                            MergedUDataSet, UFormulasUsed, UFormulas, UFormula);
                        end
                        else
                        begin
                          MergedUDataSet.RealData[LayerIndex, RowIndex,
                            ColIndex] := UDataSet.RealData[LayerIndex, RowIndex,
                            ColIndex];
                          MergedUDataSet.Annotation[LayerIndex, RowIndex,
                            ColIndex] := UDataSet.Annotation[LayerIndex,
                            RowIndex, ColIndex];
                          MergedUsedDataArray.BooleanData[
                            LayerIndex, RowIndex, ColIndex] := UsedBoundary;
                          MergedUsedDataArray.Annotation[
                            LayerIndex, RowIndex, ColIndex] := 'Assigned';
                          SaveFormulaOrValue(UPestSeriesName, UPestName,
                            UPestSeriesMethod, UDataSet, UFormulasUsed,
                            UFormulas);
                        end;
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
      sbtSpecPress:
        begin
          Assert(PQTimeList.Count = UTimeList.Count);
          for TimeListIndex := 0 to FPQTimeLists.Count - 1 do
          begin
            APQTimeList := FPQTimeLists[TimeListIndex];
            AUTimeList := FUTimeLists[TimeListIndex];

            PQPestSeriesName := FPQPestSeriesNames[TimeListIndex];
            PQPestSeriesMethod := FPQPestSeriesMethods[TimeListIndex];
            PQPestNames := FPQPestNames[TimeListIndex];

            UPestSeriesName := FUPestSeriesNames[TimeListIndex];
            UPestSeriesMethod := FUPestSeriesMethods[TimeListIndex];
            UPestNames := FUPestNames[TimeListIndex];

            Assert(APQTimeList.Count = AUTimeList.Count);
            for DataSetIndex := 0 to APQTimeList.Count - 1 do
            begin
              Assert(APQTimeList.Times[DataSetIndex] = AUTimeList.Times
                [DataSetIndex]);
              PQDataSet := APQTimeList[DataSetIndex]
                as TTransientRealSparseDataSet;
              UDataSet := AUTimeList[DataSetIndex]
                as TTransientRealSparseDataSet;
              UsedDataSet := AUTimeList.UsedItems[DataSetIndex]
                as TBooleanSparseDataSet;

              Assert(PQDataSet <> nil);
              Assert(UDataSet <> nil);
              StartTimeIndex := Times.IndexOf(APQTimeList.Times[DataSetIndex]);
              if DataSetIndex < APQTimeList.Count - 1 then
              begin
                NextTimeIndex :=
                  Times.IndexOf(APQTimeList.Times[DataSetIndex + 1])-1;
              end
              else
              begin
                NextTimeIndex := Times.Count-1;
              end;

              for TimeIndex := StartTimeIndex to NextTimeIndex do
              begin
                MergedPQDataSet := PQTimeList[TimeIndex];
                MergedUDataSet := UTimeList[TimeIndex];
                PQPestName := PQPestNames[DataSetIndex];
                UPestName := UPestNames[DataSetIndex];

                MergedUsedDataArray := PQTimeList.UsedItems[TimeIndex];

                PQFormulas := FPQPestTimeFormulas[TimeIndex];
                PQFormulasUsed := FPQFormulaUsed[TimeIndex];
                UFormulas := FUPestTimeFormulas[TimeIndex];
                UFormulasUsed := FUFormulaUsed[TimeIndex];

                for LayerIndex := PQDataSet.MinLayer to PQDataSet.MaxLayer do
                begin
                  CellLocation.Layer := LayerIndex;
                  for RowIndex := PQDataSet.MinRow to PQDataSet.MaxRow do
                  begin
                    CellLocation.Row := RowIndex;
                    for ColIndex := PQDataSet.MinColumn to PQDataSet.MaxColumn do
                    begin
                      CellLocation.Column := ColIndex;
                      CellLocationAddr := Addr(CellLocation);
                      Assert(PQDataSet.IsValue[LayerIndex, RowIndex, ColIndex]
                        = UDataSet.IsValue[LayerIndex, RowIndex, ColIndex]);
                      if PQDataSet.IsValue[LayerIndex, RowIndex, ColIndex] then
                      begin
                        UsedBoundary := UsedDataSet.BooleanData[
                          LayerIndex, RowIndex, ColIndex];
//                        MergedUsed := MergedUsedDataArray.IsValue[
//                          LayerIndex, RowIndex, ColIndex]
//                          and MergedUsedDataArray.BooleanData[
//                          LayerIndex, RowIndex, ColIndex];

                        FNodeNumbers[LayerIndex, RowIndex, ColIndex] := 1;
                        MergedPQDataSet.RealData[LayerIndex, RowIndex, ColIndex]
                          := PQDataSet.RealData[LayerIndex, RowIndex, ColIndex];
                        MergedPQDataSet.Annotation[LayerIndex, RowIndex,
                          ColIndex] := PQDataSet.Annotation[LayerIndex,
                          RowIndex, ColIndex];
                        MergedUDataSet.RealData[LayerIndex, RowIndex, ColIndex]
                          := UDataSet.RealData[LayerIndex, RowIndex, ColIndex];
                        MergedUDataSet.Annotation[LayerIndex, RowIndex,
                          ColIndex] := UDataSet.Annotation[LayerIndex, RowIndex,
                          ColIndex];

                        MergedUsedDataArray.BooleanData[
                          LayerIndex, RowIndex, ColIndex] := UsedBoundary;
                        MergedUsedDataArray.Annotation[
                          LayerIndex, RowIndex, ColIndex] := 'Assigned';

                        SaveFormulaOrValue(PQPestSeriesName, PQPestName,
                          PQPestSeriesMethod, PQDataSet, PQFormulasUsed,
                          PQFormulas);

                        SaveFormulaOrValue(UPestSeriesName, UPestName,
                          UPestSeriesMethod, UDataSet, UFormulasUsed,
                          UFormulas);
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
      sbtSpecConcTemp:
        begin
          Assert(PQTimeList.Count = 0);
          for TimeListIndex := 0 to FUTimeLists.Count - 1 do
          begin
            AUTimeList := FUTimeLists[TimeListIndex];

            UPestSeriesName := FUPestSeriesNames[TimeListIndex];
            UPestSeriesMethod := FUPestSeriesMethods[TimeListIndex];
            UPestNames := FUPestNames[TimeListIndex];

            for DataSetIndex := 0 to AUTimeList.Count - 1 do
            begin
              UDataSet := AUTimeList[DataSetIndex]
                as TTransientRealSparseDataSet;
              Assert(UDataSet <> nil);
              UsedDataSet := AUTimeList.UsedItems[DataSetIndex]
                as TBooleanSparseDataSet;

              UFormulas := FUPestTimeFormulas[DataSetIndex];
              UFormulasUsed := FUFormulaUsed[DataSetIndex];

              StartTimeIndex := Times.IndexOf(AUTimeList.Times[DataSetIndex]);
              if DataSetIndex < AUTimeList.Count - 1 then
              begin
                NextTimeIndex :=
                  Times.IndexOf(AUTimeList.Times[DataSetIndex + 1])-1;
              end
              else
              begin
                NextTimeIndex := Times.Count-1;
              end;

              for TimeIndex := StartTimeIndex to NextTimeIndex do
              begin
                MergedUDataSet := UTimeList[TimeIndex];
                MergedUsedDataArray := UTimeList.UsedItems[TimeIndex];

                UPestName := UPestNames[TimeIndex];
                for LayerIndex := UDataSet.MinLayer to UDataSet.MaxLayer do
                begin
                  CellLocation.Layer := LayerIndex;
                  for RowIndex := UDataSet.MinRow to UDataSet.MaxRow do
                  begin
                    CellLocation.Row := RowIndex;
                    for ColIndex := UDataSet.MinColumn to UDataSet.MaxColumn do
                    begin
                      CellLocation.Column := ColIndex;
                      CellLocationAddr := Addr(CellLocation);
                      if UDataSet.IsValue[LayerIndex, RowIndex, ColIndex] then
                      begin
                        FNodeNumbers[LayerIndex, RowIndex, ColIndex] := 1;
                        UsedBoundary := UsedDataSet.BooleanData[
                          LayerIndex, RowIndex, ColIndex];
//                        MergedUsed := MergedUsedDataArray.IsValue[
//                          LayerIndex, RowIndex, ColIndex]
//                          and MergedUsedDataArray.BooleanData[
//                          LayerIndex, RowIndex, ColIndex];

                        MergedUDataSet.RealData[LayerIndex, RowIndex, ColIndex]
                          := UDataSet.RealData[LayerIndex, RowIndex, ColIndex];
                        MergedUDataSet.Annotation[LayerIndex, RowIndex,
                          ColIndex] := UDataSet.Annotation[LayerIndex, RowIndex,
                          ColIndex];
                        MergedUsedDataArray.BooleanData[
                          LayerIndex, RowIndex, ColIndex] := UsedBoundary;
                        MergedUsedDataArray.Annotation[
                          LayerIndex, RowIndex, ColIndex] := 'Assigned';
                        SaveFormulaOrValue(UPestSeriesName, UPestName,
                          UPestSeriesMethod, UDataSet, UFormulasUsed,
                          UFormulas);
                      end;
                    end;
                  end;
                end;
              end;
            end;
          end;
        end;
    else
      Assert(False);
    end;
  finally
    Times.Free;
  end;

  FCount := 0;
  if (FNodeNumbers.MinLayer >= 0) {and (Mesh.MeshType = mt3D)} then
  begin
    for LayerIndex := FNodeNumbers.MinLayer to FNodeNumbers.MaxLayer do
    begin
      for RowIndex := FNodeNumbers.MinRow to FNodeNumbers.MaxRow do
      begin
        for ColIndex := FNodeNumbers.MinCol to FNodeNumbers.MaxCol do
        begin
          if FNodeNumbers.IsValue[LayerIndex,RowIndex,ColIndex] then
          begin
            Assert(RowIndex = 0);
            if Mesh.MeshType in [mt2D, mtProfile] then
            begin
              Assert(LayerIndex = 0);
              ANode2D := Mesh.Mesh2D.Nodes[ColIndex];
              FNodeNumbers[LayerIndex,RowIndex,ColIndex] := ANode2D.Number;
              Inc(FCount);
            end
            else
            begin
              ANode := Mesh.NodeArray[LayerIndex, ColIndex];
              if ANode.Active then
              begin
                FNodeNumbers[LayerIndex,RowIndex,ColIndex] := ANode.Number;
                Inc(FCount);
              end
              else
              begin
                FNodeNumbers.RemoveValue(LayerIndex,RowIndex,ColIndex);
              end;
            end;
          end;
        end;
      end;
    end;
  end;
end;

procedure TSutraBoundaryWriter.WriteDataSet0;
var
  Comment: string;
begin
  case FBoundaryType of
    sbtFluidSource: Comment := '# Fluid Flux Boundary Condition File';
    sbtMassEnergySource: Comment := '# Mass/Energy Source Boundary Condition File';
    sbtSpecPress: Comment := '# Specified Pressure Boundary Condition File';
    sbtSpecConcTemp: Comment := '# Specified Temperature/Concentration Boundary Condition File';
  end;
  WriteString(File_Comment(Comment));
  if WritingTemplate then
  begin
    WriteCommentLine('(and then modified by a parameter estimation program.)');
  end;
  NewLine;
end;

procedure TSutraBoundaryWriter.WriteDataSet1;
var
  // may be up to 10 characters long
  BCSSCH: string;
  SimulationType: TSimulationType;
begin
  WriteCommentLine('Data set 1');
  SimulationType := Model.SutraOptions.SimulationType;

  case FBoundaryType of
    sbtFluidSource:
      begin
        case SimulationType of
          stSteadyFlowSteadyTransport, stSteadyFlowTransientTransport:
            begin
              BCSSCH := 'STEP_0';
            end;
            stTransientFlowTransientTransport:
            begin
              BCSSCH := KFluidFlux;
            end;
        else
          Assert(False);
        end;
      end;
    sbtMassEnergySource:
      begin
        case SimulationType of
          stSteadyFlowSteadyTransport:
            begin
              BCSSCH := 'STEP_1';
            end;
          stSteadyFlowTransientTransport,
            stTransientFlowTransientTransport:
            begin
              BCSSCH := KUFlux;
            end;
        else
          Assert(False);
        end;
      end;
    sbtSpecPress:
      begin
        case SimulationType of
          stSteadyFlowSteadyTransport, stSteadyFlowTransientTransport:
            begin
              BCSSCH := 'STEP_0';
            end;
            stTransientFlowTransientTransport:
            begin
              BCSSCH := KSpecifiedP;
            end;
        else
          Assert(False);
        end;
      end;
    sbtSpecConcTemp:
      begin
        case SimulationType of
          stSteadyFlowSteadyTransport:
            begin
              BCSSCH := 'STEP_1';
            end;
          stSteadyFlowTransientTransport,
            stTransientFlowTransientTransport:
            begin
              BCSSCH := KSpecifiedU;
            end;
        else
          Assert(False);
        end;
      end;
  end;
  WriteString('''' + BCSSCH + '''');
  WriteString(' # BCSSCH');
  NewLine;
end;

procedure TSutraBoundaryWriter.WriteDataSet2(TimeIndex: integer; PQTimeList,
  UTimeList: TSutraMergedTimeList);
var
  // May be up to 40 characters long and may include spaces.
  BCSID: string;
  NSOP1: Integer;
  NSOU1: Integer;
  NPBC1: Integer;
  NUBC1: Integer;
  NPBG1: Integer;
  NUBG1: Integer;
  PriorUDataArray: TRealSparseDataSet;
  UDataArray: TRealSparseDataSet;
  PriorPQDataArray: TRealSparseDataSet;
  PQDataArray: TRealSparseDataSet;
  LayerIndex: Integer;
  RowIndex: Integer;
  Count: Integer;
  ColIndex: Integer;
  StartLayer: Integer;
  StartRow: Integer;
  StartCol: Integer;
  UFormulasUsed: T2DSparseBooleanArray;
  PQFormulasUsed: T2DSparseBooleanArray;
begin
  if TimeIndex < PQTimeList.Count then
  begin
    WriteCommentLine('Data set 2; Time = ' + FortranFloatToStr(PQTimeList.Times[TimeIndex]));
  end
  else
  begin
    WriteCommentLine('Data set 2');
  end;

  NSOP1 := 0;
  NSOU1 := 0;
  NPBC1 := 0;
  NUBC1 := 0;
  NPBG1 := 0;
  NUBG1 := 0;
  if TimeIndex = 0 then
  begin
    Count := 0;
    for LayerIndex := FNodeNumbers.MinLayer to FNodeNumbers.MaxLayer do
    begin
      for RowIndex := FNodeNumbers.MinRow to FNodeNumbers.MaxRow do
      begin
        for ColIndex := FNodeNumbers.MinCol to FNodeNumbers.MaxCol do
        begin
          if FNodeNumbers.IsValue[LayerIndex, RowIndex,ColIndex]
            and not FUseBctime[LayerIndex, RowIndex,ColIndex] then
          begin
            Inc(Count);
          end;
        end;
      end;
    end;
  end
  else
  begin
    Count := 0;
    PriorUDataArray :=   UTimeList[TimeIndex-1] as TRealSparseDataSet;
    UDataArray :=   UTimeList[TimeIndex] as TRealSparseDataSet;
    UFormulasUsed := FUFormulaUsed[TimeIndex];

    if TimeIndex < PQTimeList.Count then
    begin
      PriorPQDataArray :=   PQTimeList[TimeIndex-1] as TRealSparseDataSet;
      PQDataArray :=   PQTimeList[TimeIndex] as TRealSparseDataSet;
      PQFormulasUsed := FPQFormulaUsed[TimeIndex];
    end
    else
    begin
      PriorPQDataArray := nil;
      PQDataArray := nil;
      PQFormulasUsed := nil
    end;
    if (PriorUDataArray.MinLayer >= 0) or (UDataArray.MinLayer >= 0) then
    begin
      if (PriorUDataArray.MinLayer >= 0) and (UDataArray.MinLayer >= 0) then
      begin
        StartLayer := Min(PriorUDataArray.MinLayer, UDataArray.MinLayer);
        StartRow := Min(PriorUDataArray.MinRow, UDataArray.MinRow);
        StartCol := Min(PriorUDataArray.MinColumn, UDataArray.MinColumn);
      end
      else if (PriorUDataArray.MinLayer >= 0) then
      begin
        StartLayer := PriorUDataArray.MinLayer;
        StartRow := PriorUDataArray.MinRow;
        StartCol := PriorUDataArray.MinColumn;
      end
      else
      begin
        StartLayer := UDataArray.MinLayer;
        StartRow := UDataArray.MinRow;
        StartCol := UDataArray.MinColumn;
      end;

      for LayerIndex := StartLayer to
        Max(PriorUDataArray.MaxLayer, UDataArray.MaxLayer) do
      begin
        for RowIndex := StartRow to
          Max(PriorUDataArray.MaxRow, UDataArray.MaxRow) do
        begin
          for ColIndex := StartCol to
            Max(PriorUDataArray.MaxColumn, UDataArray.MaxColumn) do
          begin
            if FNodeNumbers.IsValue[LayerIndex, RowIndex, ColIndex]
              and not FUseBctime[LayerIndex, RowIndex,ColIndex] then
            begin
              if UDataArray.IsValue[LayerIndex, RowIndex, ColIndex]
                <> PriorUDataArray.IsValue[LayerIndex, RowIndex, ColIndex] then
              begin
                Inc(Count);
              end
              else if UDataArray.IsValue[LayerIndex, RowIndex, ColIndex] then
              begin
                if (UDataArray.RealData[LayerIndex, RowIndex, ColIndex]
                  <> PriorUDataArray.RealData[LayerIndex, RowIndex, ColIndex])
                  or UFormulasUsed[LayerIndex, ColIndex] then
                begin
                  Inc(Count);
                end
                else
                begin
                  if PQDataArray <> nil then
                  begin
                    if (PQDataArray.RealData[LayerIndex, RowIndex, ColIndex]
                      <> PriorPQDataArray.RealData[LayerIndex, RowIndex, ColIndex])
                      or PQFormulasUsed[LayerIndex, ColIndex]  then
                    begin
                      Inc(Count);
                    end
                  end;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  case FBoundaryType of
    sbtFluidSource:
      begin
        BCSID := '''Fluid sources''';
        NSOP1 := Count;
      end;
    sbtMassEnergySource:
      begin
        BCSID := '''Mass/Energy sources''';
        NSOU1 := Count;
      end;
    sbtSpecPress:
      begin
        BCSID := '''Specified Pressure''';
        NPBC1 := Count;
      end;
    sbtSpecConcTemp:
      begin
        BCSID := '''Specified Temperature or Concentration''';
        NUBC1 := Count;
      end;
  end;

  WriteString(BCSID);
  WriteInteger(NSOP1);
  WriteInteger(NSOU1);
  WriteInteger(NPBC1);
  WriteInteger(NUBC1);
  if Model.ModelSelection <> msSutra22 then
  begin
    WriteInteger(NPBG1);
    WriteInteger(NUBG1);
  end;
  WriteString(' # Data Set 2: BCSID, NSOP1, NSOU1, NPBC1, NUBC1');
  if Model.ModelSelection <> msSutra22 then
  begin
    WriteString(', NPBG1, NUBG1');
  end;
  NewLine;
end;

procedure TSutraBoundaryWriter.WriteDataSet3(TimeIndex: integer; PQTimeList,
  UTimeList: TSutraMergedTimeList);
var
  LayerIndex: Integer;
  RowIndex: Integer;
  ColIndex: Integer;
  UDataArray: TDataArray;
  PQDataArray: TDataArray;
  IQCP1: NativeInt;
  QINC1: double;
  UINC1: double;
  Changed: Boolean;
  PriorUDataArray: TDataArray;
  PriorPQDataArray: TDataArray;
  AnyChanged: Boolean;
  UseBCTime: Boolean;
  PQFormulas: T3DSparseStringArray;
  PQFormulasUsed: T2DSparseBooleanArray;
  UFormulas: T3DSparseStringArray;
  UFormulasUsed: T2DSparseBooleanArray;
  PQFormula: string;
  UFormula: string;
  MergedUsedDataArray: TDataArray;
//  ActiveNodeDataArray: TDataArray;
  procedure WriteALine;
  begin
    AnyChanged := True;
    WriteInteger(IQCP1);
    if IQCP1 > 0 then
    begin
      if WritingTemplate and (PQFormula <> '') then
      begin
        WriteString(PQFormula);
      end
      else
      begin
        WriteFloat(QINC1);
      end;
      if WritingTemplate and (UFormula <> '') then
      begin
        WriteString(UFormula);
      end
      else
      begin
        WriteFloat(UINC1);
      end;
    end;
    WriteString(' # Data Set 3: IQCP1');
    if IQCP1 > 0 then
    begin
      WriteString(', QINC1, UINC1');
    end;
    NewLine;
  end;
begin
  if FBoundaryType <> sbtFluidSource then
  begin
    Exit;
  end;
  if TimeIndex < PQTimeList.Count then
  begin
    WriteCommentLine('Data set 3; Time = ' + FortranFloatToStr(PQTimeList.Times[TimeIndex]));
  end
  else
  begin
    WriteCommentLine('Data set 3');
  end;

  UDataArray := UTimeList[TimeIndex];
  PQDataArray := PQTimeList[TimeIndex];
  MergedUsedDataArray := PQTimeList.UsedItems[TimeIndex];

  PQFormulas := FPQPestTimeFormulas[TimeIndex];
  PQFormulasUsed := FPQFormulaUsed[TimeIndex];
  UFormulas := FUPestTimeFormulas[TimeIndex];
  UFormulasUsed := FUFormulaUsed[TimeIndex];

  if FNodeNumbers.MaxLayer < 0 then
  begin
    Exit;
  end;
  AnyChanged := False;
  if TimeIndex = 0 then
  begin
    for LayerIndex := FNodeNumbers.MinLayer to FNodeNumbers.MaxLayer do
    begin
      for RowIndex := FNodeNumbers.MinRow to FNodeNumbers.MaxRow do
      begin
        for ColIndex := FNodeNumbers.MinCol to FNodeNumbers.MaxCol do
        begin
          if FNodeNumbers.IsValue[LayerIndex, RowIndex,ColIndex] then
          begin
            PQFormula := '';
            UFormula := '';
            if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
            begin
              if not PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                frmErrorsAndWarnings.AddError(Model, StrErrorInDataSet3,
                  Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                Exit;
              end;
              Assert(PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
              IQCP1 := FNodeNumbers[LayerIndex, RowIndex,ColIndex] + 1;
              Assert(IQCP1 > 0);
              if not MergedUsedDataArray.BooleanData[LayerIndex, RowIndex,ColIndex] then
              begin
                IQCP1 := -IQCP1;
              end;
              QINC1 := PQDataArray.RealData[LayerIndex, RowIndex,ColIndex];
              UINC1 := UDataArray.RealData[LayerIndex, RowIndex,ColIndex];
              if not PQFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                  Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                Exit;
              end;
              Assert(PQFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
              if not PQFormulasUsed.IsValue[LayerIndex, ColIndex] then
              begin
                frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                  Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                Exit;
              end;
              Assert(PQFormulasUsed.IsValue[LayerIndex, ColIndex]);
              if not UFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                  Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                Exit;
              end;
              Assert(UFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
              if not UFormulasUsed.IsValue[LayerIndex, ColIndex] then
              begin
                frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                  Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                Exit;
              end;
              Assert(UFormulasUsed.IsValue[LayerIndex, ColIndex]);
              if PQFormulasUsed[LayerIndex, ColIndex] then
              begin
                PQFormula := PQFormulas[LayerIndex, RowIndex,ColIndex];
                ExtendedTemplateFormula(PQFormula);
              end;
              if UFormulasUsed[LayerIndex, ColIndex] then
              begin
                UFormula := UFormulas[LayerIndex, RowIndex,ColIndex];
                ExtendedTemplateFormula(UFormula);
              end;
            end
            else
            begin
              Assert(not PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
              IQCP1 := -FNodeNumbers[LayerIndex, RowIndex,ColIndex] - 1;
              Assert(IQCP1 < 0);
              QINC1 := 0.0;
              UINC1 := 0.0;
            end;
            if not FUseBctime[LayerIndex, RowIndex,ColIndex] then
            begin
              WriteALine;
            end;
            if PQTimeList.Times[0] > FTime1 then
            begin
              QINC1 := 0.0;
              UINC1 := 0.0;
            end;
            if FUseBCTime.IsValue[LayerIndex, RowIndex,ColIndex] then
            begin
              UseBCTime := FUseBCTime.Items[LayerIndex, RowIndex,ColIndex];
            end
            else
            begin
              UseBCTime := False;
            end;
            FIBoundaryNodes.AddUnique(TBoundaryNode.Create(IQCP1, QINC1,
              UINC1, UseBCTime, PQFormula, UFormula));
          end;
        end;
      end;
    end;
  end
  else
  begin
    PriorUDataArray := UTimeList[TimeIndex-1];
    PriorPQDataArray := PQTimeList[TimeIndex-1];
    for LayerIndex := FNodeNumbers.MinLayer to FNodeNumbers.MaxLayer do
    begin
      for RowIndex := FNodeNumbers.MinRow to FNodeNumbers.MaxRow do
      begin
        for ColIndex := FNodeNumbers.MinCol to FNodeNumbers.MaxCol do
        begin
          if FNodeNumbers.IsValue[LayerIndex, RowIndex,ColIndex] then
          begin
            Changed := False;
            if PriorUDataArray.IsValue[LayerIndex, RowIndex,ColIndex]
              <> UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
            begin
              Changed := True;
            end
            else
            begin
              if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                Assert(PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
                Assert(PriorPQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
                Changed := (UDataArray.RealData[LayerIndex, RowIndex,ColIndex]
                  <> PriorUDataArray.RealData[LayerIndex, RowIndex,ColIndex])
                  or (PQDataArray.RealData[LayerIndex, RowIndex,ColIndex]
                  <> PriorPqDataArray.RealData[LayerIndex, RowIndex,ColIndex]);
                if not Changed {and WritingTemplate} then
                begin
                  if PQFormulasUsed[LayerIndex, ColIndex]
                    or UFormulasUsed[LayerIndex, ColIndex] then
                  begin
                    Changed := True;
                  end;
                end;
              end;
            end;
            if Changed then
            begin
              PQFormula := '';
              UFormula := '';
              if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                if not PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
                IQCP1 := FNodeNumbers[LayerIndex, RowIndex,ColIndex] + 1;
                Assert(IQCP1 > 0);
                if not MergedUsedDataArray.BooleanData[LayerIndex, RowIndex,ColIndex] then
                begin
                  IQCP1 := -IQCP1;
                end;
                QINC1 := PQDataArray.RealData[LayerIndex, RowIndex,ColIndex];
                UINC1 := UDataArray.RealData[LayerIndex, RowIndex,ColIndex];

                if not PQFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(PQFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
                if not PQFormulasUsed.IsValue[LayerIndex, ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(PQFormulasUsed.IsValue[LayerIndex, ColIndex]);
                if not UFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(UFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
                if not UFormulasUsed.IsValue[LayerIndex, ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(UFormulasUsed.IsValue[LayerIndex, ColIndex]);
                if PQFormulasUsed[LayerIndex, ColIndex] then
                begin
                  PQFormula := PQFormulas[LayerIndex, RowIndex,ColIndex];
                  ExtendedTemplateFormula(PQFormula);
  //                  PQFormula := Format(StrExtendedTemplateFormat, [PQFormula]);
                end;
                if UFormulasUsed[LayerIndex, ColIndex] then
                begin
                  UFormula := UFormulas[LayerIndex, RowIndex,ColIndex];
                  ExtendedTemplateFormula(UFormula);
  //                  UFormula := Format(StrExtendedTemplateFormat, [UFormula]);
                end;
              end
              else
              begin
                Assert(not PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
                IQCP1 := -FNodeNumbers[LayerIndex, RowIndex,ColIndex] - 1;
                Assert(IQCP1 < 0);
                QINC1 := 0.0;
                UINC1 := 0.0;
              end;
              if not FUseBctime[LayerIndex, RowIndex,ColIndex] then
              begin
                WriteALine;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  if AnyChanged then
  begin
    WriteInteger(0);
    NewLine;
  end;
end;

procedure TSutraBoundaryWriter.WriteDataSet4(TimeIndex: integer;
  UTimeList: TSutraMergedTimeList);
var
  LayerIndex: Integer;
  RowIndex: Integer;
  ColIndex: Integer;
  UDataArray: TDataArray;
  IQCU1: NativeInt;
  QUINC1: double;
  Changed: Boolean;
  PriorUDataArray: TDataArray;
  AnyChanged: Boolean;
  UseBCTime: Boolean;
//  PQFormulas: T3DSparseStringArray;
//  PQFormulasUsed: T2DSparseBooleanArray;
  UFormulas: T3DSparseStringArray;
  UFormulasUsed: T2DSparseBooleanArray;
  UFormula: string;
  MergedUsedDataArray: TDataArray;
//  ActiveNodeDataArray: TDataArray;
  procedure WriteALine;
  begin
    AnyChanged := True;
    WriteInteger(IQCU1);
    if IQCU1 > 0 then
    begin
      if WritingTemplate and (UFormula <> '') then
      begin
        WriteString(UFormula);
      end
      else
      begin
        WriteFloat(QUINC1);
      end;
    end;
    WriteString(' # Data Set 4: IQCU1');
    if IQCU1 > 0 then
    begin
      WriteString(', QUINC1');
    end;
    NewLine;
  end;
begin
  if FBoundaryType <> sbtMassEnergySource then
  begin
    Exit;
  end;
  if TimeIndex < UTimeList.Count then
  begin
    WriteCommentLine('Data set 4; Time = ' + FortranFloatToStr(UTimeList.Times[TimeIndex]));
  end
  else
  begin
    WriteCommentLine('Data set 4');
  end;
  if FNodeNumbers.MaxLayer < 0 then
  begin
    Exit;
  end;

  UDataArray := UTimeList[TimeIndex];
  MergedUsedDataArray := UTimeList.UsedItems[TimeIndex];

  UFormulas := FUPestTimeFormulas[TimeIndex];
  UFormulasUsed := FUFormulaUsed[TimeIndex];


  AnyChanged := False;
  if TimeIndex = 0 then
  begin
    for LayerIndex := FNodeNumbers.MinLayer to FNodeNumbers.MaxLayer do
    begin
      for RowIndex := FNodeNumbers.MinRow to FNodeNumbers.MaxRow do
      begin
        for ColIndex := FNodeNumbers.MinCol to FNodeNumbers.MaxCol do
        begin
          if FNodeNumbers.IsValue[LayerIndex, RowIndex,ColIndex] then
//            and (FNodeNumbers[LayerIndex, RowIndex,ColIndex] <> 0) then
          begin
//            PQFormula := '';
            UFormula := '';
            if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
            begin
              IQCU1 := FNodeNumbers[LayerIndex, RowIndex,ColIndex] + 1;
              Assert(IQCU1 > 0);
              if not MergedUsedDataArray.BooleanData[LayerIndex, RowIndex,ColIndex] then
              begin
                IQCU1 := -IQCU1;
              end;
              QUINC1 := UDataArray.RealData[LayerIndex, RowIndex,ColIndex];
              if not UFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                  Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                Exit;
              end;
              Assert(UFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
              if not UFormulasUsed.IsValue[LayerIndex, ColIndex] then
              begin
                frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                  Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                Exit;
              end;
              Assert(UFormulasUsed.IsValue[LayerIndex, ColIndex]);
              if UFormulasUsed[LayerIndex, ColIndex] then
              begin
                UFormula := UFormulas[LayerIndex, RowIndex,ColIndex];
                ExtendedTemplateFormula(UFormula);
              end;
            end
            else
            begin
              IQCU1 := -FNodeNumbers[LayerIndex, RowIndex,ColIndex] - 1;
              Assert(IQCU1 < 0);
              QUINC1 := 0.0;
            end;
            if not FUseBctime[LayerIndex, RowIndex,ColIndex] then
            begin
              WriteALine;
            end;
            if UTimeList.Times[0] > FTime1 then
            begin
              QUINC1 := 0.0;
            end;
            if FUseBCTime.IsValue[LayerIndex, RowIndex,ColIndex] then
            begin
              UseBCTime := FUseBCTime.Items[LayerIndex, RowIndex,ColIndex];
            end
            else
            begin
              UseBCTime := False;
            end;
            FIBoundaryNodes.AddUnique(TBoundaryNode.Create(IQCU1, 0,
              QUINC1, UseBCTime, '', UFormula));
          end;
        end;
      end;
    end;
  end
  else
  begin
    PriorUDataArray := UTimeList[TimeIndex-1];
    for LayerIndex := FNodeNumbers.MinLayer to FNodeNumbers.MaxLayer do
    begin
      for RowIndex := FNodeNumbers.MinRow to FNodeNumbers.MaxRow do
      begin
        for ColIndex := FNodeNumbers.MinCol to FNodeNumbers.MaxCol do
        begin
          if FNodeNumbers.IsValue[LayerIndex, RowIndex,ColIndex] then
          begin
            Changed := False;
            if PriorUDataArray.IsValue[LayerIndex, RowIndex,ColIndex]
              <> UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
            begin
              Changed := True;
            end
            else
            begin
              if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                Changed := (UDataArray.RealData[LayerIndex, RowIndex,ColIndex]
                  <> PriorUDataArray.RealData[LayerIndex, RowIndex,ColIndex]);
                if not Changed {and WritingTemplate} then
                begin
                  if UFormulasUsed[LayerIndex, ColIndex] then
                  begin
                    Changed := True;
                  end;
                end;
              end;
            end;
            if Changed then
            begin
              if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                IQCU1 := FNodeNumbers[LayerIndex, RowIndex,ColIndex] + 1;
                Assert(IQCU1 > 0);
                if not MergedUsedDataArray.BooleanData[LayerIndex, RowIndex,ColIndex] then
                begin
                  IQCU1 := -IQCU1;
                end;
                QUINC1 := UDataArray.RealData[LayerIndex, RowIndex,ColIndex];
                if not UFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(UFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
                if not UFormulasUsed.IsValue[LayerIndex, ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(UFormulasUsed.IsValue[LayerIndex, ColIndex]);
                if UFormulasUsed[LayerIndex, ColIndex] then
                begin
                  UFormula := UFormulas[LayerIndex, RowIndex,ColIndex];
                  ExtendedTemplateFormula(UFormula);
                end;
              end
              else
              begin
                IQCU1 := -FNodeNumbers[LayerIndex, RowIndex,ColIndex] - 1;
                Assert(IQCU1 < 0);
                QUINC1 := 0.0;
              end;
              if not FUseBctime[LayerIndex, RowIndex,ColIndex] then
              begin
                WriteALine;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  if AnyChanged then
  begin
    WriteInteger(0);
    NewLine;
  end;
end;

procedure TSutraBoundaryWriter.WriteDataSet5(TimeIndex: integer; PQTimeList,
  UTimeList: TSutraMergedTimeList);
var
  LayerIndex: Integer;
  RowIndex: Integer;
  ColIndex: Integer;
  UDataArray: TDataArray;
  PQDataArray: TDataArray;
  IPBC1: NativeInt;
  PBC1: double;
  UBC1: double;
  Changed: Boolean;
  PriorUDataArray: TDataArray;
  PriorPQDataArray: TDataArray;
  AnyChanged: Boolean;
  UseBCTime: Boolean;
  PQFormulas: T3DSparseStringArray;
  PQFormulasUsed: T2DSparseBooleanArray;
  UFormulas: T3DSparseStringArray;
  UFormulasUsed: T2DSparseBooleanArray;
  PQFormula: string;
  UFormula: string;
  MergedUsedDataArray: TDataArray;
//  ActiveNodeDataArray: TDataArray;
  procedure WriteALine;
  begin
    AnyChanged := True;
    WriteInteger(IPBC1);
    if IPBC1 > 0 then
    begin
      if WritingTemplate and (PQFormula <> '') then
      begin
        WriteString(PQFormula);
      end
      else
      begin
        WriteFloat(PBC1);
      end;
      if WritingTemplate and (UFormula <> '') then
      begin
        WriteString(UFormula);
      end
      else
      begin
        WriteFloat(UBC1);
      end;
    end;
    WriteString(' # Data Set 5: IPBC1');
    if IPBC1 > 0 then
    begin
      WriteString(', PBC1, UBC1');
    end;
    NewLine;
  end;
begin
  if FBoundaryType <> sbtSpecPress then
  begin
    Exit;
  end;
  if TimeIndex < PQTimeList.Count then
  begin
    WriteCommentLine('Data set 5; Time = ' + FortranFloatToStr(PQTimeList.Times[TimeIndex]));
  end
  else
  begin
    WriteCommentLine('Data set 5');
  end;
  if FNodeNumbers.MaxLayer < 0 then
  begin
    Exit;
  end;
  UDataArray := UTimeList[TimeIndex];
  PQDataArray := PQTimeList[TimeIndex];
  MergedUsedDataArray := PQTimeList.UsedItems[TimeIndex];

  PQFormulas := FPQPestTimeFormulas[TimeIndex];
  PQFormulasUsed := FPQFormulaUsed[TimeIndex];
  UFormulas := FUPestTimeFormulas[TimeIndex];
  UFormulasUsed := FUFormulaUsed[TimeIndex];

  AnyChanged := False;
  if (FNodeNumbers.MaxLayer >= 0) then
  begin
    if (TimeIndex = 0) then
    begin
      for LayerIndex := FNodeNumbers.MinLayer to FNodeNumbers.MaxLayer do
      begin
        for RowIndex := FNodeNumbers.MinRow to FNodeNumbers.MaxRow do
        begin
          for ColIndex := FNodeNumbers.MinCol to FNodeNumbers.MaxCol do
          begin
            if FNodeNumbers.IsValue[LayerIndex, RowIndex,ColIndex] then
//              and (FNodeNumbers[LayerIndex, RowIndex,ColIndex] <> 0) then
            begin
              PQFormula := '';
              UFormula := '';
              if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                if not PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
                IPBC1 := FNodeNumbers[LayerIndex, RowIndex,ColIndex] + 1;
                Assert(IPBC1 > 0);
                if not MergedUsedDataArray.BooleanData[LayerIndex, RowIndex,ColIndex] then
                begin
                  IPBC1 := -IPBC1;
                end;
                PBC1 := PQDataArray.RealData[LayerIndex, RowIndex,ColIndex];
                UBC1 := UDataArray.RealData[LayerIndex, RowIndex,ColIndex];
                if not PQFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(PQFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
                if not PQFormulasUsed.IsValue[LayerIndex, ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(PQFormulasUsed.IsValue[LayerIndex, ColIndex]);
                if not UFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(UFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
                if not UFormulasUsed.IsValue[LayerIndex, ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(UFormulasUsed.IsValue[LayerIndex, ColIndex]);
                if PQFormulasUsed[LayerIndex, ColIndex] then
                begin
                  PQFormula := PQFormulas[LayerIndex, RowIndex,ColIndex];
                  ExtendedTemplateFormula(PQFormula);
//                  PQFormula := Format(StrExtendedTemplateFormat, [PQFormula]);
                end;
                if UFormulasUsed[LayerIndex, ColIndex] then
                begin
                  UFormula := UFormulas[LayerIndex, RowIndex,ColIndex];
                  ExtendedTemplateFormula(UFormula);
//                  UFormula := Format(StrExtendedTemplateFormat, [UFormula]);
                end;
              end
              else
              begin
                Assert(not PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
                IPBC1 := -FNodeNumbers[LayerIndex, RowIndex,ColIndex] - 1;
                Assert(IPBC1 < 0);
                PBC1 := 0.0;
                UBC1 := 0.0;
              end;
              if not FUseBctime[LayerIndex, RowIndex,ColIndex] then
              begin
                WriteALine;
              end;
              if PQTimeList.Times[0] > FTime1 then
              begin
                PBC1 := 0.0;
                UBC1 := 0.0;
              end;
              if FUseBCTime.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                UseBCTime := FUseBCTime.Items[LayerIndex, RowIndex,ColIndex];
              end
              else
              begin
                UseBCTime := False;
              end;
              FIBoundaryNodes.AddUnique(TBoundaryNode.Create(IPBC1, PBC1,
                UBC1, UseBCTime, PQFormula, UFormula));
            end;
          end;
        end;
      end;
    end
    else
    begin
      PriorUDataArray := UTimeList[TimeIndex-1];
      PriorPQDataArray := PQTimeList[TimeIndex-1];
      for LayerIndex := FNodeNumbers.MinLayer to FNodeNumbers.MaxLayer do
      begin
        for RowIndex := FNodeNumbers.MinRow to FNodeNumbers.MaxRow do
        begin
          for ColIndex := FNodeNumbers.MinCol to FNodeNumbers.MaxCol do
          begin
            if FNodeNumbers.IsValue[LayerIndex, RowIndex,ColIndex]
              and not FUseBctime[LayerIndex, RowIndex,ColIndex] then
            begin
              Changed := False;
              if PriorUDataArray.IsValue[LayerIndex, RowIndex,ColIndex]
                <> UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                Changed := True;
              end
              else
              begin
                if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
                begin
                  if not PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
                  begin
                    frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                      Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                    Exit;
                  end;
                  Assert(PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
                  if not PriorPQDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
                  begin
                    frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                      Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                    Exit;
                  end;
                  Assert(PriorPQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
                  Changed := (UDataArray.RealData[LayerIndex, RowIndex,ColIndex]
                    <> PriorUDataArray.RealData[LayerIndex, RowIndex,ColIndex])
                    or (PQDataArray.RealData[LayerIndex, RowIndex,ColIndex]
                    <> PriorPqDataArray.RealData[LayerIndex, RowIndex,ColIndex]);
                  if not Changed {and WritingTemplate} then
                  begin
                    if PQFormulasUsed[LayerIndex, ColIndex]
                      or UFormulasUsed[LayerIndex, ColIndex] then
                    begin
                      Changed := True;
                    end;
                  end;
                end;
              end;
              if Changed then
              begin
                PQFormula := '';
                UFormula := '';
                if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
                begin
                  if not PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
                  begin
                    frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                      Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                    Exit;
                  end;
                  Assert(PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
                  IPBC1 := FNodeNumbers[LayerIndex, RowIndex,ColIndex] + 1;
                  Assert(IPBC1 > 0);
                  if not MergedUsedDataArray.BooleanData[LayerIndex, RowIndex,ColIndex] then
                  begin
                    IPBC1 := -IPBC1;
                  end;
                  PBC1 := PQDataArray.RealData[LayerIndex, RowIndex,ColIndex];
                  UBC1 := UDataArray.RealData[LayerIndex, RowIndex,ColIndex];

                  if not PQFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
                  begin
                    frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                      Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                    Exit;
                  end;
                  Assert(PQFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
                  if not PQFormulasUsed.IsValue[LayerIndex, ColIndex] then
                  begin
                    frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                      Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                    Exit;
                  end;
                  Assert(PQFormulasUsed.IsValue[LayerIndex, ColIndex]);
                  if not UFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
                  begin
                    frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                      Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                    Exit;
                  end;
                  Assert(UFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
                  if not UFormulasUsed.IsValue[LayerIndex, ColIndex] then
                  begin
                    frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                      Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                    Exit;
                  end;
                  Assert(UFormulasUsed.IsValue[LayerIndex, ColIndex]);
                  if PQFormulasUsed[LayerIndex, ColIndex] then
                  begin
                    PQFormula := PQFormulas[LayerIndex, RowIndex,ColIndex];
                    ExtendedTemplateFormula(PQFormula);
  //                  PQFormula := Format(StrExtendedTemplateFormat, [PQFormula]);
                  end;
                  if UFormulasUsed[LayerIndex, ColIndex] then
                  begin
                    UFormula := UFormulas[LayerIndex, RowIndex,ColIndex];
                    ExtendedTemplateFormula(UFormula);
  //                  UFormula := Format(StrExtendedTemplateFormat, [UFormula]);
                  end;
                end
                else
                begin
                  Assert(not PQDataArray.IsValue[LayerIndex, RowIndex,ColIndex]);
                  IPBC1 := -FNodeNumbers[LayerIndex, RowIndex,ColIndex] - 1;
                  Assert(IPBC1 < 0);
                  PBC1 := 0.0;
                  UBC1 := 0.0;
                end;
                if not FUseBctime[LayerIndex, RowIndex,ColIndex] then
                begin
                  WriteALine;
                end;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  if AnyChanged then
  begin
    WriteInteger(0);
    NewLine;
  end;
end;

procedure TSutraBoundaryWriter.WriteDataSet6(TimeIndex: integer;
  UTimeList: TSutraMergedTimeList);
var
  LayerIndex: Integer;
  RowIndex: Integer;
  ColIndex: Integer;
  UDataArray: TDataArray;
  IUBC1: NativeInt;
  UBC1: double;
  Changed: Boolean;
  PriorUDataArray: TDataArray;
  AnyChanged: Boolean;
  UseBCTime: Boolean;
  UFormulas: T3DSparseStringArray;
  UFormulasUsed: T2DSparseBooleanArray;
  UFormula: string;
  MergedUsedDataArray: TDataArray;
  procedure WriteALine;
  begin
    AnyChanged := True;
    WriteInteger(IUBC1);
    if IUBC1 > 0 then
    begin
      if WritingTemplate and (UFormula <> '') then
      begin
        WriteString(UFormula);
      end
      else
      begin
        WriteFloat(UBC1);
      end;
    end;
    WriteString(' # Data Set 6: IUBC1');
    if IUBC1 > 0 then
    begin
      WriteString(', UBC1');
    end;
    NewLine;
  end;
begin
  if FBoundaryType <> sbtSpecConcTemp then
  begin
    Exit;
  end;
  if TimeIndex < UTimeList.Count then
  begin
    WriteCommentLine('Data set 6; Time = ' + FortranFloatToStr(UTimeList.Times[TimeIndex]));
  end
  else
  begin
    WriteCommentLine('Data set 6');
  end;
  if FNodeNumbers.MaxLayer < 0 then
  begin
    Exit;
  end;
  UDataArray := UTimeList[TimeIndex];
  MergedUsedDataArray := UTimeList.UsedItems[TimeIndex];

  UFormulas := FUPestTimeFormulas[TimeIndex];
  UFormulasUsed := FUFormulaUsed[TimeIndex];

  AnyChanged := False;
  if TimeIndex = 0 then
  begin
    for LayerIndex := FNodeNumbers.MinLayer to FNodeNumbers.MaxLayer do
    begin
      for RowIndex := FNodeNumbers.MinRow to FNodeNumbers.MaxRow do
      begin
        for ColIndex := FNodeNumbers.MinCol to FNodeNumbers.MaxCol do
        begin
          if FNodeNumbers.IsValue[LayerIndex, RowIndex,ColIndex] then
//            and (FNodeNumbers[LayerIndex, RowIndex,ColIndex] <> 0) then
          begin
            UFormula := '';
            if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
            begin
              IUBC1 := FNodeNumbers[LayerIndex, RowIndex,ColIndex] + 1;
              Assert(IUBC1 > 0);
              if not MergedUsedDataArray.BooleanData[LayerIndex, RowIndex,ColIndex] then
              begin
                IUBC1 := -IUBC1;
              end;
              UBC1 := UDataArray.RealData[LayerIndex, RowIndex,ColIndex];
              if not UFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                  Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                Exit;
              end;
              Assert(UFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
              if not UFormulasUsed.IsValue[LayerIndex, ColIndex] then
              begin
                frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                  Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                Exit;
              end;
              Assert(UFormulasUsed.IsValue[LayerIndex, ColIndex]);
              if UFormulasUsed[LayerIndex, ColIndex] then
              begin
                UFormula := UFormulas[LayerIndex, RowIndex,ColIndex];
                ExtendedTemplateFormula(UFormula);
              end;
            end
            else
            begin
              IUBC1 := -FNodeNumbers[LayerIndex, RowIndex,ColIndex] - 1;
              Assert(IUBC1 < 0);
              UBC1 := 0.0;
            end;
            if not FUseBctime[LayerIndex, RowIndex,ColIndex] then
            begin
              WriteALine;
            end;
            if UTimeList.Times[0] > FTime1 then
            begin
              UBC1 := 0.0;
            end;
            if FUseBCTime.IsValue[LayerIndex, RowIndex,ColIndex] then
            begin
              UseBCTime := FUseBCTime.Items[LayerIndex, RowIndex,ColIndex];
            end
            else
            begin
              UseBCTime := False;
            end;
            FIBoundaryNodes.AddUnique(TBoundaryNode.Create(IUBC1, 0, UBC1,
              UseBCTime, '', UFormula));
          end;
        end;
      end;
    end;
  end
  else
  begin
    PriorUDataArray := UTimeList[TimeIndex-1];
    for LayerIndex := FNodeNumbers.MinLayer to FNodeNumbers.MaxLayer do
    begin
      for RowIndex := FNodeNumbers.MinRow to FNodeNumbers.MaxRow do
      begin
        for ColIndex := FNodeNumbers.MinCol to FNodeNumbers.MaxCol do
        begin
          if FNodeNumbers.IsValue[LayerIndex, RowIndex,ColIndex] then
          begin
            Changed := False;
            if PriorUDataArray.IsValue[LayerIndex, RowIndex,ColIndex]
              <> UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
            begin
              Changed := True;
            end
            else
            begin
              if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                Changed := (UDataArray.RealData[LayerIndex, RowIndex,ColIndex]
                  <> PriorUDataArray.RealData[LayerIndex, RowIndex,ColIndex]);
                if not Changed {and WritingTemplate} then
                begin
                  if UFormulasUsed[LayerIndex, ColIndex] then
                  begin
                    Changed := True;
                  end;
                end;
              end;
            end;
            if Changed then
            begin
              if UDataArray.IsValue[LayerIndex, RowIndex,ColIndex] then
              begin
                IUBC1 := FNodeNumbers[LayerIndex, RowIndex,ColIndex] + 1;
                Assert(IUBC1 > 0);
                if not MergedUsedDataArray.BooleanData[LayerIndex, RowIndex,ColIndex] then
                begin
                  IUBC1 := -IUBC1;
                end;
                UBC1 := UDataArray.RealData[LayerIndex, RowIndex,ColIndex];
                if not UFormulas.IsValue[LayerIndex, RowIndex,ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(UFormulas.IsValue[LayerIndex, RowIndex,ColIndex]);
                if not UFormulasUsed.IsValue[LayerIndex, ColIndex] then
                begin
                  frmErrorsAndWarnings.AddError(Model, StrErrorEvaluatingBou,
                    Format(StrErrorInLayer0d, [LayerIndex+1, ColIndex+1]));
                  Exit;
                end;
                Assert(UFormulasUsed.IsValue[LayerIndex, ColIndex]);
                if UFormulasUsed[LayerIndex, ColIndex] then
                begin
                  UFormula := UFormulas[LayerIndex, RowIndex,ColIndex];
                  ExtendedTemplateFormula(UFormula);
                end;
              end
              else
              begin
                IUBC1 := -FNodeNumbers[LayerIndex, RowIndex,ColIndex] - 1;
                Assert(IUBC1 < 0);
                UBC1 := 0.0;
              end;
              if not FUseBctime[LayerIndex, RowIndex,ColIndex] then
              begin
                WriteALine;
              end;
            end;
          end;
        end;
      end;
    end;
  end;
  if AnyChanged then
  begin
    WriteInteger(0);
    NewLine;
  end;
end;

procedure TSutraBoundaryWriter.WriteFile(FileName: string;
  BoundaryNodes: IBoundaryNodes; BcsFileNames: TLakeInteractionStringList);
var
  UTimeList: TSutraMergedTimeList;
  PQTimeList: TSutraMergedTimeList;
  SimulationType: TSimulationType;
  FirstTimeSpecified: Boolean;
  InitialTime: double;
  LakeExtension: string;
//  LakeInteraction: TLakeBoundaryInteraction;
  FileRoot: string;
begin
  FBcsFileNames := BcsFileNames;
  FIBoundaryNodes := BoundaryNodes;
//  FIBoundaryNodes.Clear;

  if BcsFileNames <> nil then
  begin
    case BcsFileNames.LakeInteraction of
      lbiActivate:
        begin
          LakeExtension := '.ActivateLake';
        end;
      lbiNoChange:
        begin
          LakeExtension := '.NoChangeLake';
        end;
      lbiInactivate:
        begin
          LakeExtension := '.InactivateLake';
        end;
      lbiUseDefaults:
        begin
          LakeExtension := '';
        end;
      else
        Assert(False);
    end;
  end
  else
  begin
    LakeExtension := '';
  end;
  FileRoot := ChangeFileExt(FileName, '');
  FileName := ChangeFileExt(FileName, LakeExtension);

  case FBoundaryType of
    sbtFluidSource: FileName := FileName + '.FluxBcs';
    sbtMassEnergySource: FileName := FileName + '.UFluxBcs';
    sbtSpecPress: FileName := FileName + '.SPecPBcs';
    sbtSpecConcTemp: FileName := FileName + '.SPecUBcs';
    else Assert(False);
  end;
  FNameOfFile := FileName;
  FInputFileName := FNameOfFile;

  UTimeList := TSutraMergedTimeList.Create(Model);
  PQTimeList := TSutraMergedTimeList.Create(Model);
  try
    // UpdateMergeLists calls Evaluate.
    UpdateMergeLists(PQTimeList, UTimeList);

    if (PQTimeList.Count > 0) or (UTimeList.Count > 0) then
    begin
      SimulationType := Model.SutraOptions.SimulationType;
      if (FBoundaryType in [sbtFluidSource, sbtSpecPress])
        and (SimulationType = stSteadyFlowSteadyTransport) then
      begin
        FirstTimeSpecified := False;
        InitialTime := (Model as TPhastModel).SutraTimeOptions.InitialTime;
        if (PQTimeList.Count > 0) and (PQTimeList.Times[0] = InitialTime) then
        begin
          FirstTimeSpecified := True;
        end
        else if (UTimeList.Count > 0) and (UTimeList.Times[0] = InitialTime) then
        begin
          FirstTimeSpecified := True;
        end;
        if not FirstTimeSpecified then
        begin
          PQTimeList.Clear;
          UTimeList.Clear;
          if BcsFileNames <> nil then
          begin
            BcsFileNames.Add('');
          end;
          Exit;
        end;
      end;
      WriteFileInternal(BcsFileNames, FileRoot, FileName, UTimeList, PQTimeList);

      if  Model.PestUsed and FPestParamUsed then
      begin
        FNameOfFile := FNameOfFile + '.tpl';
        WritePestTemplateLine(FNameOfFile);
        WritingTemplate := True;
        WriteFileInternal(BcsFileNames, FileRoot, FileName, UTimeList, PQTimeList);
      end;
    end
    else
    begin
      if BcsFileNames <> nil then
      begin
        BcsFileNames.Add('');
      end;
    end;
  finally
    PQTimeList.Free;
    UTimeList.Free;
  end;
end;

procedure TSutraBoundaryWriter.WriteFileInternal(BcsFileNames: TLakeInteractionStringList; FileRoot: string; FileName: string; UTimeList: TSutraMergedTimeList; PQTimeList: TSutraMergedTimeList);
var
  TimeIndex: Integer;
begin
  OpenFile(FNameOfFile);
  try
    WriteTemplateHeader;

    if (BcsFileNames <> nil) then
    begin
      if not WritingTemplate then
      begin
        if (BcsFileNames.LakeInteraction <> lbiUseDefaults) then
        begin
          BcsFileNames.Add(FNameOfFile);
        end
        else
        begin
          BcsFileNames.Add('');
        end;
      end;
    end;
    WriteDataSet0;
    WriteDataSet1;
    for TimeIndex := 0 to UTimeList.Count - 1 do
    begin
      WriteDataSet2(TimeIndex, PQTimeList, UTimeList);
      WriteDataSet3(TimeIndex, PQTimeList, UTimeList);
      WriteDataSet4(TimeIndex, UTimeList);
      WriteDataSet5(TimeIndex, PQTimeList, UTimeList);
      WriteDataSet6(TimeIndex, UTimeList);
    end;
    if not WritingTemplate then
    begin
      SutraFileWriter.AddBoundaryFile(FNameOfFile);
    end;
    case FBoundaryType of
      sbtFluidSource:
        begin
          SutraFileWriter.AddFile(sftBcof, ChangeFileExt(FileRoot, '.bcof'));
        end;
      sbtMassEnergySource:
        begin
          SutraFileWriter.AddFile(sftBcos, ChangeFileExt(FileRoot, '.bcos'));
        end;
      sbtSpecPress:
        begin
          SutraFileWriter.AddFile(sftBcop, ChangeFileExt(FileRoot, '.bcop'));
        end;
      sbtSpecConcTemp:
        begin
          SutraFileWriter.AddFile(sftBcou, ChangeFileExt(FileRoot, '.bcou'));
        end;
    end;
  finally
    CloseFile;
  end;
end;

{ TSutraFluxCheckList }

procedure TSutraFluxCheckList.CheckSameModel(const Data: TDataArray);
begin
  if (Data <> nil) and (Model <> nil) then
  begin
    Assert(Model = (Data.Model as TCustomModel));
  end;
end;

procedure TSutraFluxCheckList.Initialize(Times: TRealList = nil);
begin
  // do nothig.
end;

{ TBoundaryNodes }

procedure TBoundaryNodes.AddUnique(Node: TBoundaryNode);
begin
  if not ContainsKey(Node.NodeNumber) then
  begin
    Add(Node.NodeNumber, Node);
  end;

end;

function TBoundaryNodes.GetCount: Integer;
begin
  Result := inherited Count;
end;

function TBoundaryNodes.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TBoundaryNodes.ToArray: TArray<TPair<Integer, TBoundaryNode>>;
type
  TNodeComparer = TComparer<TPair<Integer, TBoundaryNode>>;
var
  Comparer: IComparer<TPair<Integer, TBoundaryNode>>;
begin
  result := inherited;
  // sort the nodes in ascending order.
  Comparer := TNodeComparer.Construct(
    function(const L, R: TPair<Integer, TBoundaryNode>): Integer
    begin
      result := L.Key - R.Key;
    end
    );
  TArray.Sort<TPair<Integer, TBoundaryNode>>(Result, Comparer );
end;

function TBoundaryNodes._AddRef: Integer;
begin
  Result := InterlockedIncrement(FRefCount);
end;

function TBoundaryNodes._Release: Integer;
begin
  Result := InterlockedDecrement(FRefCount);
  if Result = 0 then
    Destroy;
end;

{ TLakeInteractionStringList }

constructor TLakeInteractionStringList.Create;
begin
  inherited;
  FLakeInteraction := lbiUseDefaults;
end;

procedure TLakeInteractionStringList.SetLakeInteraction(
  const Value: TLakeBoundaryInteraction);
begin
  FLakeInteraction := Value;
end;

end.
