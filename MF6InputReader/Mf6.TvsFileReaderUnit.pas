unit Mf6.TvsFileReaderUnit;

interface

uses
  System.Classes, System.IOUtils, System.SysUtils, Mf6.CustomMf6PersistentUnit,
  System.Generics.Collections;

type
  TTvsOptions = class(TCustomMf6Persistent)
  private
    FDISABLE_STORAGE_CHANGE_INTEGRATION: Boolean;
    PRINT_INPUT: Boolean;
    TS6_FileNames: TStringList;
    procedure Read(Stream: TStreamReader; Unhandled: TStreamWriter);
  protected
    procedure Initialize; override;
  public
    constructor Create(PackageType: string); override;
    destructor Destroy; override;
    property DISABLE_STORAGE_CHANGE_INTEGRATION: Boolean read FDISABLE_STORAGE_CHANGE_INTEGRATION;
  end;

  TTvsPeriodData = class(TCustomMf6Persistent)
  private
    IPer: Integer;
    FCells: TTimeVariableCellList;
    procedure Read(Stream: TStreamReader; Unhandled: TStreamWriter; Dimensions: TDimensions);
    function GetCell(Index: Integer): TTimeVariableCell;
    function GetCount: Integer;
  protected
    procedure Initialize; override;
  public
    constructor Create(PackageType: string); override;
    destructor Destroy; override;
    property Period: Integer read IPer;
    property Count: Integer read GetCount;
    property Cells[Index: Integer]: TTimeVariableCell read GetCell; default;
  end;

  TTvsPeriodList = TObjectList<TTvsPeriodData>;

  TTvs = class(TDimensionedPackageReader)
  private
    FOptions: TTvsOptions;
    FPeriods: TTvsPeriodList;
    FTimeSeriesPackages: TPackageList;
    function GetCount: Integer;
    function GetPeriod(Index: Integer): TTvsPeriodData;
    function GetTimeSeriesPackage(Index: Integer): TPackage;
    function GetTimeSeriesPackageCount: Integer;
  public
    constructor Create(PackageType: string); override;
    destructor Destroy; override;
    procedure Read(Stream: TStreamReader; Unhandled: TStreamWriter; const NPER: Integer); override;
    property Options: TTvsOptions read FOptions;
    property Count: Integer read GetCount;
    property Periods[Index: Integer]: TTvsPeriodData read GetPeriod; default;
    property TimeSeriesPackageCount: Integer read GetTimeSeriesPackageCount;
    property TimeSeriesPackages[Index: Integer]: TPackage read GetTimeSeriesPackage;
  end;


implementation

uses
  ModelMuseUtilities, Mf6.TimeSeriesFileReaderUnit;

{ TTvsOptions }

constructor TTvsOptions.Create(PackageType: string);
begin
  TS6_FileNames := TStringList.Create;
  inherited;

end;

destructor TTvsOptions.Destroy;
begin
  TS6_FileNames.Free;
  inherited;
end;

procedure TTvsOptions.Initialize;
begin
  inherited;
  FDISABLE_STORAGE_CHANGE_INTEGRATION := False;
  PRINT_INPUT := False;
  TS6_FileNames.Clear;
end;

procedure TTvsOptions.Read(Stream: TStreamReader; Unhandled: TStreamWriter);
var
  ALine: string;
  ErrorLine: string;
  CaseSensitiveLine: string;
  TS6_FileName: string;
begin
  Initialize;
  while not Stream.EndOfStream do
  begin
    ALine := Stream.ReadLine;
    RestoreStream(Stream);
    ErrorLine := ALine;
    ALine := StripFollowingComments(ALine);
    if ALine = '' then
    begin
      Continue;
    end;
    if ReadEndOfSection(ALine, ErrorLine, 'OPTIONS', Unhandled) then
    begin
      Exit
    end;

    CaseSensitiveLine := ALine;
    if SwitchToAnotherFile(Stream, ErrorLine, Unhandled, ALine, 'OPTIONS') then
    begin
      // do nothing
    end
    else if FSplitter[0] = 'PRINT_INPUT' then
    begin
      PRINT_INPUT := True;
    end
    else if FSplitter[0] = 'DISABLE_STORAGE_CHANGE_INTEGRATION' then
    begin
      FDISABLE_STORAGE_CHANGE_INTEGRATION := True;
    end
    else if (FSplitter[0] = 'TS6')
      and (FSplitter.Count >= 3)
      and (FSplitter[1] = 'FILEIN') then
    begin
      FSplitter.DelimitedText := CaseSensitiveLine;
      TS6_FileName := FSplitter[2];
      TS6_FileNames.Add(TS6_FileName);
    end
    else
    begin
      Unhandled.WriteLine('Unrecognized TVS option in the following line.');
      Unhandled.WriteLine(ErrorLine);
    end;
  end
end;

{ TTvsPeriodData }

constructor TTvsPeriodData.Create(PackageType: string);
begin
  FCells := TTimeVariableCellList.Create;
  inherited;

end;

destructor TTvsPeriodData.Destroy;
begin
  FCells.Free;
  inherited;
end;

function TTvsPeriodData.GetCell(Index: Integer): TTimeVariableCell;
begin
  result := FCells[Index];
end;

function TTvsPeriodData.GetCount: Integer;
begin
    result := FCells.Count;
end;

procedure TTvsPeriodData.Initialize;
begin
  inherited;
  FCells.Clear;
end;

procedure TTvsPeriodData.Read(Stream: TStreamReader; Unhandled: TStreamWriter;
  Dimensions: TDimensions);
var
  DimensionCount: Integer;
  Cell: TTimeVariableCell;
  ALine: string;
  ErrorLine: string;
  CaseSensitiveLine: string;
begin
  DimensionCount := Dimensions.DimensionCount;
  Initialize;
  while not Stream.EndOfStream do
  begin
    ALine := Stream.ReadLine;
    RestoreStream(Stream);
    ErrorLine := ALine;
    ALine := StripFollowingComments(ALine);
    if ALine = '' then
    begin
      Continue;
    end;

    if ReadEndOfSection(ALine, ErrorLine, 'PERIOD', Unhandled) then
    begin
      Exit;
    end;

    Cell.Initialize;
    CaseSensitiveLine := ALine;
    if SwitchToAnotherFile(Stream, ErrorLine, Unhandled, ALine, 'PERIOD') then
    begin
      // do nothing
    end
    else if FSplitter.Count >= DimensionCount + 2 then
    begin
      if ReadCellID(Cell.CellId, 0, DimensionCount) then
      begin
        Cell.VariableName := FSplitter[DimensionCount];
        if TryFortranStrToFloat(FSplitter[DimensionCount+1], Cell.NumericValue) then
        begin
          Cell.ValueType := vtNumeric;
        end
        else
        begin
          Cell.ValueType := vtString;
          FSplitter.DelimitedText := CaseSensitiveLine;
          Cell.StringValue := FSplitter[DimensionCount+1];
        end;
        FCells.Add(Cell);
      end
      else
      begin
        Unhandled.WriteLine('Unrecognized TVS PERIOD data in the following line.');
        Unhandled.WriteLine(ErrorLine);
      end;
    end
    else
    begin
      Unhandled.WriteLine('Unrecognized TVS PERIOD data in the following line.');
      Unhandled.WriteLine(ErrorLine);
    end;
  end;

end;

{ TTvs }

constructor TTvs.Create(PackageType: string);
begin
  inherited;
  FOptions := TTvsOptions.Create(PackageType);
  FPeriods := TTvsPeriodList.Create;
  FTimeSeriesPackages := TPackageList.Create;
end;

destructor TTvs.Destroy;
begin
  FTimeSeriesPackages.Free;
  FOptions.Free;
  FPeriods.Free;
  inherited;
end;

function TTvs.GetCount: Integer;
begin
  result := FPeriods.Count;
end;

function TTvs.GetPeriod(Index: Integer): TTvsPeriodData;
begin
  result := FPeriods[Index];
end;

function TTvs.GetTimeSeriesPackage(Index: Integer): TPackage;
begin
  result := FTimeSeriesPackages[Index];
end;

function TTvs.GetTimeSeriesPackageCount: Integer;
begin
  result := FTimeSeriesPackages.Count;
end;

procedure TTvs.Read(Stream: TStreamReader; Unhandled: TStreamWriter; const NPER: Integer);
var
  ALine: string;
  ErrorLine: string;
  IPER: Integer;
  APeriod: TTvsPeriodData;
  TsPackage: TPackage;
  PackageIndex: Integer;
  TsReader: TTimeSeries;
begin
  if Assigned(OnUpdataStatusBar) then
  begin
    OnUpdataStatusBar(self, 'reading TVS package');
  end;
  while not Stream.EndOfStream do
  begin
    ALine := Stream.ReadLine;
    ErrorLine := ALine;
    ALine := StripFollowingComments(ALine);
    if ALine = '' then
    begin
      Continue;
    end;

    ALine := UpperCase(ALine);
    FSplitter.DelimitedText := ALine;
    if FSplitter[0] = 'BEGIN' then
    begin
      if FSplitter[1] ='OPTIONS' then
      begin
        FOptions.Read(Stream, Unhandled);
      end
      else if (FSplitter[1] ='PERIOD') and (FSplitter.Count >= 3) then
      begin
        if TryStrToInt(FSplitter[2], IPER) then
        begin
          if IPER > NPER then
          begin
            break;
          end;
          APeriod := TTvsPeriodData.Create(FPackageType);
          FPeriods.Add(APeriod);
          APeriod.IPer := IPER;
          APeriod.Read(Stream, Unhandled, FDimensions);
        end
        else
        begin
          Unhandled.WriteLine('Unrecognized TVS data in the following line.');
          Unhandled.WriteLine(ErrorLine);
        end;
      end
      else
      begin
        Unhandled.WriteLine('Unrecognized TVS data in the following line.');
        Unhandled.WriteLine(ErrorLine);
      end;
    end;
  end;
  for PackageIndex := 0 to FOptions.TS6_FileNames.Count - 1 do
  begin
    TsPackage := TPackage.Create;
    FTimeSeriesPackages.Add(TsPackage);
    TsPackage.FileType := 'Time Series';
    TsPackage.FileName := FOptions.TS6_FileNames[PackageIndex];
    TsPackage.PackageName := '';

    TsReader := TTimeSeries.Create(FPackageType);
    TsPackage.Package := TsReader;
    TsPackage.ReadPackage(Unhandled, NPER);
  end;
end;

end.
