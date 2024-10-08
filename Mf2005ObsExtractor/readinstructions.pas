unit readinstructions;

{$IFDEF FPC}
{$mode objfpc}{$H+}
{$ENDIF}

interface

uses
  Classes, SysUtils, ReadMnwiOutput, ObExtractorTypes, ReadNameFile,
    Generics.Collections, Generics.Defaults;

type

  { TObsProcessor }

  TObsProcessor = class(TObject)
  private
    FLineIndex: integer;
    FInputFile: TStringList;
    FObsList: TCustomWeightedObsValueObjectList;
    FObsDictionary: TCustomObsValueDictionary;
    FListingFile: TStringList;
    FObservationsFile: TStringList;
    FFileLink: TInputFileLink;
    FGenerateInstructionFile: Boolean;
    procedure HandleSimpleObservations;
  public
    Constructor Create(FileLink: TInputFileLink; GenerateInstructionFile: Boolean);
    destructor Destroy; override;
    procedure ProcessInstructionFile;
    procedure HandleDerivedObservations;
    procedure WriteFiles;
    property ListingFile: TStringList read FListingFile write FListingFile;
    property ObservationsFile: TStringList read FObservationsFile
      write FObservationsFile;
    property ObsDictionary: TCustomObsValueDictionary read FObsDictionary
      write FObsDictionary;
  end;

{$IFDEF FPC}
  TObsProcessorList = specialize TObjectList<TObsProcessor>;
{$ELSE}
  TObsProcessorList = TObjectList<TObsProcessor>;
{$ENDIF}

implementation

uses readgageoutput, SubsidenceObsExtractor, SwiOutputReaderUnit,
  InterpolatedObsResourceUnit, SwiObsReaderUnit, SwtObsExtractor;

resourcestring
  rsDERIVED_OBSE = 'DERIVED_OBSERVATIONS';
  rsERRORSNotFou = 'ERROR: %s not found among the direct observations';
  rsOnLine0D1SIs = 'On line %0:d of %1:s, "%2:s" is a duplicate of a previous '
    +'observation.';
  rsNoOutputFile = 'No output file has been specified for processing.';
  rsUnrecognized = 'Unrecognized keyword: "%s"';
  rsSIsOnlyValid = '"%s" is only valid for SWI observation files.';
  rs0SIsNotAVali = '"%0:s" is not a valid SWI format. Valid SWI formats are "%'
    +'1:s", "%2:s %3:s", and "%2:s %4:s".';
  rsSIsOnlyValid2 = '"%s" is only valid for SWT files.';

  { TObsProcessor }

procedure TObsProcessor.HandleSimpleObservations;
var
  ALine: string;
  Splitter: TStringList;
  ModelOutputFileName: string;
  ObsExtractor: TCustomObsExtractor;
  ObsName: String;
  ObsTypeIndex: Integer;
  ObsTime: double;
  ObsTypes: TStringList;
  Obs: TCustomWeightedObsValue;
  PrintString: string;
  ErrorMessage: string;
  ObservedValue: double;
  Weight: double;
  ObsTypeName: string;
  SubObs: TSubsidenceObsValue;
  ACellID: TCellID;
  SwiObsExtractor: TSwiObsExtractor;
  SwiObs: TSwiObsValue;
  SwiCell: TSwiCell;
  NumberOfZetaSurfaces: Integer;
  TotalNumberOfObs: Integer;
  ZetaSurfaceNumber: Integer;
  FileFormat: TSwiFileFormat;
  SwiNumber: Integer;
  SwiFraction: double;
  SwiNanme: string;
  procedure ProcessObsFile;
  begin
    if ObsExtractor <> nil then
    begin
      try
        ObsExtractor.ExtractSimulatedValues;
      finally
        FreeAndNil(ObsExtractor);
      end;
    end;
  end;
begin
  Obs := nil;
  ObsExtractor := nil;
  ObsTypes := TStringList.Create;
  Splitter := TStringList.Create;
  try
    case FFileLink.FileType of
      iftMNW2:
        begin
          ObsTypes.Add(UpperCase('Qin'));
          ObsTypes.Add(UpperCase('Qout'));
          ObsTypes.Add(UpperCase('Qnet'));
          ObsTypes.Add(UpperCase('QCumu'));
          ObsTypes.Add(UpperCase('hwell'));
        end;
      iftLAK:
        begin
          ObsTypes.Assign(LakeGageOutputTypes);
        end;
      iftSFR:
        begin
          ObsTypes.Assign(StreamGageOutputTypes);
          ObsTypes.Add('GW_FLOW');
        end;
      iftSUB:
        begin
          ObsTypes.Assign(SubsidenceTypes);
        end;
      iftSWT:
        begin
          ObsTypes.Assign(SwtTypes);
        end;
      iftSWI:
        begin
          ObsTypes.Add('ZETA');
        end
    else Assert(false, 'programming error');
    end;
    ObsTypes.CaseSensitive := False;

    Splitter.Delimiter := ' ';
    While FLineIndex < FInputFile.Count do
    begin
      ALine := Trim(FInputFile[FLineIndex]);
      Inc(FLineIndex);
      if (ALine = '') or (ALine[1] = '#') then
      begin
        if Length(ALine) > 0 then
        begin
          FListingFile.Add(ALine);
        end;
        Continue;
      end;

      Splitter.DelimitedText := ALine;
      if Splitter.Count = 2 then
      begin
        if (UpperCase(Splitter[0]) = 'END')
          and (UpperCase(Splitter[1]) = 'OBSERVATIONS') then
        begin
          ProcessObsFile;
          FListingFile.Add('END READING OBSERVATIONS');
          FListingFile.Add('');
          Exit;
        end
        else if UpperCase(Splitter[0]) = 'FILENAME' then
        begin
          ProcessObsFile;
          ModelOutputFileName := RemoveQuotes(Splitter[1]);
          Assert(FileExists(ModelOutputFileName), Format('The output file "%0:s" specified on line %1:d does not exist', [ModelOutputFileName, FLineIndex]));
          FListingFile.Add(Format('Observations will be read from "%s"',
            [ModelOutputFileName]));
          FListingFile.Add(UpperCase('Observation_Name, Observation_Type, Observation_Time, Observed_Value, Weight, Observation_Print'));
          if not FGenerateInstructionFile then
          begin
            case FFileLink.FileType of
              iftMNW2:
                begin
                  ObsExtractor := TMnwiObsExtractor.Create;
                end;
              iftLAK:
                begin
                  ObsExtractor := TLakeGageObsExtractor.Create;
                end;
              iftSFR:
                begin
                  ObsExtractor := TSfrGageObsExtractor.Create;
                end;
              iftSUB:
                begin
                  ObsExtractor := TSubsidenceObsExtractor.Create;
                end;
              iftSWT:
                begin
                  ObsExtractor := TSwtObsExtractor.Create;
                end;
              iftSWI:
                begin
                  ObsExtractor := TSwiObsExtractor.Create;
                end;
            else Assert(False);
            end;
            ObsExtractor.ModelOutputFileName := ModelOutputFileName;
          end;
        end
        else if UpperCase(Splitter[0]) = StrNUMBEROFZETASURFA then
        begin
          Assert(FFileLink.FileType = iftSWI, Format(rsSIsOnlyValid,
           [Splitter[0]]));
          NumberOfZetaSurfaces := StrToInt(Splitter[1]);
          FListingFile.Add(Format('Number Of Zeta Surfaces: "%d"',
            [NumberOfZetaSurfaces]));
          if not FGenerateInstructionFile then
          begin
            Assert(ObsExtractor <> nil, rsNoOutputFile);
            Assert(ObsExtractor is TSwiObsExtractor, Format(rsSIsOnlyValid,
              [Splitter[0]]));
            SwiObsExtractor := TSwiObsExtractor(ObsExtractor);
            SwiObsExtractor.NumberOfZetaSurfaces := NumberOfZetaSurfaces;
          end;
        end
        else if UpperCase(Splitter[0]) = StrTOTALNUMBEROFOBSE then
        begin
          Assert(FFileLink.FileType = iftSWI, Format(rsSIsOnlyValid,
           [Splitter[0]]));
          TotalNumberOfObs := StrToInt(Splitter[1]);
          FListingFile.Add(Format('Number Of observations in SWI Observation output file: "%d"',
            [TotalNumberOfObs]));
          if not FGenerateInstructionFile then
          begin
            Assert(ObsExtractor <> nil, rsNoOutputFile);
            Assert(ObsExtractor is TSwiObsExtractor, Format(rsSIsOnlyValid, [
              Splitter[0]]));
            SwiObsExtractor := TSwiObsExtractor(ObsExtractor);
            SwiObsExtractor.TotalNumberOfObs := TotalNumberOfObs;
          end;
        end
        else if UpperCase(Splitter[0]) = StrSWIOBSFORMAT then
        begin
          Assert(FFileLink.FileType = iftSWI, Format(rsSIsOnlyValid,
           [Splitter[0]]));
          Assert(UpperCase(Splitter[1]) = StrASCII, Format(rs0SIsNotAVali,
            [Splitter[1], StrASCII, StrBINARY, StrSINGLE, StrDOUBLE]));
          FListingFile.Add('SWI File format is ASCII');
          if not FGenerateInstructionFile then
          begin
            Assert(ObsExtractor <> nil, rsNoOutputFile);
            Assert(ObsExtractor is TSwiObsExtractor, Format(rsSIsOnlyValid, [
              Splitter[0]]));
            SwiObsExtractor := TSwiObsExtractor(ObsExtractor);
            SwiObsExtractor.FileFormat := sffAscii;
          end;
        end
        else if UpperCase(Splitter[0]) = StrZETASURFACENUMBER then
        begin
          Assert(FFileLink.FileType = iftSWI, Format(rsSIsOnlyValid,
           [Splitter[0]]));
          ZetaSurfaceNumber := StrToInt(Splitter[1]);
          FListingFile.Add(Format('Zeta Surface Number: %d', [ZetaSurfaceNumber]));
          //if not FGenerateInstructionFile then
          begin
            Assert(Obs <> nil, 'No observation has been defined.');
            Assert(Obs is TSwiObsValue,
              Format('"%s" is only valid for SWI observations.', [StrZETASURFACENUMBER]));
            SwiObs := TSwiObsValue(Obs);
            SwiObs.ZetaSurfaceNumber := ZetaSurfaceNumber;
          end;
        end
        else
        begin
          Assert(False, Format(rsUnrecognized, [Splitter[0]]));
        end;
      end
      else if Splitter.Count = 3 then
      begin
        FileFormat := sffAscii;
        if UpperCase(Splitter[0]) = StrSWIOBSFORMAT then
        begin
          Assert(FFileLink.FileType = iftSWI, Format(rsSIsOnlyValid,
           [Splitter[0]]));
          Assert(UpperCase(Splitter[1]) = StrBINARY, Format(rs0SIsNotAVali,
            [Splitter[1]+ ' ' + Splitter[2],
            StrASCII, StrBINARY, StrSINGLE, StrDOUBLE]));
          if UpperCase(Splitter[2]) = StrSINGLE then
          begin
            FileFormat := sffBinarySingle;
            FListingFile.Add('SWI File format is Single Precision');
          end
          else if UpperCase(Splitter[2]) = StrDOUBLE then
          begin
            FileFormat := sffBinaryDouble;
            FListingFile.Add('SWI File format is Double Precision');
          end
          else
          begin
            Assert(False, Format(rs0SIsNotAVali,
              [Splitter[1]+ ' ' + Splitter[2],
              StrASCII, StrBINARY, StrSINGLE, StrDOUBLE]));
          end;

          if not FGenerateInstructionFile then
          begin
            Assert(ObsExtractor <> nil, rsNoOutputFile);
            Assert(ObsExtractor is TSwiObsExtractor, Format(rsSIsOnlyValid, [
              Splitter[0]]));
            SwiObsExtractor := TSwiObsExtractor(ObsExtractor);
            SwiObsExtractor.FileFormat := FileFormat;
          end;
        end
        else
        begin
          Assert(False, Format(rsUnrecognized, [Splitter[0]]));
        end;
      end
      else if Splitter.Count = 4 then
      begin
        Assert(FFileLink.FileType = iftSWI, Format(rsSIsOnlyValid,
         [Splitter[0]]));
        Assert(UpperCase(Splitter[0]) = StrSWIOBSERVATION,
          Format('"%s" is only valid for SWI observations.', [StrSWIOBSERVATION]));
        SwiNumber := StrToInt(Splitter[1]);
        SwiFraction := FortranStrToFloat(Splitter[2]);
        SwiNanme := Splitter[3];
        //if not FGenerateInstructionFile then
        begin
          Assert(Obs <> nil, 'No observation has been defined.');
          Assert(Obs is TSwiObsValue, Format('"%s" is only valid for SWI observations.', [StrSWIOBSERVATION]));
          SwiObs := TSwiObsValue(Obs);
          SwiCell.Number := SwiNumber;
          SwiCell.Fraction := SwiFraction;
          SwiCell.Name := SwiNanme;
          SwiObs.SwiCellList.Add(SwiCell);
        end;
      end
      else if Splitter.Count = 5 then
      begin
        Assert(UpperCase(Splitter[0]) = 'CELL');
        Assert(FFileLink.FileType in [iftSUB, iftSWT], Format(rsSIsOnlyValid2,
         [Splitter[0]]));
        Assert(Obs <> nil);
        SubObs := Obs as TSubsidenceObsValue;
        ACellID.Layer := StrToInt(Splitter[1]);
        ACellID.Row := StrToInt(Splitter[2]);
        ACellID.Column := StrToInt(Splitter[3]);
        ACellID.Fraction := FortranStrToFloat(Splitter[4]);
        SubObs.AddCellID(ACellID);
      end
      else if Splitter.Count in [6,7] then
      begin
        Assert(UpperCase(Splitter[0]) = 'OBSERVATION');
        if not FGenerateInstructionFile then
        begin
          Assert(ObsExtractor <> nil, rsNoOutputFile);
        end;
        ObsName := Splitter[1];
        ObsTypeName := UpperCase(Splitter[2]);
        ObsTypeIndex := ObsTypes.IndexOf(ObsTypeName);
        Assert(ObsTypeIndex >= 0);
        ObsTime := FortranStrToFloat(Splitter[3]);
        ObservedValue := FortranStrToFloat(Splitter[4]);
        Weight := FortranStrToFloat(Splitter[5]);
        case FFileLink.FileType of
          iftMNW2:
            begin
              Obs := TMnwiObsValue.Create;
              TMnwiObsValue(Obs).ObsType := TMnwiObsType(ObsTypeIndex);
            end;
          iftLAK, iftSFR:
            begin
              Obs := TGageObsValue.Create;
              TGageObsValue(Obs).ObsType := ObsTypeName;
            end;
          iftSUB, iftSWT:
            begin
              Obs := TSubsidenceObsValue.Create;
              TSubsidenceObsValue(Obs).ObsType := ObsTypeName;
            end;
          iftSWI:
            begin
              Obs := TSwiObsValue.Create;
              TSwiObsValue(Obs).ObsType := ObsTypeName;
            end;
          else Assert(False);
        end;
        FObsList.Add(Obs);
        Obs.ObsName := ObsName;
        Obs.ObsTime := ObsTime;
        Obs.ObservedValue := ObservedValue;
        Obs.Weight := Weight;
        if (Splitter.Count = 7) then
        begin
          if (UpperCase(Splitter[6]) = 'PRINT') then
          begin
            Obs.Print := True;
          end
          else if (UpperCase(Splitter[6]) = 'NO_PRINT') then
          begin
            Obs.Print := False;
          end
          else
          begin
            Assert(False);
          end;
        end
        else
        begin
          Obs.Print := True;
        end;
        if not FGenerateInstructionFile then
        begin
          ObsExtractor.AddObs(Obs);
        end;
        try
          FObsDictionary.Add(UpperCase(Obs.ObsName), Obs);
        except on E: Exception do
          begin
            FListingFile.Add(E.Message);
            ErrorMessage := Format(rsOnLine0D1SIs, [FLineIndex, FFileLink.FileName, Obs.ObsName]);
            FListingFile.Add(ErrorMessage);
            Raise Exception.Create(ErrorMessage);
          end;
        end;
        if Obs.Print then
        begin
          PrintString := 'Print';
        end
        else
        begin
          PrintString := 'Do_not_Print';
        end;

        FListingFile.Add(Format('%0:s, %1:s, %2:g, %3:g, %4:g %5:s,',
          [Obs.ObsName, ObsTypes[ObsTypeIndex], Obs.ObsTime, Obs.ObservedValue,
          Obs.Weight, PrintString]));
      end
      else
      begin
        Assert(False);
      end;
    end;

  finally
    Splitter.Free;
    ObsTypes.Free;
    ObsExtractor.Free;
  end;
end;

procedure TObsProcessor.HandleDerivedObservations;
var
  ALine: string;
  Splitter: TStringList;
  FirstValue: TCustomObsValue;
  SecondValue: TCustomObsValue;
  Obs: TCustomWeightedObsValue;
  ObsName: string;
  FirstName: string;
  SecondName: string;
  ErrorMessage: string;
  LastNumber: Integer;
  Names: TStringList;
  NameIndex: Integer;
  ListingLine: string;
begin
  if FFileLink.FileType in [iftHOB, iftFlow] then
  begin
    Exit;
  end;
  Assert(ListingFile <> nil, 'programming error');
  Assert(ObservationsFile <> nil, 'programming error');
  Assert(ObsDictionary <> nil, 'programming error');

  if FLineIndex < FInputFile.Count then
  begin
    FListingFile.Add('');
    FListingFile.Add(UpperCase(Format('Reading derived observations from "%s"', [FFileLink.FileName])));
    FListingFile.Add('');
    FListingFile.Add(UpperCase('Derived_Observation_Name, Formula, Observed_Value, Weight, Print'));
  end
  else
  begin
    Exit;
  end;
  Splitter := TStringList.Create;
  try
    Splitter.Delimiter := ' ';
    While FLineIndex < FInputFile.Count do
    begin
      ALine := Trim(FInputFile[FLineIndex]);
      Inc(FLineIndex);
      if (ALine = '') or (ALine[1] = '#') then
      begin
        if Length(ALine) > 0 then
        begin
          FListingFile.Add(ALine);
        end;
        Continue;
      end;

      Splitter.DelimitedText := ALine;
      if (Splitter.Count = 2)
        and (UpperCase(Splitter[0]) = 'END')
        and (UpperCase(Splitter[1]) = rsDERIVED_OBSE)
        then
      begin
        FListingFile.Add('END READING DERIVED OBSERVATIONS');
        Exit;
      end
      else if (Splitter.Count in [6,7]) and
        (UpperCase(Splitter[0]) = 'DIFFERENCE')
        then
      begin
        ObsName := Splitter[1];
        Obs := TCustomWeightedObsValue.Create;
        Obs.ObsName := ObsName;
        try
          FObsDictionary.Add(UpperCase(Obs.ObsName), Obs);
        except on E: Exception do
          begin
            FListingFile.Add(E.Message);
            ErrorMessage := Format(rsOnLine0D1SIs,
              [FLineIndex, FFileLink.FileName, Obs.ObsName]);
            FListingFile.Add(ErrorMessage);
            Raise Exception.Create(ErrorMessage);
          end;
        end;
        if (Splitter.Count = 7) then
        begin
          if (UpperCase(Splitter[6]) = 'PRINT') then
          begin
            Obs.Print := True;
          end
          else if (UpperCase(Splitter[6]) = 'NO_PRINT') then
          begin
            Obs.Print := False;
          end
          else
          begin
            Assert(False);
          end;
        end
        else
        begin
          Obs.Print := True;
        end;
        FObsList.Add(Obs);
        Obs.SimulatedValue := MissingValue;
        FirstName := Splitter[2];
        SecondName := Splitter[3];
        Obs.ObservedValue := FortranStrToFloat(Splitter[4]);
        Obs.Weight := FortranStrToFloat(Splitter[5]);
        if Obs.Print then
        begin
        FListingFile.Add(Format('%0:s, %1:s - %2:s, %3:g, %4:g, PRINT',
          [Obs.ObsName, FirstName, SecondName, Obs.ObservedValue, Obs.Weight]));
        end
        else
        begin
          FListingFile.Add(Format('%0:s, %1:s - %2:s, %3:g, %4:g, NO_PRINT',
            [Obs.ObsName, FirstName, SecondName, Obs.ObservedValue, Obs.Weight]));
        end;
        if not FObsDictionary.TryGetValue(UpperCase(FirstName), FirstValue) then
        begin
          FirstValue := nil;
          FListingFile.Add(Format(rsERRORSNotFou, [FirstName]));
        end;
        if not FObsDictionary.TryGetValue(UpperCase(SecondName), SecondValue) then
        begin
          SecondValue := nil;
          FListingFile.Add(Format(rsERRORSNotFou, [FirstName]));
        end;
        if (FirstValue <> nil) and (SecondValue <> nil) then
        begin
          if (FirstValue.SimulatedValue <> MissingValue)
            or (SecondValue.SimulatedValue <> MissingValue) then
          begin
            Obs.SimulatedValue :=
              FirstValue.SimulatedValue - SecondValue.SimulatedValue;
          end;
        end;
      end
      else if (Splitter.Count >= 6) and
        (UpperCase(Splitter[0]) = 'SUM')
        then
      begin
        ObsName := Splitter[1];
        Obs := TCustomWeightedObsValue.Create;
        Obs.ObsName := ObsName;
        try
          FObsDictionary.Add(UpperCase(Obs.ObsName), Obs);
        except on E: Exception do
          begin
            FListingFile.Add(E.Message);
            ErrorMessage := Format(rsOnLine0D1SIs, [FLineIndex, FFileLink.FileName, Obs.ObsName]);
            FListingFile.Add(ErrorMessage);
            Raise Exception.Create(ErrorMessage);
          end;
        end;
        if (UpperCase(Splitter[Splitter.Count-1]) = 'PRINT') then
        begin
          Obs.Print := True;
          LastNumber := Splitter.Count-2;
        end
        else if (UpperCase(Splitter[Splitter.Count-1]) = 'NO_PRINT') then
        begin
          Obs.Print := False;
          LastNumber := Splitter.Count-2;
        end
        else
        begin
          Obs.Print := True;
          LastNumber := Splitter.Count-1;
        end;
        LastNumber := LastNumber -2;
        FObsList.Add(Obs);
        Obs.SimulatedValue := MissingValue;
        Obs.ObservedValue := FortranStrToFloat(Splitter[LastNumber+1]);
        Obs.Weight := FortranStrToFloat(Splitter[LastNumber+2]);

        ListingLine := Format('%0:s, ', [Obs.ObsName]);

        Names := TStringList.Create;
        try
          for NameIndex := 2 to LastNumber do
          begin
            Names.Add(Splitter[NameIndex]);
            ListingLine := Format('%0:s %1:s +', [ListingLine, Splitter[NameIndex]])
          end;
          ListingLine := Copy(ListingLine, 1, Length(ListingLine)-2);

          if Obs.Print then
          begin
            ListingLine := Format('%0:s, %1:g, %2:g, PRINT',
              [ListingLine, Obs.ObservedValue, Obs.Weight]);
          end
          else
          begin
            ListingLine := Format('%0:s, %1:g, %2:g, NO_PRINT',
              [ListingLine, Obs.ObservedValue, Obs.Weight]);
          end;
          FListingFile.Add(ListingLine);

          FirstName := Names[0];

          if not FObsDictionary.TryGetValue(UpperCase(FirstName), FirstValue) then
          begin
            FirstValue := nil;
            ErrorMessage := Format(rsERRORSNotFou, [FirstName]);
            FListingFile.Add(ErrorMessage);
            raise Exception.Create(ErrorMessage);
          end;
          Obs.SimulatedValue := FirstValue.SimulatedValue;

          for NameIndex := 1 to Pred(Names.Count) do
          begin
            FirstName := Names[NameIndex];
            if not FObsDictionary.TryGetValue(UpperCase(FirstName), FirstValue) then
            begin
              FirstValue := nil;
              ErrorMessage := Format(rsERRORSNotFou, [FirstName]);
              FListingFile.Add(ErrorMessage);
              raise Exception.Create(ErrorMessage);
            end;
            Obs.SimulatedValue := Obs.SimulatedValue +
              FirstValue.SimulatedValue;
          end;

        finally
          Names.Free;
        end;
      end
      else
      begin
        Assert(False);
      end;
    end;

  finally
    Splitter.Free;
  end;
end;

procedure TObsProcessor.WriteFiles;
var
  Index: Integer;
  Obs: TCustomWeightedObsValue;
  ObsPrinted: Boolean;
begin
  Assert(FObsList.Count > 0, 'No observations specified');
  ObsPrinted := False;
  FListingFile.Add('');
  FListingFile.Add('Observation_Name, Simulated_Value, Observed_Value, Weight');
  if not FGenerateInstructionFile and (FObservationsFile.Count = 0) then
  begin
    FObservationsFile.Add('Observation_Name, Simulated_Value, Observed_Value, Weight');
  end;
  for Index := 0 to Pred(FObsList.Count) do
  begin
    Obs := FObsList[Index];
    if Obs.Print then
    begin
      ObsPrinted := True;
      if FGenerateInstructionFile then
      begin
        FObservationsFile.Add(Format('l1 @"%0:s",@ w !%0:s! @,@', [Obs.ObsName]));
      end
      else
      begin
        FObservationsFile.Add(
          Format('"%0:s", %1:g, %2:g, %3:g', [Obs.ObsName, Obs.SimulatedValue, Obs.ObservedValue, Obs.Weight]));
      end;
    end;
    if FGenerateInstructionFile then
    begin
      FListingFile.Add(Format('l1 @"%0:s",@ w !%0:s! @,@', [Obs.ObsName]));
    end
    else
    begin
      FListingFile.Add(
        Format('"%0:s", %1:g, %2:g, %3:g', [Obs.ObsName, Obs.SimulatedValue, Obs.ObservedValue, Obs.Weight]));
    end;
  end;
  FListingFile.Add('');
  Assert(ObsPrinted, 'No observations printed');
end;

constructor TObsProcessor.Create(FileLink: TInputFileLink;
  GenerateInstructionFile: Boolean);
begin
  FFileLink := FileLink;
  FGenerateInstructionFile := GenerateInstructionFile;
  FObsList := TCustomWeightedObsValueObjectList.Create;
end;

destructor TObsProcessor.Destroy;
begin
  FObsList.Free;
  FInputFile.Free;
  inherited Destroy;
end;

procedure TObsProcessor.ProcessInstructionFile;
var
  ALine: string;
  ObservationsFound: Boolean;
  ErrorMessage: string;
  InstructionFileName: string;
  Splitter: TStringList;
  StartIndex: Integer;
  ObsName: string;
  SimulatedValue: double;
  ObservedValue: double;
  Obs: TCustomWeightedObsValue;
  PrintString: string;
  LineIndex: integer;
  ObsTypeID: string;
begin
  Assert(ListingFile <> nil, 'programming error');
  Assert(ObservationsFile <> nil, 'programming error');
  Assert(ObsDictionary <> nil, 'programming error');

  InstructionFileName := FFileLink.FileName;
  ObservationsFound := False;
  FInputFile := TStringList.Create;
  try
    FInputFile.LoadFromFile(InstructionFileName);
    if FFileLink.FileType in [iftHOB, iftFlow] then
    begin
      Splitter := TStringList.Create;
      try
        if FFileLink.FileType = iftHOB then
        begin
          StartIndex :=1;
          FListingFile.Add(Format('Reading HOB output file "%s".',
            [InstructionFileName]));
          ObsTypeID := 'HOB';
        end
        else
        begin
          StartIndex := 0;
          FListingFile.Add(Format('Reading flow observation output file "%s".', [InstructionFileName]));
          ObsTypeID := 'Flow Observation';
        end;
        for LineIndex := StartIndex to Pred(FInputFile.Count) do
        begin
          ALine := FInputFile[LineIndex];
          if ALine <> '' then
          begin
            Splitter.DelimitedText := ALine;
            Assert(Splitter.Count = 3, Format('Error reading %0:d in "%1:s".',
              [LineIndex+1, InstructionFileName]));
            ObsName := Splitter[2];
            SimulatedValue := FortranStrToFloat(Splitter[0]);
            try
              ObservedValue := FortranStrToFloat(Splitter[1]);
            except on EConvertError do
              ObservedValue := 1E9;
            end;
            Obs := TCustomWeightedObsValue.Create;
            FObsList.Add(Obs);
            Obs.ObsName := ObsName;
            Obs.ObsTime := 0;
            Obs.SimulatedValue := SimulatedValue;
            Obs.ObservedValue := ObservedValue;
            Obs.Weight := 1;
            Obs.Print := True;
            if not FGenerateInstructionFile then
            begin
              //ObsExtractor.AddObs(Obs);
            end;

            try
              FObsDictionary.Add(UpperCase(Obs.ObsName), Obs);
            except on E: Exception do
              begin
                FListingFile.Add(E.Message);
                ErrorMessage := Format(rsOnLine0D1SIs, [FLineIndex, FFileLink.FileName, Obs.ObsName]);
                FListingFile.Add(ErrorMessage);
                Raise Exception.Create(ErrorMessage);
              end;
            end;
            PrintString := 'Print';

            FListingFile.Add(Format('%0:s, %1:s, %2:g, %3:g, %4:g %5:s,',
              [Obs.ObsName, ObsTypeID, Obs.ObsTime, Obs.ObservedValue,
              Obs.Weight, PrintString]));

          end;
        end;
        Exit;
      finally
        Splitter.Free;
      end;
    end
    else
    begin
      FLineIndex := 0;
      While FLineIndex < FInputFile.Count do
      begin
        ALine := Trim(FInputFile[FLineIndex]);
        Inc(FLineIndex);
        if (ALine = '') or (ALine[1] = '#') then
        begin
          if Length(ALine) > 0 then
          begin
            FListingFile.Add(ALine);
          end;
          Continue;
        end;
        ALine := UpperCase(ALine);
        if Pos('BEGIN', ALine) = 1 then
        begin
          ALine := Trim(Copy(ALine, 7, MAXINT));
          if ALine = 'OBSERVATIONS' then
          begin
            Assert(not ObservationsFound);
            FListingFile.Add('');
            FListingFile.Add(UpperCase('Reading observations'));
            HandleSimpleObservations;
            ObservationsFound := True;
          end
          else if ALine = rsDERIVED_OBSE then
          begin
            Exit;
          end;
        end
        else
        begin
          Assert(False);
        end;
      end;
    end;
    Assert(ObservationsFound, 'No observations were specified');
  except on E: Exception do
    begin
      Writeln(E.message);
      FListingFile.Add(E.message);

      ErrorMessage := Format('Error processing line %0:d of %1:s',
        [FLineIndex, InstructionFileName]);
      Writeln(ErrorMessage);
      FListingFile.Add(ErrorMessage);
      if (FLineIndex > 0) and (FLineIndex <= FInputFile.Count) then
      begin
        FListingFile.Add(FInputFile[FLineIndex-1]);
      end;
    end;
  end;
end;

end.

