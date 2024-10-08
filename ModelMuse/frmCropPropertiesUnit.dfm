inherited frmCropProperties: TfrmCropProperties
  HelpType = htKeyword
  HelpKeyword = 'Farm_Crop_Properties_Dialog_Bo'
  Caption = 'Farm Land Use Properties'
  ClientHeight = 520
  ClientWidth = 858
  ExplicitWidth = 874
  ExplicitHeight = 559
  TextHeight = 18
  object splitterMain: TJvNetscapeSplitter
    Left = 285
    Top = 0
    Height = 476
    Align = alLeft
    Maximized = False
    Minimized = False
    ButtonCursor = crDefault
    ExplicitLeft = 280
    ExplicitTop = 136
    ExplicitHeight = 100
  end
  object jvpltvMain: TJvPageListTreeView
    Left = 0
    Top = 0
    Width = 285
    Height = 476
    ShowButtons = True
    PageDefault = 0
    PageList = jplMain
    Align = alLeft
    HideSelection = False
    Indent = 19
    TabOrder = 0
    OnChange = jvpltvMainChange
    OnChanging = jvpltvMainChanging
    OnCustomDrawItem = jvpltvMainCustomDrawItem
    Items.Links = {00000000}
  end
  object jplMain: TJvPageList
    Left = 295
    Top = 0
    Width = 563
    Height = 476
    ActivePage = jvspBoolCollection
    PropagateEnable = False
    Align = alClient
    OnChange = jplMainChange
    object jvspCropName: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      HelpType = htKeyword
      HelpKeyword = 'Crops_Pane'
      Caption = 'jvspCropName'
      inline frameCropName: TframeFormulaGrid
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 563
        ExplicitHeight = 476
        inherited Panel: TPanel
          Top = 435
          Width = 563
          ExplicitTop = 435
          ExplicitWidth = 563
          inherited lbNumber: TLabel
            Top = 6
            Width = 115
            Height = 18
            Caption = 'Number of crops'
            ExplicitTop = 6
            ExplicitWidth = 115
            ExplicitHeight = 18
          end
          inherited sbAdd: TSpeedButton
            Left = 270
            OnClick = frameCropNamesbAddClick
            ExplicitLeft = 148
          end
          inherited sbInsert: TSpeedButton
            Left = 320
            OnClick = frameCropNamesbInsertClick
            ExplicitLeft = 176
          end
          inherited sbDelete: TSpeedButton
            Left = 367
            OnClick = frameCropNamesbDeleteClick
            ExplicitLeft = 204
          end
          inherited seNumber: TJvSpinEdit
            Height = 26
            OnChange = frameCropNameseNumberChange
            ExplicitHeight = 26
          end
        end
        inherited Grid: TRbwDataGrid4
          Width = 563
          Height = 378
          OnSelectCell = frameCropNameGridSelectCell
          OnSetEditText = frameCropNameGridSetEditText
          OnBeforeDrawCell = frameCropNameGridBeforeDrawCell
          OnButtonClick = GridButtonClick
          OnStateChange = frameCropNameGridStateChange
          ExplicitWidth = 563
          ExplicitHeight = 378
        end
        inherited pnlTop: TPanel
          Width = 563
          ExplicitWidth = 563
          inherited edFormula: TLabeledEdit
            Height = 26
            EditLabel.Width = 57
            EditLabel.Height = 18
            EditLabel.ExplicitLeft = 128
            EditLabel.ExplicitTop = 9
            EditLabel.ExplicitHeight = 18
            ExplicitHeight = 26
          end
          inherited comboChoice: TComboBox
            Height = 26
            ExplicitHeight = 26
          end
        end
      end
    end
    object jvspEvapFractions: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      HelpType = htKeyword
      HelpKeyword = 'Consumptive_Use_Factors_Pane'
      Caption = 'jvspEvapFractions'
      inline frameEvapFractions: TframeFormulaGrid
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 563
        ExplicitHeight = 476
        inherited Panel: TPanel
          Top = 435
          Width = 563
          ExplicitTop = 435
          ExplicitWidth = 563
          inherited lbNumber: TLabel
            Width = 55
            Height = 18
            ExplicitWidth = 55
            ExplicitHeight = 18
          end
          inherited sbAdd: TSpeedButton
            Left = 269
            ExplicitLeft = 148
          end
          inherited sbInsert: TSpeedButton
            Left = 319
            ExplicitLeft = 176
          end
          inherited sbDelete: TSpeedButton
            Left = 364
            ExplicitLeft = 204
          end
          inherited seNumber: TJvSpinEdit
            Height = 26
            ExplicitHeight = 26
          end
        end
        inherited Grid: TRbwDataGrid4
          Width = 563
          Height = 378
          OnSetEditText = GridSetEditText
          OnButtonClick = GridButtonClick
          OnEndUpdate = frameEvapFractionsGridEndUpdate
          ExplicitWidth = 563
          ExplicitHeight = 378
        end
        inherited pnlTop: TPanel
          Width = 563
          ExplicitWidth = 563
          inherited edFormula: TLabeledEdit
            Height = 26
            EditLabel.Width = 57
            EditLabel.Height = 18
            EditLabel.ExplicitLeft = 128
            EditLabel.ExplicitTop = 9
            EditLabel.ExplicitHeight = 18
            ExplicitHeight = 26
          end
          inherited comboChoice: TComboBox
            Height = 26
            ExplicitHeight = 26
          end
        end
      end
    end
    object jvspLosses: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      HelpType = htKeyword
      HelpKeyword = 'Inefficiency_Losses_to_Surface'
      Caption = 'jvspLosses'
      inline frameLosses: TframeFormulaGrid
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 563
        ExplicitHeight = 476
        inherited Panel: TPanel
          Top = 435
          Width = 563
          ExplicitTop = 435
          ExplicitWidth = 563
          inherited lbNumber: TLabel
            Width = 55
            Height = 18
            ExplicitWidth = 55
            ExplicitHeight = 18
          end
          inherited sbAdd: TSpeedButton
            Left = 270
            ExplicitLeft = 148
          end
          inherited sbInsert: TSpeedButton
            Left = 321
            ExplicitLeft = 176
          end
          inherited sbDelete: TSpeedButton
            Left = 367
            ExplicitLeft = 204
          end
          inherited seNumber: TJvSpinEdit
            Height = 26
            ExplicitHeight = 26
          end
        end
        inherited Grid: TRbwDataGrid4
          Width = 563
          Height = 378
          OnSetEditText = GridSetEditText
          OnButtonClick = GridButtonClick
          OnEndUpdate = frameLossesGridEndUpdate
          ExplicitWidth = 563
          ExplicitHeight = 378
        end
        inherited pnlTop: TPanel
          Width = 563
          ExplicitWidth = 563
          inherited edFormula: TLabeledEdit
            Height = 26
            EditLabel.Width = 57
            EditLabel.Height = 18
            EditLabel.ExplicitLeft = 128
            EditLabel.ExplicitTop = 9
            EditLabel.ExplicitHeight = 18
            ExplicitHeight = 26
          end
          inherited comboChoice: TComboBox
            Height = 26
            ExplicitHeight = 26
          end
        end
      end
    end
    object jvspCropFunction: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      HelpType = htKeyword
      HelpKeyword = 'Crop_Price_Function_Pane'
      Caption = 'jvspCropFunction'
      inline frameCropFunction: TframeFormulaGrid
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 563
        ExplicitHeight = 476
        inherited Panel: TPanel
          Top = 435
          Width = 563
          ExplicitTop = 435
          ExplicitWidth = 563
          inherited lbNumber: TLabel
            Width = 55
            Height = 18
            ExplicitWidth = 55
            ExplicitHeight = 18
          end
          inherited sbAdd: TSpeedButton
            Left = 270
            ExplicitLeft = 148
          end
          inherited sbInsert: TSpeedButton
            Left = 321
            ExplicitLeft = 176
          end
          inherited sbDelete: TSpeedButton
            Left = 367
            ExplicitLeft = 204
          end
          inherited seNumber: TJvSpinEdit
            Height = 26
            ExplicitHeight = 26
          end
        end
        inherited Grid: TRbwDataGrid4
          Width = 563
          Height = 378
          OnSetEditText = GridSetEditText
          OnButtonClick = GridButtonClick
          OnEndUpdate = frameCropFunctionGridEndUpdate
          ExplicitWidth = 563
          ExplicitHeight = 378
        end
        inherited pnlTop: TPanel
          Width = 563
          ExplicitWidth = 563
          inherited edFormula: TLabeledEdit
            Height = 26
            EditLabel.Width = 57
            EditLabel.Height = 18
            EditLabel.ExplicitLeft = 128
            EditLabel.ExplicitTop = 9
            EditLabel.ExplicitHeight = 18
            ExplicitHeight = 26
          end
          inherited comboChoice: TComboBox
            Height = 26
            ExplicitHeight = 26
          end
        end
      end
    end
    object jvspCropWaterUse: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      HelpType = htKeyword
      HelpKeyword = 'Consumptive_Use_Flux_or_Crop_C'
      Caption = 'jvspCropWaterUse'
      inline frameCropWaterUse: TframeFormulaGrid
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 563
        ExplicitHeight = 476
        inherited Panel: TPanel
          Top = 435
          Width = 563
          ExplicitTop = 435
          ExplicitWidth = 563
          inherited lbNumber: TLabel
            Width = 55
            Height = 18
            ExplicitWidth = 55
            ExplicitHeight = 18
          end
          inherited sbAdd: TSpeedButton
            Left = 270
            ExplicitLeft = 148
          end
          inherited sbInsert: TSpeedButton
            Left = 321
            ExplicitLeft = 176
          end
          inherited sbDelete: TSpeedButton
            Left = 367
            ExplicitLeft = 204
          end
          inherited seNumber: TJvSpinEdit
            Height = 26
            ExplicitHeight = 26
          end
        end
        inherited Grid: TRbwDataGrid4
          Width = 563
          Height = 378
          OnSetEditText = GridSetEditText
          OnBeforeDrawCell = frameCropWaterUseGridBeforeDrawCell
          OnButtonClick = GridButtonClick
          OnEndUpdate = frameCropWaterUseGridEndUpdate
          ExplicitWidth = 563
          ExplicitHeight = 378
        end
        inherited pnlTop: TPanel
          Width = 563
          ExplicitWidth = 563
          inherited edFormula: TLabeledEdit
            Height = 26
            EditLabel.Width = 57
            EditLabel.Height = 18
            EditLabel.ExplicitLeft = 128
            EditLabel.ExplicitTop = 9
            EditLabel.ExplicitHeight = 18
            ExplicitHeight = 26
          end
          inherited comboChoice: TComboBox
            Height = 26
            ExplicitHeight = 26
          end
        end
      end
    end
    object jvspIrrigation: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      Caption = 'jvspIrrigation'
      inline frameIrrigation: TframeFormulaGrid
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 563
        ExplicitHeight = 476
        inherited Panel: TPanel
          Top = 435
          Width = 563
          ExplicitTop = 435
          ExplicitWidth = 563
          inherited lbNumber: TLabel
            Width = 55
            Height = 18
            ExplicitWidth = 55
            ExplicitHeight = 18
          end
          inherited sbAdd: TSpeedButton
            Left = 269
            ExplicitLeft = 232
          end
          inherited sbInsert: TSpeedButton
            Left = 319
            ExplicitLeft = 275
          end
          inherited sbDelete: TSpeedButton
            Left = 366
            ExplicitLeft = 318
          end
          inherited seNumber: TJvSpinEdit
            Height = 26
            ExplicitHeight = 26
          end
        end
        inherited Grid: TRbwDataGrid4
          Width = 563
          Height = 378
          OnSelectCell = frameIrrigationGridSelectCell
          OnSetEditText = GridSetEditText
          OnButtonClick = GridButtonClick
          OnEndUpdate = frameIrrigationGridEndUpdate
          ExplicitWidth = 563
          ExplicitHeight = 378
        end
        inherited pnlTop: TPanel
          Width = 563
          ExplicitWidth = 563
          inherited edFormula: TLabeledEdit
            Height = 26
            EditLabel.Width = 57
            EditLabel.Height = 18
            EditLabel.ExplicitLeft = 128
            EditLabel.ExplicitTop = 9
            EditLabel.ExplicitHeight = 18
            ExplicitHeight = 26
          end
          inherited comboChoice: TComboBox
            Height = 26
            ExplicitHeight = 26
          end
        end
      end
    end
    object jvspOwhmCollection: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      Caption = 'jvspOwhmCollection'
      inline frameOwhmCollection: TframeFormulaGrid
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 563
        ExplicitHeight = 476
        inherited Panel: TPanel
          Top = 435
          Width = 563
          ExplicitTop = 435
          ExplicitWidth = 563
          inherited lbNumber: TLabel
            Width = 55
            Height = 18
            ExplicitWidth = 55
            ExplicitHeight = 18
          end
          inherited sbAdd: TSpeedButton
            Left = 273
            ExplicitLeft = 265
          end
          inherited sbInsert: TSpeedButton
            Left = 325
            ExplicitLeft = 314
          end
          inherited sbDelete: TSpeedButton
            Left = 369
            ExplicitLeft = 362
          end
          inherited seNumber: TJvSpinEdit
            Height = 26
            ExplicitHeight = 26
          end
        end
        inherited Grid: TRbwDataGrid4
          Width = 563
          Height = 378
          ColCount = 3
          OnSetEditText = GridSetEditText
          OnButtonClick = GridButtonClick
          OnEndUpdate = frameLandUseFractionGridEndUpdate
          Columns = <
            item
              AutoAdjustRowHeights = True
              AutoAdjustCaptionRowHeights = False
              ButtonCaption = '...'
              ButtonFont.Charset = DEFAULT_CHARSET
              ButtonFont.Color = clWindowText
              ButtonFont.Height = -11
              ButtonFont.Name = 'Tahoma'
              ButtonFont.Style = []
              ButtonUsed = False
              ButtonWidth = 20
              CheckMax = False
              CheckMin = False
              ComboUsed = False
              Format = rcf4String
              LimitToList = False
              MaxLength = 0
              ParentButtonFont = False
              WordWrapCaptions = True
              WordWrapCells = False
              CaseSensitivePicklist = False
              CheckStyle = csCheck
              AutoAdjustColWidths = True
            end
            item
              AutoAdjustRowHeights = True
              AutoAdjustCaptionRowHeights = False
              ButtonCaption = '...'
              ButtonFont.Charset = DEFAULT_CHARSET
              ButtonFont.Color = clWindowText
              ButtonFont.Height = -12
              ButtonFont.Name = 'Segoe UI'
              ButtonFont.Style = []
              ButtonUsed = False
              ButtonWidth = 20
              CheckMax = False
              CheckMin = False
              ComboUsed = False
              Format = rcf4String
              LimitToList = False
              MaxLength = 0
              ParentButtonFont = False
              WordWrapCaptions = True
              WordWrapCells = False
              CaseSensitivePicklist = False
              CheckStyle = csCheck
              AutoAdjustColWidths = True
            end
            item
              AutoAdjustRowHeights = True
              AutoAdjustCaptionRowHeights = False
              ButtonCaption = '...'
              ButtonFont.Charset = DEFAULT_CHARSET
              ButtonFont.Color = clWindowText
              ButtonFont.Height = -12
              ButtonFont.Name = 'Segoe UI'
              ButtonFont.Style = []
              ButtonUsed = False
              ButtonWidth = 20
              CheckMax = False
              CheckMin = False
              ComboUsed = False
              Format = rcf4String
              LimitToList = False
              MaxLength = 0
              ParentButtonFont = False
              WordWrapCaptions = True
              WordWrapCells = False
              CaseSensitivePicklist = False
              CheckStyle = csCheck
              AutoAdjustColWidths = True
            end>
          ExplicitWidth = 563
          ExplicitHeight = 378
        end
        inherited pnlTop: TPanel
          Width = 563
          ExplicitWidth = 563
          inherited edFormula: TLabeledEdit
            Height = 26
            EditLabel.Width = 57
            EditLabel.Height = 18
            EditLabel.ExplicitLeft = 128
            EditLabel.ExplicitTop = 9
            EditLabel.ExplicitHeight = 18
            ExplicitHeight = 26
          end
          inherited comboChoice: TComboBox
            Height = 26
            ExplicitHeight = 26
          end
        end
      end
    end
    object jvspRootPressure: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      Caption = 'jvspRootPressure'
      inline frameRootPressure: TframeFormulaGrid
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 563
        ExplicitHeight = 476
        inherited Panel: TPanel
          Top = 435
          Width = 563
          ExplicitTop = 435
          ExplicitWidth = 563
          inherited lbNumber: TLabel
            Width = 55
            Height = 18
            ExplicitWidth = 55
            ExplicitHeight = 18
          end
          inherited sbAdd: TSpeedButton
            Left = 275
            ExplicitLeft = 265
          end
          inherited sbInsert: TSpeedButton
            Left = 325
            ExplicitLeft = 314
          end
          inherited sbDelete: TSpeedButton
            Left = 374
            ExplicitLeft = 362
          end
          inherited seNumber: TJvSpinEdit
            Height = 26
            ExplicitHeight = 26
          end
        end
        inherited Grid: TRbwDataGrid4
          Width = 563
          Height = 378
          OnSelectCell = frameRootPressureGridSelectCell
          OnSetEditText = GridSetEditText
          OnButtonClick = GridButtonClick
          OnEndUpdate = frameRootPressureGridEndUpdate
          ExplicitWidth = 563
          ExplicitHeight = 378
        end
        inherited pnlTop: TPanel
          Width = 563
          ExplicitWidth = 563
          inherited edFormula: TLabeledEdit
            Height = 26
            EditLabel.Width = 57
            EditLabel.Height = 18
            EditLabel.ExplicitLeft = 128
            EditLabel.ExplicitTop = 9
            EditLabel.ExplicitHeight = 18
            ExplicitHeight = 26
          end
          inherited comboChoice: TComboBox
            Height = 26
            ExplicitHeight = 26
          end
        end
      end
    end
    object jvspGwRootInteraction: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      HelpType = htKeyword
      HelpKeyword = 'Groundwater-Root-Interaction-P'
      Caption = 'jvspGwRootInteraction'
      OnShow = jvspGwRootInteractionShow
      object rdgGwRootInteraction: TRbwDataGrid4
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        ColCount = 1
        DefaultColWidth = 500
        FixedCols = 0
        RowCount = 4
        FixedRows = 0
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goColSizing, goEditing, goAlwaysShowEditor]
        TabOrder = 0
        OnExit = rdgGwRootInteractionExit
        ExtendedAutoDistributeText = False
        AutoMultiEdit = False
        AutoDistributeText = False
        AutoIncreaseColCount = False
        AutoIncreaseRowCount = False
        SelectedRowOrColumnColor = clAqua
        UnselectableColor = clBtnFace
        OnStateChange = rdgGwRootInteractionStateChange
        ColorRangeSelection = False
        ColorSelectedRow = False
        Columns = <
          item
            AutoAdjustRowHeights = False
            AutoAdjustCaptionRowHeights = False
            ButtonCaption = '...'
            ButtonFont.Charset = DEFAULT_CHARSET
            ButtonFont.Color = clWindowText
            ButtonFont.Height = -12
            ButtonFont.Name = 'Segoe UI'
            ButtonFont.Style = []
            ButtonUsed = False
            ButtonWidth = 20
            CheckMax = False
            CheckMin = False
            ComboUsed = False
            Format = rcf4Boolean
            LimitToList = False
            MaxLength = 0
            ParentButtonFont = False
            WordWrapCaptions = False
            WordWrapCells = False
            CaseSensitivePicklist = False
            CheckStyle = csCheck
            AutoAdjustColWidths = False
          end>
        WordWrapRowCaptions = False
      end
    end
    object jvspAddedDemand: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      HelpType = htKeyword
      HelpKeyword = 'Added-Demand-Pane'
      Caption = 'jvspAddedDemand'
      inline frameAddedDemand: TframeFormulaGrid
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 563
        ExplicitHeight = 476
        inherited Panel: TPanel
          Top = 435
          Width = 563
          ExplicitTop = 435
          ExplicitWidth = 563
          inherited lbNumber: TLabel
            Width = 55
            Height = 18
            ExplicitWidth = 55
            ExplicitHeight = 18
          end
          inherited sbAdd: TSpeedButton
            Left = 278
            ExplicitLeft = 265
          end
          inherited sbInsert: TSpeedButton
            Left = 330
            ExplicitLeft = 314
          end
          inherited sbDelete: TSpeedButton
            Left = 377
            ExplicitLeft = 362
          end
          inherited seNumber: TJvSpinEdit
            Height = 26
            ExplicitHeight = 26
          end
        end
        inherited Grid: TRbwDataGrid4
          Width = 563
          Height = 378
          OnSetEditText = GridSetEditText
          OnButtonClick = GridButtonClick
          OnEndUpdate = frameAddedDemandGridEndUpdate
          ExplicitWidth = 563
          ExplicitHeight = 378
        end
        inherited pnlTop: TPanel
          Width = 563
          ExplicitWidth = 563
          inherited edFormula: TLabeledEdit
            Height = 26
            EditLabel.Width = 57
            EditLabel.Height = 18
            EditLabel.ExplicitLeft = 128
            EditLabel.ExplicitTop = 9
            EditLabel.ExplicitHeight = 18
            ExplicitHeight = 26
          end
          inherited comboChoice: TComboBox
            Height = 26
            ExplicitHeight = 26
          end
        end
      end
    end
    object jvspLeach: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      Caption = 'jvspLeach'
      inline frameLeach: TframeLeach
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 563
        ExplicitHeight = 476
        inherited Panel: TPanel
          Top = 435
          Width = 563
          ExplicitTop = 435
          ExplicitWidth = 563
          inherited lbNumber: TLabel
            Width = 55
            Height = 18
            ExplicitWidth = 55
            ExplicitHeight = 18
          end
          inherited sbAdd: TSpeedButton
            Left = 278
            ExplicitLeft = 265
          end
          inherited sbInsert: TSpeedButton
            Left = 330
            ExplicitLeft = 314
          end
          inherited sbDelete: TSpeedButton
            Left = 376
            ExplicitLeft = 362
          end
          inherited seNumber: TJvSpinEdit
            Height = 26
            ExplicitHeight = 26
          end
        end
        inherited Grid: TRbwDataGrid4
          Width = 563
          Height = 378
          OnSetEditText = GridSetEditText
          OnButtonClick = frameLeachGridButtonClick
          OnEndUpdate = frameLeachGridEndUpdate
          Columns = <
            item
              AutoAdjustRowHeights = False
              AutoAdjustCaptionRowHeights = True
              ButtonCaption = '...'
              ButtonFont.Charset = ANSI_CHARSET
              ButtonFont.Color = clBlack
              ButtonFont.Height = -16
              ButtonFont.Name = 'Arial'
              ButtonFont.Pitch = fpVariable
              ButtonFont.Style = []
              ButtonUsed = False
              ButtonWidth = 20
              CheckMax = False
              CheckMin = False
              ComboUsed = True
              Format = rcf4Real
              LimitToList = False
              MaxLength = 0
              ParentButtonFont = False
              WordWrapCaptions = True
              WordWrapCells = False
              CaseSensitivePicklist = False
              CheckStyle = csCheck
              AutoAdjustColWidths = True
            end
            item
              AutoAdjustRowHeights = False
              AutoAdjustCaptionRowHeights = True
              ButtonCaption = '...'
              ButtonFont.Charset = ANSI_CHARSET
              ButtonFont.Color = clBlack
              ButtonFont.Height = -16
              ButtonFont.Name = 'Arial'
              ButtonFont.Pitch = fpVariable
              ButtonFont.Style = []
              ButtonUsed = False
              ButtonWidth = 20
              CheckMax = False
              CheckMin = False
              ComboUsed = True
              Format = rcf4Real
              LimitToList = False
              MaxLength = 0
              ParentButtonFont = False
              WordWrapCaptions = True
              WordWrapCells = False
              CaseSensitivePicklist = False
              CheckStyle = csCheck
              AutoAdjustColWidths = True
            end
            item
              AutoAdjustRowHeights = False
              AutoAdjustCaptionRowHeights = True
              ButtonCaption = '...'
              ButtonFont.Charset = ANSI_CHARSET
              ButtonFont.Color = clBlack
              ButtonFont.Height = -16
              ButtonFont.Name = 'Arial'
              ButtonFont.Pitch = fpVariable
              ButtonFont.Style = []
              ButtonUsed = False
              ButtonWidth = 20
              CheckMax = False
              CheckMin = False
              ComboUsed = True
              Format = rcf4String
              LimitToList = True
              MaxLength = 0
              ParentButtonFont = False
              PickList.Strings = (
                'Value'
                'Rhoades'
                'None'
                'Custom FMP Formula')
              WordWrapCaptions = True
              WordWrapCells = False
              CaseSensitivePicklist = False
              CheckStyle = csCheck
              AutoAdjustColWidths = True
            end
            item
              AutoAdjustRowHeights = False
              AutoAdjustCaptionRowHeights = True
              ButtonCaption = 'F()'
              ButtonFont.Charset = ANSI_CHARSET
              ButtonFont.Color = clBlack
              ButtonFont.Height = -16
              ButtonFont.Name = 'Arial'
              ButtonFont.Pitch = fpVariable
              ButtonFont.Style = []
              ButtonUsed = True
              ButtonWidth = 35
              CheckMax = False
              CheckMin = False
              ComboUsed = False
              Format = rcf4String
              LimitToList = False
              MaxLength = 0
              ParentButtonFont = False
              WordWrapCaptions = True
              WordWrapCells = False
              CaseSensitivePicklist = False
              CheckStyle = csCheck
              AutoAdjustColWidths = True
            end>
          ExplicitWidth = 563
          ExplicitHeight = 378
          ColWidths = (
            64
            64
            138
            224)
        end
        inherited pnlTop: TPanel
          Width = 563
          ExplicitWidth = 563
          inherited edFormula: TLabeledEdit
            Height = 26
            EditLabel.Width = 57
            EditLabel.Height = 18
            EditLabel.ExplicitLeft = 128
            EditLabel.ExplicitTop = 9
            EditLabel.ExplicitHeight = 18
            ExplicitHeight = 26
          end
          inherited comboChoice: TComboBox
            Height = 26
            ExplicitHeight = 26
          end
        end
      end
    end
    object jvspBoolCollection: TJvStandardPage
      Left = 0
      Top = 0
      Width = 563
      Height = 476
      Caption = 'jvspBoolCollection'
      inline frameBoolCollection: TframeFormulaGrid
        Left = 0
        Top = 0
        Width = 563
        Height = 476
        Align = alClient
        TabOrder = 0
        ExplicitWidth = 563
        ExplicitHeight = 476
        inherited Panel: TPanel
          Top = 435
          Width = 563
          ExplicitTop = 435
          ExplicitWidth = 563
          inherited lbNumber: TLabel
            Width = 55
            Height = 18
            ExplicitWidth = 55
            ExplicitHeight = 18
          end
          inherited sbAdd: TSpeedButton
            Left = 284
            ExplicitLeft = 265
          end
          inherited sbInsert: TSpeedButton
            Left = 337
            ExplicitLeft = 314
          end
          inherited sbDelete: TSpeedButton
            Left = 386
            ExplicitLeft = 362
          end
          inherited seNumber: TJvSpinEdit
            Height = 26
            ExplicitHeight = 26
          end
        end
        inherited Grid: TRbwDataGrid4
          Width = 563
          Height = 378
          OnSetEditText = GridSetEditText
          OnButtonClick = GridButtonClick
          OnEndUpdate = frameBoolCollectiondEndUpdate
          ExplicitWidth = 563
          ExplicitHeight = 378
        end
        inherited pnlTop: TPanel
          Width = 563
          ExplicitWidth = 563
          inherited edFormula: TLabeledEdit
            Height = 26
            EditLabel.Width = 57
            EditLabel.Height = 18
            EditLabel.ExplicitLeft = 128
            EditLabel.ExplicitTop = 9
            EditLabel.ExplicitHeight = 18
            ExplicitHeight = 26
          end
          inherited comboChoice: TComboBox
            Height = 26
            ExplicitHeight = 26
          end
        end
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 476
    Width = 858
    Height = 44
    Align = alBottom
    ParentColor = True
    TabOrder = 2
    object btnCancel: TBitBtn
      Left = 758
      Top = 6
      Width = 91
      Height = 33
      Kind = bkCancel
      NumGlyphs = 2
      TabOrder = 2
    end
    object btnOK: TBitBtn
      Left = 661
      Top = 6
      Width = 91
      Height = 33
      Kind = bkOK
      NumGlyphs = 2
      TabOrder = 1
      OnClick = btnOKClick
    end
    object btnHelp: TBitBtn
      Left = 564
      Top = 6
      Width = 91
      Height = 33
      Kind = bkHelp
      NumGlyphs = 2
      TabOrder = 0
      OnClick = btnHelpClick
    end
  end
  object rbwprsrGlobal: TRbwParser
    Left = 112
    Top = 8
  end
end
