inherited frmCustomSelectObjects: TfrmCustomSelectObjects
  Caption = 'frmCustomSelectObjects'
  ClientHeight = 417
  ClientWidth = 408
  ExplicitWidth = 424
  ExplicitHeight = 456
  TextHeight = 18
  object pnlBottom: TPanel
    Left = 0
    Top = 376
    Width = 408
    Height = 41
    Align = alBottom
    ParentColor = True
    TabOrder = 1
    DesignSize = (
      408
      41)
    object btnClose: TBitBtn
      Left = 306
      Top = 6
      Width = 89
      Height = 33
      Anchors = [akTop, akRight]
      Kind = bkClose
      NumGlyphs = 2
      TabOrder = 1
    end
    object btnHelp: TBitBtn
      Left = 213
      Top = 6
      Width = 89
      Height = 33
      Anchors = [akTop, akRight]
      Kind = bkHelp
      NumGlyphs = 2
      TabOrder = 0
    end
  end
  object vstObjects: TVirtualStringTree
    Left = 0
    Top = 0
    Width = 408
    Height = 376
    Align = alClient
    Colors.BorderColor = 15987699
    Colors.DisabledColor = clGray
    Colors.DropMarkColor = 15385233
    Colors.DropTargetColor = 15385233
    Colors.DropTargetBorderColor = 15385233
    Colors.FocusedSelectionColor = 15385233
    Colors.FocusedSelectionBorderColor = 15385233
    Colors.GridLineColor = 15987699
    Colors.HeaderHotColor = clBlack
    Colors.HotColor = clBlack
    Colors.SelectionRectangleBlendColor = 15385233
    Colors.SelectionRectangleBorderColor = 15385233
    Colors.SelectionTextColor = clBlack
    Colors.TreeLineColor = 9471874
    Colors.UnfocusedColor = clGray
    Colors.UnfocusedSelectionColor = 13421772
    Colors.UnfocusedSelectionBorderColor = 13421772
    Header.AutoSizeIndex = 0
    Header.MainColumn = -1
    Header.Options = [hoColumnResize, hoDrag]
    TabOrder = 0
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSort, toAutoDeleteMovedNodes, toAutoChangeScale]
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toCheckSupport, toFullRepaintOnResize, toInitOnSave, toWheelPanning]
    TreeOptions.SelectionOptions = [toFullRowSelect]
    OnChecking = vstObjectsChecking
    OnFreeNode = vstObjectsFreeNode
    OnGetText = vstObjectsGetText
    OnInitNode = vstObjectsInitNode
    OnStateChange = vstObjectsStateChange
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <>
  end
end
