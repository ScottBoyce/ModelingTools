unit Modflow6ModelImporter;

interface

uses
  System.Classes, System.IOUtils, Vcl.Dialogs, System.SysUtils, System.UITypes,
  Mf6.SimulationNameFileReaderUnit, System.Math, Mf6.CustomMf6PersistentUnit,
  ScreenObjectUnit, DataSetUnit, System.Generics.Collections,
  System.Generics.Defaults;

  // The first name in NameFiles must be the name of the groundwater flow
  // simulation name file (mfsim.nam). Any additional names must be associated
  // transport simulation name files (mfsim.nam)

type
  TimeSeriesMap = TDictionary<string, string>;

  TModflow6Importer = class(TObject)
  private
    FErrorMessages: TStringList;
    FSimulation: TMf6Simulation;
    FFlowModel: TModel;
    FAllTopCellsScreenObject: TScreenObject;
    FModelNameFile: string;
    TSIndex: Integer;
    procedure ImportFlowModelTiming;
    procedure ImportSimulationOptions;
    procedure ImportSolutionGroups;
    function ImportFlowModel: Boolean;
    procedure ImportDis(Package: TPackage);
    procedure ImportDisV(Package: TPackage);
    procedure UpdateLayerStructure(NumberOfLayers: Integer);
    procedure CreateAllTopCellsScreenObject;
    function GetAllTopCellsScreenObject: TScreenObject;
    property AllTopCellsScreenObject: TScreenObject read GetAllTopCellsScreenObject;
    procedure AssignRealValuesToCellCenters(DataArray: TDataArray;
      ScreenObject: TScreenObject; ImportedData: TDArray2D);
    procedure AssignIntegerValuesToCellCenters(DataArray: TDataArray;
      ScreenObject: TScreenObject; ImportedData: TIArray2D);
    procedure AssignBooleanValuesToCellCenters(DataArray: TDataArray;
      ScreenObject: TScreenObject; ImportedData: TBArray2D); overload;
    procedure AssignBooleanValuesToCellCenters(DataArray: TDataArray;
      ScreenObject: TScreenObject; ImportedData: TIArray2D); overload;
    procedure AssignIDomain(IDOMAIN: TIArray3D; NumberOfLayers: Integer);
    procedure AssignBOTM(BOTM: TDArray3D);
    procedure AssignTOP(TOP: TDArray2D);
    procedure ImportIc(Package: TPackage);
    procedure Assign3DRealDataSet(DsName: string; Data: TDArray3D);
    procedure Assign3DIntegerDataSet(DsName: string; Data: TIArray3D);
    procedure Assign3DBooleanDataSet(DsName: string; Data: TIArray3D);
    procedure ImportOc(Package: TPackage);
    procedure ImportGwfObs(Package: TPackage);
    procedure ImportNpf(Package: TPackage);
    procedure ImportTvk(Package: TPackage);
    procedure ImportTimeSeries(Package: TPackage; Map: TimeSeriesMap);
    procedure ImportHfb(Package: TPackage);
    procedure ImportSto(Package: TPackage);
    procedure ImportTvs(Package: TPackage);
    procedure ImportCSub(Package: TPackage);
    procedure ImportBuy(Package: TPackage);
    procedure ImportVsc(Package: TPackage);
    procedure ImportChd(Package: TPackage; TransportModels: TModelList);
  public
    Constructor Create;
    procedure ImportModflow6Model(NameFiles, ErrorMessages: TStringList);
  end;

implementation

uses
  PhastModelUnit, frmGoPhastUnit, GoPhastTypes, frmSelectFlowModelUnit,
  Mf6.TDisFileReaderUnit, ModflowTimeUnit, ModflowOptionsUnit,
  Mf6.AtsFileReaderUnit, ModflowPackageSelectionUnit, ModflowOutputControlUnit,
  Mf6.NameFileReaderUnit, Mf6.DisFileReaderUnit, LayerStructureUnit,
  UndoItems, FastGEO, AbstractGridUnit, ValueArrayStorageUnit,
  InterpolationUnit, GIS_Functions, RbwParser, DataSetNamesUnit,
  Mf6.DisvFileReaderUnit, ModflowIrregularMeshUnit, Mf6.IcFileReaderUnit,
  Mf6.OcFileReaderUnit, Mf6.ObsFileReaderUnit, Modflow6ObsUnit,
  Mf6.NpfFileReaderUnit, Mf6.TvkFileReaderUnit, ModflowTvkUnit,
  Mf6.TimeSeriesFileReaderUnit, Modflow6TimeSeriesCollectionsUnit,
  Modflow6TimeSeriesUnit, Mf6.HfbFileReaderUnit, ModflowHfbUnit,
  Mf6.StoFileReaderUnit, Mf6.TvsFileReaderUnit, ModflowTvsUnit,
  Mf6.CSubFileReaderUnit, ModflowCSubInterbed, ModflowCsubUnit,
  DataArrayManagerUnit, Mf6.BuyFileReaderUnit, Mt3dmsChemSpeciesUnit,
  Mf6.VscFileReaderUnit, Mf6.ChdFileReaderUnit, Mf6.CncFileReaderUnit;

resourcestring
  StrTheNameFileSDoe = 'The name file %s does not exist.';

procedure TModflow6Importer.AssignBooleanValuesToCellCenters(
  DataArray: TDataArray; ScreenObject: TScreenObject; ImportedData: TBArray2D);
var
  PointIndex: Integer;
  ImportedValues: TValueArrayItem;
  DataSetIndex: Integer;
  RowIndex: Integer;
  ColIndex: Integer;
  Interpolator: TNearestPoint2DInterpolator;
  Model: TPhastModel;
begin
  Model := frmGoPhast.PhastModel;
  Assert(DataArray.Orientation = dsoTop);
  if DataArray.TwoDInterpolator = nil then
  begin
    Interpolator := TNearestPoint2DInterpolator.Create(nil);
    try
      DataArray.TwoDInterpolator := Interpolator;
    finally
      Interpolator.Free;
    end;
  end;
  DataSetIndex := ScreenObject.AddDataSet(DataArray);
  ScreenObject.DataSetFormulas[DataSetIndex] := rsObjectImportedValuesB
    + '("' + DataArray.Name + '")';
  ScreenObject.ImportedValues.Add;
  ImportedValues := ScreenObject.ImportedValues.Items[
    ScreenObject.ImportedValues.Count-1];
  ImportedValues.Values.DataType := rdtBoolean;
  ImportedValues.Values.Count := Model.RowCount * Model.ColumnCount;
  ImportedValues.Name := DataArray.Name;
  PointIndex := 0;
  for RowIndex := 0 to Model.RowCount - 1 do
  begin
    for ColIndex := 0 to Model.ColumnCount - 1 do
    begin
      ImportedValues.Values.BooleanValues[PointIndex] :=
        ImportedData[RowIndex, ColIndex];
      Inc(PointIndex);
    end;
  end;
  ImportedValues.Values.Count := PointIndex;
  ImportedValues.Values.CacheData;
end;

procedure TModflow6Importer.AssignIntegerValuesToCellCenters(
  DataArray: TDataArray; ScreenObject: TScreenObject; ImportedData: TIArray2D);
var
  PointIndex: Integer;
  ImportedValues: TValueArrayItem;
  DataSetIndex: Integer;
  RowIndex: Integer;
  ColIndex: Integer;
  Interpolator: TNearestPoint2DInterpolator;
  Model: TPhastModel;
begin
  Model := frmGoPhast.PhastModel;
  Assert(DataArray.Orientation = dsoTop);
  if DataArray.TwoDInterpolator = nil then
  begin
    Interpolator := TNearestPoint2DInterpolator.Create(nil);
    try
      DataArray.TwoDInterpolator := Interpolator;
    finally
      Interpolator.Free;
    end;
  end;
  DataSetIndex := ScreenObject.AddDataSet(DataArray);
  ScreenObject.DataSetFormulas[DataSetIndex] := rsObjectImportedValuesI;
  ScreenObject.ImportedValues.Add;
  ImportedValues := ScreenObject.ImportedValues.Items[
    ScreenObject.ImportedValues.Count-1];
  ImportedValues.Values.DataType := rdtInteger;
  ImportedValues.Values.Count := Model.RowCount * Model.ColumnCount;
  ImportedValues.Name := DataArray.Name;
  PointIndex := 0;
  for RowIndex := 0 to Model.RowCount - 1 do
  begin
    for ColIndex := 0 to Model.ColumnCount - 1 do
    begin
//      APoint := Grid.TwoDElementCenter(ColIndex, RowIndex);
//      if (FImporter.FImportParameters.Outline = nil)
//        or FImporter.FImportParameters.Outline.PointInside(APoint) then
      begin
        ImportedValues.Values.IntValues[PointIndex] :=
          ImportedData[RowIndex, ColIndex];
        Inc(PointIndex);
      end;
    end;
  end;
  ImportedValues.Values.Count := PointIndex;
  ImportedValues.Values.CacheData;
end;

procedure TModflow6Importer.AssignRealValuesToCellCenters(DataArray: TDataArray;
  ScreenObject: TScreenObject; ImportedData: TDArray2D);
var
  PointIndex: Integer;
  ImportedValues: TValueArrayItem;
  DataSetIndex: Integer;
  RowIndex: Integer;
  ColIndex: Integer;
  Interpolator: TNearestPoint2DInterpolator;
  Model: TPhastModel;
begin
  Model := frmGoPhast.PhastModel;
  Assert(DataArray.Orientation = dsoTop);
  if DataArray.TwoDInterpolator = nil then
  begin
    Interpolator := TNearestPoint2DInterpolator.Create(nil);
    try
      DataArray.TwoDInterpolator := Interpolator;
    finally
      Interpolator.Free;
    end;
  end;
  DataSetIndex := ScreenObject.AddDataSet(DataArray);
  ScreenObject.DataSetFormulas[DataSetIndex] := rsObjectImportedValuesR
    + '("' + DataArray.Name + '")';
  ScreenObject.ImportedValues.Add;
  ImportedValues := ScreenObject.ImportedValues.Items[
    ScreenObject.ImportedValues.Count-1];
  ImportedValues.Values.DataType := rdtDouble;
  ImportedValues.Values.Count := Model.RowCount * Model.ColumnCount;
  ImportedValues.Name := DataArray.Name;
  PointIndex := 0;
  for RowIndex := 0 to Model.RowCount - 1 do
  begin
    for ColIndex := 0 to Model.ColumnCount - 1 do
    begin
//      APoint := Grid.TwoDElementCenter(ColIndex, RowIndex);
//      if (FImporter.FImportParameters.Outline = nil)
//        or FImporter.FImportParameters.Outline.PointInside(APoint) then
      begin
        ImportedValues.Values.RealValues[PointIndex] :=
          ImportedData[RowIndex, ColIndex];
        Inc(PointIndex);
      end;
    end;
  end;
  ImportedValues.Values.Count := PointIndex;
  ImportedValues.Values.CacheData;
end;

constructor TModflow6Importer.Create;
begin
  TSIndex := 0;
end;

procedure TModflow6Importer.CreateAllTopCellsScreenObject;
var
  UndoCreateScreenObject: TCustomUndo;
  RowIndex: Integer;
  ColIndex: Integer;
  APoint: TPoint2D;
  Model: TPhastModel;
begin
  Assert(FAllTopCellsScreenObject = nil);
    Model := frmGoPhast.PhastModel;
    FAllTopCellsScreenObject := TScreenObject.CreateWithViewDirection(
      Model, vdTop, UndoCreateScreenObject, False);
    FAllTopCellsScreenObject.Comment := 'Imported from ' + FModelNameFile +' on ' + DateTimeToStr(Now);

    Model.AddScreenObject(FAllTopCellsScreenObject);
    FAllTopCellsScreenObject.ElevationCount := ecZero;
//    if FImporter.FImportParameters.AssignmentMethod = camInterpolate then
//    begin
//      FAllTopCellsScreenObject.SetValuesByInterpolation := True;
//    end
//    else
//    begin
      FAllTopCellsScreenObject.SetValuesOfIntersectedCells := True;
//    end;
    FAllTopCellsScreenObject.EvaluatedAt := eaBlocks;
    FAllTopCellsScreenObject.Visible := False;
    FAllTopCellsScreenObject.Capacity := Model.RowCount * Model.ColumnCount;
    for RowIndex := 0 to Model.RowCount - 1 do
    begin
      for ColIndex := 0 to Model.ColumnCount - 1 do
      begin
        APoint := Model.TwoDElementCenter(ColIndex, RowIndex);
        FAllTopCellsScreenObject.AddPoint(APoint, True);
      end;
    end;
    FAllTopCellsScreenObject.Name := 'Imported_Arrays';
    FAllTopCellsScreenObject.SectionStarts.CacheData;
end;

function TModflow6Importer.GetAllTopCellsScreenObject: TScreenObject;
begin
  if FAllTopCellsScreenObject = nil then
  begin
    CreateAllTopCellsScreenObject;
  end;
  result := FAllTopCellsScreenObject;
end;

procedure TModflow6Importer.ImportBuy(Package: TPackage);
var
  Buy: TBuy;
  Model: TPhastModel;
  BuoyancyPackage: TBuoyancyPackage;
  Options: TBuyOptions;
  PackageData: TBuyPackageData;
  index: Integer;
  Item: TBuyItem;
  ChemComponents: TMobileChemSpeciesCollection;
  ChemItem: TMobileChemSpeciesItem;
begin
  Model := frmGoPhast.PhastModel;
  BuoyancyPackage := Model.ModflowPackages.BuoyancyPackage;
  BuoyancyPackage.IsSelected := True;

  Buy := Package.Package as TBuy;
  Options := Buy.Options;
  if Options.HHFORMULATION_RHS.Used then
  begin
    BuoyancyPackage.RightHandSide := True;
  end;
  if Options.DENSEREF.Used then
  begin
    BuoyancyPackage.RefDensity := Options.DENSEREF.Value;
  end;
  if Options.DENSITY.Used then
  begin
    BuoyancyPackage.WriteDensity := True;
  end;

  ChemComponents := Model.MobileComponents;
  PackageData := Buy.PackageData;
  for index := 0 to PackageData.Count - 1 do
  begin
    Item := PackageData[index];
    ChemItem := ChemComponents.GetItemByName(Item.auxspeciesname);
    if ChemItem = nil then
    begin
      ChemItem := ChemComponents.Add;
      ChemItem.Name := Item.auxspeciesname;
    end;
    if SameText(ChemItem.Name, 'Density') then
    begin
      BuoyancyPackage.DensitySpecified := True;
    end;
    ChemItem.DensitySlope := Item.drhodc;
    ChemItem.RefConcentration := Item.crhoref;
  end;
end;

procedure TModflow6Importer.ImportChd(Package: TPackage; TransportModels: TModelList);
var
  Model: TPhastModel;
  Chd: TChd;
  CncList: TList<TCnc>;
  AModel: TModel;
  APackage: TPackage;
  ModelIndex: Integer;
  TransportModel: TTransportNameFile;
  PackageIndex: Integer;
begin
  Model := frmGoPhast.PhastModel;
  Model.ModflowPackages.ChdBoundary.IsSelected := True;

  Chd := Package.Package as TChd;
  CncList := TList<TCnc>.Create;
  try
    for ModelIndex := 0 to TransportModels.Count - 1 do
    begin
      AModel := TransportModels[ModelIndex];
      TransportModel := AModel.FName as TTransportNameFile;
      for PackageIndex := 0 to TransportModel.NfPackages.Count  - 1 do
      begin
        APackage := TransportModel.NfPackages[PackageIndex];
        if APackage.FileType = 'CNC6' then
        begin
          CncList.Add(APackage.Package as TCnc)
        end;
      end;
    end;



  finally
    CncList.Free;
  end;
end;

procedure TModflow6Importer.ImportCSub(Package: TPackage);
var
  Model: TPhastModel;
  CSub: TCSub;
  CSubPackage: TCSubPackageSelection;
  Options: TCSubOptions;
  OutputTypes: TCsubOutputTypes;
  DelayCounts: array of array of array of Integer;
  NoDelayCounts: array of array of array of Integer;
  PackageData: TMf6CSubPackageData;
  Index: Integer;
  Item: TMf6CSubItem;
  LayerIndex: Integer;
  RowIndex: Integer;
  ColumnIndex: Integer;
  MaxDelay: Integer;
  MaxNoDelay: Integer;
  NoDelayLists: TObjectList<TCSubItemList>;
  DelayLists: TObjectList<TCSubItemList>;
  List: TCSubItemList;
  Interbed: TCSubInterbed;
  GridData: TCSubGridData;
  DataArrayName: string;
  Map: TimeSeriesMap;
  TimeSeriesPackage: TPackage;
  TimeSeriesIndex: Integer;
  ObsPackageIndex: Integer;
  ObsFiles: TObs;
  ObsFileIndex: Integer;
  ObsFile: TObsFile;
  ObsIndex: Integer;
  Observation: TObservation;
  IcsubnoObsDictionary: TDictionary<Integer, TObservationList>;
  BoundNameObsDictionary: TDictionary<string, TObservationList>;
  CellIdObsDictionary: TDictionary<TCellId, TObservationList>;
  ObsLists: TObjectList<TObservationList>;
  ObsList: TObservationList;
  PriorItem: TMf6CSubItem;
  PriorBoundName: string;
  BoundName: string;
  PriorItemAssigned: Boolean;
  ObjectCount: Integer;
  StartTime: double;
  LastTime: double;
  AScreenObject: TScreenObject;
  NoDelayInterbeds: TList<TCSubInterbed>;
  DelayInterbeds: TList<TCSubInterbed>;
  PackageItem: TCSubPackageData;
  InterbedIndex: Integer;
  pcs0: TValueArrayItem;
  thick_frac: TValueArrayItem;
  rnb: TValueArrayItem;
  ssv_cc: TValueArrayItem;
  sse_cr: TValueArrayItem;
  theta: TValueArrayItem;
  kv: TValueArrayItem;
  h0: TValueArrayItem;
  CellId: TCellId;
  ElementCenter: TDualLocation;
  APoint: TPoint2D;
  BName: TStringOption;
  Obs: TObservation;
  PeriodIndex: Integer;
  APeriod: TCSubPeriod;
  CellIndex: Integer;
  ACell: TCSubTimeItem;
  PriorTimeSeriesAssigned: Boolean;
  PriorTimeSeries: string;
  TimeSeries: string;
  PriorScreenObjects: TScreenObjectList;
  ScreenObjectIndex: Integer;
  TimeItem: TCSubItem;
  Formula: string;
  ImportedTimeSeriesName: String;
  ImportedName: string;
  sig0: TValueArrayItem;
  ObsListIndex: Integer;
  function CreateScreenObject(BoundName: String; Period: Integer): TScreenObject;
  var
    UndoCreateScreenObject: TCustomUndo;
    NewName: string;
    NewItem: TCSubItem;
    CSubPackageData: TCSubPackageDataCollection;
    Index: Integer;
    ImportedName: string;
  begin
    result := TScreenObject.CreateWithViewDirection(
      Model, vdTop, UndoCreateScreenObject, False);
    if BoundName <> '' then
    begin
      NewName := 'ImportedCSUB_' + BoundName;
    end
    else
    begin
      if Period > 0 then
      begin
        NewName := 'ImportedCSUB_Period_' + IntToStr(Period);
      end
      else
      begin
        Inc(ObjectCount);
        NewName := 'ImportedCSUB_Obs'  + IntToStr(ObjectCount);
      end;
    end;
    result.Name := NewName;
    result.Comment := 'Imported from ' + FModelNameFile +' on ' + DateTimeToStr(Now);

    Model.AddScreenObject(result);
    result.ElevationCount := ecOne;
    result.SetValuesOfIntersectedCells := True;
    result.EvaluatedAt := eaBlocks;
    result.Visible := False;
    result.ElevationFormula := rsObjectImportedValuesR + '("' + StrImportedElevations + '")';

    if Period > 0 then
    begin
      result.CreateCsubBoundary;
      NewItem := result.ModflowCSub.Values.Add as TCsubItem;
      NewItem.StartTime := StartTime;
      NewItem.EndTime := LastTime;
    end
    else if Period = 0 then
    begin
      result.CreateCsubBoundary;
      CSubPackageData := result.ModflowCSub.CSubPackageData;
      for Index := 0 to CSubPackage.Interbeds.Count - 1 do
      begin
        PackageItem := CSubPackageData.Add;
        PackageItem.InterbedSystemName := CSubPackage.Interbeds[Index].Name;
      end;

      ImportedName := 'Imported_pcs0';
      pcs0 := result.ImportedValues.Add;
      pcs0.Name := ImportedName;
      pcs0.Values.DataType := rdtDouble;

      ImportedName := 'Imported_thick_frac';
      thick_frac := result.ImportedValues.Add;
      thick_frac.Name := ImportedName;
      thick_frac.Values.DataType := rdtDouble;

      ImportedName := 'Imported_rnb';
      rnb := result.ImportedValues.Add;
      rnb.Name := ImportedName;
      rnb.Values.DataType := rdtDouble;

      ImportedName := 'Imported_ssv_cc';
      ssv_cc := result.ImportedValues.Add;
      ssv_cc.Name := ImportedName;
      ssv_cc.Values.DataType := rdtDouble;


      ImportedName := 'Imported_sse_cr';
      sse_cr := result.ImportedValues.Add;
      sse_cr.Name := ImportedName;
      sse_cr.Values.DataType := rdtDouble;

      ImportedName := 'Imported_theta';
      theta := result.ImportedValues.Add;
      theta.Name := ImportedName;
      theta.Values.DataType := rdtDouble;

      ImportedName := 'Imported_kv';
      kv := result.ImportedValues.Add;
      kv.Name := ImportedName;
      kv.Values.DataType := rdtDouble;

      ImportedName := 'Imported_h0';
      h0 := result.ImportedValues.Add;
      h0.Name := ImportedName;
      h0.Values.DataType := rdtDouble;
    end
    else if Period = -1 then
    begin
      // do nothing
    end;
  end;
  procedure IncludeObservations(ObsList: TObservationList; AScreenObject: TScreenObject);
  var
    Modflow6Obs: TModflow6Obs;
    CSubObsSet: TSubObsSet;
    ObsIndex: Integer;
    CSubDelayCells: TIntegerCollection;
  begin
    AScreenObject.CreateMf6Obs;
    Modflow6Obs := AScreenObject.Modflow6Obs;
    CSubObsSet := Modflow6Obs.CSubObs.CSubObsSet;
    CSubDelayCells := Modflow6Obs.CSubDelayCells;
    for ObsIndex := 0 to ObsList.Count - 1 do
    begin
      Obs := ObsList[ObsIndex];
      if Obs.ObsType = 'csub' then
      begin
        Include(CSubObsSet, coCSub)
      end
      else if Obs.ObsType = 'inelastic-csub' then
      begin
        Include(CSubObsSet, coInelastCSub)
      end
      else if Obs.ObsType = 'elastic-csub' then
      begin
        Include(CSubObsSet, coElastCSub)
      end
      else if Obs.ObsType = 'coarse-csub' then
      begin
        Include(CSubObsSet, coCoarseCSub)
      end
      else if Obs.ObsType = 'csub-cell' then
      begin
        Include(CSubObsSet, coCSubCell)
      end
      else if Obs.ObsType = 'wcomp-csub-cell' then
      begin
        Include(CSubObsSet, coWcompCSubCell)
      end
      else if Obs.ObsType = 'sk' then
      begin
        Include(CSubObsSet, coSk)
      end
      else if Obs.ObsType = 'ske' then
      begin
        Include(CSubObsSet, coSke)
      end
      else if Obs.ObsType = 'sk-cell' then
      begin
        Include(CSubObsSet, coSkCell)
      end
      else if Obs.ObsType = 'ske-cell' then
      begin
        Include(CSubObsSet, coSkeCell)
      end
      else if Obs.ObsType = 'estress-cell' then
      begin
        Include(CSubObsSet, coEStressCell)
      end
      else if Obs.ObsType = 'gstress-cell' then
      begin
        Include(CSubObsSet, coGStressCell)
      end
      else if Obs.ObsType = 'interbed-compaction' then
      begin
        Include(CSubObsSet, coIntbedComp)
      end
      else if Obs.ObsType = 'elastic-compaction' then
      begin
        Include(CSubObsSet, coElastComp)
      end
      else if Obs.ObsType = 'coarse-compaction' then
      begin
        Include(CSubObsSet, coCoarseCompaction)
      end
      else if Obs.ObsType = 'inelastic-compaction-cell' then
      begin
//        Include(CSubObsSet, coCompCell)
      end
      else if Obs.ObsType = 'elastic-compaction-cell' then
      begin
//        Include(CSubObsSet, coCompCell)
      end
      else if Obs.ObsType = 'compaction-cell' then
      begin
        Include(CSubObsSet, coCompCell)
      end
      else if Obs.ObsType = 'thickness' then
      begin
        Include(CSubObsSet, coThickness)
      end
      else if Obs.ObsType = 'coarse-thickness' then
      begin
        Include(CSubObsSet, coCoarseThickness)
      end
      else if Obs.ObsType = 'thickness-cell' then
      begin
        Include(CSubObsSet, coThickCell)
      end
      else if Obs.ObsType = 'theta' then
      begin
        Include(CSubObsSet, coTheta)
      end
      else if Obs.ObsType = 'coarse-theta' then
      begin
        Include(CSubObsSet, coCoarseTheta)
      end
      else if Obs.ObsType = 'theta-cell' then
      begin
        Include(CSubObsSet, coThetaCell)
      end
      else if Obs.ObsType = 'delay-flowtop' then
      begin
        Include(CSubObsSet, coDelayFlowTop)
      end
      else if Obs.ObsType = 'delay-flowbot' then
      begin
        Include(CSubObsSet, coDelayFlowBot)
      end
      else if Obs.ObsType = 'delay-head' then
      begin
        Include(CSubObsSet, coDelayHead);
        Assert(Obs.IdType2 = itNumber);
        if CSubDelayCells.IndexOf(Obs.Num2) < 0 then
        begin
          CSubDelayCells.Add.Value := Obs.Num2;
        end;
      end
      else if Obs.ObsType = 'delay-gstress' then
      begin
        Include(CSubObsSet, coDelayGStress);
        Assert(Obs.IdType2 = itNumber);
        if CSubDelayCells.IndexOf(Obs.Num2) < 0 then
        begin
          CSubDelayCells.Add.Value := Obs.Num2;
        end;
      end
      else if Obs.ObsType = 'delay-estress' then
      begin
        Include(CSubObsSet, coDelayEStress);
        Assert(Obs.IdType2 = itNumber);
        if CSubDelayCells.IndexOf(Obs.Num2) < 0 then
        begin
          CSubDelayCells.Add.Value := Obs.Num2;
        end;
      end
      else if Obs.ObsType = 'delay-preconstress' then
      begin
        Include(CSubObsSet, coDelayPreConStress);
        Assert(Obs.IdType2 = itNumber);
        if CSubDelayCells.IndexOf(Obs.Num2) < 0 then
        begin
          CSubDelayCells.Add.Value := Obs.Num2;
        end;
      end
      else if Obs.ObsType = 'delay-compaction' then
      begin
        Include(CSubObsSet, coDelayComp);
        Assert(Obs.IdType2 = itNumber);
        if CSubDelayCells.IndexOf(Obs.Num2) < 0 then
        begin
          CSubDelayCells.Add.Value := Obs.Num2;
        end;
      end
      else if Obs.ObsType = 'delay-thickness' then
      begin
        Include(CSubObsSet, coDelayThickness);
        Assert(Obs.IdType2 = itNumber);
        if CSubDelayCells.IndexOf(Obs.Num2) < 0 then
        begin
          CSubDelayCells.Add.Value := Obs.Num2;
        end;
      end
      else if Obs.ObsType = 'delay-theta' then
      begin
        Include(CSubObsSet, coDelayTheta);
        Assert(Obs.IdType2 = itNumber);
        if CSubDelayCells.IndexOf(Obs.Num2) < 0 then
        begin
          CSubDelayCells.Add.Value := Obs.Num2;
        end;
      end
      else if Obs.ObsType = 'preconstress-cell' then
      begin
        Include(CSubObsSet, coPreConsStressCell);
      end
      else
      begin
        FErrorMessages.Add(Format('Unrecognized UZF observation type "%s".', [Obs.ObsType]))
      end;
    end;
    Modflow6Obs.CSubObs.CSubObsSet := CSubObsSet;
  end;
  procedure AssignPackageData(PackageDataList: TObjectList<TCSubItemList>);
  var
    ListIndex: Integer;
    ItemIndex: Integer;
    AnInterBed: TCSubInterbed;
    DataArrayManager: TDataArrayManager;
    ADataArray: TDataArray;
    DataSetIndex: Integer;
  begin
    DataArrayManager := Model.DataArrayManager;
    for ListIndex := 0 to PackageDataList.Count - 1 do
    begin
      AnInterBed := CSubPackage.Interbeds[InterbedIndex];
      PriorBoundName := '';
      PriorItemAssigned := False;
      List := PackageDataList[ListIndex];
      AScreenObject := nil;
      PackageItem := nil;
      for ItemIndex := 0 to List.Count - 1 do
      begin
        Item := List[ItemIndex];
        if Item.boundname.Used then
        begin
          BoundName := UpperCase(Item.boundname.Value);
        end
        else
        begin
          BoundName := '';
        end;

        if (not PriorItemAssigned) or (BoundName <> PriorBoundName) then
        begin
          AScreenObject := CreateScreenObject(BoundName, 0);
          PackageItem := AScreenObject.ModflowCSub.CSubPackageData[InterbedIndex];

          PackageItem.Used := True;
          PackageItem.InitialOffset := rsObjectImportedValuesR + '("' + pcs0.Name + '")';
          PackageItem.Thickness := rsObjectImportedValuesR + '("' + thick_frac.Name + '")';
          PackageItem.EquivInterbedNumber := rsObjectImportedValuesR + '("' + rnb.Name + '")';
          PackageItem.InitialInelasticSpecificStorage := rsObjectImportedValuesR + '("' + ssv_cc.Name + '")';
          PackageItem.InitialElasticSpecificStorage := rsObjectImportedValuesR + '("' + sse_cr.Name + '")';
          PackageItem.InitialPorosity := rsObjectImportedValuesR + '("' + theta.Name + '")';
          PackageItem.DelayKv := rsObjectImportedValuesR + '("' + kv.Name + '")';
          PackageItem.InitialDelayHeadOffset := rsObjectImportedValuesR + '("' + h0.Name + '")';

          if BoundName <> '' then
          begin
            if not BoundNameObsDictionary.TryGetValue(BoundName, ObsList) then
            begin
              Assert(False);
            end;
            IncludeObservations(ObsList, AScreenObject);
          end;

          if AnInterBed.InterbedType = itDelay then
          begin
            ADataArray := DataArrayManager.GetDataSetByName(AnInterBed.DelayKvName);
            Assert(ADataArray <> nil);
            DataSetIndex := AScreenObject.AddDataSet(ADataArray);
            AScreenObject.DataSetFormulas[DataSetIndex] := PackageItem.DelayKv;
          end;

          if AnInterBed.InterbedType = itDelay then
          begin
            ADataArray := DataArrayManager.GetDataSetByName(AnInterBed.EquivInterbedNumberName);
            Assert(ADataArray <> nil);
            DataSetIndex := AScreenObject.AddDataSet(ADataArray);
            AScreenObject.DataSetFormulas[DataSetIndex] := PackageItem.EquivInterbedNumber;
          end;

          if AnInterBed.InterbedType = itDelay then
          begin
            ADataArray := DataArrayManager.GetDataSetByName(AnInterBed.InitialDelayHeadOffset);
            Assert(ADataArray <> nil);
            DataSetIndex := AScreenObject.AddDataSet(ADataArray);
            AScreenObject.DataSetFormulas[DataSetIndex] := PackageItem.InitialDelayHeadOffset;
          end;

          ADataArray := DataArrayManager.GetDataSetByName(AnInterBed.InitialElasticSpecificStorage);
          Assert(ADataArray <> nil);
          DataSetIndex := AScreenObject.AddDataSet(ADataArray);
          AScreenObject.DataSetFormulas[DataSetIndex] := PackageItem.InitialElasticSpecificStorage;

          ADataArray := DataArrayManager.GetDataSetByName(AnInterBed.InitialInelasticSpecificStorage);
          Assert(ADataArray <> nil);
          DataSetIndex := AScreenObject.AddDataSet(ADataArray);
          AScreenObject.DataSetFormulas[DataSetIndex] := PackageItem.InitialInelasticSpecificStorage;

          ADataArray := DataArrayManager.GetDataSetByName(AnInterBed.InitialOffset);
          Assert(ADataArray <> nil);
          DataSetIndex := AScreenObject.AddDataSet(ADataArray);
          AScreenObject.DataSetFormulas[DataSetIndex] := PackageItem.InitialOffset;

          ADataArray := DataArrayManager.GetDataSetByName(AnInterBed.InitialPorosity);
          Assert(ADataArray <> nil);
          DataSetIndex := AScreenObject.AddDataSet(ADataArray);
          AScreenObject.DataSetFormulas[DataSetIndex] := PackageItem.InitialPorosity;

          ADataArray := DataArrayManager.GetDataSetByName(AnInterBed.Thickness);
          Assert(ADataArray <> nil);
          DataSetIndex := AScreenObject.AddDataSet(ADataArray);
          AScreenObject.DataSetFormulas[DataSetIndex] := PackageItem.Thickness;

          ADataArray := DataArrayManager.GetDataSetByName(AnInterBed.CSubBoundName);
          Assert(ADataArray <> nil);
          DataSetIndex := AScreenObject.AddDataSet(ADataArray);
          AScreenObject.DataSetFormulas[DataSetIndex] := Format('"%s"', [AScreenObject.Name]);
        end;

        pcs0.Values.Add(Item.pcs0);
        thick_frac.Values.Add(Item.thick_frac);
        rnb.Values.Add(Item.rnb);
        ssv_cc.Values.Add(Item.ssv_cc);
        sse_cr.Values.Add(Item.sse_cr);
        theta.Values.Add(Item.theta);
        kv.Values.Add(Item.kv);
        h0.Values.Add(Item.h0);

        CellId := Item.cellid;
        ElementCenter := Model.ElementLocation[CellId.Layer-1, CellId.Row-1, CellId.Column-1];
        APoint.x := ElementCenter.RotatedLocation.x;
        APoint.y := ElementCenter.RotatedLocation.y;
        AScreenObject.AddPoint(APoint, True);
        AScreenObject.ImportedSectionElevations.Add(ElementCenter.RotatedLocation.z);

        PriorItem := Item;
        PriorBoundName := BoundName;
        PriorItemAssigned := True;
      end;
      Inc(InterbedIndex);
    end
  end;
begin
  StartTime := 0.0;
  ObjectCount := 0;
  Model := frmGoPhast.PhastModel;
  CSubPackage := Model.ModflowPackages.CSubPackage;
  CSubPackage.IsSelected := True;

  CSub := Package.Package as TCSub;

  NoDelayInterbeds := TList<TCSubInterbed>.Create;
  DelayInterbeds := TList<TCSubInterbed>.Create;
  IcsubnoObsDictionary := TDictionary<Integer, TObservationList>.Create;
  BoundNameObsDictionary := TDictionary<string, TObservationList>.Create;
  CellIdObsDictionary := TDictionary<TCellId, TObservationList>.Create;
  ObsLists := TObjectList<TObservationList>.Create;
  Map := TimeSeriesMap.Create;
  try
    for TimeSeriesIndex := 0 to CSub.TimeSeriesCount - 1 do
    begin
      TimeSeriesPackage := CSub.TimeSeries[TimeSeriesIndex];
      ImportTimeSeries(TimeSeriesPackage, Map);
    end;

    if CSub.ObservationCount > 0 then
    begin
      Model.ModflowPackages.Mf6ObservationUtility.IsSelected := True;
    end;
    for ObsPackageIndex := 0 to CSub.ObservationCount - 1 do
    begin
      ObsFiles := CSub.Observations[ObsPackageIndex].Package as TObs;
      for ObsFileIndex := 0 to ObsFiles.FileCount - 1 do
      begin
        ObsFile := ObsFiles[ObsFileIndex];
        for ObsIndex := 0 to ObsFile.Count - 1 do
        begin
          Observation := ObsFile[ObsIndex];
          case Observation.IdType1 of
            itCell:
              begin
                if not CellIdObsDictionary.TryGetValue(Observation.CellId1, ObsList) then
                begin
                  ObsList := TObservationList.Create;
                  ObsLists.Add(ObsList);
                  CellIdObsDictionary.Add(Observation.CellId1, ObsList);
                end;
                ObsList.Add(Observation);
              end;
            itNumber:
              begin
                if not IcsubnoObsDictionary.TryGetValue(Observation.Num1, ObsList) then
                begin
                  ObsList := TObservationList.Create;
                  ObsLists.Add(ObsList);
                  IcsubnoObsDictionary.Add(Observation.Num1, ObsList);
                end;
                ObsList.Add(Observation);
              end;
            itFloat:
              begin
                Assert(False)
              end;
            itName:
              begin
                if not BoundNameObsDictionary.TryGetValue(UpperCase(Observation.Name1), ObsList) then
                begin
                  ObsList := TObservationList.Create;
                  ObsLists.Add(ObsList);
                  BoundNameObsDictionary.Add(UpperCase(Observation.Name1), ObsList);
                end;
                ObsList.Add(Observation);
              end;
            itAbsent:
              begin
                Assert(False)
              end;
          end;

        end;
      end;
    end;

    Options := CSub.Options;

    if Options.GAMMAW.Used then
    begin
      CSubPackage.Gamma := Options.GAMMAW.Value;
    end;
    if Options.Beta.Used then
    begin
      CSubPackage.Beta := Options.Beta.Value;
    end;
    CSubPackage.HeadBased := Options.HEAD_BASED;
    CSubPackage.PreconsolidationHeadUsed := Options.INITIAL_PRECONSOLIDATION_HEAD;
    if Options.NDELAYCELLS.Used then
    begin
      CSubPackage.NumberOfDelayCells := Options.NDELAYCELLS.Value;
    end;
    CSubPackage.CompressionMethod := TCompressionMethod(Options.COMPRESSION_INDICES);
    CSubPackage.UpdateMaterialProperties := Options.UPDATE_MATERIAL_PROPERTIES;
    CSubPackage.InterbedThicknessMethod := TInterbedThicknessMethod(Options.CELL_FRACTION);

    CSubPackage.SpecifyInitialPreconsolidationStress := Options.SPECIFIED_INITIAL_PRECONSOLIDATION_STRESS;
    CSubPackage.SpecifyInitialDelayHead := Options.SPECIFIED_INITIAL_DELAY_HEAD;
    if Options.SPECIFIED_INITIAL_INTERBED_STATE then
    begin
      CSubPackage.SpecifyInitialPreconsolidationStress := True;
      CSubPackage.SpecifyInitialDelayHead := True;
    end;
    CSubPackage.EffectiveStressLag := Options.EFFECTIVE_STRESS_LAG;
    OutputTypes := [];
    if Options.STRAIN_CSV_INTERBED then
    begin
      Include(OutputTypes, coInterbedStrain);
    end;
    if Options.STRAIN_CSV_COARSE then
    begin
      Include(OutputTypes, coCourseStrain);
    end;
    if Options.COMPACTION then
    begin
      Include(OutputTypes, coCompaction);
    end;
    if Options.COMPACTION_ELASTIC then
    begin
      Include(OutputTypes, coElasticComp);
    end;
    if Options.COMPACTION_INELASTIC then
    begin
      Include(OutputTypes, coInelasticComp);
    end;
    if Options.COMPACTION_INTERBED then
    begin
      Include(OutputTypes, coInterbedComp);
    end;
    if Options.COMPACTION_COARSE then
    begin
      Include(OutputTypes, coCoarseComp);
    end;
    if Options.ZDISPLACEMENT then
    begin
      Include(OutputTypes, coZDisplacement);
    end;
    CSubPackage.OutputTypes := OutputTypes;
    CSubPackage.WriteConvergenceData := Options.PACKAGE_CONVERGENCE;

    SetLength(DelayCounts, Model.LayerCount, Model.RowCount, Model.ColumnCount);
    SetLength(NoDelayCounts, Model.LayerCount, Model.RowCount, Model.ColumnCount);
    for LayerIndex := 0 to Model.LayerCount - 1 do
    begin
      for RowIndex := 0 to Model.RowCount - 1 do
      begin
        for ColumnIndex := 0 to Model.ColumnCount - 1 do
        begin
          DelayCounts[LayerIndex, RowIndex, ColumnIndex] := 0;
          NoDelayCounts[LayerIndex, RowIndex, ColumnIndex] := 0;
        end;
      end;
    end;
    MaxDelay := 0;
    MaxNoDelay := 0;
    PackageData := CSub.PackageData;
    for Index := 0 to PackageData.Count - 1 do
    begin
      Item := PackageData[Index];
      if Item.boundname.Used then
      begin
        BoundName := UpperCase(Item.boundname.Value);
      end
      else
      begin
        BoundName := '';
      end;
      if BoundName <> '' then
      begin
        if not BoundNameObsDictionary.ContainsKey(BoundName) then
        begin
          BName := Item.boundname;
          BName.Used := False;
          Item.boundname := BName;
          PackageData[Index] := Item;
        end;
      end;
    end;
    PackageData.sort;
    DelayLists := TObjectList<TCSubItemList>.Create;
    NoDelayLists := TObjectList<TCSubItemList>.Create;
    try
      for Index := 0 to PackageData.Count - 1 do
      begin
        Item := PackageData[Index];
        if Item.cdelay = 'DELAY' then
        begin
          Inc(DelayCounts[Item.cellid.Layer-1, Item.cellid.Row-1, Item.cellid.Column-1]);
          if DelayCounts[Item.cellid.Layer-1, Item.cellid.Row-1, Item.cellid.Column-1] > MaxDelay then
          begin
            MaxDelay := DelayCounts[Item.cellid.Layer-1, Item.cellid.Row-1, Item.cellid.Column-1];
            List := TCSubItemList.Create;
            DelayLists.Add(List);
          end;

          List := DelayLists[DelayCounts[Item.cellid.Layer-1, Item.cellid.Row-1, Item.cellid.Column-1] -1];
          List.Add(Item);
        end
        else if Item.cdelay = 'NODELAY' then
        begin
          Inc(NoDelayCounts[Item.cellid.Layer-1, Item.cellid.Row-1, Item.cellid.Column-1]);
          if NoDelayCounts[Item.cellid.Layer-1, Item.cellid.Row-1, Item.cellid.Column-1] > MaxNoDelay then
          begin
            MaxNoDelay := NoDelayCounts[Item.cellid.Layer-1, Item.cellid.Row-1, Item.cellid.Column-1];
            List := TCSubItemList.Create;
            NoDelayLists.Add(List);
          end;

          List := NoDelayLists[NoDelayCounts[Item.cellid.Layer-1, Item.cellid.Row-1, Item.cellid.Column-1] -1];
          List.Add(Item);
        end
        else
        begin
          FErrorMessages.Add(Format('Invalid cdelay value "%s"', [Item.cdelay]))
        end;
      end;

      CSubPackage.Interbeds.Capacity := MaxDelay + MaxNoDelay;
      for Index := 1 to MaxNoDelay do
      begin
        Interbed := CSubPackage.Interbeds.Add;
        Interbed.Name := Format('No_Delay_%d', [Index]);
        Interbed.InterbedType := itNoDelay;
        NoDelayInterbeds.Add(Interbed);
      end;
      for Index := 1 to MaxDelay do
      begin
        Interbed := CSubPackage.Interbeds.Add;
        Interbed.Name := Format('Delay_%d', [Index]);
        Interbed.InterbedType := itDelay;
        DelayInterbeds.Add(Interbed);
      end;

      Model.DataArrayManager.CreateInitialDataSets;

      GridData := CSub.GridData;

      if CSubPackage.CompressionMethod = coRecompression then
      begin
        DataArrayName := KInitialElasticReco;
      end
      else
      begin
        DataArrayName := KInitialElasticSpec;
      end;
      Assign3DRealDataSet(DataArrayName, GridData.CG_SKE_CR);
      Assign3DRealDataSet(KInitialCoarsePoros, GridData.CG_THETA);
      Assign3DRealDataSet(KMoistSpecificGravi, GridData.SGM);
      Assign3DRealDataSet(KSaturatedSpecificG, GridData.SGS);

      Assert(NoDelayLists.Count = NoDelayInterbeds.Count);
      InterbedIndex := 0;

      AssignPackageData(NoDelayLists);
      AssignPackageData(DelayLists);


    finally
      DelayLists.Free;
      NoDelayLists.Free;
    end;

    LastTime := Model.ModflowStressPeriods.Last.EndTime;
    PriorScreenObjects := TScreenObjectList.Create;
    try
      for PeriodIndex := 0 to CSub.PeriodCount - 1 do
      begin
        APeriod := CSub[PeriodIndex];
        StartTime := Model.ModflowStressPeriods[APeriod.Period-1].StartTime;
        for ScreenObjectIndex := 0 to PriorScreenObjects.Count - 1 do
        begin
          TimeItem := PriorScreenObjects[ScreenObjectIndex].ModflowCSub.Values.Last as TCsubItem;
          TimeItem.EndTime := StartTime;
        end;
        PriorScreenObjects.Clear;

        PriorTimeSeriesAssigned := False;
        PriorTimeSeries := '';
        AScreenObject := nil;
        sig0 := nil;

        if APeriod.Count > 0 then
        begin
          APeriod.Sort;
          for CellIndex := 0 to APeriod.Count - 1 do
          begin
            ACell := APeriod[CellIndex];
            case ACell.ValueType of
              vtNumeric:
                begin
                  TimeSeries := '';
                end;
              vtString:
                begin
                  TimeSeries := ACell.StringValue;
                end;
            end;

            if (not PriorTimeSeriesAssigned) or (TimeSeries <> PriorTimeSeries) then
            begin
              AScreenObject := CreateScreenObject(TimeSeries, APeriod.Period);
              PriorScreenObjects.Add(AScreenObject);
              case ACell.ValueType of
                vtNumeric:
                  begin
                    ImportedName := 'ImportedCSub_sig0_' + IntToStr(APeriod.Period);

                    sig0 := AScreenObject.ImportedValues.Add;
                    sig0.Name := ImportedName;
                    sig0.Values.DataType := rdtDouble;

                    Formula := rsObjectImportedValuesR + '("' + ImportedName + '")'
                  end;
                vtString:
                  begin
                    if not Map.TryGetValue(TimeSeries, ImportedTimeSeriesName) then
                    begin
                      Assert(False);
                    end;
                    Formula := ImportedTimeSeriesName;
                  end;
              end;

              if ACell.ValueType = vtNumeric then
              begin
                sig0.Values.Add(ACell.sig0);
              end;

              CellId := ACell.cellid;
              if Model.DisvUsed then
              begin
                CellId.Row := 1;
              end;

              ElementCenter := Model.ElementLocation[CellId.Layer-1, CellId.Row-1, CellId.Column-1];
              APoint.x := ElementCenter.RotatedLocation.x;
              APoint.y := ElementCenter.RotatedLocation.y;
              AScreenObject.AddPoint(APoint, True);
              AScreenObject.ImportedSectionElevations.Add(ElementCenter.RotatedLocation.z);
            end;

            PriorTimeSeries := TimeSeries;
            PriorTimeSeriesAssigned := True;
          end;
        end;
      end;
    finally
      PriorScreenObjects.Free;
    end;

    for ObsListIndex := 0 to ObsLists.Count - 1 do
    begin
      ObsList := ObsLists[ObsListIndex];
      case ObsList[0].IdType1 of
        itCell:
          begin
            CellId := ObsList[0].CellId1;
          end;
        itNumber:
          begin
            CellId := PackageData.Items[ObsList[0].Num1-1].cellid;
          end;
        itName:
          begin
            Continue;
          end;
        else
          Assert(False)
      end;
      if Model.DisvUsed then
      begin
        CellId.Row := 1;
      end;
      AScreenObject := CreateScreenObject('', -1);

      ElementCenter := Model.ElementLocation[CellId.Layer-1, CellId.Row-1, CellId.Column-1];
      APoint.x := ElementCenter.RotatedLocation.x;
      APoint.y := ElementCenter.RotatedLocation.y;
      AScreenObject.AddPoint(APoint, True);
      AScreenObject.ImportedSectionElevations.Add(ElementCenter.RotatedLocation.z);

      IncludeObservations(ObsList, AScreenObject)
    end;

  finally
    Map.Free;
    IcsubnoObsDictionary.Free;
    BoundNameObsDictionary.Free;
    CellIdObsDictionary.Free;
    ObsLists.Free;
    NoDelayInterbeds.Free;
    DelayInterbeds.Free;
  end;
end;

procedure TModflow6Importer.ImportDis(Package: TPackage);
var
  Dis: TDis;
  XOrigin: Extended;
  YOrigin: Extended;
  GridAngle: Extended;
  Model: TPhastModel;
  MfOptions: TModflowOptions;
  ColumnPositions: TOneDRealArray;
  RowPositions: TOneDRealArray;
  Delr: TDArray1D;
  Position: Extended;
  ColIndex: Integer;
  Delc: TDArray1D;
  AngleToLL: Extended;
  DistanceToLL: Extended;
  RowIndex: Integer;
  TOP: TDArray2D;
  BOTM: TDArray3D;
  NumberOfLayers: Integer;
  IDOMAIN: TIArray3D;
begin
  Model := frmGoPhast.PhastModel;
  MfOptions := Model.ModflowOptions;

  Dis := Package.Package as TDis;
  MfOptions.LengthUnit := Dis.Options.LENGTH_UNITS;
  MfOptions.WriteBinaryGridFile := not Dis.Options.NOGRB;

  XOrigin := Dis.Options.XORIGIN;
  YOrigin := Dis.Options.YORIGIN;
  GridAngle := Dis.Options.ANGROT * Pi / 180;

  Delr := Dis.GridData.DELR;
  SetLength(ColumnPositions, Length(Delr) + 1);
  Delc := Dis.GridData.DELC;
  SetLength(RowPositions, Length(Delc) + 1);

  if GridAngle = 0 then
  begin
    Position := XOrigin;
    ColumnPositions[0] := Position;
    for ColIndex := 0 to Length(Delr) - 1 do
    begin
      Position := Position + Delr[ColIndex];
      ColumnPositions[ColIndex+1] := Position;
    end;

    Position := YOrigin;
    RowPositions[Length(RowPositions)-1] := Position;
    for RowIndex := 0 to Length(Delc) - 1 do
    begin
      Position := Position + Delc[RowIndex];
      RowPositions[Length(RowPositions) - RowIndex -2] := Position;
    end;
  end
  else
  begin
    AngleToLL := ArcTan2(YOrigin, XOrigin);
    DistanceToLL := Sqrt(Sqr(XOrigin) + Sqr(YOrigin));

    Position := DistanceToLL * Cos(AngleToLL - GridAngle);
    ColumnPositions[0] := Position;
    for ColIndex := 0 to Length(Delr) - 1 do
    begin
      Position := Position + Delr[ColIndex];
      ColumnPositions[ColIndex+1] := Position;
    end;

    Position := DistanceToLL * Sin(AngleToLL - GridAngle);
    RowPositions[Length(RowPositions)-1] := Position;
    for RowIndex := 0 to Length(Delc) - 1 do
    begin
      Position := Position + Delc[RowIndex];
      RowPositions[Length(RowPositions) - RowIndex - 2] := Position;
    end;
  end;

  TOP := Dis.GridData.TOP;
  BOTM  := Dis.GridData.BOTM;
  IDOMAIN := Dis.GridData.IDOMAIN;
  NumberOfLayers := Length(BOTM);
  UpdateLayerStructure(NumberOfLayers);

  Model.ModflowGrid.BeginGridChange;
  try
    Model.ModflowGrid.GridAngle := GridAngle;
    Model.ModflowGrid.ColumnPositions := ColumnPositions;
    Model.ModflowGrid.RowPositions := RowPositions;
  finally
    Model.ModflowGrid.EndGridChange;
  end;
  AssignTOP(TOP);
  AssignBOTM(BOTM);
  AssignIDomain(IDOMAIN, NumberOfLayers);

end;

procedure TModflow6Importer.ImportDisV(Package: TPackage);
var
  Model: TPhastModel;
  MfOptions: TModflowOptions;
  Disv: TDisv;
  XOrigin: Extended;
  YOrigin: Extended;
  GridAngle: Extended;
  Mesh3D: TModflowDisvGrid;
  Mesh2D: TModflowIrregularGrid2D;
  CellCorners: TModflowNodes;
  Verticies: TDisvVertices;
  Index: Integer;
  Vertex: TVertex;
  Node: TModflowNode;
  Cells: TDisvCells;
  ModelCells: TModflowIrregularCell2DCollection;
  Cell: TDisvCell;
  IrregularCell: TModflowIrregularCell2D;
  NodeIndex: Integer;
  NodeNumber: Integer;
  ModelNode: TIntegerItem;
  TOP: TDArray2D;
  BOTM: TDArray3D;
  IDOMAIN: TIArray3D;
  APoint: TPoint2D;
  NumberOfLayers: Integer;
  function ConvertLocation(X, Y: Extended): TPoint2D;
  begin
    if GridAngle = 0 then
    begin
      result.x := XOrigin + X;
      result.Y := YOrigin + Y;
    end
    else
    begin
      result.x := XOrigin + X * Cos(GridAngle);
      result.Y := YOrigin + Y * Sin(GridAngle);
    end;
  end;
begin
  Model := frmGoPhast.PhastModel;
  MfOptions := Model.ModflowOptions;

  Model.Mf6GridType := mgtLayered;

  Disv := Package.Package as TDisv;
  MfOptions.LengthUnit := Disv.Options.LENGTH_UNITS;
  MfOptions.WriteBinaryGridFile := not Disv.Options.NOGRB;

  XOrigin := Disv.Options.XORIGIN;
  YOrigin := Disv.Options.YORIGIN;
  GridAngle := Disv.Options.ANGROT * Pi / 180;
  
  NumberOfLayers := Disv.Dimensions.NLay;
  UpdateLayerStructure(NumberOfLayers);

  Mesh3D := Model.DisvGrid;
  Mesh2D := Mesh3D.TwoDGrid;
  CellCorners := Mesh2D.CellCorners;
  
  Verticies := Disv.Verticies;
  CellCorners.Capacity := Verticies.Count;
  for Index := 0 to Verticies.Count - 1 do
  begin
    Vertex := Verticies[Index];
    Node := CellCorners.Add;
    APoint := ConvertLocation(Vertex.xv, Vertex.yv);
    Node.X := APoint.x;
    Node.Y := APoint.y;
    Node.Number := Vertex.iv -1; 
  end;

  Cells := Disv.Cells;
  ModelCells := Mesh2D.Cells;

  ModelCells.Capacity := Cells.Count;
  for Index := 0 to Cells.Count - 1 do
  begin
    Cell := Cells[Index];
    IrregularCell := ModelCells.Add;
    IrregularCell.ElementNumber := Cell.icell2d -1;
    APoint := ConvertLocation(Cell.xc, Cell.yc);
    IrregularCell.X := APoint.x;
    IrregularCell.Y := APoint.y; 
    IrregularCell.NodeNumbers.Capacity := Cell.ncvert;
    for NodeIndex := 0 to Cell.ncvert - 1 do
    begin
      NodeNumber := Cell.icvert[NodeIndex] -1;
      ModelNode := IrregularCell.NodeNumbers.Add;
      ModelNode.Value := NodeNumber;
    end;
  end;

  Mesh3D.Loaded;

  TOP := Disv.GridData.TOP;
  BOTM := Disv.GridData.BOTM;
  IDOMAIN := Disv.GridData.IDOMAIN;
  
  AssignTOP(TOP);
  AssignBOTM(BOTM);
  AssignIDomain(IDOMAIN, NumberOfLayers);

end;

function TModflow6Importer.ImportFlowModel: Boolean;
var
  NameFile: TFlowNameFile;
  Options: TFlowNameFileOptions;
  Packages: TFlowPackages;
  Model: TPhastModel;
  MfOptions: TModflowOptions;
  OC: TModflowOutputControl;
  PackageIndex: Integer;
  APackage: TPackage;
  FlowBudgetFileName: string;
  TransportModels: TModelList;
  ModelIndex: Integer;
  ATransportModel: TModel;
begin
  result := True;
  TransportModels := TModelList.Create;
  try
    if FFlowModel <> nil then
    begin
      Model := frmGoPhast.PhastModel;

      NameFile := FFlowModel.FName as TFlowNameFile;
      FlowBudgetFileName := FFlowModel.FullBudgetFileName;

      for ModelIndex := 0 to FSimulation.Models.Count - 1 do
      begin
        ATransportModel := FSimulation.Models[ModelIndex];
        if (ATransportModel.ModelType = 'GWT6')
          and (ATransportModel.FullBudgetFileName = FlowBudgetFileName) then
        begin
          TransportModels.Add(ATransportModel);
        end;
      end;


      Options := NameFile.NfOptions;
      MfOptions := Model.ModflowOptions;
      MfOptions.NewtonMF6 := Options.NEWTON;
      MfOptions.UnderRelaxationMF6 := Options.UNDER_RELAXATION;
      if Options.PRINT_INPUT then
      begin
        OC := Model.ModflowOutputControl;
        OC.PrintInputCellLists := True;
        OC.PrintInputArrays := True;
      end;

      Packages := NameFile.NfPackages;

      for PackageIndex := 0 to Packages.Count - 1 do
      begin
        APackage := Packages[PackageIndex];
        if APackage.FileType = 'DIS6' then
        begin
          ImportDis(APackage);
          break
        end
        else if APackage.FileType = 'DISV6' then
        begin
          ImportDisV(APackage);
          break;
        end
        else if APackage.FileType = 'DISU6' then
        begin
          MessageDlg('ModelMuse can not import DISU models.', mtError, [mbOK], 0);
          result := False;
          Exit
        end
        else
        begin
          Continue;
        end;
      end;

      for PackageIndex := 0 to Packages.Count - 1 do
      begin
        APackage := Packages[PackageIndex];
        if (APackage.FileType = 'DIS6')
          or (APackage.FileType = 'DISV6')
          or (APackage.FileType = 'DISU6')
          then
        begin
          Continue;
        end;

        if APackage.FileType = 'IC6' then
        begin
          ImportIc(APackage);
        end
        else if APackage.FileType = 'OC6' then
        begin
          ImportOc(APackage)
        end
        else if APackage.FileType = 'OBS6' then
        begin
          ImportGwfObs(APackage)
        end
        else if APackage.FileType = 'NPF6' then
        begin
          ImportNpf(APackage);
        end
        else if APackage.FileType = 'HFB6' then
        begin
          ImportHfb(APackage);
        end
        else if APackage.FileType = 'STO6' then
        begin
          ImportSto(APackage);
        end
        else if APackage.FileType = 'CSUB6' then
        begin
          ImportCSub(APackage);
        end
        else if APackage.FileType = 'BUY6' then
        begin
          ImportBuy(APackage);
        end
        else if APackage.FileType = 'VSC6' then
        begin
          ImportVsc(APackage);
        end
        else if APackage.FileType = 'CHD6' then
        begin
          ImportChd(APackage, TransportModels);
        end
        else if APackage.FileType = 'WEL6' then
        begin
  //        WelReader := TWel.Create(APackage.FileType);
  //        WelReader.Dimensions := FDimensions;
  //        APackage.Package := WelReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'DRN6' then
        begin
  //        DrnReader := TDrn.Create(APackage.FileType);
  //        DrnReader.Dimensions := FDimensions;
  //        APackage.Package := DrnReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'GHB6' then
        begin
  //        GhbReader := TGhb.Create(APackage.FileType);
  //        GhbReader.Dimensions := FDimensions;
  //        APackage.Package := GhbReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'RIV6' then
        begin
  //        RivReader := TRiv.Create(APackage.FileType);
  //        RivReader.Dimensions := FDimensions;
  //        APackage.Package := RivReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'RCH6' then
        begin
  //        RchReader := TRch.Create(APackage.FileType);
  //        RchReader.Dimensions := FDimensions;
  //        APackage.Package := RchReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'EVT6' then
        begin
  //        EvtReader := TEvt.Create(APackage.FileType);
  //        EvtReader.Dimensions := FDimensions;
  //        APackage.Package := EvtReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'MAW6' then
        begin
  //        MawReader := TMaw.Create(APackage.FileType);
  //        MawReader.Dimensions := FDimensions;
  //        APackage.Package := MawReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'SFR6' then
        begin
  //        SfrReader := TSfr.Create(APackage.FileType);
  //        SfrReader.Dimensions := FDimensions;
  //        APackage.Package := SfrReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'LAK6' then
        begin
  //        LakReader := TLak.Create(APackage.FileType);
  //        LakReader.Dimensions := FDimensions;
  //        APackage.Package := LakReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'UZF6' then
        begin
  //        UzfReader := TUzf.Create(APackage.FileType);
  //        UzfReader.Dimensions := FDimensions;
  //        APackage.Package := UzfReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'MVR6' then
        begin
  //        MovReader := TMvr.Create(APackage.FileType);
  //        APackage.Package := MovReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'GNC6' then
        begin
  //        GncReader := TGnc.Create(APackage.FileType);
  //        GncReader.Dimensions := FDimensions;
  //        APackage.Package := GncReader;
  //        APackage.ReadPackage(Unhandled);
        end
        else if APackage.FileType = 'GWF6-GWF6' then
        begin
  //        GwfGwfReader := TGwfGwf.Create(APackage.FileType);
  //        GwfGwfReader.Dimensions := FDimensions;
  //        GwfGwfReader.FDimensions2 := FDimensions;
  //        APackage.Package := GwfGwfReader;
  //        APackage.ReadPackage(Unhandled);
        end

      end;

    end;
  finally
    TransportModels.Free;
  end;
end;

procedure TModflow6Importer.ImportFlowModelTiming;
var
  PhastModel: TPhastModel;
  MFStressPeriods: TModflowStressPeriods;
  StressPeriods: TTDis;
  MfOptions: TModflowOptions;
  TimeUnits: string;
  ValidUnits: TStringList;
  MfTimeUnit: Integer;
  SPIndex: Integer;
  SPData: TPeriod;
  MfStressPeriod: TModflowStressPeriod;
  StartTime: double;
  AtsIndex: Integer;
  AtsPeriod: TAtsPeriod;
begin
  StressPeriods := FSimulation.Timing.TDis;


  PhastModel := frmGoPhast.PhastModel;
  MfOptions := PhastModel.ModflowOptions;
  TimeUnits := UpperCase(StressPeriods.Options.TimeUnits);
  if StressPeriods.Options.StartDate <> '' then
  begin
    MfOptions.Description.Add('Start Date = ' + StressPeriods.Options.StartDate);
    FErrorMessages.Add('Warning: The start date of the model has been added as a comment to the model description')
  end;

  ValidUnits := TStringList.Create;
  try
    ValidUnits.Add('UNKNOWN');
    ValidUnits.Add('SECONDS');
    ValidUnits.Add('MINUTES');
    ValidUnits.Add('HOURS');
    ValidUnits.Add('DAYS');
    ValidUnits.Add('YEARS');
    MfTimeUnit := ValidUnits.IndexOf(TimeUnits);
    if MfTimeUnit < 0 then
    begin
      MfTimeUnit := 0;
    end;
    MfOptions.TimeUnit := MfTimeUnit;
  finally
    ValidUnits.Free;
  end;


  MFStressPeriods := PhastModel.ModflowStressPeriods;
  MFStressPeriods.Capacity := StressPeriods.Dimensions.NPER;
  StartTime := 0.0;
  for SPIndex := 0 to StressPeriods.PeriodData.Count - 1 do
  begin
    SPData := StressPeriods.PeriodData[SPIndex];
    MfStressPeriod := MFStressPeriods.Add;
    MfStressPeriod.StartTime := StartTime;
    StartTime := StartTime + SPData.PerLen;
    MfStressPeriod.EndTime := StartTime;
    MfStressPeriod.PeriodLength := SPData.PerLen;
    MfStressPeriod.TimeStepMultiplier := SPData.TSMult;

    if SPData.NSTP > 1 then
    begin
      if SPData.TSMULT = 1 then
      begin
        MfStressPeriod.MaxLengthOfFirstTimeStep :=
          SPData.PERLEN / SPData.NSTP;
      end
      else
      begin
        MfStressPeriod.MaxLengthOfFirstTimeStep :=
          SPData.PERLEN * (SPData.TSMULT - 1)
          / (IntPower(SPData.TSMULT, SPData.NSTP) - 1);
      end;
    end
    else
    begin
      MfStressPeriod.MaxLengthOfFirstTimeStep := MfStressPeriod.PeriodLength;
    end;
  end;

  if StressPeriods.Ats <> nil then
  begin
    for AtsIndex := 0 to StressPeriods.Ats.Count - 1 do
    begin
      AtsPeriod := StressPeriods.Ats.AtsPeriod[AtsIndex];
      if AtsPeriod.iperats <= 0 then
      begin
        FErrorMessages.Add('ATS period data for iperats <= 0 is skipped ')
      end
      else if AtsPeriod.iperats > MFStressPeriods.Count then
      begin
        FErrorMessages.Add('ATS period data for iperats > NPER is skipped ')
      end
      else
      begin
        MfStressPeriod := MFStressPeriods[AtsPeriod.iperats-1];
        MfStressPeriod.AtsUsed := True;
        MfStressPeriod.AtsInitialStepSize := AtsPeriod.dt0;
        MfStressPeriod.AtsMinimumStepSize := AtsPeriod.dtmin;
        MfStressPeriod.AtsMaximumStepSize := AtsPeriod.dtmax;
        MfStressPeriod.AtsAdjustmentFactor := AtsPeriod.dtadj;
        MfStressPeriod.AtsFailureFactor := AtsPeriod.dtfailadj;
      end;
    end;
  end;
end;

procedure TModflow6Importer.ImportGwfObs(Package: TPackage);
var
  Obs: TObs;
  Model: TPhastModel;
  Mf6ObservationUtility: TMf6ObservationUtility;
  FileIndex: Integer;
  ObsFile: TObsFile;
  ObsIndex: Integer;
  Observation: TObservation;
  ScreenObject: TScreenObject;
  UndoCreateScreenObject: TCustomUndo;
  Modflow6Obs: TModflow6Obs;
  APoint: TPoint2D;
  CellId: TCellId;
begin
  Obs := Package.Package as TObs;
  Model := frmGoPhast.PhastModel;
  Mf6ObservationUtility := Model.ModflowPackages.Mf6ObservationUtility;
  Mf6ObservationUtility.IsSelected := True;
  if Obs.Options.Digits > 0 then
  begin
    Mf6ObservationUtility.OutputFormat := ofText;
    Mf6ObservationUtility.Digits := Obs.Options.Digits;
  end
  else
  begin
    Mf6ObservationUtility.OutputFormat := ofBinary;
  end;

  for FileIndex := 0 to Obs.FileCount - 1 do
  begin
    ObsFile := Obs[FileIndex];
    for ObsIndex := 0 to ObsFile.Count - 1 do
    begin
      Observation := ObsFile[ObsIndex];

      if AnsiSameText(Observation.ObsType, 'head')
        or AnsiSameText(Observation.ObsType, 'drawdown') then
      begin

        ScreenObject := TScreenObject.CreateWithViewDirection(
          Model, vdTop, UndoCreateScreenObject, False);
        ScreenObject.Comment := 'Imported from ' + FModelNameFile +' on ' + DateTimeToStr(Now);

        Model.AddScreenObject(ScreenObject);
        ScreenObject.ElevationCount := ecOne;
        ScreenObject.SetValuesOfIntersectedCells := True;
        ScreenObject.EvaluatedAt := eaBlocks;
        ScreenObject.Visible := False;
        ScreenObject.Capacity := 1;

        CellId := Observation.CellId1;
        if Model.DisvUsed then
        begin
          Dec(CellId.Column);
          CellId.Row := 0;
        end
        else
        begin
          Dec(CellId.Column);
          Dec(CellId.Row);
        end;
        Assert(Observation.IdType1 = itCell);
        APoint := Model.TwoDElementCenter(CellId.Column, CellId.Row);
        ScreenObject.AddPoint(APoint, True);
        ScreenObject.ElevationFormula := Format('LayerCenter(%d)', [CellId.Layer]);

        ScreenObject.CreateMf6Obs;
        Modflow6Obs := ScreenObject.Modflow6Obs;
        Modflow6Obs.Name := Observation.ObsName;
        if AnsiSameText(Observation.ObsType, 'head') then
        begin
          Modflow6Obs.General := [ogHead];
        end
        else
        begin
          Modflow6Obs.General := [ogDrawdown];
        end;

      end
      else if AnsiSameText(Observation.ObsType, 'flow-ja-face') then
      begin
        FErrorMessages.Add(Format('ModelMuse could not import the observation "%s" because it is a flow-ja-face observation', [Observation.ObsName] ));
      end
      else
      begin
        FErrorMessages.Add(Format('ModelMuse could not import the observation "%s" because it is not a recognized type', [Observation.ObsName] ));
      end;
    end;
  end;
end;

procedure TModflow6Importer.ImportHfb(Package: TPackage);
const
  KImportedHfbValue = 'ImportedHfbValue';
var
  Hfb: THfb;
  PeriodIndex: Integer;
  Model: TPhastModel;
  LastTime: Double;
  HfbPeriod: THfbStressPeriod;
  AScreenObject: TScreenObject;
  UndoCreateScreenObject: TCustomUndo;
  NewItem: THfbItem;
  StartTime: Double;
  Item: THfbItem;
  ScreenObjects: Array of TScreenObject;
  LayerIndex: Integer;
  ItemIndex: Integer;
  Barrier: THfbCellPair;
  Layer: Integer;
  Storage: TValueArrayItem;
  StorageValues: TValueArrayStorage;
  Point1: TPoint2D;
  Point2: TPoint2D;
  TwoDGrid: TModflowIrregularGrid2D;
  Cell1: TModflowIrregularCell2D;
  Cell2: TModflowIrregularCell2D;
  BoundarySegment: TSegment2D;
  Column: Integer;
  Row: Integer;
  function CreateScreenObject(LayerIndex: Integer): TScreenObject;
  begin
    result := TScreenObject.CreateWithViewDirection(
      Model, vdTop, UndoCreateScreenObject, False);
    result.Name := Format('Imported_HFB_Layer_%d_Period_%d', [LayerIndex + 1, HfbPeriod.Period]);
    result.Comment := 'Imported from ' + FModelNameFile +' on ' + DateTimeToStr(Now);

    Model.AddScreenObject(result);
    result.ElevationCount := ecOne;
    result.SetValuesOfIntersectedCells := True;
    result.EvaluatedAt := eaBlocks;
    result.Visible := False;
    result.ElevationFormula := Format('LayerCenter(%d)', [LayerIndex+1]);
    ScreenObjects[LayerIndex] := result;

    Storage := result.ImportedValues.Add;
    Storage.Name := KImportedHfbValue;
    Storage.Values.DataType := rdtDouble;

    result.CreateHfbBoundary;

    NewItem := result.ModflowHfbBoundary.Values.Add as THfbItem;
    NewItem.StartTime := StartTime;
    NewItem.EndTime := LastTime;
    NewItem.HydraulicConductivity := rsObjectImportedValuesR + '("' + KImportedHfbValue + '")';
    NewItem.Thickness := '1';
  end;
begin
  Model := frmGoPhast.PhastModel;
  SetLength(ScreenObjects, Model.LayerCount);
  Model.ModflowPackages.HfbPackage.IsSelected := True;
  LastTime := Model.ModflowStressPeriods.Last.EndTime;

  Hfb := Package.Package as THfb;

  for PeriodIndex := 0 to Hfb.Count - 1 do
  begin
    HfbPeriod := Hfb[PeriodIndex];
    StartTime := Model.ModflowStressPeriods[HfbPeriod.Period-1].StartTime;
    for LayerIndex := 0 to Length(ScreenObjects) - 1 do
    begin
      AScreenObject := ScreenObjects[LayerIndex];
      if AScreenObject <> nil then
      begin
        Item := AScreenObject.ModflowHfbBoundary.Values.Last as THfbItem;
        Item.EndTime := StartTime;
        ScreenObjects[LayerIndex] := nil;
      end;
    end;
    if HfbPeriod.Count > 0 then
    begin
      for ItemIndex := 0 to HfbPeriod.Count - 1 do
      begin
        Barrier := HfbPeriod[ItemIndex];
        Layer := Barrier.CellId1.Layer;
        Assert(Layer = Barrier.CellId2.Layer);
        AScreenObject := ScreenObjects[Layer-1];
        if AScreenObject = nil then
        begin
          AScreenObject := CreateScreenObject(Layer-1);
        end;
        StorageValues := AScreenObject.ImportedValues.ValuesByName(KImportedHfbValue);
        StorageValues.Add(Barrier.hydchr);

        if Model.DisvUsed then
        begin
          TwoDGrid := Model.DisvGrid.TwoDGrid;
          Cell1 := TwoDGrid.Cells[Barrier.CellId1.Column-1];
          Cell2 := TwoDGrid.Cells[Barrier.CellId2.Column-1];
          if Cell1.BoundarySegment(Cell2, BoundarySegment) then
          begin
            AScreenObject.AddPoint(BoundarySegment[1], True);
            AScreenObject.AddPoint(BoundarySegment[2], False);
          end
          else
          begin
            FErrorMessages.Add(Format('Error importing HRB because Cells %d and %d are not neighbors', [Barrier.CellId1.Column, Barrier.CellId2.Column]));
          end;
        end
        else
        begin
          Assert((Abs(Barrier.CellId1.Column - Barrier.CellId2.Column) = 1)
            xor (Abs(Barrier.CellId1.Row - Barrier.CellId2.Row) = 1));

          Column := Max(Barrier.CellId1.Column, Barrier.CellId2.Column)-1;
          Row := Max(Barrier.CellId1.Row, Barrier.CellId2.Row)-1;
          Point1 := Model.Grid.TwoDElementCorner(Column, Row);

          if Barrier.CellId1.Column = Barrier.CellId2.Column then
          begin
            Inc(Column);
          end
          else
          begin
            Inc(Row);
          end;

          Point2 := Model.Grid.TwoDElementCorner(Column, Row);
          AScreenObject.AddPoint(Point1, True);
          AScreenObject.AddPoint(Point2, False);
        end;
      end;
    end;
  end;
end;

procedure TModflow6Importer.ImportIc(Package: TPackage);
var
  IC: TIc;
begin
  IC := Package.Package as TIc;
  Assign3DRealDataSet(rsModflow_Initial_Head, IC.GridData.STRT);
end;

procedure TModflow6Importer.ImportModflow6Model(NameFiles, ErrorMessages: TStringList);
var
  FileIndex: Integer;
  OutFile: string;
  ListFile: TStringList;
  PhastModel: TPhastModel;
  ModelIndex: Integer;
  AModel: TModel;
  FlowModelNames: TStringList;
  FlowModelImported: Boolean;
  frmSelectFlowModel: TfrmSelectFlowModel;
  ExchangeIndex: Integer;
  Exchange: TExchange;
begin
  FErrorMessages := ErrorMessages;
  for FileIndex := 0 to NameFiles.Count - 1 do
  begin
    if not TFile.Exists(NameFiles[FileIndex]) then
    begin
      Beep;
      MessageDlg(Format(StrTheNameFileSDoe, [NameFiles[FileIndex]]), mtError, [mbOK], 0);
      Exit;
    end;
  end;
  PhastModel := frmGoPhast.PhastModel;
  PhastModel.Clear;
  frmGoPhast.Caption := StrModelName;
  frmGoPhast.sdSaveDialog.FileName := '';
  PhastModel.ModelSelection := msModflow2015;

  FlowModelImported := False;
  for FileIndex := 0 to NameFiles.Count - 1 do
  begin
    FSimulation := TMf6Simulation.Create('Simulation');
    try
      FSimulation.ReadSimulation(NameFiles[FileIndex]);
      OutFile := ChangeFileExt(NameFiles[FileIndex], '.lst');
      if TFile.Exists(OutFile) then
      begin
        ListFile := TStringList.Create;
        try
          ListFile.LoadFromFile(OutFile);
          if ListFile.Count > 0 then
          begin
            ErrorMessages.Add('The following errors were encountered when reading ' + NameFiles[FileIndex]);
            ErrorMessages.AddStrings(ListFile);
            ErrorMessages.Add('');
          end;
        finally
          ListFile.Free;
        end;
      end
      else
      begin
        ErrorMessages.Add(OutFile + ' does not exist.')
      end;

      for ExchangeIndex := 0 to FSimulation.Exchanges.Count - 1 do
      begin
        Exchange := FSimulation.Exchanges[ExchangeIndex];
        if not AnsiSameText(Exchange.ExchangeType, 'GWF6-GWT6') then
        begin
          ErrorMessages.Add('The following error was encountered when reading ' + NameFiles[FileIndex]);
          ErrorMessages.Add('ModelMuse does not currently support MODFLOW 6 exchanges');
          break;
        end;
      end;

      FlowModelNames := TStringList.Create;
      try
        for ModelIndex := 0 to FSimulation.Models.Count - 1 do
        begin
          AModel := FSimulation.Models[ModelIndex];
          if AModel.ModelType = 'GWF6' then
          begin
            FlowModelNames.Add(AModel.NameFile)
          end;
        end;
        if FlowModelImported and (FlowModelNames.Count > 0) then
        begin
          ErrorMessages.Add('The following error was encountered when reading ' + NameFiles[FileIndex]);
          ErrorMessages.Add('Another flow model name file was already in another simulation name file');
          Exit;
        end;
        FModelNameFile := '';
        if FlowModelNames.Count > 1 then
        begin
          frmSelectFlowModel := TfrmSelectFlowModel.Create(nil);
          try
            frmSelectFlowModel.rgFlowModels.Items := FlowModelNames;
            frmSelectFlowModel.rgFlowModels.ItemIndex := 0;
            if frmSelectFlowModel.ShowModal = mrOK then
            begin
              FModelNameFile := frmSelectFlowModel.rgFlowModels.Items[frmSelectFlowModel.rgFlowModels.ItemIndex];
            end
            else
            begin
              Exit;
            end;
          finally
            frmSelectFlowModel.Free
          end;
        end
        else
        begin
          FModelNameFile := FlowModelNames[0];
        end;
        if FModelNameFile <> '' then
        begin
          FFlowModel := FSimulation.Models.GetModelByNameFile(FModelNameFile);
        end
        else
        begin
          FFlowModel := nil;
        end;
        ImportSimulationOptions;
        ImportFlowModelTiming;
        ImportSolutionGroups;
        if not ImportFlowModel then
        begin
          Exit;
        end;

      finally
        FlowModelNames.Free
      end;

    finally
      FSimulation.Free;
      FSimulation := nil;
    end;
  end;
  PhastModel.Exaggeration := frmGoPhast.DefaultVE;
  frmGoPhast.RestoreDefault2DView1Click(nil);
end;

procedure TModflow6Importer.ImportNpf(Package: TPackage);
var
  Npf: TNpf;
  Model: TPhastModel;
  NpfPackage: TNpfPackage;
  Options: TNpfOptions;
  GridData: TNpfGridData;
  DataArray: TDataArray;
  TvkIndex: Integer;
begin
  Model := frmGoPhast.PhastModel;
  Npf := Package.Package as TNpf;

  NpfPackage := Model.ModflowPackages.NpfPackage;
  Options := Npf.Options;
  if Options.ALTERNATIVE_CELL_AVERAGING <> '' then
  begin
    if Options.ALTERNATIVE_CELL_AVERAGING = 'LOGARITHMIC' then
    begin
      NpfPackage.CellAveraging := caLogarithmic;
    end
    else if Options.ALTERNATIVE_CELL_AVERAGING = 'AMT-LMK' then
    begin
      NpfPackage.CellAveraging := caArithLog;
    end
    else if Options.ALTERNATIVE_CELL_AVERAGING = 'AMT-HMK' then
    begin
      NpfPackage.CellAveraging := caArithHarm;
    end
    else
    begin
      FErrorMessages.Add(Format('Unrecognized ALTERNATIVE_CELL_AVERAGING option %s in NPF package',
        [Options.ALTERNATIVE_CELL_AVERAGING]))
    end;
  end;
  NpfPackage.UseSaturatedThickness := Options.THICKSTRT;
  NpfPackage.TimeVaryingVerticalConductance := Options.VARIABLECV;
  NpfPackage.Dewatered := Options.DEWATERED;
  NpfPackage.Perched := Options.PERCHED;
  Model.ModflowWettingOptions.WettingActive := Options.REWET.Used;
  if Options.REWET.Used then
  begin
    Model.ModflowWettingOptions.WettingFactor := Options.REWET.WETFCT;
    Model.ModflowWettingOptions.WettingIterations := Options.REWET.IWETIT;
    Model.ModflowWettingOptions.WettingEquation := Options.REWET.IHDWET;
  end;
  NpfPackage.UseXT3D := Options.XT3D;
  NpfPackage.Xt3dOnRightHandSide := Options.RHS;
  NpfPackage.SaveSpecificDischarge := Options.SAVE_SPECIFIC_DISCHARGE;
  NpfPackage.SaveSaturation := Options.SAVE_SATURATION;
  NpfPackage.UseHorizontalAnisotropy := Options.K22OVERK;
  NpfPackage.UseVerticalAnisotropy := Options.K33OVERK;

  GridData := Npf.GridData;
  Assign3DIntegerDataSet(KCellType, GridData.ICELLTYPE);

  Assign3DRealDataSet(rsKx, GridData.K);

  if GridData.K22 <> nil then
  begin
    if NpfPackage.UseHorizontalAnisotropy then
    begin
      Assign3DRealDataSet(KKyOverKx, GridData.K22);
    end
    else
    begin
      Assign3DRealDataSet(rsKy, GridData.K22);
    end;
  end
  else
  begin
    DataArray := Model.DataArrayManager.GetDataSetByName(rsKy);
    DataArray.Formula := rsKx;
  end;

  if GridData.K33 <> nil then
  begin
    if NpfPackage.UseVerticalAnisotropy then
    begin
      Assign3DRealDataSet(KKzOverKx, GridData.K33);
    end
    else
    begin
      Assign3DRealDataSet(rsKz, GridData.K33);
    end;
  end
  else
  begin
    DataArray := Model.DataArrayManager.GetDataSetByName(rsKz);
    DataArray.Formula := rsKx;
  end;

  if GridData.ANGLE1 <> nil then
  begin
    Assign3DRealDataSet(KXT3DAngle1, GridData.ANGLE1);
  end;

  if GridData.ANGLE2 <> nil then
  begin
    Assign3DRealDataSet(KXT3DAngle2, GridData.ANGLE2);
  end;

  if GridData.ANGLE3 <> nil then
  begin
    Assign3DRealDataSet(KXT3DAngle3, GridData.ANGLE3);
  end;

  if GridData.WETDRY <> nil then
  begin
    Assign3DRealDataSet(rsWetDry, GridData.WETDRY);
  end;

  if Npf.Count > 0 then
  begin
    Model.ModflowPackages.TvkPackage.IsSelected := True;
    for TvkIndex := 0 to Npf.Count - 1 do
    begin
      ImportTvk(Npf[TvkIndex])
    end;
  end;
end;

procedure TModflow6Importer.ImportOc(Package: TPackage);
var
  OC: TOc;
  Model: TPhastModel;
  OutputControl: TModflowOutputControl;
begin
  OC := Package.Package as TOc;
  Model := frmGoPhast.PhastModel;
  OutputControl := Model.ModflowOutputControl;

  if OC.Options.BudgetFile then
  begin
    OutputControl.SaveCellFlows := csfBinary
  end;
  if OC.Options.BudgetCsvFile then
  begin
    OutputControl.SaveBudgetCSV := True
  end;
  if OC.Options.HeadFile then
  begin
    OutputControl.HeadOC.SaveInExternalFile := True
  end;
  if OC.Options.ConcentrationFile then
  begin
    OutputControl.ConcentrationOC.SaveInExternalFile := True
  end;
end;

procedure TModflow6Importer.Assign3DBooleanDataSet(DsName: string;
  Data: TIArray3D);
var
  Formula: string;
  Model: TPhastModel;
  LayerIndex: Integer;
  FirstValue: Boolean;
  RowIndex: Integer;
  ColIndex: Integer;
  Uniform: Boolean;
  DataArrayName: string;
  DataArray: TDataArray;
  Interpolator: TNearestPoint2DInterpolator;
  ScreenObject: TScreenObject;
begin
  Formula := 'CaseB(Layer';
  Model := frmGoPhast.PhastModel;
  for LayerIndex := 1 to Model.LayerStructure.Count - 1 do
  begin
    Uniform := True;
    FirstValue := Data[LayerIndex - 1, 0, 0] <> 0;
    for RowIndex := 0 to Model.RowCount - 1 do
    begin
      for ColIndex := 0 to Model.ColumnCount - 1 do
      begin
        Uniform := FirstValue = (Data[LayerIndex - 1, RowIndex, ColIndex] <> 0);
        if not Uniform then
        begin
          break;
        end;
      end;
    end;
    DataArrayName := Format('Imported_%s_%d', [DsName, LayerIndex]);
    Formula := Formula + ',' + DataArrayName;
    DataArray := Model.DataArrayManager.CreateNewDataArray(TDataArray,
      DataArrayName, '0', DataArrayName, [dcType], rdtBoolean, eaBlocks, dsoTop, '');
    DataArray.Comment := Format('Imported from %s on %s', [FModelNameFile, DateTimeToStr(Now)]);
    DataArray.UpdateDimensions(Model.LayerCount, Model.RowCount, Model.ColumnCount);
    Interpolator := TNearestPoint2DInterpolator.Create(nil);
    try
      DataArray.TwoDInterpolator := Interpolator;
    finally
      Interpolator.Free;
    end;
    if Uniform then
    begin
      if FirstValue then
      begin
        DataArray.Formula := 'True';
      end
      else
      begin
        DataArray.Formula := 'False';
      end;
    end
    else
    begin
      ScreenObject := AllTopCellsScreenObject;
      AssignBooleanValuesToCellCenters(DataArray, ScreenObject, Data[LayerIndex - 1]);
    end;
  end;
  Formula := Formula + ')';
  if Model.LayerCount = 1 then
  begin
    DataArrayName := Format('Imported_%s_%d', [DsName, 1]);
    Formula := DataArrayName;
  end
  else
  begin
    Formula := Format('IfB(Layer > %d, False, %s)', [Model.LayerCount, Formula]);
  end;
  DataArray := Model.DataArrayManager.GetDataSetByName(DsName);
  Assert(DataArray <> nil);
  DataArray.Formula := Formula;
end;

procedure TModflow6Importer.Assign3DIntegerDataSet(DsName: string;
  Data: TIArray3D);
var
  Formula: string;
  Model: TPhastModel;
  LayerIndex: Integer;
  FirstValue: Integer;
  RowIndex: Integer;
  ColIndex: Integer;
  Uniform: Boolean;
  DataArrayName: string;
  DataArray: TDataArray;
  Interpolator: TNearestPoint2DInterpolator;
  ScreenObject: TScreenObject;
begin
  Formula := 'CaseI(Layer';
  Model := frmGoPhast.PhastModel;
  for LayerIndex := 1 to Model.LayerStructure.Count - 1 do
  begin
    Uniform := True;
    FirstValue := Data[LayerIndex - 1, 0, 0];
    for RowIndex := 0 to Model.RowCount - 1 do
    begin
      for ColIndex := 0 to Model.ColumnCount - 1 do
      begin
        Uniform := FirstValue = Data[LayerIndex - 1, RowIndex, ColIndex];
        if not Uniform then
        begin
          break;
        end;
      end;
    end;
    DataArrayName := Format('Imported_%s_%d', [DsName, LayerIndex]);
    Formula := Formula + ',' + DataArrayName;
    DataArray := Model.DataArrayManager.CreateNewDataArray(TDataArray,
      DataArrayName, '0', DataArrayName, [dcType], rdtInteger, eaBlocks, dsoTop, '');
    DataArray.Comment := Format('Imported from %s on %s', [FModelNameFile, DateTimeToStr(Now)]);
    DataArray.UpdateDimensions(Model.LayerCount, Model.RowCount, Model.ColumnCount);
    Interpolator := TNearestPoint2DInterpolator.Create(nil);
    try
      DataArray.TwoDInterpolator := Interpolator;
    finally
      Interpolator.Free;
    end;
    if Uniform then
    begin
      DataArray.Formula := IntToStr(FirstValue);
    end
    else
    begin
      ScreenObject := AllTopCellsScreenObject;
      AssignIntegerValuesToCellCenters(DataArray, ScreenObject, Data[LayerIndex - 1]);
    end;
  end;
  Formula := Formula + ')';
  if Model.LayerCount = 1 then
  begin
    DataArrayName := Format('Imported_%s_%d', [DsName, 1]);
    Formula := DataArrayName;
  end
  else
  begin
    Formula := Format('IfI(Layer > %d, 0, %s)', [Model.LayerCount, Formula]);
  end;
  DataArray := Model.DataArrayManager.GetDataSetByName(DsName);
  Assert(DataArray <> nil);
  DataArray.Formula := Formula;
end;

procedure TModflow6Importer.Assign3DRealDataSet(DsName: string; Data: TDArray3D);
var
  Formula: string;
  Model: TPhastModel;
  LayerIndex: Integer;
  FirstValue: Double;
  RowIndex: Integer;
  ColIndex: Integer;
  Uniform: Boolean;
  DataArrayName: string;
  DataArray: TDataArray;
  Interpolator: TNearestPoint2DInterpolator;
  ScreenObject: TScreenObject;
begin
  Formula := 'CaseR(Layer';
  Model := frmGoPhast.PhastModel;
  for LayerIndex := 1 to Model.LayerStructure.Count - 1 do
  begin
    Uniform := True;
    FirstValue := Data[LayerIndex - 1, 0, 0];
    for RowIndex := 0 to Model.RowCount - 1 do
    begin
      for ColIndex := 0 to Model.ColumnCount - 1 do
      begin
        Uniform := FirstValue = Data[LayerIndex - 1, RowIndex, ColIndex];
        if not Uniform then
        begin
          break;
        end;
      end;
    end;
    DataArrayName := Format('Imported_%s_%d', [DsName, LayerIndex]);
    Formula := Formula + ',' + DataArrayName;
    DataArray := Model.DataArrayManager.CreateNewDataArray(TDataArray,
      DataArrayName, '0', DataArrayName, [dcType], rdtDouble, eaBlocks, dsoTop, '');
    DataArray.Comment := Format('Imported from %s on %s', [FModelNameFile, DateTimeToStr(Now)]);
    DataArray.UpdateDimensions(Model.LayerCount, Model.RowCount, Model.ColumnCount);
    Interpolator := TNearestPoint2DInterpolator.Create(nil);
    try
      DataArray.TwoDInterpolator := Interpolator;
    finally
      Interpolator.Free;
    end;
    if Uniform then
    begin
      DataArray.Formula := FortranFloatToStr(FirstValue);
    end
    else
    begin
      ScreenObject := AllTopCellsScreenObject;
      AssignRealValuesToCellCenters(DataArray, ScreenObject, Data[LayerIndex - 1]);
    end;
  end;
  Formula := Formula + ')';
  if Model.LayerCount = 1 then
  begin
    DataArrayName := Format('Imported_%s_%d', [DsName, 1]);
    Formula := DataArrayName;
  end
  else
  begin
    Formula := Format('IfR(Layer > %d, 1, %s)', [Model.LayerCount, Formula]);
  end;
  DataArray := Model.DataArrayManager.GetDataSetByName(DsName);
  Assert(DataArray <> nil);
  DataArray.Formula := Formula;
end;

procedure TModflow6Importer.AssignTOP(TOP: TDArray2D);
var
  Model: TPhastModel; 
  ColIndex: Integer; 
  RowIndex: Integer;
  Uniform: Boolean;
  FirstValue: Double;
  DataArrayName: string;
  DataArray: TDataArray;
  ScreenObject: TScreenObject;
begin
  Model := frmGoPhast.PhastModel;
  Uniform := True;
  FirstValue := TOP[0, 0];
  for RowIndex := 0 to Model.RowCount - 1 do
  begin
    for ColIndex := 0 to Model.ColumnCount - 1 do
    begin
      Uniform := FirstValue = TOP[RowIndex, ColIndex];
      if not Uniform then
      begin
        break;
      end;
    end;
  end;
  DataArrayName := Model.LayerStructure[0].DataArrayName;
  DataArray := Model.DataArrayManager.GetDataSetByName(DataArrayName);
  if Uniform then
  begin
    DataArray.Formula := FortranFloatToStr(FirstValue);
  end
  else
  begin
    ScreenObject := AllTopCellsScreenObject;
    AssignRealValuesToCellCenters(DataArray, ScreenObject, TOP);
  end;
end;

procedure TModflow6Importer.AssignBooleanValuesToCellCenters(
  DataArray: TDataArray; ScreenObject: TScreenObject; ImportedData: TIArray2D);
var
  PointIndex: Integer;
  ImportedValues: TValueArrayItem;
  DataSetIndex: Integer;
  RowIndex: Integer;
  ColIndex: Integer;
  Interpolator: TNearestPoint2DInterpolator;
  Model: TPhastModel;
begin
  Model := frmGoPhast.PhastModel;
  Assert(DataArray.Orientation = dsoTop);
  if DataArray.TwoDInterpolator = nil then
  begin
    Interpolator := TNearestPoint2DInterpolator.Create(nil);
    try
      DataArray.TwoDInterpolator := Interpolator;
    finally
      Interpolator.Free;
    end;
  end;
  DataSetIndex := ScreenObject.AddDataSet(DataArray);
  ScreenObject.DataSetFormulas[DataSetIndex] := rsObjectImportedValuesB
    + '("' + DataArray.Name + '")';
  ScreenObject.ImportedValues.Add;
  ImportedValues := ScreenObject.ImportedValues.Items[
    ScreenObject.ImportedValues.Count-1];
  ImportedValues.Values.DataType := rdtBoolean;
  ImportedValues.Values.Count := Model.RowCount * Model.ColumnCount;
  ImportedValues.Name := DataArray.Name;
  PointIndex := 0;
  for RowIndex := 0 to Model.RowCount - 1 do
  begin
    for ColIndex := 0 to Model.ColumnCount - 1 do
    begin
      ImportedValues.Values.BooleanValues[PointIndex] :=
        ImportedData[RowIndex, ColIndex] <> 0;
      Inc(PointIndex);
    end;
  end;
  ImportedValues.Values.Count := PointIndex;
  ImportedValues.Values.CacheData;
end;

procedure TModflow6Importer.AssignBOTM(BOTM: TDArray3D);
var
  Model: TPhastModel; 
  LayerIndex: Integer;
  Uniform: Boolean; 
  FirstValue: Double; 
  DataArrayName: string; 
  DataArray: TDataArray; 
  ScreenObject: TScreenObject;
  RowIndex: Integer;
  ColIndex: Integer;
begin
  Model := frmGoPhast.PhastModel;
  for LayerIndex := 1 to Model.LayerStructure.Count - 1 do
  begin
    Uniform := True;
    FirstValue := BOTM[LayerIndex - 1, 0, 0];
    for RowIndex := 0 to Model.RowCount - 1 do
    begin
      for ColIndex := 0 to Model.ColumnCount - 1 do
      begin
        Uniform := FirstValue = BOTM[LayerIndex - 1, RowIndex, ColIndex];
        if not Uniform then
        begin
          break;
        end;
      end;
    end;
    DataArrayName := Model.LayerStructure[LayerIndex].DataArrayName;
    DataArray := Model.DataArrayManager.GetDataSetByName(DataArrayName);
    if Uniform then
    begin
      DataArray.Formula := FortranFloatToStr(FirstValue);
    end
    else
    begin
      ScreenObject := AllTopCellsScreenObject;
      AssignRealValuesToCellCenters(DataArray, ScreenObject, BOTM[LayerIndex - 1]);
    end;
  end;
end;

procedure TModflow6Importer.AssignIDomain(IDOMAIN: TIArray3D; NumberOfLayers: Integer);
var
  Uniform: Boolean; 
  DataArrayName: string; 
  DataArray: TDataArray; 
  ScreenObject: TScreenObject;
  Model: TPhastModel; 
  ColIndex: Integer; 
  RowIndex: Integer; 
  LayerIndex: Integer;
  IDomainFormula: string;
  FirstIntValue: Integer;
  Interpolator: TNearestPoint2DInterpolator;
  ActiveFormula: string;
  Active: TBArray2D;
  FirstBoolValue: Boolean;
begin
  Model := frmGoPhast.PhastModel;
  if IDOMAIN = nil then
  begin
    DataArray := Model.DataArrayManager.GetDataSetByName(K_IDOMAIN);
    DataArray.Formula := '1';
    DataArray := Model.DataArrayManager.GetDataSetByName(rsActive);
    DataArray.Formula := 'True';
    Exit;
  end;
  IDomainFormula := 'CaseI(Layer';
  for LayerIndex := 1 to Model.LayerStructure.Count - 1 do
  begin
    Uniform := True;
    FirstIntValue := IDOMAIN[LayerIndex - 1, 0, 0];
    for RowIndex := 0 to Model.RowCount - 1 do
    begin
      for ColIndex := 0 to Model.ColumnCount - 1 do
      begin
        Uniform := FirstIntValue = IDOMAIN[LayerIndex - 1, RowIndex, ColIndex];
        if not Uniform then
        begin
          break;
        end;
      end;
    end;
    DataArrayName := Format('Imported_IDOMAIN_%d', [LayerIndex]);
    IDomainFormula := IDomainFormula + ',' + DataArrayName;
    DataArray := Model.DataArrayManager.CreateNewDataArray(TDataArray,
      DataArrayName, '0', DataArrayName, [dcType], rdtInteger, eaBlocks,
      dsoTop, '');
    DataArray.Comment := Format('Imported from %s on %s',
      [FModelNameFile, DateTimeToStr(Now)]);
    DataArray.UpdateDimensions(Model.LayerCount, Model.RowCount, Model.ColumnCount);
    Interpolator := TNearestPoint2DInterpolator.Create(nil);
    try
      DataArray.TwoDInterpolator := Interpolator;
    finally
      Interpolator.Free;
    end;
    if Uniform then
    begin
      DataArray.Formula := IntToStr(FirstIntValue);
    end
    else
    begin
      ScreenObject := AllTopCellsScreenObject;
      AssignIntegerValuesToCellCenters(DataArray, ScreenObject, IDOMAIN[LayerIndex - 1]);
    end;
  end;
  IDomainFormula := IDomainFormula + ')';
  if NumberOfLayers = 1 then
  begin
    DataArrayName := Format('Imported_IDOMAIN_%d', [1]);
    IDomainFormula := DataArrayName;
  end
  else
  begin
    IDomainFormula := Format('IfI(Layer > %d, 1, %s)', [NumberOfLayers, IDomainFormula]);
  end;
  DataArray := Model.DataArrayManager.GetDataSetByName(K_IDOMAIN);
  DataArray.Formula := IDomainFormula;

  ActiveFormula := 'CaseB(Layer';
  SetLength(Active, Model.RowCount, Model.ColumnCount);
  for LayerIndex := 1 to Model.LayerStructure.Count - 1 do
  begin
    for RowIndex := 0 to Model.RowCount - 1 do
    begin
      for ColIndex := 0 to Model.ColumnCount - 1 do
      begin
        Active[RowIndex, ColIndex] := IDOMAIN[LayerIndex - 1, RowIndex, ColIndex] <> 0;
      end;
    end;
    Uniform := True;
    FirstBoolValue := Active[0, 0];
    for RowIndex := 0 to Model.RowCount - 1 do
    begin
      for ColIndex := 0 to Model.ColumnCount - 1 do
      begin
        Uniform := FirstBoolValue = Active[RowIndex, ColIndex];
        if not Uniform then
        begin
          break;
        end;
      end;
    end;
    DataArrayName := Format('Imported_Active_%d', [LayerIndex]);
    ActiveFormula := ActiveFormula + ',' + DataArrayName;
    DataArray := Model.DataArrayManager.CreateNewDataArray(TDataArray, 
      DataArrayName, 'True', DataArrayName, [dcType], rdtBoolean, eaBlocks, 
      dsoTop, '');
    DataArray.Comment := Format('Imported from %s on %s', 
      [FModelNameFile, DateTimeToStr(Now)]);
    DataArray.UpdateDimensions(Model.LayerCount, Model.RowCount, Model.ColumnCount);
    Interpolator := TNearestPoint2DInterpolator.Create(nil);
    try
      DataArray.TwoDInterpolator := Interpolator;
    finally
      Interpolator.Free;
    end;
    if Uniform then
    begin
      if FirstBoolValue then
      begin
        DataArray.Formula := 'True';
      end
      else
      begin
        DataArray.Formula := 'False';
      end;
    end
    else
    begin
      ScreenObject := AllTopCellsScreenObject;
      AssignBooleanValuesToCellCenters(DataArray, ScreenObject, Active);
    end;
  end;
  ActiveFormula := ActiveFormula + ')';
  if NumberOfLayers = 1 then
  begin
    DataArrayName := Format('Imported_Active_%d', [1]);
    ActiveFormula := DataArrayName;
  end
  else
  begin
    ActiveFormula := Format('IfB(Layer > %d, True, %s)', [NumberOfLayers, ActiveFormula]);
  end;
  DataArray := Model.DataArrayManager.GetDataSetByName(rsActive);
  DataArray.Formula := ActiveFormula;
end;

procedure TModflow6Importer.UpdateLayerStructure(NumberOfLayers: Integer);
var
  Model: TPhastModel;
  TopLayer: TLayerGroup;
  LayerIndex: Integer;
  LayerGroup: TLayerGroup;
begin
  Model := frmGoPhast.PhastModel;
  Model.LayerStructure.BeginUpdate;
  try
    TopLayer := Model.LayerStructure.Add;
    TopLayer.AquiferName := kModelTop;
    for LayerIndex := 1 to NumberOfLayers do
    begin
      LayerGroup := Model.LayerStructure.Add;
      LayerGroup.AquiferName := Format('Layer %d', [LayerIndex]);
    end;
    Model.ModflowGrid.LayerCount := NumberOfLayers;
    Model.DisvGrid.LayerCount := NumberOfLayers;
  finally
    Model.LayerStructure.EndUpdate;
  end;
end;

procedure TModflow6Importer.ImportSimulationOptions;
var
  Model: TPhastModel;
  SmsPkg: TSmsPackageSelection;
  OC: TModflowOutputControl;
begin
  Model := frmGoPhast.PhastModel;
  SmsPkg := Model.ModflowPackages.SmsPackage;
  SmsPkg.ContinueModel := FSimulation.Options.ContinueOption;
  if FSimulation.Options.NoCheckOption then
  begin
    SmsPkg.CheckInput := ciDontCheck
  end;
  case FSimulation.Options.MemPrint of
    Mf6.SimulationNameFileReaderUnit.mpNone:
      begin
        SmsPkg.MemoryPrint := ModflowPackageSelectionUnit.mpNone;
      end;
    Mf6.SimulationNameFileReaderUnit.mpSummary:
      begin
        SmsPkg.MemoryPrint := ModflowPackageSelectionUnit.mpSummary;
      end;
    Mf6.SimulationNameFileReaderUnit.mpAll:
      begin
        SmsPkg.MemoryPrint := ModflowPackageSelectionUnit.mpAll;
      end;
  end;
  SmsPkg.MaxErrors := FSimulation.Options.MaxErrors;
  if FSimulation.Options.PrintInputOption then
  begin
    OC := Model.ModflowOutputControl;
    OC.PrintInputCellLists := True;
  end;
end;

procedure TModflow6Importer.ImportSolutionGroups;
var
  GroupIndex: Integer;
  Group: TSolutionGroup;
  SolutionIndex: Integer;
  Solution: TSolution;
  ModelIndex: Integer;
  Model: TPhastModel;
begin
  // for now, this just imports Mxiter.
  if FFlowModel = nil then
  begin
    Exit;
  end;
  Model := frmGoPhast.PhastModel;
  for GroupIndex := 0 to FSimulation.SolutionGroupCount - 1 do
  begin
    Group := FSimulation.SolutionGroups[GroupIndex];
    for SolutionIndex := 0 to Group.Count - 1 do
    begin
      Solution := Group.Solutions[SolutionIndex];
      for ModelIndex := 0 to Solution.FSolutionModelNames.Count - 1 do
      begin
        if AnsiSameText(Solution.FSolutionModelNames[ModelIndex], FFlowModel.ModelName) then
        begin
          Model.ModflowPackages.SmsPackage.SolutionGroupMaxIteration
            := Group.Mxiter
        end;
      end;
    end;
  end;
end;

procedure TModflow6Importer.ImportSto(Package: TPackage);
var
  Sto: TSto;
  Model: TPhastModel;
  StoPackage: TStoPackage;
  Options: TStoOptions;
  GridData: TStoGridData;
  TvsIndex: Integer;
  DataSetName: string;
  StressPeriods: TModflowStressPeriods;
  SPIndex: Integer;
  StoPeriod: TStoStressPeriod;
  PriorStoPeriod: TStoStressPeriod;
  StressPeriod: TModflowStressPeriod;
  InnerIndex: Integer;
begin
  Model := frmGoPhast.PhastModel;
  Sto := Package.Package as TSto;

  StoPackage := Model.ModflowPackages.StoPackage;
  StoPackage.IsSelected := True;
  Options := Sto.Options;
  if Options.STORAGECOEFFICIENT then
  begin
    StoPackage.StorageChoice := scStorageCoefficient;
  end;

  Model.DataArrayManager.CreateInitialDataSets;

  GridData := Sto.GridData;
  Assign3DBooleanDataSet(KConvertible, GridData.ICONVERT);

  case StoPackage.StorageChoice of
    scSpecificStorage:
      begin
        DataSetName := rsSpecific_Storage;
      end;
    scStorageCoefficient:
      begin
        DataSetName := StrConfinedStorageCoe;
      end;
  end;
  Assign3DRealDataSet(DataSetName, GridData.SS);

  Assign3DRealDataSet(rsSpecificYield, GridData.SY);

  PriorStoPeriod := nil;
  StressPeriods := Model.ModflowStressPeriods;
  for SPIndex := 0 to Sto.Count - 1 do
  begin
    StoPeriod := Sto[SPIndex];
    StressPeriod := StressPeriods[StoPeriod.Period -1];
    if StoPeriod.Transient then
    begin
      StressPeriod.StressPeriodType := sptTransient;
    end
    else
    begin
      StressPeriod.StressPeriodType := sptSteadyState;
    end;
    if PriorStoPeriod <> nil then
    begin
      for InnerIndex := PriorStoPeriod.Period to StoPeriod.Period - 2 do
      begin
        StressPeriod := StressPeriods[InnerIndex];
        if PriorStoPeriod.Transient then
        begin
          StressPeriod.StressPeriodType := sptTransient;
        end
        else
        begin
          StressPeriod.StressPeriodType := sptSteadyState;
        end;
      end;
    end;

    PriorStoPeriod := StoPeriod
  end;
  if PriorStoPeriod <> nil then
  begin
    for InnerIndex := PriorStoPeriod.Period to StressPeriods.Count - 1 do
    begin
      StressPeriod := StressPeriods[InnerIndex];
      if PriorStoPeriod.Transient then
      begin
        StressPeriod.StressPeriodType := sptTransient;
      end
      else
      begin
        StressPeriod.StressPeriodType := sptSteadyState;
      end;
    end;
  end;

  if Sto.TvsCount > 0 then
  begin
    Model.ModflowPackages.TvsPackage.IsSelected := True;
    for TvsIndex := 0 to Sto.TvsCount - 1 do
    begin
      ImportTvs(Sto.TvsPackages[TvsIndex])
    end;
  end;
end;

procedure TModflow6Importer.ImportTimeSeries(Package: TPackage; Map: TimeSeriesMap);
var
  TsReader: TTimeSeries;
  Model: TPhastModel;
  Mf6TimesSeries: TTimesSeriesCollections;
  Attributes: TTsAttributes;
  GroupName: string;
  NewGroup: TTimesSeriesCollection;
  Index: Integer;
  TSName: string;
  NewName: string;
  TimeSeries: TMf6TimeSeries;
  Method: TTsMethod;
  ImportedTs: TTsTimeSeries;
  TimeIndex: Integer;
  ImportedValues: TDoubleList;
begin
  Model := frmGoPhast.PhastModel;
  Mf6TimesSeries := Model.Mf6TimesSeries;

  GroupName := ExtractFileName(Package.FileName);
  NewGroup := Mf6TimesSeries.Add.TimesSeriesCollection;
  NewGroup.GroupName := AnsiString(GroupName);

  TsReader := Package.Package as TTimeSeries;
  Attributes := TsReader.Attributes;
  ImportedTs := TsReader.TimeSeries;

  NewGroup.Times.Capacity := ImportedTs.TimeCount;
  for TimeIndex := 0 to ImportedTs.TimeCount - 1 do
  begin
    NewGroup.Times.Add.Value := ImportedTs.Times[TimeIndex];
  end;

  for Index := 0 to Attributes.NameCount - 1 do
  begin
    TSName := Attributes.Names[Index];

    if Mf6TimesSeries.GetTimeSeriesByName(TSName) = nil then
    begin
      NewName := TSName;
    end
    else
    begin
      Inc(TSIndex);
      NewName := 'ImportedTS_' + TSName + '_' + IntToStr(TSIndex);
      while Mf6TimesSeries.GetTimeSeriesByName(TSName) <> nil do
      begin
        Inc(TSIndex);
        NewName := 'ImportedTS_' + TSName + '_' + IntToStr(TSIndex);
      end;
    end;

    Map.Add(TSName, NewName);

    TimeSeries := NewGroup.Add.TimeSeries;
    TimeSeries.SeriesName := AnsiString(NewName);

    Method := Attributes.Methods[Index];
    Assert(Method <> tsUndefined);
    case Method of
      tmStepWise:
        begin
          TimeSeries.InterpolationMethod := mimStepwise;
        end;
      tmLinear:
        begin
          TimeSeries.InterpolationMethod := mimLinear;
        end;
      tmLinearEnd:
        begin
          TimeSeries.InterpolationMethod := mimLinearEnd;
        end;
      else
        begin
          assert(False)
        end;
    end;
    if Attributes.SfacCount > Index then
    begin
      TimeSeries.ScaleFactor := Attributes.SFacs[Index];
    end
    else
    begin
      TimeSeries.ScaleFactor := 1;
    end;
    ImportedValues := ImportedTs.TimeSeriesValues[Index];
    TimeSeries.Capacity := ImportedValues.Count;
    for TimeIndex := 0 to ImportedValues.Count - 1 do
    begin
      TimeSeries.Add.Value := ImportedValues[TimeIndex];
    end;
  end;
end;

procedure TModflow6Importer.ImportTvk(Package: TPackage);
var
  Tvk: TTvk;
  APeriod: TTvkPeriodData;
  Model: TPhastModel;
  LastTime: Double;
  StartTime: Double;
  PeriodIndex: Integer;
  BoundIndex: Integer;
  TvkBound: TTimeVariableCell;
  KScreenObject: TScreenObject;
  Item: TTvkItem;
  CellId: TCellId;
  KDictionary: TDictionary<string, TScreenObject>;
  AScreenObject: TScreenObject;
  UndoCreateScreenObject: TCustomUndo;
  APoint: TPoint2D;
  TimeSeriesName: string;
  KStorage: TValueArrayItem;
  ImportedKName: string;
  K22ScreenObject: TScreenObject;
  K33ScreenObject: TScreenObject;
  K22Storage: TValueArrayItem;
  K22Dictionary: TDictionary<string, TScreenObject>;
  K33Dictionary: TDictionary<string, TScreenObject>;
  K33Storage: TValueArrayItem;
  TimeSeriesIndex: Integer;
  TimeSeriesPackage: TPackage;
  Map: TimeSeriesMap;
  ImportedTimeSeriesName: string;
  ElementCenter: TDualLocation;
  function CreateScreenObject(RootName: String): TScreenObject;
  var
    NewItem: TTvkItem;
  begin
    result := TScreenObject.CreateWithViewDirection(
      Model, vdTop, UndoCreateScreenObject, False);
    result.Name := 'ImportedTVK_' + RootName + '_Period_' + IntToStr(APeriod.Period);
    result.Comment := 'Imported from ' + FModelNameFile +' on ' + DateTimeToStr(Now);

    Model.AddScreenObject(result);
    result.ElevationCount := ecOne;
    result.SetValuesOfIntersectedCells := True;
    result.EvaluatedAt := eaBlocks;
    result.Visible := False;
    result.ElevationFormula := rsObjectImportedValuesR + '("' + StrImportedElevations + '")';

    result.CreateTvkBoundary;

    NewItem := result.ModflowTvkBoundary.Values.Add as TTvkItem;
    NewItem.StartTime := StartTime;
    NewItem.EndTime := LastTime;
  end;
begin
  Model := frmGoPhast.PhastModel;
  LastTime := Model.ModflowStressPeriods.Last.EndTime;

  KDictionary := TDictionary<string, TScreenObject>.Create;
  K22Dictionary := TDictionary<string, TScreenObject>.Create;
  K33Dictionary := TDictionary<string, TScreenObject>.Create;
  Map := TimeSeriesMap.Create;
  try
    Tvk := Package.Package as TTvk;

    for TimeSeriesIndex := 0 to Tvk.TimeSeriesPackageCount - 1 do
    begin
      TimeSeriesPackage := Tvk.TimeSeriesPackages[TimeSeriesIndex];
      ImportTimeSeries(TimeSeriesPackage, Map);
    end;

    KScreenObject := nil;
    K22ScreenObject := nil;
    K33ScreenObject := nil;
    for PeriodIndex := 0 to Tvk.Count - 1 do
    begin
      KStorage := nil;
      K22Storage := nil;
      K33Storage := nil;

      APeriod := Tvk[PeriodIndex];
      StartTime := Model.ModflowStressPeriods[APeriod.Period-1].StartTime;
      if KScreenObject <> nil then
      begin
        Item := KScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
        Item.EndTime := StartTime;
      end;
      KScreenObject := nil;

      if K22ScreenObject <> nil then
      begin
        Item := K22ScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
        Item.EndTime := StartTime;
      end;
      K22ScreenObject := nil;

      if K33ScreenObject <> nil then
      begin
        Item := K33ScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
        Item.EndTime := StartTime;
      end;
      K33ScreenObject := nil;

      for AScreenObject in KDictionary.Values do
      begin
        Item := AScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
        Item.EndTime := StartTime;
      end;
      KDictionary.Clear;

      for AScreenObject in K22Dictionary.Values do
      begin
        Item := AScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
        Item.EndTime := StartTime;
      end;
      K22Dictionary.Clear;

      for AScreenObject in K33Dictionary.Values do
      begin
        Item := AScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
        Item.EndTime := StartTime;
      end;
      K33Dictionary.Clear;

      for BoundIndex := 0 to APeriod.Count - 1 do
      begin
        TvkBound := APeriod[BoundIndex];
        if TvkBound.VariableName = 'K' then
        begin
          if TvkBound.ValueType = vtNumeric then
          begin
            ImportedKName := 'ImportedTvk_K_' + IntToStr(APeriod.Period);
            if KScreenObject = nil then
            begin

              KScreenObject := CreateScreenObject('K');

              KStorage := KScreenObject.ImportedValues.Add;
              KStorage.Name := ImportedKName;
              KStorage.Values.DataType := rdtDouble;

              Item := KScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
              Item.K := rsObjectImportedValuesR + '("' + ImportedKName + '")';
            end;
            AScreenObject := KScreenObject;
            KStorage.Values.Add(TvkBound.NumericValue);
          end
          else
          begin
            Assert(TvkBound.ValueType = vtString);
            TimeSeriesName := TvkBound.StringValue;
            if not Map.TryGetValue(TimeSeriesName, ImportedTimeSeriesName) then
            begin
              Assert(False);
            end;
            TimeSeriesName := ImportedTimeSeriesName;
            if not KDictionary.TryGetValue(TimeSeriesName, AScreenObject) then
            begin
              AScreenObject := CreateScreenObject('K_' + TimeSeriesName);

              KDictionary.Add(TimeSeriesName, AScreenObject);
              Item := AScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
              Item.K := TimeSeriesName;
            end;
          end;
        end
        else if TvkBound.VariableName = 'K22' then
        begin
          if TvkBound.ValueType = vtNumeric then
          begin
            ImportedKName := 'ImportedTvk_K22_' + IntToStr(APeriod.Period);
            if K22ScreenObject = nil then
            begin

              K22ScreenObject := CreateScreenObject('K22');

              K22Storage := K22ScreenObject.ImportedValues.Add;
              K22Storage.Name := ImportedKName;
              K22Storage.Values.DataType := rdtDouble;

              Item := K22ScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
              Item.K22 := rsObjectImportedValuesR + '("' + ImportedKName + '")';
            end;
            AScreenObject := K22ScreenObject;
            K22Storage.Values.Add(TvkBound.NumericValue);
          end
          else
          begin
            Assert(TvkBound.ValueType = vtString);
            TimeSeriesName := TvkBound.StringValue;
            if not Map.TryGetValue(TimeSeriesName, ImportedTimeSeriesName) then
            begin
              Assert(False);
            end;
            if not K22Dictionary.TryGetValue(TimeSeriesName, AScreenObject) then
            begin
              AScreenObject := CreateScreenObject('K22_' + TimeSeriesName);

              K22Dictionary.Add(TimeSeriesName, AScreenObject);
              Item := AScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
              Item.K22 := TimeSeriesName;
            end;
          end;
        end
        else if TvkBound.VariableName = 'K33' then
        begin
          if TvkBound.ValueType = vtNumeric then
          begin
            ImportedKName := 'ImportedTvk_K33_' + IntToStr(APeriod.Period);
            if K33ScreenObject = nil then
            begin

              K33ScreenObject := CreateScreenObject('K33');

              K33Storage := K33ScreenObject.ImportedValues.Add;
              K33Storage.Name := ImportedKName;
              K33Storage.Values.DataType := rdtDouble;

              Item := K33ScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
              Item.K33 := rsObjectImportedValuesR + '("' + ImportedKName + '")';
            end;
            AScreenObject := K33ScreenObject;
            K33Storage.Values.Add(TvkBound.NumericValue);
          end
          else
          begin
            Assert(TvkBound.ValueType = vtString);
            TimeSeriesName := TvkBound.StringValue;
            if not Map.TryGetValue(TimeSeriesName, ImportedTimeSeriesName) then
            begin
              Assert(False);
            end;
            if not K33Dictionary.TryGetValue(TimeSeriesName, AScreenObject) then
            begin
              AScreenObject := CreateScreenObject('K33_' + TimeSeriesName);

              K33Dictionary.Add(TimeSeriesName, AScreenObject);
              Item := AScreenObject.ModflowTvkBoundary.Values.Last as TTvkItem;
              Item.K33 := TimeSeriesName;
            end;
          end;
        end
        else
        begin
          Assert(False);
        end;
        CellId := TvkBound.CellId;
        if Model.DisvUsed then
        begin
          Dec(CellId.Column);
          CellId.Row := 0;
        end
        else
        begin
          Dec(CellId.Column);
          Dec(CellId.Row);
        end;
        ElementCenter := Model.ElementLocation[CellId.Layer-1, CellId.Row, CellId.Column];
        APoint.x := ElementCenter.RotatedLocation.x;
        APoint.y := ElementCenter.RotatedLocation.y;
        AScreenObject.AddPoint(APoint, True);
        AScreenObject.ImportedSectionElevations.Add(ElementCenter.RotatedLocation.z);
      end;
    end;
  finally
    KDictionary.Free;
    K22Dictionary.Free;
    K33Dictionary.Free;
    Map.Free;
  end;

end;

procedure TModflow6Importer.ImportTvs(Package: TPackage);
var
  Tvs: TTvs;
  APeriod: TTvsPeriodData;
  Model: TPhastModel;
  LastTime: Double;
  StartTime: Double;
  PeriodIndex: Integer;
  BoundIndex: Integer;
  TvsBound: TTimeVariableCell;
  SsScreenObject: TScreenObject;
  Item: TTvsItem;
  CellId: TCellId;
  SsDictionary: TDictionary<string, TScreenObject>;
  AScreenObject: TScreenObject;
  UndoCreateScreenObject: TCustomUndo;
  APoint: TPoint2D;
  TimeSeriesName: string;
  SsStorage: TValueArrayItem;
  ImportedName: string;
  SyScreenObject: TScreenObject;
  SyStorage: TValueArrayItem;
  SyDictionary: TDictionary<string, TScreenObject>;
  TimeSeriesIndex: Integer;
  TimeSeriesPackage: TPackage;
  Map: TimeSeriesMap;
  ImportedTimeSeriesName: string;
  ElementCenter: TDualLocation;
  function CreateScreenObject(RootName: String): TScreenObject;
  var
    NewItem: TTvsItem;
  begin
    result := TScreenObject.CreateWithViewDirection(
      Model, vdTop, UndoCreateScreenObject, False);
    result.Name := 'ImportedTVS_' + RootName + '_Period_' + IntToStr(APeriod.Period);
    result.Comment := 'Imported from ' + FModelNameFile +' on ' + DateTimeToStr(Now);

    Model.AddScreenObject(result);
    result.ElevationCount := ecOne;
    result.SetValuesOfIntersectedCells := True;
    result.EvaluatedAt := eaBlocks;
    result.Visible := False;
    result.ElevationFormula := rsObjectImportedValuesR + '("' + StrImportedElevations + '")';

    result.CreateTvsBoundary;

    NewItem := result.ModflowTvsBoundary.Values.Add as TTvsItem;
    NewItem.StartTime := StartTime;
    NewItem.EndTime := LastTime;
  end;
begin
  Model := frmGoPhast.PhastModel;
  LastTime := Model.ModflowStressPeriods.Last.EndTime;

  SsDictionary := TDictionary<string, TScreenObject>.Create;
  SyDictionary := TDictionary<string, TScreenObject>.Create;
  Map := TimeSeriesMap.Create;
  try
    Tvs := Package.Package as TTvs;

    Model.ModflowPackages.TvsPackage.Enable_Storage_Change_Integration :=
      not Tvs.Options.DISABLE_STORAGE_CHANGE_INTEGRATION;

    for TimeSeriesIndex := 0 to Tvs.TimeSeriesPackageCount - 1 do
    begin
      TimeSeriesPackage := Tvs.TimeSeriesPackages[TimeSeriesIndex];
      ImportTimeSeries(TimeSeriesPackage, Map);
    end;

    SsScreenObject := nil;
    SyScreenObject := nil;
    for PeriodIndex := 0 to Tvs.Count - 1 do
    begin
      SsStorage := nil;
      SyStorage := nil;
//      K33Storage := nil;

      APeriod := Tvs[PeriodIndex];
      StartTime := Model.ModflowStressPeriods[APeriod.Period-1].StartTime;
      if SsScreenObject <> nil then
      begin
        Item := SsScreenObject.ModflowTvsBoundary.Values.Last as TTvsItem;
        Item.EndTime := StartTime;
      end;
      SsScreenObject := nil;

      if SyScreenObject <> nil then
      begin
        Item := SyScreenObject.ModflowTvsBoundary.Values.Last as TTvsItem;
        Item.EndTime := StartTime;
      end;
      SyScreenObject := nil;

      for AScreenObject in SsDictionary.Values do
      begin
        Item := AScreenObject.ModflowTvsBoundary.Values.Last as TTvsItem;
        Item.EndTime := StartTime;
      end;
      SsDictionary.Clear;

      for AScreenObject in SyDictionary.Values do
      begin
        Item := AScreenObject.ModflowTvsBoundary.Values.Last as TTvsItem;
        Item.EndTime := StartTime;
      end;
      SyDictionary.Clear;

      for BoundIndex := 0 to APeriod.Count - 1 do
      begin
        TvsBound := APeriod[BoundIndex];
        if TvsBound.VariableName = 'SS' then
        begin
          if TvsBound.ValueType = vtNumeric then
          begin
            ImportedName := 'ImportedTvs_SS_' + IntToStr(APeriod.Period);
            if SsScreenObject = nil then
            begin

              SsScreenObject := CreateScreenObject('Ss');

              SsStorage := SsScreenObject.ImportedValues.Add;
              SsStorage.Name := ImportedName;
              SsStorage.Values.DataType := rdtDouble;

              Item := SsScreenObject.ModflowTvsBoundary.Values.Last as TTvsItem;
              Item.Ss := rsObjectImportedValuesR + '("' + ImportedName + '")';
            end;
            AScreenObject := SsScreenObject;
            SsStorage.Values.Add(TvsBound.NumericValue);
          end
          else
          begin
            Assert(TvsBound.ValueType = vtString);
            TimeSeriesName := TvsBound.StringValue;
            if not Map.TryGetValue(TimeSeriesName, ImportedTimeSeriesName) then
            begin
              Assert(False);
            end;
            TimeSeriesName := ImportedTimeSeriesName;
            if not SsDictionary.TryGetValue(TimeSeriesName, AScreenObject) then
            begin
              AScreenObject := CreateScreenObject('Ss_' + TimeSeriesName);

              SsDictionary.Add(TimeSeriesName, AScreenObject);
              Item := AScreenObject.ModflowTvsBoundary.Values.Last as TTvsItem;
              Item.Ss := TimeSeriesName;
            end;
          end;
        end
        else if TvsBound.VariableName = 'SY' then
        begin
          if TvsBound.ValueType = vtNumeric then
          begin
            ImportedName := 'ImportedTvs_Sy_' + IntToStr(APeriod.Period);
            if SyScreenObject = nil then
            begin

              SyScreenObject := CreateScreenObject('Sy');

              SyStorage := SyScreenObject.ImportedValues.Add;
              SyStorage.Name := ImportedName;
              SyStorage.Values.DataType := rdtDouble;

              Item := SyScreenObject.ModflowTvsBoundary.Values.Last as TTvsItem;
              Item.Sy := rsObjectImportedValuesR + '("' + ImportedName + '")';
            end;
            AScreenObject := SyScreenObject;
            SyStorage.Values.Add(TvsBound.NumericValue);
          end
          else
          begin
            Assert(TvsBound.ValueType = vtString);
            TimeSeriesName := TvsBound.StringValue;
            if not Map.TryGetValue(TimeSeriesName, ImportedTimeSeriesName) then
            begin
              Assert(False);
            end;
            if not SyDictionary.TryGetValue(TimeSeriesName, AScreenObject) then
            begin
              AScreenObject := CreateScreenObject('Sy_' + TimeSeriesName);

              SyDictionary.Add(TimeSeriesName, AScreenObject);
              Item := AScreenObject.ModflowTvsBoundary.Values.Last as TTvsItem;
              Item.Sy := TimeSeriesName;
            end;
          end;
        end
        else
        begin
          Assert(False);
        end;
        CellId := TvsBound.CellId;
        if Model.DisvUsed then
        begin
          Dec(CellId.Column);
          CellId.Row := 0;
        end
        else
        begin
          Dec(CellId.Column);
          Dec(CellId.Row);
        end;
        ElementCenter := Model.ElementLocation[CellId.Layer-1, CellId.Row, CellId.Column];
        APoint.x := ElementCenter.RotatedLocation.x;
        APoint.y := ElementCenter.RotatedLocation.y;
        AScreenObject.AddPoint(APoint, True);
        AScreenObject.ImportedSectionElevations.Add(ElementCenter.RotatedLocation.z);
      end;
    end;
  finally
    SsDictionary.Free;
    SyDictionary.Free;
    Map.Free;
  end;

end;

procedure TModflow6Importer.ImportVsc(Package: TPackage);
var
  Vsc: TVsc;
  Model: TPhastModel;
  ViscosityPackage: TViscosityPackage;
  Options: TVscOptions;
  PackageData: TVscPackageData;
  index: Integer;
  Item: TVscItem;
  ChemComponents: TMobileChemSpeciesCollection;
  ChemItem: TMobileChemSpeciesItem;
begin
  Model := frmGoPhast.PhastModel;
  ViscosityPackage := Model.ModflowPackages.ViscosityPackage;
  ViscosityPackage.IsSelected := True;
  ViscosityPackage.ViscositySpecified := False;

  Vsc := Package.Package as TVsc;
  Options := Vsc.Options;
  
  if Options.VISCREF.Used then
  begin
    ViscosityPackage.RefViscosity := Options.VISCREF.Value;
  end;
  if Options.TEMPERATURE_SPECIES_NAME.Used then
  begin
    ViscosityPackage.ThermalSpecies := Options.TEMPERATURE_SPECIES_NAME.Value;
  end;
  if Options.THERMAL_FORMULATION.Used then
  begin
    if Options.THERMAL_FORMULATION.Value = 'LINEAR' then
    begin
      ViscosityPackage.ThermalFormulation := tfLinear;
    end
    else if Options.THERMAL_FORMULATION.Value = 'NONLINEAR' then
    begin
      ViscosityPackage.ThermalFormulation := tfNonLinear;
    end
    else
    begin
      Assert(False)
    end;
  end;
  if Options.THERMAL_A2.Used then
  begin
    ViscosityPackage.ThermalA2 := Options.THERMAL_A2.Value;
  end;
  if Options.THERMAL_A3.Used then
  begin
    ViscosityPackage.ThermalA3 := Options.THERMAL_A3.Value;
  end;
  if Options.THERMAL_A4.Used then
  begin
    ViscosityPackage.ThermalA4 := Options.THERMAL_A4.Value;
  end;

  ChemComponents := Model.MobileComponents;
  PackageData := Vsc.PackageData;
  for index := 0 to PackageData.Count - 1 do
  begin
    Item := PackageData[index];
    ChemItem := ChemComponents.GetItemByName(Item.auxspeciesname);
    if ChemItem = nil then
    begin
      ChemItem := ChemComponents.Add;
      ChemItem.Name := Item.auxspeciesname;
    end;
    if SameText(ChemItem.Name, 'Viscosity') then
    begin
      ViscosityPackage.ViscositySpecified := True;
    end;
    ChemItem.RefViscosity := Item.cviscref;
    ChemItem.ViscositySlope := Item.dviscdc;
  end;
end;

end.