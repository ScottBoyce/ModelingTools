unit Mf6.ChdFileReaderUnit;

interface

uses
  System.Classes, System.IOUtils, System.SysUtils, Mf6.CustomMf6PersistentUnit,
  System.Generics.Collections;

type
  TChdOptions = class(TCustomMf6Persistent)
  private
    AUXILIARY: TStringList;
    AUXMULTNAME: string;
    BOUNDNAMES: Boolean;
    PRINT_INPUT: Boolean;
    PRINT_FLOWS: Boolean;
    SAVE_FLOWS: Boolean;
    TS6_FileNames: TStringList;
    Obs6_FileNames: TStringList;
    procedure Read(Stream: TStreamReader; Unhandled: TStreamWriter);
  protected
    procedure Initialize; override;
  public
    constructor Create(PackageType: string); override;
    destructor Destroy; override;
  end;

  TChdDimensions = class(TCustomMf6Persistent)
  private
    MAXBOUND: Integer;
    procedure Read(Stream: TStreamReader; Unhandled: TStreamWriter);
  protected
    procedure Initialize; override;
  end;

  TChdTimeItem = class(TObject)
    cellid: TCellId;
    head: TBoundaryValue;
    aux: TList<TBoundaryValue>;
    boundname: string;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TChdTimeItemList = TObjectList<TChdTimeItem>;

  TChdPeriod = class(TCustomMf6Persistent)
  private
    IPer: Integer;
    FCells: TChdTimeItemList;
    procedure Read(Stream: TStreamReader; Unhandled: TStreamWriter;
      Dimensions: TDimensions; naux: Integer; BOUNDNAMES: Boolean);
    function GetCell(Index: Integer): TChdTimeItem;
    function GetCount: Integer;
  protected
    procedure Initialize; override;
  public
    constructor Create(PackageType: string); override;
    destructor Destroy; override;
    property Period: Integer read IPer;
    property Count: Integer read GetCount;
    property Cells[Index: Integer]: TChdTimeItem read GetCell;

  end;

  TChdPeriodList = TObjectList<TChdPeriod>;

  TChd = class(TDimensionedPackageReader)
  private
    FOptions: TChdOptions;
    FChdDimensions: TChdDimensions;
    FPeriods: TChdPeriodList;
    FTimeSeriesPackages: TPackageList;
    FObservationsPackages: TPackageList;
    function GeObservations(Index: Integer): TPackage;
    function GetObservationsCount: Integer;
    function GetPeriod(Index: Integer): TChdPeriod;
    function GetPeriodCount: Integer;
    function GetTimeSeries(Index: Integer): TPackage;
    function GetTimeSeriesCount: Integer;
  public
    constructor Create(PackageType: string); override;
    destructor Destroy; override;
    procedure Read(Stream: TStreamReader; Unhandled: TStreamWriter); override;
    property PeriodCount: Integer read GetPeriodCount;
    property Periods[Index: Integer]: TChdPeriod read GetPeriod;
    property TimeSeriesCount: Integer read GetTimeSeriesCount;
    property TimeSeries[Index: Integer]: TPackage read GetTimeSeries;
    property ObservationsCount: Integer read GetObservationsCount;
    property Observations[Index: Integer]: TPackage read GeObservations;
  end;


implementation

uses
  ModelMuseUtilities, Mf6.TimeSeriesFileReaderUnit, Mf6.ObsFileReaderUnit;

{ TChdOptions }

constructor TChdOptions.Create(PackageType: string);
begin
  AUXILIARY := TStringList.Create;
  TS6_FileNames := TStringList.Create;
  Obs6_FileNames := TStringList.Create;
  inherited;

end;

destructor TChdOptions.Destroy;
begin
  AUXILIARY.Free;
  TS6_FileNames.Free;
  Obs6_FileNames.Free;
  inherited;
end;

procedure TChdOptions.Initialize;
begin
  inherited;
  AUXILIARY.Clear;
  TS6_FileNames.Clear;
  Obs6_FileNames.Clear;
  BOUNDNAMES := False;
  PRINT_INPUT := False;
  PRINT_FLOWS := False;
  SAVE_FLOWS := False;
end;

procedure TChdOptions.Read(Stream: TStreamReader; Unhandled: TStreamWriter);
var
  ALine: string;
  ErrorLine: string;
  CaseSensitiveLine: string;
  TS6_FileName: string;
  Obs_FileName: string;
  AUXILIARY_Name: string;
  AuxIndex: Integer;
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
    else if FSplitter[0] = 'BOUNDNAMES' then
    begin
      BOUNDNAMES := True;
    end
    else if FSplitter[0] = 'PRINT_INPUT' then
    begin
      PRINT_INPUT := True;
    end
    else if FSplitter[0] = 'PRINT_FLOWS' then
    begin
      PRINT_FLOWS := True;
    end
    else if FSplitter[0] = 'SAVE_FLOWS' then
    begin
      SAVE_FLOWS := True;
    end
    else if (FSplitter[0] = 'AUXILIARY')
      and (FSplitter.Count >= 2) then
    begin
      FSplitter.DelimitedText := CaseSensitiveLine;
      for AuxIndex := 1 to FSplitter.Count - 1 do
      begin
        AUXILIARY_Name := FSplitter[AuxIndex];
        AUXILIARY.Add(AUXILIARY_Name);
      end;
    end
    else if (FSplitter[0] = 'AUXMULTNAME')
      and (FSplitter.Count >= 2) then
    begin
      if AUXMULTNAME = '' then
      begin
        FSplitter.DelimitedText := CaseSensitiveLine;
        AUXMULTNAME := FSplitter[1];
      end
      else
      begin
        Unhandled.WriteLine('AUXMULTNAME was specified more than once in the CHD package in the following line.');
        Unhandled.WriteLine(ErrorLine);
      end;
    end
    else if (FSplitter[0] = 'TS6')
      and (FSplitter.Count >= 3)
      and (FSplitter[1] = 'FILEIN') then
    begin
      FSplitter.DelimitedText := CaseSensitiveLine;
      TS6_FileName := FSplitter[2];
      TS6_FileNames.Add(TS6_FileName);
    end
    else if (FSplitter[0] = 'OBS6')
      and (FSplitter.Count >= 3)
      and (FSplitter[1] = 'FILEIN') then
    begin
      FSplitter.DelimitedText := CaseSensitiveLine;
      Obs_FileName := FSplitter[2];
      Obs6_FileNames.Add(Obs_FileName);
    end
    else
    begin
      Unhandled.WriteLine(Format(StrUnrecognizedOpti, [FPackageType]));
      Unhandled.WriteLine(ErrorLine);
    end;
  end;
end;

{ TChdDTimeItem }

constructor TChdTimeItem.Create;
begin
  cellid.Initialize;
  head.Initialize;
  aux := TList<TBoundaryValue>.Create;
  boundname := '';
end;

destructor TChdTimeItem.Destroy;
begin
  aux.Free;
  inherited;
end;

{ TChdDimensions }

procedure TChdDimensions.Initialize;
begin
  inherited;
  MAXBOUND := 0;
end;

procedure TChdDimensions.Read(Stream: TStreamReader; Unhandled: TStreamWriter);
var
  ALine: string;
  ErrorLine: string;
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
    if ReadEndOfSection(ALine, ErrorLine, 'DIMENSIONS', Unhandled) then
    begin
      Exit
    end;

    if SwitchToAnotherFile(Stream, ErrorLine, Unhandled, ALine, 'DIMENSIONS') then
    begin
      // do nothing
    end
    else if (FSplitter[0] = 'MAXBOUND') and (FSplitter.Count >= 2)
      and TryStrToInt(FSplitter[1], MAXBOUND) then
    begin
    end
    else
    begin
      Unhandled.WriteLine(Format(StrUnrecognizedOpti, [FPackageType]));
      Unhandled.WriteLine(ErrorLine);
    end;
  end
end;

{ TChdPeriod }

constructor TChdPeriod.Create(PackageType: string);
begin
  FCells := TChdTimeItemList.Create;
  inherited;
end;

destructor TChdPeriod.Destroy;
begin
  FCells.Free;
  inherited;
end;

function TChdPeriod.GetCell(Index: Integer): TChdTimeItem;
begin
  result := FCells[Index];
end;

function TChdPeriod.GetCount: Integer;
begin
  result := FCells.Count;
end;

procedure TChdPeriod.Initialize;
begin
  inherited;
  FCells.Clear;
end;

procedure TChdPeriod.Read(Stream: TStreamReader; Unhandled: TStreamWriter;
  Dimensions: TDimensions; naux: Integer; BOUNDNAMES: Boolean);
var
  DimensionCount: Integer;
  Cell: TChdTimeItem;
  ALine: string;
  ErrorLine: string;
  CaseSensitiveLine: string;
  Aux: TBoundaryValue;
  StartIndex: Integer;
  AuxIndex: Integer;
  NumberOfItems: Integer;
begin
  DimensionCount := Dimensions.DimensionCount;
  NumberOfItems := DimensionCount + 1 + naux;
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

    Cell := TChdTimeItem.Create;;
    try
      CaseSensitiveLine := ALine;
      if SwitchToAnotherFile(Stream, ErrorLine, Unhandled, ALine, 'PERIOD') then
      begin
        // do nothing
      end
      else if FSplitter.Count >= NumberOfItems then
      begin
        if ReadCellID(Cell.CellId, 0, DimensionCount) then
        begin
          if TryFortranStrToFloat(FSplitter[DimensionCount], Cell.head.NumericValue) then
          begin
            Cell.head.ValueType := vtNumeric;
          end
          else
          begin
            Cell.head.ValueType := vtString;
            FSplitter.DelimitedText := CaseSensitiveLine;
            Cell.head.StringValue := FSplitter[DimensionCount];
          end;
          StartIndex := DimensionCount + 1;
          for AuxIndex := 0 to naux - 1 do
          begin
            Aux.Initialize;
            if TryFortranStrToFloat(FSplitter[StartIndex], Aux.NumericValue) then
            begin
              Aux.ValueType := vtNumeric;
            end
            else
            begin
              Aux.ValueType := vtString;
              FSplitter.DelimitedText := CaseSensitiveLine;
              Aux.StringValue := FSplitter[StartIndex];
            end;
            Inc(StartIndex);
            Cell.aux.Add(Aux);
          end;
          if BOUNDNAMES and (FSplitter.Count >= NumberOfItems + 1) then
          begin
            Cell.boundname := FSplitter[StartIndex];
          end;
          FCells.Add(Cell);
          Cell:= nil;
        end
        else
        begin
          Unhandled.WriteLine(Format(StrUnrecognizedSPERI, [FPackageType]));
          Unhandled.WriteLine(ErrorLine);
        end;
      end
      else
      begin
          Unhandled.WriteLine(Format(StrUnrecognizedSPERI, [FPackageType]));
        Unhandled.WriteLine(ErrorLine);
      end;
    finally
      Cell.Free;
    end;
  end;

end;

{ TChd }

constructor TChd.Create(PackageType: string);
begin
  inherited;
  FOptions := TChdOptions.Create(PackageType);
  FChdDimensions := TChdDimensions.Create(PackageType);
  FPeriods := TChdPeriodList.Create;
  FTimeSeriesPackages := TPackageList.Create;
  FObservationsPackages := TPackageList.Create;

end;

destructor TChd.Destroy;
begin
  FOptions.Free;
  FChdDimensions.Free;
  FPeriods.Free;
  FTimeSeriesPackages.Free;
  FObservationsPackages.Free;
  inherited;
end;

function TChd.GeObservations(Index: Integer): TPackage;
begin
  result := FObservationsPackages[Index];
end;

function TChd.GetObservationsCount: Integer;
begin
  result := FObservationsPackages.Count;
end;

function TChd.GetPeriod(Index: Integer): TChdPeriod;
begin
    result := FPeriods[Index];
end;

function TChd.GetPeriodCount: Integer;
begin
  result := FPeriods.Count;
end;

function TChd.GetTimeSeries(Index: Integer): TPackage;
begin
  result := FTimeSeriesPackages[Index];
end;

function TChd.GetTimeSeriesCount: Integer;
begin
  result := FTimeSeriesPackages.count
end;

procedure TChd.Read(Stream: TStreamReader; Unhandled: TStreamWriter);
var
  ALine: string;
  ErrorLine: string;
  IPER: Integer;
  APeriod: TChdPeriod;
  TsPackage: TPackage;
  PackageIndex: Integer;
  TsReader: TTimeSeries;
  ObsReader: TObs;
  ObsPackage: TPackage;
begin
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
      else if FSplitter[1] ='DIMENSIONS' then
      begin
        FChdDimensions.Read(Stream, Unhandled);
      end
      else if (FSplitter[1] ='PERIOD') and (FSplitter.Count >= 3) then
      begin
        if TryStrToInt(FSplitter[2], IPER) then
        begin
          APeriod := TChdPeriod.Create(FPackageType);
          FPeriods.Add(APeriod);
          APeriod.IPer := IPER;
          APeriod.Read(Stream, Unhandled, FDimensions, FOptions.AUXILIARY.Count,
            FOptions.BOUNDNAMES);
        end
        else
        begin
          Unhandled.WriteLine(Format(StrUnrecognizedSData, [FPackageType]));
          Unhandled.WriteLine(ErrorLine);
        end;
      end
      else
      begin
        Unhandled.WriteLine(Format(StrUnrecognizedSData, [FPackageType]));
        Unhandled.WriteLine(ErrorLine);
      end;
    end
    else
    begin
      Unhandled.WriteLine(Format(StrUnrecognizedSData, [FPackageType]));
      Unhandled.WriteLine(ErrorLine);
    end;
  end;
  for PackageIndex := 0 to FOptions.TS6_FileNames.Count - 1 do
  begin
    TsPackage := TPackage.Create;
    FTimeSeriesPackages.Add(TsPackage);
    TsPackage.FileType := FPackageType;
    TsPackage.FileName := FOptions.TS6_FileNames[PackageIndex];
    TsPackage.PackageName := '';

    TsReader := TTimeSeries.Create(FPackageType);
    TsPackage.Package := TsReader;
    TsPackage.ReadPackage(Unhandled);
  end;
  for PackageIndex := 0 to FOptions.Obs6_FileNames.Count - 1 do
  begin
    ObsPackage := TPackage.Create;
    FObservationsPackages.Add(ObsPackage);
    ObsPackage.FileType := FPackageType;
    ObsPackage.FileName := FOptions.Obs6_FileNames[PackageIndex];
    ObsPackage.PackageName := '';

    ObsReader := TObs.Create(FPackageType);
    ObsReader.Dimensions := FDimensions;
    ObsPackage.Package := ObsReader;
    ObsPackage.ReadPackage(Unhandled);
  end;
end;

end.