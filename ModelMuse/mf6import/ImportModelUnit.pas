unit ImportModelUnit;

interface

uses
  Modflow6ConstantsUnit,
  Mf6Variables,
  Mf6Functions, System.Classes, System.SysUtils;

type
  TAnsiStringArray = Array of AnsiString;
  TCIntArray = array of cint;
  TDoubleArray = array of double;
  TLongBoolArray = array of LongBool;

  TStressPeriod = record
    Length: Double;
    NStep: Integer;
    TSMult: double;
    Transient: Boolean;
  end;

  TStressPeriods = array of TStressPeriod;

  TPackage = record
    PackageType: AnsiString;
    PackageName: AnsiString
  end;

  TPackages = array of TPackage;

  TVertex = record
    VertexNumber: Integer;
    X: double;
    Y: double;
  end;

  TVertices = array of TVertex;

  TCell = record
    CellNumber: integer;
    CellX: double;
    CellY: double;
    VertexNumbers: TCIntArray;
  end;

  TCells = array of TCell;

  TMfCell = record
    Layer: Integer;
    Row: Integer;
    Column: Integer;
  end;

procedure ImportModel;

procedure GetStringVariable(VarName: AnsiString; var NameTypes: TAnsiStringArray);
procedure GetIntegerVariable(VarName: AnsiString; var IntArray: TCIntArray);
procedure GetDoubleVariable(VarName: AnsiString; var RealArray: TDoubleArray);
procedure GetLogicalVariable(VarName: AnsiString; var BoolArray: TLongBoolArray);

implementation

uses
  Vcl.Dialogs, System.AnsiStrings, JclAnsiStrings, System.Math,
  System.Generics.Collections;

const
  StrLEN: Ansistring = 'LEN=';

type
  TAnsiCharArray = array[0..255*10] of AnsiChar;
  TDisvCellDict = TDictionary<Integer, TMfCell>;

var
  ErrorMessages: TStringList;
  NameList: TAnsiStringList;
  DisvCellDict: TDisvCellDict = nil;

procedure ExtractStrArray(AString: AnsiString; out Strings: TAnsiStringArray);
var
  StringList: TJclAnsiStringList;
  index: Integer;
  StartIndex: Integer;
  CharIndex: Integer;
  NewString: AnsiString;
begin
  StringList := TAnsiStringList.Create;
  try
    StartIndex := 1;
    for CharIndex := StartIndex to Length(AString) do
    begin
      if AString[CharIndex] = #0 then
      begin
        NewString := Trim(Copy(AString,StartIndex, CharIndex - StartIndex));
        if NewString <> '' then
        begin
          StringList.Add(NewString);
        end;
        StartIndex := CharIndex + 1;
      end;
    end;
    SetLength(Strings, StringList.Count);
    for index := 0 to StringList.Count - 1 do
    begin
      Strings[index] := StringList[index];
    end;
  finally
    StringList.Free;
  end;
end;

procedure ExtractStrArray2(AString: TAnsiCharArray; out Strings: TAnsiStringArray);
var
  StringList: TJclAnsiStringList;
  index: Integer;
//  StartIndex: Integer;
  CharIndex: Integer;
  NewString: AnsiString;
  StringBuilder: TStringBuilder;
begin
  StringList := TAnsiStringList.Create;
  StringBuilder := TStringBuilder.Create;
  try
//    StartIndex := 0;
    for CharIndex := 0 to Length(AString) -1 do
    begin
      if AString[CharIndex] = #0 then
      begin
        NewString := AnsiString(Trim(StringBuilder.ToString));
        if NewString <> '' then
        begin
          StringList.Add(NewString);
        end;
//        StartIndex := CharIndex + 1;
        StringBuilder.Clear;
      end
      else
      begin
        StringBuilder.Append(AString[CharIndex])
      end;
    end;
    SetLength(Strings, StringList.Count);
    for index := 0 to StringList.Count - 1 do
    begin
      Strings[index] := StringList[index];
    end;
  finally
    StringList.Free;
  end;
end;

function GetModelType: TAnsiStringArray;
Const
  ModelTypeVarName = '__INPUT__/SIM/NAM/MTYPE';
begin
  GetStringVariable(ModelTypeVarName, result);
end;

function GetModelName: TAnsiStringArray;
const
  ModelNameVarName = '__INPUT__/SIM/NAM/MNAME';
begin
  GetStringVariable(ModelNameVarName, result);
end;

function GetNumberOfPeriods: Integer;
const
  NPerVanName = 'TDIS/NPER';
var
  IntArray: TCIntArray;
begin
  GetIntegerVariable(NPerVanName, IntArray);
  Assert(Length(IntArray) = 1);
  result := IntArray[0];
end;

function GetNumberOfSteps: TCIntArray;
const
  NStepVanName = 'TDIS/NSTP';
begin
  GetIntegerVariable(NStepVanName, result);
end;

function GetPerLen: TDoubleArray;
const
  PerLenName = 'TDIS/PERLEN';
begin
  GetDoubleVariable(PerLenName, result);
end;

function GetTsmult: TDoubleArray;
const
  TsMultName = 'TDIS/TSMULT';
begin
  GetDoubleVariable(TsMultName, result);
end;

function GetEndOfSimulation: Boolean;
const
  EndSimName = 'TDIS/ENDOFSIMULATION';
var
  BoolArray: TLongBoolArray;
begin
  GetLogicalVariable(EndSimName, BoolArray);
  Assert(Length(BoolArray) = 1);
  result := BoolArray[0];
end;


function GetPackageNames(ModelName: AnsiString): TPackages;
var
  Index: Integer;
  PackageNameString: AnsiString;
  PackageTypeString: AnsiString;
  PackageTypes: TAnsiStringArray;
  PackageNames: TAnsiStringArray;
begin
  PackageTypeString := '__INPUT__/' + ModelName + '/PKGTYPES';
  PackageNameString := '__INPUT__/' + ModelName + '/PKGNAMES';
  GetStringVariable(PackageTypeString, PackageTypes);
  GetStringVariable(PackageNameString, PackageNames);
  Assert(Length(PackageNames) = Length(PackageTypes));
  SetLength(Result, Length(PackageNames));
  for Index := 0 to Length(PackageNames) - 1 do
  begin
    Result[Index].PackageType := PackageTypes[Index];
    Result[Index].PackageName := PackageNames[Index];
  end;

  for Index := 0 to Length(PackageNames) - 1 do
  begin
    Writeln(PackageTypes[Index], ' ', PackageNames[Index])
  end;

end;

function GetModflowGridType(ModelName: AnsiString; var GridShape: TCIntArray): TMf6GridType;
var
  MShapeName: AnsiString;
begin
  MShapeName := '__INPUT__/' + ModelName + '/MODEL_SHAPE';
  GetIntegerVariable(MShapeName, GridShape);
  Assert(Length(GridShape) in [1..3]);
  result := TMf6GridType(Length(GridShape) -1);
end;

function GetTimeUnits: TMf6TimeUnits;
var
  TimeUnits: TCIntArray;
  VarName: AnsiString;
begin
  VarName := 'TDIS/ITMUNI';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, TimeUnits);
    Assert(Length(TimeUnits) = 1);
    Assert(TimeUnits[0] in [0..5]);
    result := TMf6TimeUnits(TimeUnits[0]);
  end
  else
  begin
    result := mtuUndefined;
  end;
end;

function GetLengthUnit(ModelName, DisPackageName: AnsiString): Tmf6LengthUnit;
var
  VarName: AnsiString;
  LengthUnits: TAnsiStringArray;
begin
  Result := mluUndefined;
  VarName := '__INPUT__/' + ModelName + '/' + DisPackageName + '/LENGTH_UNITS';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetStringVariable(VarName, LengthUnits);
    Assert(Length(LengthUnits) = 1);
    if LengthUnits[0] = 'UNDEFINED' then
    begin
      Result := mluUndefined;
    end
    else if LengthUnits[0] = 'FEET' then
    begin
      Result := mluFeet;
    end
    else if LengthUnits[0] = 'METERS' then
    begin
      Result := mluMeters;
    end
    else if LengthUnits[0] = 'CENTIMETERS' then
    begin
      Result := mluCentimeters;
    end
    else
    begin
      Assert(False)
    end;
  end
  else
  begin
    Result := mluUndefined;
  end;
end;

function GetXOrigin(ModelName, DisPackageName: AnsiString): Double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := ModelName + '/' + DisPackageName + '/XORIGIN';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result := 0;
  end;
end;

function GetYOrigin(ModelName, DisPackageName: AnsiString): Double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := ModelName + '/' + DisPackageName + '/YORIGIN';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result := 0;
  end;
end;

function GetGridRotation(ModelName, DisPackageName: AnsiString): Double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := ModelName + '/' + DisPackageName + '/ANGROT';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result := 0;
  end;
end;

// Get column widths
function GetDelR(ModelName, DisPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + DisPackageName + '/DELR';
  Assert(NameList.IndexOf(VarName) >= 0);
  GetDoubleVariable(VarName, result);
end;

// Get row widths
function GetDelc(ModelName, DisPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + DisPackageName + '/DELC';
  Assert(NameList.IndexOf(VarName) >= 0);
  GetDoubleVariable(VarName, result);
end;

function GetTop(ModelName, DisPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + DisPackageName + '/TOP';
  Assert(NameList.IndexOf(VarName) >= 0);
  GetDoubleVariable(VarName, result);
end;

function GetBottom(ModelName, DisPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + DisPackageName + '/BOTM';
  Assert(NameList.IndexOf(VarName) >= 0);
  GetDoubleVariable(VarName, result);
end;

function GetIDomain(ModelName, DisPackageName: AnsiString): TCIntArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + DisPackageName + '/IDOMAIN';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, result);
  end
  else
  begin
    result := nil;
  end;
end;

function GetVertices(ModelName, DisPackageName: AnsiString): TVertices;
var
  IVarName: AnsiString;
  XVarName: AnsiString;
  YVarName: AnsiString;
  IArray: TCIntArray;
  XArray: TDoubleArray;
  YArray: TDoubleArray;
  Index: Integer;
begin
  IVarName := '__INPUT__/' + ModelName + '/' + DisPackageName + '/IV';
  XVarName := '__INPUT__/' + ModelName + '/' + DisPackageName + '/XV';
  YVarName := '__INPUT__/' + ModelName + '/' + DisPackageName + '/YV';
  Assert(NameList.IndexOf(IVarName) >= 0);
  Assert(NameList.IndexOf(XVarName) >= 0);
  Assert(NameList.IndexOf(YVarName) >= 0);
  GetIntegerVariable(IVarName, IArray);
  GetDoubleVariable(XVarName, XArray);
  GetDoubleVariable(YVarName, YArray);
  Assert(Length(IArray) = Length(XArray));
  Assert(Length(IArray) = Length(YArray));
  SetLength(result, Length(IArray));
  for Index := 0 to Length(result) - 1 do
  begin
    result[Index].VertexNumber := IArray[Index];
    result[Index].X := XArray[Index];
    result[Index].Y := YArray[Index];
  end;
end;

function GetDisvCells(ModelName, DisPackageName: AnsiString): TCells;
var
  ICellVarName: AnsiString;
  XCellVarName: AnsiString;
  YCellVarName: AnsiString;
  NVertCellVarName: AnsiString;
  IVertCellVarName: AnsiString;
  ICell: TCIntArray;
  XCell: TDoubleArray;
  YCell: TDoubleArray;
  NVert: TCIntArray;
  IVert: TCIntArray;
  CellIndex: Integer;
  VertIndex: Integer;
  VertexCount: cint;
  VIndex: Integer;
  VertexArrayLength: Integer;
begin
  ICellVarName := '__INPUT__/'+ ModelName +'/' + DisPackageName + '/ICELL2D';
  XCellVarName := '__INPUT__/'+ ModelName +'/' + DisPackageName + '/XC';
  YCellVarName := '__INPUT__/'+ ModelName +'/' + DisPackageName + '/YC';
  NVertCellVarName := '__INPUT__/'+ ModelName +'/' + DisPackageName + '/NCVERT';
  IVertCellVarName := '__INPUT__/'+ ModelName +'/' + DisPackageName + '/ICVERT';

  Assert(NameList.IndexOf(ICellVarName) >= 0);
  Assert(NameList.IndexOf(XCellVarName) >= 0);
  Assert(NameList.IndexOf(YCellVarName) >= 0);
  Assert(NameList.IndexOf(NVertCellVarName) >= 0);
  Assert(NameList.IndexOf(IVertCellVarName) >= 0);

  GetIntegerVariable(ICellVarName, ICell);
  GetDoubleVariable(XCellVarName, XCell);
  GetDoubleVariable(YCellVarName, YCell);
  GetIntegerVariable(NVertCellVarName, NVert);
  GetIntegerVariable(IVertCellVarName, IVert);

  Assert(Length(ICell) = Length(XCell));
  Assert(Length(ICell) = Length(YCell));
  Assert(Length(ICell) = Length(NVert));

  VertIndex := 0;
  SetLength(result, Length(ICell));
  VertexArrayLength := Length(IVert);
  for CellIndex := 0 to Length(result) - 1 do
  begin
    result[CellIndex].CellNumber := ICell[CellIndex];
    result[CellIndex].CellX := XCell[CellIndex];
    result[CellIndex].CellY := YCell[CellIndex];
    VertexCount := NVert[CellIndex];
    SetLength(result[CellIndex].VertexNumbers, VertexCount);
    for VIndex := 0 to VertexCount - 1 do
    begin
      Assert(VertIndex < VertexArrayLength);
      result[CellIndex].VertexNumbers[VIndex] := IVert[VertIndex];
      Inc(VertIndex);
    end;
  end;
  Assert(VertIndex = VertexArrayLength);
end;

function GetNpfAveraging(ModelName, NpfPackageName: AnsiString): TNpfAveraging;
var
  VarName: AnsiString;
  Values: TAnsiStringArray;
begin
  VarName := '__INPUT__/'+ ModelName + '/' + NpfPackageName +'/CELLAVG';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetStringVariable(VarName, Values);
    Assert(Length(Values) = 1);
    if Values[0] = 'LOGARITHMIC' then
    begin
      Result := naLog
    end
    else if Values[0] = 'AMT-LMK' then
    begin
      Result := naAritimeticLog
    end
    else if Values[0] = 'AMT-HMK' then
    begin
      Result := naHarmonicLog
    end
    else
    begin
      Assert(False)
    end;
  end
  else
  begin
    Result := naHarmonic;
  end;
end;

function UseTHICKSTRT(ModelName, NpfPackageName: AnsiString): Boolean;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/ITHICKSTRT';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0] <> 0;
  end
  else
  begin
    result := False;
  end;
end;

function UseVARIABLECV(ModelName, NpfPackageName: AnsiString): Boolean;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/IVARCV';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0] <> 0;
  end
  else
  begin
    result := False;
  end;
end;

function UseDEWATERED(ModelName, NpfPackageName: AnsiString): Boolean;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/IDEWATCV';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0] <> 0;
  end
  else
  begin
    result := False;
  end;
end;

function UsePerched(ModelName, NpfPackageName: AnsiString): Boolean;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/IPERCHED';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0] <> 0;
  end
  else
  begin
    result := False;
  end;
end;

function UseREWET(ModelName, NpfPackageName: AnsiString): Boolean;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/IREWET';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0] <> 0;
  end
  else
  begin
    result := False;
  end;
end;

function GetWETFCT(ModelName, NpfPackageName: AnsiString): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
//  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/WETFCT';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    Assert(False);
  end;
end;

function GetIWETIT(ModelName, NpfPackageName: AnsiString): Integer;
var
  VarName: AnsiString;
//  Values: TDoubleArray;
  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/IWETIT';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    Assert(False);
  end;
end;

function GetIHDWET(ModelName, NpfPackageName: AnsiString): Integer;
var
  VarName: AnsiString;
//  Values: TDoubleArray;
  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/IHDWET';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    Assert(False);
  end;
end;

function UseK22OVERK(ModelName, NpfPackageName: AnsiString): Boolean;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/IK22OVERK';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0] <> 0;
  end
  else
  begin
    result := False;
  end;
end;

function UseK33OVERK(ModelName, NpfPackageName: AnsiString): Boolean;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/IK33OVERK';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0] <> 0;
  end
  else
  begin
    result := False;
  end;
end;

function UseXT3D(ModelName, NpfPackageName: AnsiString): Boolean;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/IXT3D';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0] <> 0;
  end
  else
  begin
    result := False;
  end;
end;

function UseXT3D_RHS(ModelName, NpfPackageName: AnsiString): Boolean;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName + '/IXT3DRHS';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0] <> 0;
  end
  else
  begin
    result := False;
  end;
end;

function GetICELLTYPE(ModelName, NpfPackageName: AnsiString): TCIntArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName +'/ICELLTYPE';
  Assert(NameList.IndexOf(VarName) >= 0);
  GetIntegerVariable(VarName, result);
end;

function GetK(ModelName, NpfPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName +'/K';
  Assert(NameList.IndexOf(VarName) >= 0);
  GetDoubleVariable(VarName, result);
end;

function GetK22(ModelName, NpfPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName +'/K22';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, result);
  end
  else
  begin
    result := nil;
  end;
end;

function GetK33(ModelName, NpfPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName +'/K33';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, result);
  end
  else
  begin
    result := nil;
  end;
end;

function GetAngle1(ModelName, NpfPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName +'/ANGLE1';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, result);
  end
  else
  begin
    result := nil;
  end;
end;

function GetAngle2(ModelName, NpfPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName +'/ANGLE2';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, result);
  end
  else
  begin
    result := nil;
  end;
end;

function GetAngle3(ModelName, NpfPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName +'/ANGLE3';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, result);
  end
  else
  begin
    result := nil;
  end;
end;

function GetWetDry(ModelName, NpfPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := '__INPUT__/' + ModelName + '/' + NpfPackageName +'/WETDRY';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, result);
  end
  else
  begin
    result := nil;
  end;
end;

function GetImsPrintOption(SolutionNumber: integer): integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := AnsiString(Format('SLN_%d/IPRIMS', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    Assert(Values[0] in [0..2]);
    result := Values[0];
    // 0 = NONE
    // 1 = Summary
    // 2 = All
  end
  else
  begin
    result := 0;
  end;
end;

function GetImsNoPTC(SolutionNumber: integer): integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := AnsiString(Format('SLN_%d/IALLOWPTC', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    Assert(Values[0] in [0..1]);
    result := Values[0];
    // 0 = All
    // 1 = First
  end
  else
  begin
    result := -1;
    // -1 = not active
  end;
end;

function GetImsATS_OUTER_MAXIMUM_FRACTION(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/ATSFRAC', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result := 1/3;
  end;
end;

function GetImsOUTER_DVCLOSE(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/DVCLOSE', [SolutionNumber]));
  Assert(NameList.IndexOf(VarName) >= 0);
  GetDoubleVariable(VarName, Values);
  Assert(Length(Values) = 1);
  result := Values[0];
end;

function GetImsOUTER_MAXIMUM(SolutionNumber: integer): integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := AnsiString(Format('SLN_%d/MXITER', [SolutionNumber]));
  Assert(NameList.IndexOf(VarName) >= 0);
  GetIntegerVariable(VarName, Values);
  Assert(Length(Values) = 1);
  result := Values[0];
end;

function GetImsUNDER_RELAXATION(SolutionNumber: integer): integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := AnsiString(Format('SLN_%d/NONMETH', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
    assert(result in [0..3]);
    // 0 = none
    // 1 = SIMPLE
    // 2 = COOLEY
    // 3 = DBD
  end
  else
  begin
    result := 0;
  end;
end;

function GetImsUNDER_RELAXATION_GAMMA(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/GAMMA', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  0.2;
  end;
end;

function GetImsUNDER_RELAXATION_THETA(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/THETA', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  0.7;
  end;
end;

function GetImsUNDER_RELAXATION_KAPPA(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/AKAPPA', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  0.1;
  end;
end;

function GetImsUNDER_RELAXATION_MOMENTUM(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/AMOMENTUM', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  0.001;
  end;
end;

function GetImsBACKTRACKING_NUMBER(SolutionNumber: integer): integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := AnsiString(Format('SLN_%d/IBFLAG', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  10;
  end;
end;

function GetImsBACKTRACKING_TOLERANCE(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/BTOL', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  1E4;
  end;
end;

function GetImsBACKTRACKING_REDUCTION_FACTOR(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/BREDUC', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  0.2;
  end;
end;

function GetImsBACKTRACKING_RESIDUAL_LIMIT(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/RES_LIM', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  100;
  end;
end;

function GetImsINNER_MAXIMUM(SolutionNumber: integer): integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := AnsiString(Format('SLN_%d/IMSLINEAR/ITER1', [SolutionNumber]));
  Assert(NameList.IndexOf(VarName) >= 0);
  GetIntegerVariable(VarName, Values);
  Assert(Length(Values) = 1);
  result := Values[0];
end;

function GetImsINNER_DVCLOSE(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/IMSLINEAR/DVCLOSE', [SolutionNumber]));
  Assert(NameList.IndexOf(VarName) >= 0);
  GetDoubleVariable(VarName, Values);
  Assert(Length(Values) = 1);
  result := Values[0];
end;

function GetImsINNER_RCLOSE(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/IMSLINEAR/RCLOSE', [SolutionNumber]));
  Assert(NameList.IndexOf(VarName) >= 0);
  GetDoubleVariable(VarName, Values);
  Assert(Length(Values) = 1);
  result := Values[0];
end;

function GetImsLINEAR_ACCELERATION(SolutionNumber: integer): integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := AnsiString(Format('SLN_%d/IMSLINEAR/ILINMETH', [SolutionNumber]));
  Assert(NameList.IndexOf(VarName) >= 0);
  GetIntegerVariable(VarName, Values);
  Assert(Length(Values) = 1);
  result := Values[0];
  Assert(result in [1,2])
  // 1 = CG
  // 2 = BICGSTAB
end;

function GetImsRELAXATION_FACTOR(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/IMSLINEAR/RELAX', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  0;
  end;
end;

function GetImsPRECONDITIONER_LEVELS(SolutionNumber: integer): integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := AnsiString(Format('SLN_%d/IMSLINEAR/LEVEL', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  0;
  end;
end;

function GetImsPRECONDITIONER_DROP_TOLERANCE(SolutionNumber: integer): double;
var
  VarName: AnsiString;
  Values: TDoubleArray;
begin
  VarName := AnsiString(Format('SLN_%d/IMSLINEAR/DROPTOL', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  0;
  end;
end;

function GetImsNUMBER_ORTHOGONALIZATIONS(SolutionNumber: integer): integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := AnsiString(Format('SLN_%d/IMSLINEAR/NORTH', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result :=  7;
  end;
end;

function GetImsSCALING_METHOD(SolutionNumber: integer): integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := AnsiString(Format('SLN_%d/IMSLINEAR/ISCL', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
    Assert(result in [0..2]);
    // 0 = NONE
    // 1 = DIAGONAL
    // 2 = L2NORM
  end
  else
  begin
    result :=  0;
  end;
end;

function GetImsREORDERING_METHOD(SolutionNumber: integer): integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := AnsiString(Format('SLN_%d/IMSLINEAR/IORD', [SolutionNumber]));
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
    Assert(result in [0..2]);
    // 0 = NONE
    // 1 = RCM
    // 2 = MD
  end
  else
  begin
    result :=  0;
  end;
end;

function GetStoSTORAGECOEFFICIENT(ModelName, StoPackageName: AnsiString): Integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := ModelName + '/' + StoPackageName + '/ISTOR_COEF';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
    Assert(result in [0..1]);
    // 1 = STORAGECOEFFICIENT
  end
  else
  begin
    result := 0;
  end;
end;

function GetStoSS_CONFINED_ONLY(ModelName, StoPackageName: AnsiString): Integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := ModelName + '/' + StoPackageName + '/ICONF_SS';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
    Assert(result in [0..1]);
    // 1 = SS_CONFINED_ONLY
  end
  else
  begin
    result := 0;
  end;
end;

function GetStoICONVERT(ModelName, StoPackageName: AnsiString): TCIntArray;
var
  VarName: AnsiString;
begin
  VarName := ModelName + '/' + StoPackageName +'/ICONVERT';
  Assert(NameList.IndexOf(VarName) >= 0);
  GetIntegerVariable(VarName, result);
end;

function GetStoSS(ModelName, StoPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := ModelName + '/' + StoPackageName +'/SS';
  Assert(NameList.IndexOf(VarName) >= 0);
  GetDoubleVariable(VarName, result);
end;

function GetStoSY(ModelName, StoPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := ModelName + '/' + StoPackageName +'/SY';
  Assert(NameList.IndexOf(VarName) >= 0);
  GetDoubleVariable(VarName, result);
end;

function GetIcSTRT(ModelName, IcPackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := ModelName + '/' + IcPackageName +'/STRT';
  Assert(NameList.IndexOf(VarName) >= 0);
  GetDoubleVariable(VarName, result);
end;

function GetAuxName(ModelName, PackageName: AnsiString): TAnsiStringArray;
var
  VarName: AnsiString;
begin
  VarName := ModelName + '/' + PackageName +'/AUXNAME_CST';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetStringVariable(VarName, result);
  end
  else
  begin
    SetLength(result, 0);
  end;
end;

function GetAuxMult(ModelName, PackageName: AnsiString): Integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := ModelName + '/' + PackageName +'/IAUXMULTCOL';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    result := Values[0];
  end
  else
  begin
    result := -1;
  end;
end;

function GetBoundNames(ModelName, PackageName: AnsiString): TAnsiStringArray;
var
  VarName: AnsiString;
begin
  VarName := ModelName + '/' + PackageName +'/BOUNDNAME_CST';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetStringVariable(VarName, result);
  end
  else
  begin
    SetLength(result, 0);
  end;
end;

function GetBound(ModelName, PackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := ModelName + '/' + PackageName +'/BOUND';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, result);
  end
  else
  begin
    SetLength(result, 0);
  end;
end;

function GetNodeList(ModelName, PackageName: AnsiString): TCIntArray;
var
  VarName: AnsiString;
begin
  VarName := ModelName + '/' + PackageName +'/NODELIST';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, result);
  end
  else
  begin
    SetLength(result, 0);
  end;
end;

function GetAuxValue(ModelName, PackageName: AnsiString): TDoubleArray;
var
  VarName: AnsiString;
begin
  VarName := ModelName + '/' + PackageName +'/AUXVAR';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetDoubleVariable(VarName, result);
  end
  else
  begin
    SetLength(result, 0);
  end;
end;

function GetTransient(ModelName: AnsiString): Boolean;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := ModelName + '/' + 'ISS';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    Assert(Values[0] in [0..1]);
    result := Values[0] = 1;
  end
  else
  begin
    result := False;
  end;
end;

function GetNewDataRead(ModelName, PackageName: AnsiString): Integer;
var
  VarName: AnsiString;
  Values: TCIntArray;
begin
  VarName := ModelName + '/' + PackageName + '/IONPER';
  if NameList.IndexOf(VarName) >= 0 then
  begin
    GetIntegerVariable(VarName, Values);
    Assert(Length(Values) = 1);
    result := Values[0];
  end
  else
  begin
    result := -1;
  end;
end;

procedure AlternateGetStringVariable2(VarName: AnsiString);
var
  Rank: Integer;
  ErrorMessage: TErrorMessage;
  Shape: array of Integer;
  Index: Integer;
begin
  if get_var_rank(PAnsiChar(VarName), Rank) = 0 then
  begin
    if Rank > 0 then
    begin
      if Rank > 1 then
      begin
        WriteLn('Rank > 1 for ', VarName, ': ', Rank);
      end;
      SetLength(Shape, Rank);
      if get_var_shape(PAnsiChar(VarName), @Shape[0]) = 0 then
      begin
        for Index := 0 to Length(Shape) - 1 do
        begin
          Writeln(Shape[Index]);
        end;
      end
      else
      begin
        Writeln('Failed to get variable shape for "', VarName, '".');
        get_last_bmi_error(@ErrorMessage);
        Writeln(ErrorMessage);
      end;
    end
    else
    begin
      Writeln('variable rank "', VarName, '" was set to ', Rank, '.');
    end;
  end
  else
  begin
    Writeln('Failed to get variable rank for "', VarName, '".');
    get_last_bmi_error(@ErrorMessage);
    Writeln(ErrorMessage);

  end;
end;

// AlternateGetStringVariable doesn't work.
procedure AlternateGetStringVariable(VarName: AnsiString);
var
  ResultString: AnsiString;
  var_nbytes: Integer;
  ErrorMessage: TErrorMessage;
  Index: Integer;
begin
  Writeln('Alternate method');
  var_nbytes := -1;
  if get_var_nbytes(PAnsiChar(VarName), var_nbytes) = 0 then
  begin
    if var_nbytes > 0 then
    begin
      SetLength(ResultString, var_nbytes*100);
      for Index := 1 to Length(ResultString) do
      begin
        ResultString[Index] := #0;
      end;
//      if get_value(PAnsiChar(VarName), PAnsiChar(ResultString)) = 0 then
      if get_value(PAnsiChar(VarName), @ResultString[1]) = 0 then
      begin
        Writeln(ResultString);
      end
      else
      begin
        Writeln('Failed to get variable value for "', VarName, '".');
        get_last_bmi_error(@ErrorMessage);
        Writeln(ErrorMessage);
      end;
    end
    else
    begin
      Writeln('variable size in bytes for "', VarName, '" was set to ', var_nbytes, '.');
    end;
  end
  else
  begin
    Writeln('Failed to get variable size in bytes for "', VarName, '".');
    get_last_bmi_error(@ErrorMessage);
    Writeln(ErrorMessage);
  end;

end;

procedure InitializeVariableType(out VariableType: AnsiString);
var
  CharIndex: Integer;
begin
  SetLength(VariableType, BMI_LENVARTYPE);
  for CharIndex := 1 to BMI_LENVARTYPE do
  begin
    VariableType[CharIndex] := #0;
  end;
end;

function GetArraySize(VarName: AnsiString): integer;
var
  Rank: Integer;
  Shape: array of cint;
  RankIndex: Integer;
  Error: TErrorMessage;
begin
  Rank := -1;
  result := -1;
  if get_var_rank(PAnsiChar(VarName), Rank) = 0 then
  begin
//    Writeln('Rank: ', Rank);
  end
  else
  begin
    ErrorMessages.Add('Failed to get Rank for "' + VarName + '".');
    WriteLn('Failed to get Rank for "', VarName, '".');
    if get_last_bmi_error(@Error) = 0 then
    begin
      Writeln(Error);
      ErrorMessages.Add(string(Error));
    end
    else
    begin
      Assert(False);
    end;
    Exit
  end;

  if Rank > 0 then
  begin
    SetLength(Shape, Rank);
    for RankIndex := 0 to Length(Shape) - 1 do
    begin
      Shape[RankIndex] := Mf6Undefined;
    end;
    if get_var_shape(PAnsiChar(VarName), @Shape[0]) = 0 then
    begin
      result := 1;
      for RankIndex := 0 to Length(Shape) - 1 do
      begin
        if Shape[RankIndex] <= 0 then
        begin
          WriteLn(VarName, ' ', Shape[RankIndex]);
          Assert(Shape[RankIndex] = 0);
        end;
        result := result*Shape[RankIndex];
      end;
    end
    else
    begin
      ErrorMessages.Add('Failed to get shape for "' + VarName + '".');
      ErrorMessages.Add(Error);

      WriteLn('Failed to get shape for "', VarName, '".');
      Assert(False);
    end;
  end
  else if Rank = 0 then
  begin
    result := 1;
  end;
end;

procedure GetLogicalVariable(VarName: AnsiString; var BoolArray: TLongBoolArray);
var
  VariableType: AnsiString;
  ArraySize: Integer;
  ValueIndex: Integer;
begin
  InitializeVariableType(VariableType);
  if get_var_type(PAnsiChar(VarName), PAnsiChar(VariableType)) = 0 then
  begin
    Assert(AnsiPos('LOGICAL', VariableType) = 1);
    ArraySize := GetArraySize(VarName);

    if ArraySize > 0 then
    begin
      SetLength(BoolArray, ArraySize);
      if get_value_bool(PAnsiChar(PAnsiChar(VarName)), @BoolArray) = 0 then
      begin
//        for ValueIndex := 0 to Min(10, Length(BoolArray)) - 1 do
//        begin
//          Writeln(BoolArray[ValueIndex])
//        end;
      end
      else
      begin
        Assert(False);
      end;
    end;
  end
  else
  begin
    Assert(False);
  end;
end;


procedure GetDoubleVariable(VarName: AnsiString; var RealArray: TDoubleArray);
var
  VariableType: AnsiString;
  ArraySize: Integer;
  ValueIndex: Integer;
begin
  InitializeVariableType(VariableType);
  if get_var_type(PAnsiChar(VarName), PAnsiChar(VariableType)) = 0 then
  begin
    Assert(AnsiPos('DOUBLE', VariableType) = 1);
    ArraySize := GetArraySize(VarName);

    if ArraySize > 0 then
    begin
      SetLength(RealArray, ArraySize);
      if get_value_double(PAnsiChar(PAnsiChar(VarName)), @RealArray) = 0 then
      begin
//        for ValueIndex := 0 to Min(10, Length(RealArray)) - 1 do
//        begin
//          Writeln(RealArray[ValueIndex])
//        end;
      end
      else
      begin
        Assert(False);
      end;
    end;
  end
  else
  begin
    Assert(False);
  end;
end;

procedure GetIntegerVariable(VarName: AnsiString; var IntArray: TCIntArray);
var
  VariableType: AnsiString;
//  IntArray: TCIntArray;
  ArraySize: Integer;
  ValueIndex: Integer;
begin
  InitializeVariableType(VariableType);
  if get_var_type(PAnsiChar(VarName), PAnsiChar(VariableType)) = 0 then
  begin
    Assert(AnsiPos('INTEGER', VariableType) = 1);
    ArraySize := GetArraySize(VarName);

    if ArraySize > 0 then
    begin
      SetLength(IntArray, ArraySize);
      if get_value_int(PAnsiChar(PAnsiChar(VarName)), @IntArray) = 0 then
      begin
//        for ValueIndex := 0 to Min(10, Length(IntArray)) - 1 do
//        begin
//          Writeln(IntArray[ValueIndex])
//        end;
      end
      else
      begin
        Assert(False);
      end;
    end;
  end
  else
  begin
    Assert(False);
  end;
end;

procedure GetStringVariable(VarName: AnsiString; var NameTypes: TAnsiStringArray);
var
  VariableType: AnsiString;
  CharIndex: Integer;
  StrLengthPos: Integer;
  ParenPos: Integer;
  VarLength: string;
  StringLength: Integer;
  Rank: Integer;
  NIndex: Integer;
  SavedVarType: AnsiString;
  VariableValues: AnsiString;
  PVarVal: PAnsiChar;
  PPVarVal: PPAnsiChar;
begin
  InitializeVariableType(VariableType);
  if get_var_type(PAnsiChar(VarName), PAnsiChar(VariableType)) = 0 then
  begin
    if AnsiPos('STRING', VariableType) = 1 then
    begin
      StrLengthPos := AnsiPos(StrLEN, VariableType);
      if StrLengthPos > 0 then
      begin
        Inc(StrLengthPos, Length(StrLEN));
        SavedVarType := VariableType;
        VariableType := Trim(Copy(VariableType, StrLengthPos, MAXINT));
        ParenPos := AnsiPos('(', VariableType);
        if ParenPos > 0 then
        begin
          VarLength := Trim(Copy(VariableType,1,ParenPos-1));
          VariableType := Copy(VariableType, ParenPos+1, MAXINT);
          ParenPos := AnsiPos(')', VariableType);
          Assert(ParenPos > 0);
          VariableType := Trim(Copy(VariableType,1,ParenPos-1));
          Rank := StrToInt(VariableType);
          if Rank = 0 then
          begin
            WriteLn('  empty');
            Exit;
          end;
        end
        else
        begin
          VarLength := VariableType;
          Rank := 1;
        end;
        StringLength := Max(StrToInt(VarLength), 255);
      end
      else
      begin
        StringLength := BMI_LENVARTYPE;
        if get_var_rank(PAnsiChar(VarName), Rank) = 0 then
        begin
          Writeln('Rank: ', Rank);
        end
        else
        begin
          WriteLn('Failed to get Rank for "', VarName, '".');
        end;
      end;
        SetLength(VariableValues, (StringLength+1)*Rank);
      begin
        for CharIndex := 1 to Length(VariableValues) do
        begin
          VariableValues[CharIndex] := #0;
        end;
      end;
      PVarVal := PAnsiChar(VariableValues);
      PPVarVal := @PVarVal;
      if get_value_string(PAnsiChar(VarName), PPVarVal) = 0 then
      begin
        begin
        try
          ExtractStrArray(VariableValues, NameTypes);
        except
          Writeln(VarName);
          Exit;
        end;
//            ExtractStrArray(TypeNames[RankIndex], NameTypes);
          if Length(NameTypes) > 0 then
          begin
            for NIndex := 0 to Length(NameTypes) - 1 do
            begin
              WriteLn('  ', Trim(NameTypes[NIndex]));
            end;
          end
          else
          begin
            WriteLn('  no values extracted from "', VarName, '."');
          end;
        end;
      end
      else
      begin
        WriteLn('Failed to get values for "', VarName, '."');
      end;
    end;
  end
  else
  begin
    WriteLn;
    WriteLn('Failed to get variable type for "', VarName, '".');
  end;
end;

procedure GetStringVariables(Names: TStringList);
var
  Index: Integer;
  VarName: AnsiString;
  NameTypes: TAnsiStringArray;
//  VariableType: AnsiString;
//  CharIndex: Integer;
//  StrLengthPos: Integer;
//  ParenPos: Integer;
//  VarLength: string;
//  StringLength: Integer;
//  TypeNames: array of AnsiString;
//  Rank: Integer;
//  NameTypes: TAnsiStringArray;
//  NIndex: Integer;
//  SavedVarType: AnsiString;
//  RankIndex: Integer;
//  VariableValues: TAnsiCharArray;
//  PVarVal: PAnsiChar;
//  PPVarVal: PPAnsiChar;
begin
  for Index := 0 to Names.Count - 1 do
  begin
    VarName := AnsiString(Names[Index]);
    GetStringVariable(VarName, NameTypes);
//    SetLength(VariableType, BMI_LENVARTYPE);
//    for CharIndex := 1 to BMI_LENVARTYPE do
//    begin
//      VariableType[CharIndex] := AnsiChar(nil);
//    end;
//    if get_var_type(PAnsiChar(VarName), PAnsiChar(VariableType)) = 0 then
//    begin
////      Writeln(VarName, ': ', VariableType);
//      if Pos('STRING', VariableType) = 1 then
//      begin
//        Writeln;
//        Writeln(VarName);
//        StrLengthPos := Pos(StrLEN, VariableType);
//        if StrLengthPos > 0 then
//        begin
//          Inc(StrLengthPos, Length(StrLEN));
//          SavedVarType := VariableType;
//          VariableType := Trim(Copy(VariableType, StrLengthPos, MAXINT));
//          ParenPos := Pos('(', VariableType);
//          if ParenPos > 0 then
//          begin
//            VarLength := Trim(Copy(VariableType,1,ParenPos-1));
//            VariableType := Copy(VariableType, ParenPos+1, MAXINT);
//            ParenPos := Pos(')', VariableType);
//            Assert(ParenPos > 0);
//            VariableType := Trim(Copy(VariableType,1,ParenPos-1));
//            Rank := StrToInt(VariableType);
//            if Rank = 0 then
//            begin
//              WriteLn('  empty');
//              Continue;
//            end;
//          end
//          else
//          begin
//            VarLength := VariableType;
//            Rank := 1;
//          end;
//          StringLength := Max(StrToInt(VarLength), 255);
//        end
//        else
//        begin
//          StringLength := BMI_LENVARTYPE;
//          if get_var_rank(PAnsiChar(VarName), Rank) = 0 then
//          begin
//            Writeln('Rank: ', Rank);
//          end
//          else
//          begin
//            WriteLn('Failed to get Rank for "', VarName, '".');
//          end;
//        end;
////        StringLength := StrToInt(VarLength);
////        Rank := 1;
//        RankIndex := 0;
////        SetLength(TypeNames, Rank);
////        SetLength(VariableValues, (StringLength+1)*Rank);
////        for RankIndex := 0 to Rank - 1 do
//        begin
////          SetLength(TypeNames[RankIndex], (StringLength+1)*Rank);
//          for CharIndex := 0 to Length(VariableValues) -1 do
//          begin
////            TypeNames[RankIndex][CharIndex] := AnsiChar(nil);
//            VariableValues[CharIndex] := #0;
//          end;
//        end;
//        PVarVal := @VariableValues;
//        PPVarVal := @PVarVal;
//        if get_value_string(PAnsiChar(VarName), PPVarVal) = 0 then
//        begin
////          for RankIndex := 0 to Rank - 1 do
//          begin
//            ExtractStrArray2(VariableValues, NameTypes);
////            ExtractStrArray(TypeNames[RankIndex], NameTypes);
//            if Length(NameTypes) > 0 then
//            begin
//              for NIndex := 0 to Length(NameTypes) - 1 do
//              begin
//                WriteLn('  ', Trim(NameTypes[NIndex]));
//              end;
//            end
//            else
//            begin
//              WriteLn('  no values extracted from "', VarName, '."');
//              Writeln(SavedVarType);
//              for CharIndex := 0 to Length(VariableValues) - 1 do
//              begin
//                Write(VariableValues[CharIndex]);
//              end;
//              Writeln;
//            end;
//          end;
//        end
//        else
//        begin
//          WriteLn('Failed to get values for "', VarName, '."');
//        end;
//      end;
//    end
//    else
//    begin
//      WriteLn;
//      WriteLn('Failed to get variable type for "', VarName, '".');
//    end;
  end;
end;

procedure GetSimulationValues(Names: TAnsiStringList);
var
  Index: Integer;
  VarName: AnsiString;
  VariableType: AnsiString;
  NameTypes: TAnsiStringArray;
  IntArray: TCIntArray;
  RealArray: TDoubleArray;
  BoolArray: TLongBoolArray;
  WriteValues: Boolean;
  procedure InitializeVarType;
  var
    CharIndex: Integer;
  begin
    for CharIndex := 1 to BMI_LENVARTYPE do
    begin
      VariableType[CharIndex] := #0;
    end;
  end;
begin
  SetLength(VariableType, BMI_LENVARTYPE);
  for Index := 0 to Names.Count - 1 do
  begin
    VarName := AnsiString(Names[Index]);
    WriteValues := Pos('/CHD', VarName) > 0;
//    WriteValues := True;
    if not WriteValues then
    begin
      Continue;
    end;
    InitializeVarType;
    if get_var_type(PAnsiChar(VarName), PAnsiChar(VariableType)) = 0 then
    begin
      Writeln(VarName, ': ', VariableType);
      if AnsiPos('STRING', VariableType) = 1 then
      begin
        GetStringVariable(VarName, NameTypes);
      end
      else if AnsiPos('INTEGER', VariableType) = 1 then
      begin
        GetIntegerVariable(VarName, IntArray);
      end
      else if AnsiPos('DOUBLE', VariableType) = 1 then
      begin
        GetDoubleVariable(VarName, RealArray);
      end
      else if AnsiPos('LOGICAL', VariableType) = 1 then
      begin
        GetLogicalVariable(VarName, BoolArray);
      end
      else
      begin
        Writeln('bad type')
      end;
    end
    else
    begin
      Writeln('failed to get variable type for ', VarName);
    end;
  end;
end;

procedure GetSimulationInputs(Names: TAnsiStringList);
var
  Value: array[0..355*6] of Ansichar;
  ABool: array of LongBool;
  ASize: Integer;
  VariableType: AnsiString;
  CharIndex: Integer;
  VarName: AnsiString;
  StrLengthPos: Integer;
  ParenPos: Integer;
  VarLength: AnsiString;
  StringLength: Integer;
  TypeNames: array of AnsiString;
  NameIndex: Integer;
//  TypeNamesAddr: array of PAnsiChar;
  NameTypes: TAnsiStringArray;
  NIndex: Integer;
begin
  VarName := '__INPUT__/MODFLOW/NAM/FTYPE';
  if Names.IndexOf(VarName) >= 0 then
  begin
    Writeln(VarName);
    SetLength(VariableType, BMI_LENVARTYPE);
    for CharIndex := 1 to BMI_LENVARTYPE do
    begin
      VariableType[CharIndex] := AnsiChar(nil);
    end;
    if get_var_type(PAnsiChar(VarName), PAnsiChar(VariableType)) = 0 then
    begin
      Writeln(VarName, ': ', VariableType);
    end;
    StrLengthPos := AnsiPos(StrLEN, VariableType);
    Assert(StrLengthPos > 0);
    Inc(StrLengthPos, Length(StrLEN));
    VariableType := Trim(Copy(VariableType, StrLengthPos, MAXINT));
    ParenPos := AnsiPos('(', VariableType);
    if ParenPos > 0 then
    begin
      VarLength := Trim(Copy(VariableType,1,ParenPos-1));
    end
    else
    begin
      VarLength := VariableType;
    end;
    StringLength := StrToInt(VarLength);
    SetLength(TypeNames, 1);
//    SetLength(TypeNamesAddr, 6);

    for NameIndex := 0 to Length(TypeNames) - 1 do
    begin
      SetLength(TypeNames[NameIndex], (StringLength+1)*6);
      for CharIndex := 1 to (StringLength+1)*6 do
      begin
        TypeNames[NameIndex][CharIndex] := AnsiChar(nil);
      end;
//      TypeNamesAddr[NameIndex] := @TypeNames[NameIndex];
    end;
    if get_value_string(PAnsiChar(VarName), @TypeNames[0]) = 0 then
    begin
      for NameIndex := 0 to Length(TypeNames) - 1 do
      begin
        Writeln(Length(TypeNames[NameIndex]));
        ExtractStrArray(TypeNames[NameIndex], NameTypes);
        for NIndex := 0 to Length(NameTypes) - 1 do
        begin
          WriteLn(Trim(NameTypes[NIndex]));
        end;
      end;
    end
    else
    begin
      WriteLn('Failed get_value_string');
    end;
  end;

  VarName := '__INPUT__/MODFLOW/PKGNAMES';
  if Names.IndexOf(VarName) >= 0 then
  begin
    Writeln(VarName);
    SetLength(VariableType, BMI_LENVARTYPE);
    for CharIndex := 1 to BMI_LENVARTYPE do
    begin
      VariableType[CharIndex] := AnsiChar(nil);
    end;
    if get_var_type(PAnsiChar(VarName), PAnsiChar(VariableType)) = 0 then
    begin
      Writeln(VarName, ': ', VariableType);
    end;
    StrLengthPos := AnsiPos(StrLEN, VariableType);
    Assert(StrLengthPos > 0);
    Inc(StrLengthPos, Length(StrLEN));
    VariableType := Trim(Copy(VariableType, StrLengthPos, MAXINT));
    ParenPos := AnsiPos('(', VariableType);
    if ParenPos > 0 then
    begin
      VarLength := Trim(Copy(VariableType,1,ParenPos-1));
    end
    else
    begin
      VarLength := VariableType;
    end;
    StringLength := StrToInt(VarLength);
    SetLength(TypeNames, 1);
//    SetLength(TypeNamesAddr, 6);

    for NameIndex := 0 to Length(TypeNames) - 1 do
    begin
      SetLength(TypeNames[NameIndex], (StringLength+1)*6);
      for CharIndex := 1 to (StringLength+1)*6 do
      begin
        TypeNames[NameIndex][CharIndex] := AnsiChar(nil);
      end;
//      TypeNamesAddr[NameIndex] := @TypeNames[NameIndex];
    end;
    if get_value_string(PAnsiChar(VarName), @TypeNames[0]) = 0 then
    begin
      for NameIndex := 0 to Length(TypeNames) - 1 do
      begin
        Writeln(Length(TypeNames[NameIndex]));
        ExtractStrArray(TypeNames[NameIndex], NameTypes);
        for NIndex := 0 to Length(NameTypes) - 1 do
        begin
          WriteLn(Trim(NameTypes[NIndex]));
        end;
      end;
    end
    else
    begin
      WriteLn('Failed get_value_string');
    end;
  end;

  VarName := '__INPUT__/MODFLOW/NAM/PNAME';
  if Names.IndexOf(VarName) >= 0 then
  begin
    Writeln(VarName);
    SetLength(VariableType, BMI_LENVARTYPE);
    for CharIndex := 1 to BMI_LENVARTYPE do
    begin
      VariableType[CharIndex] := AnsiChar(nil);
    end;
    if get_var_type(PAnsiChar(VarName), PAnsiChar(VariableType)) = 0 then
    begin
      Writeln(VarName, ': ', VariableType);
    end;
    StrLengthPos := AnsiPos(StrLEN, VariableType);
    Assert(StrLengthPos > 0);
    Inc(StrLengthPos, Length(StrLEN));
    VariableType := Trim(Copy(VariableType, StrLengthPos, MAXINT));
    ParenPos := AnsiPos('(', VariableType);
    if ParenPos > 0 then
    begin
      VarLength := Trim(Copy(VariableType,1,ParenPos-1));
    end
    else
    begin
      VarLength := VariableType;
    end;
    StringLength := StrToInt(VarLength);
    SetLength(TypeNames, 1);
//    SetLength(TypeNamesAddr, 6);

    for NameIndex := 0 to Length(TypeNames) - 1 do
    begin
      SetLength(TypeNames[NameIndex], (StringLength+1)*6);
      for CharIndex := 1 to (StringLength+1)*6 do
      begin
        TypeNames[NameIndex][CharIndex] := AnsiChar(nil);
      end;
//      TypeNamesAddr[NameIndex] := @TypeNames[NameIndex];
    end;
    if get_value_string(PAnsiChar(VarName), @TypeNames[0]) = 0 then
    begin
      for NameIndex := 0 to Length(TypeNames) - 1 do
      begin
        Writeln(Length(TypeNames[NameIndex]));
        ExtractStrArray(TypeNames[NameIndex], NameTypes);
        for NIndex := 0 to Length(NameTypes) - 1 do
        begin
          WriteLn(Trim(NameTypes[NIndex]));
        end;
      end;
    end
    else
    begin
      WriteLn('Failed get_value_string');
    end;
  end;

  if Names.IndexOf('TDIS/ENDOFPERIOD') >= 0 then
  begin
    if get_var_itemsize('TDIS/ENDOFPERIOD', ASize) = 0 then
    begin
      writeln(ASize);
    end
    else
    begin
      writeln('faiure get_var_itemsize');
    end;
    if get_var_nbytes('TDIS/ENDOFPERIOD', ASize) = 0 then
    begin
      writeln(ASize);
    end
    else
    begin
      writeln('faiure get_var_nbytes');
    end;
    SetLength(ABool, 1);
    get_value_bool('TDIS/ENDOFPERIOD', @ABool);
    WriteLn(ABool[0]);
  end
  else
  begin
    WriteLn('FTYPE not found');
  end;

  Exit;
  if Names.IndexOf('__INPUT__/MODFLOW/NAM/FTYPE') >= 0 then
  begin
    get_value_string('__INPUT__/MODFLOW/NAM/FTYPE', @Value);
    WriteLn(Value);
  end
  else
  begin
    WriteLn('FTYPE not found');
  end;
  if Names.IndexOf('__INPUT__/SIM/NAM/TDIS6') >= 0 then
  begin
//    get_value_string('__INPUT__/SIM/NAM/TDIS6', @Value);
//    WriteLn(Value);
  end
  else
  begin
    WriteLn('TDIS not found');
  end;
end;

function GetTimeDiscretization: TStressPeriods;
var
  Nper: Integer;
  NStep: TCIntArray;
  PerLen: TDoubleArray;
  Tsmult: TDoubleArray;
  PeriodIndex: Integer;
begin
  Nper := GetNumberOfPeriods;
  SetLength(Result, Nper);
//  Writeln(Nper);
  NStep := GetNumberOfSteps;
  PerLen := GetPerLen;
  Tsmult := GetTsmult;
  for PeriodIndex := 0 to Nper - 1 do
  begin
    Result[PeriodIndex].Length := PerLen[PeriodIndex];
    Result[PeriodIndex].NStep := NStep[PeriodIndex];
    Result[PeriodIndex].TSMult := Tsmult[PeriodIndex];
  end;
  Writeln(Ord(GetTimeUnits));
end;

procedure GetDiscretization(ModelNames: TAnsiStringArray;
  Packages: TPackages; Mf6GridType: TMf6GridType; var IDomain: TCIntArray);
var
  DisPackageName: AnsiString;
  PackageIndex: Integer;
  LengthUnit: Tmf6LengthUnit;
  RotationAngle: Double;
  Vertices: TVertices;
  Cells: TCells;
  ACell: TCell;
  VIndex: Integer;
  DelR: TDoubleArray;
  DelC: TDoubleArray;
  GridTop: TDoubleArray;
  GridBottom: TDoubleArray;
  Index: Integer;
  PackageID: AnsiString;
begin
  case Mf6GridType of
    gtDISU: PackageID := 'DISU6';
    gtDISV: PackageID := 'DISV6';
    gtDIS: PackageID := 'DIS6';
  end;
  DisPackageName := '';
  for PackageIndex := 0 to Length(Packages) - 1 do
  begin
    if Packages[PackageIndex].PackageType = PackageID then
    begin
      DisPackageName := Packages[PackageIndex].PackageName;
      Break;
    end;
  end;
  Assert(DisPackageName <> '');
  LengthUnit := GetLengthUnit(ModelNames[0], DisPackageName);
  WriteLn(Ord(LengthUnit));
  Writeln(GetXOrigin(ModelNames[0], DisPackageName));
  Writeln(GetYOrigin(ModelNames[0], DisPackageName));
  RotationAngle := GetGridRotation(ModelNames[0], DisPackageName);
  Writeln(RotationAngle);
  case Mf6GridType of
    gtDISU:
      Assert(False);
    gtDISV:
      begin
        Vertices := GetVertices(ModelNames[0], DisPackageName);
        for Index := 0 to Length(Vertices) - 1 do
        begin
          WriteLn(Vertices[Index].VertexNumber, ''#9'',
            Vertices[Index].X, ''#9'', Vertices[Index].Y);
        end;
        Cells := GetDisvCells(ModelNames[0], DisPackageName);
        for Index := 0 to Length(Cells) - 1 do
        begin
          ACell := Cells[Index];
          Write(ACell.CellNumber, ''#9'', ACell.CellX, ''#9'', ACell.CellY);
          for VIndex := 0 to Length(ACell.VertexNumbers) - 1 do
          begin
            Write(''#9'', ACell.VertexNumbers[VIndex]);
          end;
          WriteLn;
        end;
      end;
    gtDIS:
      begin
        DelR := GetDelR(ModelNames[0], DisPackageName);
        WriteLn('DelR');
        for Index := 0 to Length(DelR) - 1 do
        begin
          Write(' ', DelR[Index]);
        end;
        Writeln;
        DelC := GetDelC(ModelNames[0], DisPackageName);
        WriteLn('DelC');
        for Index := 0 to Length(DelC) - 1 do
        begin
          Write(' ', DelC[Index]);
        end;
      end;
  end;
  GridTop := GetTop(ModelNames[0], DisPackageName);
  GridBottom := GetBottom(ModelNames[0], DisPackageName);
  IDomain := GetIDomain(ModelNames[0], DisPackageName);
end;

procedure GetNPF(ModelNames: TAnsiStringArray; Packages: TPackages);
var
  NpfPackageName: AnsiString;
  PackageIndex: Integer;
  CellType: TCIntArray;
  K: TDoubleArray;
  K22: TDoubleArray;
  K33: TDoubleArray;
  Angle1: TDoubleArray;
  Angle2: TDoubleArray;
  Angle3: TDoubleArray;
  WetDry: TDoubleArray;
begin
  NpfPackageName := '';
  for PackageIndex := 0 to Length(Packages) - 1 do
  begin
    if Packages[PackageIndex].PackageType = 'NPF6' then
    begin
      NpfPackageName := Packages[PackageIndex].PackageName;
      break;
    end;
  end;
  Assert(NpfPackageName <> '');
  Writeln(Ord(GetNpfAveraging(ModelNames[0], NpfPackageName)));
  WriteLn(UseTHICKSTRT(ModelNames[0], NpfPackageName));
  if UseVARIABLECV(ModelNames[0], NpfPackageName) then
  begin
    WriteLn(True, UseDEWATERED(ModelNames[0], NpfPackageName));
  end
  else
  begin
    WriteLn(False);
  end;
  WriteLn(UsePerched(ModelNames[0], NpfPackageName));
  if UseREWET(ModelNames[0], NpfPackageName) then
  begin
    WriteLn(True, GetWETFCT(ModelNames[0], NpfPackageName),
      GetIWETIT(ModelNames[0], NpfPackageName),
      GetIHDWET(ModelNames[0], NpfPackageName));
  end
  else
  begin
    WriteLn(False);
  end;
  WriteLn(UseK22OVERK(ModelNames[0], NpfPackageName));
  WriteLn(UseK33OVERK(ModelNames[0], NpfPackageName));
  WriteLn(UseXT3D(ModelNames[0], NpfPackageName));
  WriteLn(UseXT3D_RHS(ModelNames[0], NpfPackageName));
  CellType := GetICELLTYPE(ModelNames[0], NpfPackageName);
  K := GetK(ModelNames[0], NpfPackageName);
  K22 := GetK22(ModelNames[0], NpfPackageName);
  K33 := GetK33(ModelNames[0], NpfPackageName);
  Angle1 := GetAngle1(ModelNames[0], NpfPackageName);
  Angle2 := GetAngle2(ModelNames[0], NpfPackageName);
  Angle3 := GetAngle3(ModelNames[0], NpfPackageName);
  WetDry := GetWetDry(ModelNames[0], NpfPackageName);
end;

procedure GetIms(ImsNumber: Integer);
var
  UnderRelax: Integer;
  BackTrackNumber: Integer;
  SimpleMatch: integer;
  ModelerateMatch: Integer;
  ComplexMatch: integer;
  OUTER_DVCLOSE: Double;
  OUTER_MAXIMUM: Integer;
  Gamma: Double;
  INNER_MAXIMUM: Integer;
  INNER_DVCLOSE: Double;
  INNER_RCLOSE: Double;
  LINEAR_ACCELERATION: Integer;
  RELAXATION_FACTOR: Double;
  PRECONDITIONER_LEVELS: Integer;
  PRECONDITIONER_DROP_TOLERANCE: Double;
  NUMBER_ORTHOGONALIZATIONS: Integer;
  Method: Integer;
const
  Epsilon = 1E-10;
begin
  Method := 1;
  SimpleMatch := 0;
  ModelerateMatch := 0;
  ComplexMatch := 0;
  WriteLn(GetImsPrintOption(ImsNumber));
  WriteLn(GetImsNoPTC(ImsNumber));
  WriteLn(GetImsATS_OUTER_MAXIMUM_FRACTION(ImsNumber));
  OUTER_DVCLOSE := GetImsOUTER_DVCLOSE(ImsNumber);
  if Abs(OUTER_DVCLOSE - 1E-3) < Epsilon then
  begin
    Inc(SimpleMatch)
  end
  else if Abs(OUTER_DVCLOSE - 1E-2) < Epsilon then
  begin
    Inc(ModelerateMatch)
  end
  else if Abs(OUTER_DVCLOSE - 1E-1) < Epsilon then
  begin
    Inc(ComplexMatch);
  end;
  WriteLn(OUTER_DVCLOSE);
  OUTER_MAXIMUM := GetImsOUTER_MAXIMUM(ImsNumber);
  if OUTER_MAXIMUM = 25 then
  begin
    Inc(SimpleMatch);
  end
  else if OUTER_MAXIMUM = 50 then
  begin
    Inc(ModelerateMatch);
  end
  else if OUTER_MAXIMUM = 100 then
  begin
    Inc(ComplexMatch);
  end;
  WriteLn(OUTER_MAXIMUM);

  UnderRelax := GetImsUNDER_RELAXATION(ImsNumber);
  WriteLn(UnderRelax);
  if UnderRelax <> 0 then
  begin
    Inc(ModelerateMatch);
    Inc(ComplexMatch);
    Gamma := GetImsUNDER_RELAXATION_GAMMA(ImsNumber);
    WriteLn(GetImsUNDER_RELAXATION_GAMMA(ImsNumber));
    if Gamma = 0 then
    begin
      Inc(ModelerateMatch);
      Inc(ComplexMatch);
    end;
  end;
  if UnderRelax = 3 then
  begin
    Inc(ComplexMatch);
    WriteLn(GetImsUNDER_RELAXATION_THETA(ImsNumber));
    WriteLn(GetImsUNDER_RELAXATION_KAPPA(ImsNumber));
    WriteLn(GetImsUNDER_RELAXATION_MOMENTUM(ImsNumber));
  end;
  if UnderRelax = 0 then
  begin
    Inc(SimpleMatch);
  end;

  BackTrackNumber := GetImsBACKTRACKING_NUMBER(ImsNumber);
  if BackTrackNumber = 0 then
  begin
    Inc(SimpleMatch);
    Inc(ModelerateMatch);
  end
  else if BackTrackNumber = 20 then
  begin
    Inc(ComplexMatch);
  end;
  Writeln(BackTrackNumber);
  if BackTrackNumber > 0 then
  begin
    WriteLn(BackTrackNumber);
    WriteLn(GetImsBACKTRACKING_TOLERANCE(ImsNumber));
    WriteLn(GetImsBACKTRACKING_REDUCTION_FACTOR(ImsNumber));
    WriteLn(GetImsBACKTRACKING_RESIDUAL_LIMIT(ImsNumber));
  end;

  INNER_MAXIMUM := GetImsINNER_MAXIMUM(ImsNumber);
  if INNER_MAXIMUM = 50 then
  begin
    Inc(SimpleMatch);
  end
  else if INNER_MAXIMUM = 100 then
  begin
    Inc(ModelerateMatch);
  end
  else if INNER_MAXIMUM = 500 then
  begin
    Inc(ComplexMatch);
  end;
  WriteLn(INNER_MAXIMUM);
  
  INNER_DVCLOSE := GetImsINNER_DVCLOSE(ImsNumber);
  WriteLn(INNER_DVCLOSE);
  if Abs(INNER_DVCLOSE - 1E-3) < Epsilon then
  begin
    Inc(SimpleMatch)
  end
  else if Abs(INNER_DVCLOSE - 1E-2) < Epsilon then
  begin
    Inc(ModelerateMatch);
  end
  else if Abs(INNER_DVCLOSE - 1E-1) < Epsilon then
  begin
    Inc(ComplexMatch);
  end;
  
  INNER_RCLOSE := GetImsINNER_RCLOSE(ImsNumber);
  WriteLn(INNER_RCLOSE);
  
  LINEAR_ACCELERATION := GetImsLINEAR_ACCELERATION(ImsNumber);
  if LINEAR_ACCELERATION = 1 then
  begin
    Inc(SimpleMatch)
  end
  else if LINEAR_ACCELERATION = 2 then
  begin
    Inc(ModelerateMatch);
    Inc(ComplexMatch);
  end;
  WriteLn(LINEAR_ACCELERATION);
  
  RELAXATION_FACTOR := GetImsRELAXATION_FACTOR(ImsNumber);
  if Abs(RELAXATION_FACTOR - 0) < Epsilon then
  begin
    Inc(SimpleMatch);
    Inc(ComplexMatch);
  end
  else if Abs(RELAXATION_FACTOR - 0.97) < Epsilon then
  begin
    Inc(ModelerateMatch);
  end;
  WriteLn(GetImsRELAXATION_FACTOR(ImsNumber));
  
  PRECONDITIONER_LEVELS := GetImsPRECONDITIONER_LEVELS(ImsNumber);
  if Abs(PRECONDITIONER_LEVELS - 0) < Epsilon then
  begin
    Inc(SimpleMatch);
    Inc(ModelerateMatch);
  end
  else if Abs(PRECONDITIONER_LEVELS - 5) < Epsilon then
  begin
    Inc(ComplexMatch);
  end;
  WriteLn(PRECONDITIONER_LEVELS);
  
  PRECONDITIONER_DROP_TOLERANCE := GetImsPRECONDITIONER_DROP_TOLERANCE(ImsNumber);
  if Abs(PRECONDITIONER_DROP_TOLERANCE - 0) < Epsilon then
  begin
    Inc(SimpleMatch);
    Inc(ModelerateMatch);
  end
  else if Abs(PRECONDITIONER_DROP_TOLERANCE - 0.0001) < Epsilon then
  begin
    Inc(ComplexMatch);
  end;
  WriteLn(PRECONDITIONER_DROP_TOLERANCE);
  
  NUMBER_ORTHOGONALIZATIONS := GetImsNUMBER_ORTHOGONALIZATIONS(ImsNumber);
  if NUMBER_ORTHOGONALIZATIONS = 0 then
  begin
    Inc(SimpleMatch);
    Inc(ModelerateMatch);
  end
  else if NUMBER_ORTHOGONALIZATIONS = 2 then
  begin
    Inc(ComplexMatch);
  end;
  WriteLn(NUMBER_ORTHOGONALIZATIONS);
  
  WriteLn(GetImsSCALING_METHOD(ImsNumber));
  WriteLn(GetImsREORDERING_METHOD(ImsNumber));
  if ModelerateMatch > SimpleMatch then
  begin
    Method := 2;
  end;
  if (Method = 2) and (ComplexMatch > ModelerateMatch) then
  begin
    Method := 3;
  end;
  case Method of
    1: WriteLn('Simple');
    2: WriteLn('Moderate');
    3: WriteLn('Complex');
    else Assert(False);
  end;
       
end;

procedure GetStoragePackage(ModelNames: TAnsiStringArray; Packages: TPackages; var StoPackageName: string);
var
  PackageIndex: Integer;
begin
  StoPackageName := '';
  for PackageIndex := 0 to Length(Packages) - 1 do
  begin
    if Packages[PackageIndex].PackageType = 'STO6' then
    begin
      StoPackageName := Packages[PackageIndex].PackageName;
      break;
    end;
  end;
  if (StoPackageName <> '') then
  begin
    WriteLn(GetStoSTORAGECOEFFICIENT(ModelNames[0], StoPackageName));
    WriteLn(GetStoSS_CONFINED_ONLY(ModelNames[0], StoPackageName));
    GetStoICONVERT(ModelNames[0], StoPackageName);
    GetStoSS(ModelNames[0], StoPackageName);
    GetStoSY(ModelNames[0], StoPackageName);
  end;
end;

procedure GetInitialConditions(ModelNames: TAnsiStringArray; Packages: TPackages);
var
  ICPackageName: AnsiString;
  PackageIndex: Integer;
begin
  ICPackageName := '';
  for PackageIndex := 0 to Length(Packages) - 1 do
  begin
    if Packages[PackageIndex].PackageType = 'IC6' then
    begin
      ICPackageName := Packages[PackageIndex].PackageName;
      break;
    end;
  end;
  if ICPackageName <> '' then
  begin
    GetIcSTRT(ModelNames[0], ICPackageName);
  end;
end;

procedure GetCell(NodeNumber: Integer; MFGridShape, IDomain: TCIntArray; var MfCell: TMfCell);
var
  Layer: Integer;
  Row: Integer;
  Col: Integer;
  CellIndex: Integer;
  CellNumber: Integer;
begin
  case Length(MFGridShape) of
    1:
      begin
        // DISU
        MfCell.Layer := 0;
        MfCell.Row := 0;
        MfCell.Column := 0;
      end;
    2:
      begin
        if DisvCellDict = nil then
        begin
          DisvCellDict := TDisvCellDict.Create;
          Layer := -1;
          Col := -1;
          CellNumber := 0;
          for CellIndex := 0 to Length(IDomain) - 1 do
          begin
            if (CellIndex mod MFGridShape[1]) = 0 then
            begin
              Inc(Layer);
              Col := -1;
            end;
            Inc(Col);
            if IDomain[CellIndex] > 0 then
            begin
              Inc(CellNumber);
              MfCell.Layer := Layer + 1;
              MfCell.Row := 1;
              MfCell.Column := Col + 1;
              DisvCellDict.Add(CellNumber, MfCell)
            end;
          end;
        end;
        // DISV
        if not DisvCellDict.TryGetValue(NodeNumber, MfCell) then
        begin
          MfCell.Layer := 0;
          MfCell.Row := 0;
          MfCell.Column := 0;
        end;
      end;
    3:
      begin
        // DIS
        Layer := (NodeNumber -1) mod MFGridShape[0];
        NodeNumber := NodeNumber - Layer * MFGridShape[0];
        Row := (NodeNumber -1) mod MFGridShape[1];
        NodeNumber := NodeNumber - Row * MFGridShape[1];
        Col := NodeNumber;
        MfCell.Layer := Layer + 1;
        MfCell.Row := Row + 1;
        MfCell.Column := Col + 1;
      end;
  end;
end;

procedure ImportModel;
var
  version : PAnsiChar;
  vstr : TMfName;
  component : PAnsiChar;
  cname : TMfComponentName;
  GridType : TGridType;
  cnt : cint;
  GridID: cint;
  GridShape: TGridShape;
  Names: array of AnsiChar;
  NameIndex: Integer;
  NameBuilder: TStringBuilder;
//  NameList2: TStringList;
  CharIndex: Integer;
  AChar: AnsiChar;
  AName: string;
  NperID: array[0..255] of AnsiChar;
  NperIDP: PAnsiChar;
  NperIDArray: cintArray;
  varNames: TVarNames;

  ErrorMessage: TErrorMessage;
//  NameStart: Integer;
  currentTime: double;
//  rank: cint;
  GridSize: cint;
  Index: Integer;
  InnerIndex: Integer;
  X, Y: array of double;
  NVertString: AnsiString;
  NCPL_String: AnsiString;
  NVERT: cint;
  NCPL: cint;
  DISV_NCVERT: AnsiString;
  DISV_ICVERT: AnsiString;
  DISV_XC: AnsiString;
  DISV_YC: AnsiString;
  MODEL_SHAPE: AnsiString;
  DIS_TOP: AnsiString;
  DIS_BOT: AnsiString;
  DIS_LENUNI: AnsiString;
  NPF_K: AnsiString;
  VertPerCell: array of cint;
  Verticies: array of cint;
  VertLength: integer;
  VertIndex: Integer;
  ModelShapeArray: array of cint;
  DimCount: Integer;
  Mf6GridType: TMf6GridType;
  ModelTop: array of Double;
  ModelBottom: array of Double;
  ArrayLength: Integer;
//  LenUni: cint;
  LenUniArray: array of cint;
//  k: array of Double;
  Mode: array of cint;
  ModeString: AnsiString;
  VariableName: AnsiString;
  VariableType: AnsiString;
  Rank: Integer;
  RankIndex: Integer;
  ModelNames: TAnsiStringArray;
  ModelTypes: TAnsiStringArray;
  MFGridShape: TCIntArray;
  Packages: TPackages;
  PackageID: Ansistring;
  K: TDoubleArray;
  ImsNumber: Integer;
  StoPackageName: string;
  current_time: Double;
  TimeStep: Double;
  NStep: TCIntArray;
  PeriodIndex: Integer;
  StepIndex: Integer;
  NewStressPeriodTransientDataRead: Integer;
  Transient: Boolean;
  TDIS: TStressPeriods;
  PackageIndex: Integer;
  ChdPackageName: AnsiString;
  AuxNames: TAnsiStringArray;
  AuxMult: Integer;
  BoundNames: TAnsiStringArray;
  SetMode: Boolean;
  ChdBound: TDoubleArray;
  AuxValues: TDoubleArray;
  NodeList: TCIntArray;
  CellIndex: Integer;
  IDomain: TCIntArray;
  MfCell: TMfCell;
begin
  with TFileOpenDialog.Create(nil) do
  try
    Options := [fdoPickFolders];
    if Execute then
    begin
     SetCurrentDir(FileName);
    end
    else
    begin
      Exit;
    end;
  finally
    Free;
  end;

  version := @vstr;
  component := @cname;
//  PGridType := @GridType;
  writeln ('Hello, mf6 world.');
  initialize();
  get_version(vstr);
  get_component_name(cname);
  writeln('Component name: ' + cname);
  writeln('MF6 DLL version: ' + version);
  writeln('MF6 DLL component: ' + component);
//  count := @cnt;
  get_output_item_count(cnt);
  write('MF6 output item count: ');
  writeln(cnt);

  SetLength(Names, (cnt+1)*BMI_LENVARADDRESS);
  SetLength(varNames,  cnt+1);

//  NamesP := @Names;
  get_output_var_names(Addr(Names[0]));

  NVertString := '';
  NCPL_String := '';
  DISV_NCVERT := '';
  DISV_ICVERT := '';
  DISV_XC := '';
  DISV_YC := '';
  MODEL_SHAPE := '';
  DIS_TOP := '';
  DIS_BOT := '';
  DIS_LENUNI := '';
  NPF_K := '';
  NameBuilder := TStringBuilder.Create;
  NameList := TAnsiStringList.Create;
//  NameList2 := TStringList.Create;
  try
    for CharIndex := 0 to Length(Names) - 1 do
    begin
      AChar := Names[CharIndex];
      if Ord(AChar) = 0 then
      begin
        AName := NameBuilder.ToString;
        if AName <> '' then
        begin
          NameList.Add(AnsiString(AName));
          NameBuilder.Clear;
        end;
      end
      else
      begin
        NameBuilder.Append(AChar);
      end;
    end;
    for NameIndex := 0 to NameList.Count - 1 do
    begin
      Writeln(NameList[NameIndex]);
    end;

    // Set mode
    SetMode := True;
    if SetMode then
    begin
      if (NameList.Count > 0) and (NameList[0] = 'SIM/ISIM_MODE') then
      begin
        SetLength(Mode, 1);
        ModeString := AnsiString(NameList[0]);
        if get_value_int(PAnsiChar(ModeString), @Mode) = 0 then
        begin
          Writeln('Mode: ', Mode[0]);
          Mode[0] := 0;
          if set_value_int(PAnsiChar(ModeString), @Mode) = 0 then
          begin
            Writeln('success Setting Mode: ');
          end
          else
          begin
            Writeln('Error Setting Mode: ');
            get_last_bmi_error(@ErrorMessage);
            Writeln(ErrorMessage);
          end;
        end
        else
        begin
          Writeln('Error Getting Mode: ');
          get_last_bmi_error(@ErrorMessage);
          Writeln(ErrorMessage);
        end;
      end;
    end;

    ModelTypes := GetModelType;
    ModelNames := GetModelName;
    Assert(Length(ModelNames) = Length(ModelTypes));
    for Index := 0 to Length(ModelNames) - 1 do
    begin
      WriteLn(ModelNames[Index], ' ', ModelTypes[Index]);
    end;
    TDIS := GetTimeDiscretization;
//    GetStringVariable('MODFLOW/CHD-1/BOUNDNAME_CST');

//    update();

//    GetSimulationValues(NameList);
//    GetSimulationInputs(NameList);
    Packages := GetPackageNames(ModelNames[0]);
    Mf6GridType := GetModflowGridType(ModelNames[0], MFGridShape);
    Writeln(Ord(Mf6GridType));
    GetDiscretization(ModelNames, Packages, Mf6GridType, IDomain);
    GetNPF(ModelNames, Packages);

    ImsNumber := 1;
    GetIms(ImsNumber);
    GetStoragePackage(ModelNames, Packages, StoPackageName);
    GetInitialConditions(ModelNames, Packages);

    ChdPackageName := '';
    for PackageIndex := 0 to Length(Packages) - 1 do
    begin
      if Packages[PackageIndex].PackageType = 'CHD6' then
      begin
        ChdPackageName := Packages[PackageIndex].PackageName;
        break;
      end;
    end;
    if ChdPackageName <> '' then
    begin
      AuxNames := GetAuxName(ModelNames[0], ChdPackageName);
      AuxMult := GetAuxMult(ModelNames[0], ChdPackageName);
    end;

    NStep := GetNumberOfSteps;
    NewStressPeriodTransientDataRead := 1;

    for PeriodIndex := 0 to Length(NStep) - 1 do
    begin
      for StepIndex := 0 to NStep[PeriodIndex] - 1 do
      begin
        if not GetEndOfSimulation then
        begin
          update;
        end;

        GetSimulationValues(NameList);

        if ChdPackageName <> '' then
        begin
          NodeList := GetNodeList(ModelNames[0], ChdPackageName);
          ChdBound := GetBound(ModelNames[0], ChdPackageName);
          BoundNames := GetBoundNames(ModelNames[0], ChdPackageName);
          AuxValues := GetAuxValue(ModelNames[0], ChdPackageName);
          Assert(Length(NodeList) = Length(ChdBound));
          if BoundNames <> nil then
          begin
            Assert(Length(NodeList) = Length(BoundNames));
          end;
          if AuxValues <> nil then
          begin
            Assert(Length(NodeList) = Length(AuxValues));
          end;
          for CellIndex := 0 to Length(NodeList)  - 1 do
          begin
            GetCell(NodeList[CellIndex], MFGridShape, IDomain, MfCell);
            Write(NodeList[CellIndex], ' ', MfCell.Layer, ' ', MfCell.Row, ' ',
              MfCell.Column, ' ', ChdBound[CellIndex]);
            if AuxValues <> nil then
            begin
              Write(' ', AuxValues[CellIndex]);
            end;
            if BoundNames <> nil then
            begin
              Write(' ', BoundNames[CellIndex]);
            end;
            Writeln;
          end
        end;

        if (StepIndex = NStep[PeriodIndex] - 1) then
        begin
          if StoPackageName <> '' then
          begin
            NewStressPeriodTransientDataRead :=
              GetNewDataRead(ModelNames[0], StoPackageName);

            if NewStressPeriodTransientDataRead = PeriodIndex+1 then
            begin
              Transient := GetTransient(ModelNames[0]);
            end;
            TDIS[PeriodIndex].Transient := Transient;
          end
          else
          begin
            TDIS[PeriodIndex].Transient := False;
          end;
        end;
      end;
    end;
    for PeriodIndex := 0 to Length(TDIS) - 1 do
    begin
      if TDIS[PeriodIndex].Transient then
      begin
        Writeln(TDIS[PeriodIndex].Length, ' ', TDIS[PeriodIndex].NStep, ' ',
           TDIS[PeriodIndex].TSMult, ' Transient')
      end
      else
      begin
        Writeln(TDIS[PeriodIndex].Length, ' ', TDIS[PeriodIndex].NStep, ' ',
           TDIS[PeriodIndex].TSMult, ' Steady-State')
      end;
    end;


//    ModelName

    for Index := 0 to NameList.Count - 1 do
    begin
      VariableName := AnsiString(NameList[Index]);
      SetLength(VariableType, BMI_LENVARTYPE);
      for CharIndex := 1 to BMI_LENVARTYPE do
      begin
        VariableType[CharIndex] := AnsiChar(nil);
      end;
      if get_var_type(PAnsiChar(VariableName), PAnsiChar(VariableType)) = 0 then
      begin
        WriteLn('Variable Type: ', VariableName, ' = ', VariableType);
      end
      else
      begin
        WriteLn('Failure get_var_type at Index = ', Index);
        get_last_bmi_error(@ErrorMessage);
        Writeln(ErrorMessage);
        break
      end;
      if get_var_rank(PAnsiChar(VariableName), Rank) = 0 then
      begin
        WriteLn('Variable Rank: ', VariableName, ' = ', Rank);
        SetLength(ModelShapeArray,Rank);
        for RankIndex := 0 to Length(ModelShapeArray) - 1 do
        begin
          ModelShapeArray[RankIndex] := Mf6Undefined;
        end;
        if Rank > 0 then
        begin
          if get_var_shape(PAnsiChar(VariableName), @ModelShapeArray[0]) = 0 then
          begin
            for RankIndex := 0 to Length(ModelShapeArray) - 1 do
            begin
              WriteLn(ModelShapeArray[RankIndex]);
            end;
          end
          else
          begin
            WriteLn('Failure get_var_shape at Index = ', Index);
          end;
        end;
      end
      else
      begin
        WriteLn('Failure get_var_rank at Index = ', Index);
        get_last_bmi_error(@ErrorMessage);
        Writeln(ErrorMessage);
//        if Pos('0', VariableType) <= 0 then
//        begin
//          break
//        end;
      end;
    end;

//    for NameIndex := 0 to cnt - 1 do
//    begin
//      NameStart := NameIndex * BMI_LENVARADDRESS;
//      AName := string(PAnsiChar(Addr(Names[NameStart])));
//      if Pos('/DISV/NVERT', AName) > 0 then
//      begin
//        NVertString := AnsiString(AName);
//      end;
//      if Pos('/DISV/NCPL', AName) > 0 then
//      begin
//        NCPL_String := AnsiString(AName);
//      end;
//      if Pos('/DISV/NCVERT', AName) > 0 then
//      begin
//        DISV_NCVERT := AnsiString(AName);
//      end;
//      if Pos('/DISV/ICVERT', AName) > 0 then
//      begin
//        DISV_ICVERT := AnsiString(AName);
//      end;
//      if Pos('/DISV/XC', AName) > 0 then
//      begin
//        DISV_XC := AnsiString(AName);
//      end;
//      if Pos('/DISV/YC', AName) > 0 then
//      begin
//        DISV_YC := AnsiString(AName);
//      end;
//      if Pos('MODEL_SHAPE', AName) > 0 then
//      begin
//        MODEL_SHAPE := AnsiString(AName);
//      end;
//      if Pos('/DIS/TOP', AName) > 0 then
//      begin
//        DIS_TOP := AnsiString(AName);
//      end;
//      if Pos('/DIS/BOT', AName) > 0 then
//      begin
//        DIS_BOT := AnsiString(AName);
//      end;
//      if Pos('/DIS/LENUNI', AName) > 0 then
//      begin
//        DIS_LENUNI := AnsiString(AName);
//      end;
//      if (Pos('/NPF/K', AName) > 0) and (AName[Length(AName)] = 'K') then
//      begin
//        NPF_K := AnsiString(AName);
//      end;
//
//
//
//      NameList2.Add(AName);
//    end;
//    Assert(NameList.Count = NameList2.Count);
//    Assert(NameList.CommaText = NameList2.CommaText);
  finally
//    NameList2.Free;
    NameList.Free;
    NameBuilder.Free;
    DisvCellDict.Free;
    DisvCellDict := nil;
  end;

  if NPF_K <> '' then
  begin
    SetLength(ModelShapeArray,MAXMEMRANK);
    for Index := 0 to Length(ModelShapeArray) - 1 do
    begin
      ModelShapeArray[Index] := Mf6Undefined;
    end;
//    ArrayLength := 1;
    if get_var_shape(PAnsiChar(NPF_K), @ModelShapeArray[0]) = 0 then
    begin
      ArrayLength := 1;
      for Index := 0 to Length(ModelShapeArray) - 1 do
      begin
        if ModelShapeArray[Index] <> Mf6Undefined then
        begin
          Writeln('k dimension: ', Index, ' ', ModelShapeArray[Index]);
          ArrayLength := ArrayLength * ModelShapeArray[Index]
        end;
      end;
      SetLength(K, ArrayLength);
      if get_value_double(PAnsiChar(NPF_K), @K) = 0 then
      begin
        for Index := 0 to Length(K) - 1 do
        begin
          WriteLn(Index, ' ', K[Index]);
        end;
      end;
    end;
  end;

  if DIS_LENUNI <> '' then
  begin
    SetLength(LenUniArray, 1);
    if get_value_int(PAnsiChar(DIS_LENUNI), @LenUniArray) = 0 then
    begin
      Writeln('LENUNI: ', LenUniArray[0]);
    end;
  end;


  if DIS_TOP <> '' then
  begin
    SetLength(ModelShapeArray,MAXMEMRANK);
    for Index := 0 to Length(ModelShapeArray) - 1 do
    begin
      ModelShapeArray[Index] := Mf6Undefined;
    end;
//    ArrayLength := 1;
    if get_var_shape(PAnsiChar(DIS_TOP), @ModelShapeArray[0]) = 0 then
    begin
      ArrayLength := 1;
      for Index := 0 to Length(ModelShapeArray) - 1 do
      begin
        if ModelShapeArray[Index] <> Mf6Undefined then
        begin
          Writeln('Top dimension: ', Index, ' ', ModelShapeArray[Index]);
          ArrayLength := ArrayLength * ModelShapeArray[Index]
        end;
      end;

      SetLength(ModelTop, ArrayLength);
      if get_value_double(PAnsiChar(DIS_TOP), @ModelTop) = 0 then
      begin
        for Index := 0 to Length(ModelTop) - 1 do
        begin
          WriteLn(Index, ' ', ModelTop[Index]);
        end;
      end;
    end;
  end;

  if DIS_BOT <> '' then
  begin
    SetLength(ModelShapeArray,MAXMEMRANK);
    for Index := 0 to Length(ModelShapeArray) - 1 do
    begin
      ModelShapeArray[Index] := Mf6Undefined;
    end;
    if get_var_shape(PAnsiChar(DIS_BOT), @ModelShapeArray[0]) = 0 then
    begin
      ArrayLength := 1;
      for Index := 0 to Length(ModelShapeArray) - 1 do
      begin
        if ModelShapeArray[Index] <> Mf6Undefined then
        begin
          Writeln('Botm dimension: ', Index, ' ', ModelShapeArray[Index]);
          ArrayLength := ArrayLength * ModelShapeArray[Index]
        end;
      end;
      SetLength(ModelBottom, ArrayLength);
      if get_value_double(PAnsiChar(DIS_BOT), @ModelBottom) = 0 then
      begin
        for Index := 0 to Length(ModelBottom) - 1 do
        begin
          WriteLn(Index, ' ', ModelBottom[Index]);
        end;
      end;
    end;
  end;


  DimCount := 0;
  if MODEL_SHAPE <> '' then
  begin
    SetLength(ModelShapeArray,3);
    for Index := 0 to Length(ModelShapeArray) - 1 do
    begin
      ModelShapeArray[Index] := Mf6Undefined;
    end;
    if get_value_int(PAnsiChar(MODEL_SHAPE), @ModelShapeArray) = 0 then
    begin
      for Index := 0 to Length(ModelShapeArray) - 1 do
      begin
        if ModelShapeArray[Index] <> Mf6Undefined then
        begin
          Inc(DimCount);
        end;
      end;
    end;
    Mf6GridType := TMf6GridType(DimCount-1);
  end;

  NVERT := 0;
  SetLength(NperIDArray, 1);
  if NVertString <> '' then
  begin
    if get_value_int(PAnsiChar(NVertString), @NperIDArray) = 0 then
    begin
      Writeln('Success');
      NVERT := NperIDArray[0];
    end
  end;

  NCPL := 0;
  if NCPL_String <> '' then
  begin
    if get_value_int(PAnsiChar(NCPL_String), @NperIDArray) = 0 then
    begin
      Writeln('Success');
      NCPL := NperIDArray[0];
    end
  end;

  if (NCPL > 0) and (DISV_NCVERT <> '') and (DISV_ICVERT <> '')
    and (DISV_XC <> '') and (DISV_YC <> '') then
  begin
    SetLength(VertPerCell, NCPL);
    SetLength(X, NCPL);
    SetLength(Y, NCPL);
    if (get_value_int(PAnsiChar(DISV_NCVERT), @VertPerCell) = 0)
      and (get_value_double(PAnsiChar(DISV_XC), @X) = 0)
      and (get_value_double(PAnsiChar(DISV_YC), @Y) = 0) then
    begin
      Writeln('Success');
      VertLength := 0;
      for Index := 0 to Length(VertPerCell) - 1 do
      begin
        VertLength := VertLength + VertPerCell[Index];
      end;
      SetLength(Verticies, VertLength);
      if get_value_int(PAnsiChar(DISV_ICVERT), @Verticies) = 0 then
      begin
        Writeln('Success');
        VertIndex := 0;
        for Index := 0 to Length(VertPerCell) - 1 do
        begin
          Write(Index,' ', VertPerCell[Index], ' ', X[Index], ' ', Y[Index]);
          for InnerIndex := 0 to VertPerCell[Index] - 1 do
          begin
            Write(' ', Verticies[VertIndex]);
            Inc(VertIndex);
          end;
          Writeln;
        end;
      end;
    end
  end;

  SetLength(NperIDArray, 1);
  NperID := 'TDIS/NPER';
  NperIDP := @NperID;
  if get_value_int(NperIDP, @NperIDArray) = 0 then
  begin
    Writeln('Success');
  end
  else
  begin
    get_last_bmi_error(@ErrorMessage);
    Writeln(ErrorMessage);
  end;
  writeln('NPER: ', NperIDArray[0]);

  GridID := 1;
  if get_grid_type(@GridID, GridType) = 0 then
  begin
    writeln('grid type: ' + GridType);
  end
  else
  begin
    writeln('Failure');
  end;

  if get_grid_face_count(@GridID, cnt) = 0 then
  begin
  writeln('face count: ', cnt);
  end
  else
  begin
    writeln('Failure');
  end;

  GridShape[0] := Mf6Undefined;
  GridShape[1] := Mf6Undefined;
  GridShape[2] := Mf6Undefined;

//  GridShapeP := @GridShape;
  if get_grid_shape(@GridID, GridShape) = 0 then
  begin
    WriteLn('GridShape[0], NLAY: ', GridShape[0]);
    WriteLn('GridShape[1], NROW: ', GridShape[1]);
    WriteLn('GridShape[2], NCOL: ', GridShape[2]);
    GridSize := 1;
    for Index := 0 to Length(GridShape) - 1 do
    begin
      if GridShape[Index] <> Mf6Undefined then
      begin
        GridSize := GridSize * GridShape[Index]
      end;
    end;
    writeln('GridSize: ', GridSize);
  end
  else
  begin
    writeln('Failure');
  end;
  get_current_time(currentTime);
  Writeln('Current time: ',  currentTime);
  get_end_time(currentTime);
  Writeln('end time: ',  currentTime);

  SetLength(X, NVERT);
  SetLength(Y, NVERT);
  for Index := 0 to Length(X) - 1 do
  begin
    X[Index] := Mf6Undefined;
    Y[Index] := Mf6Undefined;
  end;

  GridID := 1;
  if (NVERT > 0) and (get_grid_x(@GridID, Addr(X[0])) = 0)
    and (get_grid_y(@GridID, Addr(Y[0])) = 0) then
  begin
    for Index := 0 to Length(X) - 1 do
    begin
      if X[Index] = Mf6Undefined then
      begin
        Assert(False)
      end;
      if Y[Index] = Mf6Undefined then
      begin
        Assert(False)
      end;
      writeln(Index, X[Index], Y[Index]);
    end;
  end
  else
  begin
    writeln('Failure get_grid_x');
  end;

  GridID := 1;
  GridSize := 0;
  if get_grid_size(@GridID, GridSize) = 0 then
  begin
    // grid size should not be zero.
    writeln('grid size: ', GridSize);
  end
  else
  begin
    writeln('Failure get_grid_size');
  end;

  if not GetEndOfSimulation then
  begin
    update;
  end;

  get_output_item_count(cnt);
  write('MF6 output item count: ');
  writeln(cnt);

  get_current_time(currentTime);
  Writeln('Current time: ',  currentTime);

  finalize();
end;

initialization
  ErrorMessages:= TStringList.Create;

finalization
  ErrorMessages.Free;


end.