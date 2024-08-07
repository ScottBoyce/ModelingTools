unit OrderedCollectionUnit;

interface

uses
  DataArrayInterfaceUnit, ModflowParameterInterfaceUnit,
  System.Classes, GoPhastTypes, SysUtils, SubscriptionUnit,
  RbwParser,
  ModelMuseInterfaceUnit, OrderedCollectionInterfaceUnit,
  FormulaManagerInterfaceUnit, ObsInterfaceUnit, ScreenObjectInterfaceUnit;

type



  {@name defines the types of parameters used in MODFLOW.
  @value(ptUndefined ptUndefined represents an undefined type.)
  @value(ptLPF_HK ptLPF_HK represents the HK parameter type
    in the LPF package. (Hydraulic conductivity in the
    horizontal (row) direction.))
  @value(ptLPF_HANI ptLPF_HANI represents the HANI parameter type
    in the LPF package. (Horizontal anisotropy: the ratio of hydraulic
    conductivity along columns to hydraulic conductivity along rows.
    The hydraulic conductivity along columns is the product of the values
    in HK and HANI))
  @value(ptLPF_VK ptLPF_VK represents the VK parameter type
    in the LPF package. (Hydraulic conductivity in the
    vertical direction.))
  @value(ptLPF_VANI ptLPF_VANI represents the VANI parameter type
    in the LPF package. (Vertical anisotropy: the ratio of
    hydraulic conductivity along rows to vertical hydraulic
    conductivity.)  HK is divided by VANI to obtain vertical
    hydraulic conductivity, and values of VANI typically are greater
    than or equal to 1.0)
  @value(ptLPF_SS ptLPF_SS represents the SS parameter type
    in the LPF package. (Specific storage.))
  @value(ptLPF_SY ptLPF_SY represents the SY parameter type
    in the LPF package. (Specific yield.))
  @value(ptLPF_VKCB ptLPF_VKCB represents the VKCB parameter type
    in the LPF package. (Vertical hydraulic conductivity of a
    Quasi-three-dimensional confining layer.))
  @value(ptRCH ptRCH represents the RCH parameter type
    in the RCH package. (ptRCH defines values of the recharge at the boundary.))
  @value(ptEVT ptEVT represents the EVT parameter type
    in the EVT package. (ptEVT defines values of the maximum
    evapotranspiration at the boundary.))
  @value(ptETS ptETS represents the ETS parameter type
    in the ETS package. (ptETS defines values of the maximum
    evapotranspiration at the boundary.))
  @value(ptCHD ptCHD represents the CHD parameter type
    in the CHD package. (ptCHD defines values of the start
    and end head at the boundary.))
  @value(ptGHB ptGHB represents the GHB parameter type
    in the General-Head Boundary package. (ptGHB defines values of the conductance
    at the boundary.))
  @value(ptQ ptQ represents the Q parameter type
    in the Well package. (ptQ defines values of the pumping rate
    at the boundary.))
  @value(ptRIV ptRIV represents the RIV parameter type
    in the River package. (ptRIV defines values of the conductance
    at the boundary.))
  @value(ptDRN ptDRN represents the DRN parameter type
    in the Drain package. (ptDRN defines values of the conductance
    at the boundary.))
  @value(ptDRT ptDRT represents the DRT parameter type
    in the Drain Return package. (ptDRT defines values of the conductance
    at the boundary.))
  @value(ptSFR ptSFR represents the SFR parameter type
    in the SFR package. (ptSFR defines values of the streambed hydraulic
    conductivity at the boundary.))
  @value(ptHFB ptHFB represents the HFB parameter type
    in the HFB package. (ptHFB defines values of the hydraulic characteristic
    of the barrier.))

  @value(ptHUF_HK ptHUF_HK represents the HK parameter type
    in the HUF package. (ptHUF_HK defines values of the horizontal hydraulic conductivity
    of the hydrogeologic unit.))
  @value(ptHUF_HANI ptHUF_HANI represents the HANI parameter type
    in the HUF package. (ptHUF_HANI defines values of the horizontal anisotropy
    of the hydrogeologic unit.))
  @value(ptHUF_VK ptHUF_VK represents the VK parameter type
    in the HUF package. (ptHUF_VK defines values of the vertical hydraulic conductivity
    of the hydrogeologic unit.))
  @value(ptHUF_VANI ptHUF_VANI represents the VANI parameter type
    in the HUF package. (ptHUF_VANI defines values of the vertical anisotropy
    of the hydrogeologic unit.))
  @value(ptHUF_SS ptHUF_SS represents the SS parameter type
    in the HUF package. (ptHUF_SS defines values of the specific storage
    of the hydrogeologic unit.))
  @value(ptHUF_SY ptHUF_SY represents the SY parameter type
    in the HUF package. (ptHUF_SY defines values of the specific yield
    of the hydrogeologic unit.))
  @value(ptHUF_SYTP ptHUF_SYTP represents the SYTP parameter type
    in the HUF package. (ptHUF_SYTP defines values of the storage coefficient
    for the top active cell.))
  @value(ptHUF_KDEP ptHUF_KDEP represents the KDEP parameter type
    in the KDEP package. (ptHUF_KDEP defines values of the depth-dependent
    hydraulic conductivity coefficient.))
  @value(ptHUF_LVDA ptHUF_LVDA represents the LVDA parameter type
    in the LVDA package. (ptHUF_LVDA defines values of horizontal anisotropy.))
  @value(ptSTR ptSTR represents the STR parameter type
    in the STR package. (ptSTR defines values of stream conductance.))
  @value(ptQMAX ptQMAX represents the QMAX parameter type
    in the Farm Process. (ptQMAX defines the maximum pumping rate.))

  {@name is designed to allow @link(TOrderedCollection) to identify
    changed and new items during @link(TOrderedCollection.Assign
    TOrderedCollection.Assign).
    Descendents need to override @link(IsSame) and @link(Assign).}
  TOrderedItem = class(TCollectionItem, IOrderedItem)
  private
    {@name is the ID of a @classname that has been assigned to this
     @classname.  If no @classname has been assigned to it, @name is -1.}
    FForeignId: integer;
    // See @link(AlwaysAssignForeignId).
    FAlwaysAssignForeignId: boolean;
    FInsertionNeeded: boolean;
    FNewIndex: Integer;
    function IsSame(AnotherItem: IOrderedItem): boolean; overload;
  protected
    { TODO -cRefactor : Consider replacing Model with an interface. }
    //
    function Model: IModelForTOrderedCollection;
    function GetOnInvalidateModelEvent: TNotifyEvent;
    property OnInvalidateModelEvent: TNotifyEvent read GetOnInvalidateModelEvent;
    // @name tests whether another @classname is identical to the current one.
    function IsSame(AnotherItem: TOrderedItem): boolean; overload; virtual; abstract;
    // @name invalidates the model.
    // @seeAlso(TOrderedCollection.InvalidateModel)
    // @seeAlso(TBaseModel.Invalidate)
    procedure InvalidateModel; virtual;
    // if @name is @true, @link(FForeignId) will always be assigned during
    // @link(Assign).  Otherwise, @link(FForeignId) will only be assigned if
    // @link(IsSame) returns @false.
    // @name is set to @true in @link(TModflowParamItem)
    // and @link(TGlobalVariableItem).
    property AlwaysAssignForeignId: boolean read FAlwaysAssignForeignId
      write FAlwaysAssignForeignId;
    procedure SetBooleanProperty(var AField: boolean; const NewValue: boolean);
    procedure SetIntegerProperty(var AField: Integer; const NewValue: Integer);
    procedure SetRealProperty(var AField: double; NewValue: double);
    procedure SetCaseSensitiveStringProperty(var AField: string;
      const NewValue: string);
    procedure SetCaseInsensitiveStringProperty(var AField: string;
      NewValue: string);
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    // @name copies Source to the current @classname.  It will also assign
    // @link(FForeignId) if @link(AlwaysAssignForeignId) is @true or
    // @link(IsSame) returns @false.
    procedure Assign(Source: TPersistent); override;
    // @name creates and instance of @classname and
    // sets @link(FForeignId) to -1.
    constructor Create(Collection: TCollection); override;
    property ForeignId: Integer read FForeignId;
    function QueryInterface(const IID: TGUID; out Obj): HRESULT;
      virtual; stdcall;
  end;

  // @name defines boundary properties that are defined with formulas but
  // do not have a starting and ending time assigned. A starting time is
  // defined in the descendant @link(TCustomBoundaryItem). A @name may be
  // associated with some other class that does have a starting or ending time
  // assigned.
  // Descendants of @classname must override @link(UpdateFormulaDependencies),
  // @link(GetObserver), and @link(GetScreenObject). They must also assign
  // values to @link(OnRemoveSubscription) and @link(OnRestoreSubscription);
  // If @link(UpdateFormulaDependencies) is overridden, @link(GetScreenObject)
  // might not be used.
  TFormulaOrderedItem = class(TOrderedItem)
  private
    FOnRemoveSubscription: TChangeSubscription;
    FOnRestoreSubscription: TChangeSubscription;
    function GetScreenObjectI: IScreenObject;
  protected
    procedure UpdateFormulaDependencies(OldFormula: string;
      var NewFormula: string; Observer: TObserver; Compiler: TRbwParser);
      virtual;
    function GetObserver(Index: Integer): TObserver; virtual; abstract;
    function GetScreenObject: TObject; virtual; abstract;
    // After calling this function, the calling function needs to
    // call AddSubscriptionEvents on the result.
    function CreateBlockFormulaObject(Orientation:
      TDataSetOrientation): IFormulaObject;
  public
    property Observer[Index: Integer]: TObserver read GetObserver;
    procedure UpdateFormulaBlocks(Value: string; Position: integer;
      var FormulaObject: IFormulaObject); overload;
    procedure UpdateFormulaNodes(Value: string; Position: integer;
      var FormulaObject: IFormulaObject); overload;
    property OnRemoveSubscription: TChangeSubscription
      read FOnRemoveSubscription write FOnRemoveSubscription;
    property OnRestoreSubscription: TChangeSubscription
      read FOnRestoreSubscription write FOnRestoreSubscription;
    property ScreenObject: TObject read GetScreenObject;
    property ScreenObjectI: IScreenObject read GetScreenObjectI;
  end;

  TPestMethodItem = class(TOrderedItem)
  private
    FPestParamMethod: TPestParamMethod;
    procedure SetPestParamMethod(const Value: TPestParamMethod);
  protected
    function IsSame(AnotherItem: TOrderedItem): boolean; override;
  public
    procedure Assign(Source: TPersistent); override;
  published
    property PestParamMethod: TPestParamMethod read FPestParamMethod
      write SetPestParamMethod;
  end;


  // @name is a base class for collections that avoid deleting their collection
  // items during assign whenever they can. @name is typically used to
  // allow editing of the collection in a GUI.  The model owns (directly or
  // indirectly) one copy of the @classname.  Another copy will be created
  // in the GUI in which @link(TOrderedCollection.Model) will be @nil.
  // The user will edit this latter copy in the GUI.  The copy then gets
  // assigned back to the original copy.
  // @seealso(TOrderedCollection.Assign)
  TOrderedCollection = class(TCollection, IOrderedCollection)
  private
    { TODO -cRefactor : Consider replacing Model with an interface. }
    // See @link(Model).
    FModel: IModelForTOrderedCollection;
    procedure SetCount(const Value: Integer);
  protected
    // @name invalidates the model.
    // @seeAlso(TBaseModel.Invalidate)
    procedure InvalidateModel; virtual;
    // If @name returns true, @link(Assign) will sort the items
    // using the same order as in the collection that is being assigned to it.
    function SortItems: Boolean; virtual;
    function GetCount: Integer; virtual;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    function First: TCollectionItem;
    function Last: TCollectionItem;
    // @name tests whether the contents of AnOrderedCollection are the same
    // as the current @classname.
    function IsSame(AnOrderedCollection: TOrderedCollection): boolean; virtual;
    { TODO -cRefactor : Consider replacing Model with a TNotifyEvent or interface. }
    // @name is a @link(TPhastModel) or nil.
    property Model: IModelForTOrderedCollection read FModel;
    { TODO -cRefactor : Consider replacing Model with a TNotifyEvent or interface. }
    // @name creates an instance of @classname.
    // @param(ItemClass ItemClass must be a descendant of @link(TOrderedItem).)
    // @param(Model Model must be a @link(TPhastModel) or nil.)
    constructor Create(ItemClass: TCollectionItemClass; Model: IModelForTOrderedCollection);
    // @name copies the source @classname to itself.  If @link(Model) is nil,
    // it uses the inherited method which causes it to delete all its items,
    // and copy new ones from the source.  If @link(Model) is assigned,
    // @unorderedlist(
    //   @item(existing items will be copied back to the items from which
    //     they were originally copied.)
    //   @item(items deleted in the copy will be deleted in the original.)
    //   @item(new items created in the copy will be inserted into the
    //     original at the same position.)
    // )
    procedure Assign(Source: TPersistent); override;
    function FindMatchingItem(AnOrderedItem: TOrderedItem): TOrderedItem;
    property Count: Integer read GetCount write SetCount;
    function QueryInterface(const IID: TGUID; out Obj): HRESULT;
      virtual; stdcall;
  end;

  // @name extends @link(TOrderedCollection) by adding
  // @link(TEnhancedOrderedCollection.IndexOf) and
  // @link(TEnhancedOrderedCollection.Remove).
  TEnhancedOrderedCollection = class(TOrderedCollection)
  public
    // @name returns the position of Item.  @name returns -1
    // if Item is not in the @classname.
    function IndexOf(Item: TOrderedItem): integer;
    // @name removes Item from the @classname if it is in it.
    procedure Remove(Item: TOrderedItem);
  end;

  TGwtPestMethodCollection = class(TEnhancedOrderedCollection)
  protected
    function GetItems(const Index: Integer): TPestMethodItem; virtual;
    procedure SetItems(const Index: Integer; const Value: TPestMethodItem);
    function GetCount: Integer; override;
  public
    constructor Create(Model: IModelForTOrderedCollection);
    property Items[const Index: Integer]: TPestMethodItem read GetItems
      write SetItems; default;
  end;

  TLandUsePestMethodCollection = class(TEnhancedOrderedCollection)
  protected
    function GetItems(const Index: Integer): TPestMethodItem; virtual;
    procedure SetItems(const Index: Integer; const Value: TPestMethodItem);
    function GetCount: Integer; override;
  public
    constructor Create(Model: IModelForTOrderedCollection);
    property Items[const Index: Integer]: TPestMethodItem read GetItems
      write SetItems; default;
  end;

  TCustomObjectOrderedCollection = class(TEnhancedOrderedCollection)
  private
    FScreenObject: IScreenObject;
  public
    // @name is the @link(TScreenObject) for this boundary.
    // @name provides access to @link(TCustomModflowBoundaryItem) representing
    // the boundary conditions for different time periods.
    property ScreenObject: IScreenObject read FScreenObject;
    constructor Create(ItemClass: TCollectionItemClass;
      Model: IModelForTOrderedCollection;
      AScreenObject: IScreenObject);
  end;

  // @name is a @link(TEnhancedOrderedCollection) that stores of list of
  // @link(TDataArray)s that it can delete. The list (@link(NewDataSets))
  // is not created by the @classname.  Instead another class
  // creates it and assigns it to @classname. @link(TCustomCreateRequiredDataSetsUndo)
  // is an example of a class that assigns @link(NewDataSets).
  //
  // When a new @link(TDataArray) is created, it should be added to
  // @link(NewDataSets) using @link(AddOwnedDataArray);
  // In @link(TUndoItem.DoCommand),  @link(ClearNewDataSets) should be called
  // before the @link(TDataArray)s are created.
  // In @link(TUndoItem.Undo),  @link(RemoveNewDataSets) should be called;
  TLayerOwnerCollection = class(TEnhancedOrderedCollection)
  private
    // See @link(NewDataSets).
    FNewDataSets: TIDataArrayList;
  protected
    // @name adds DataArray to @link(NewDataSets)
    procedure AddOwnedDataArray(DataArray: IDataArray);
  public
    // @name clears @link(NewDataSets).
    procedure ClearNewDataSets;
    // @name frees all the @link(TDataArray)s in @link(NewDataSets).
    procedure RemoveNewDataSets;
    // @name is the list of @link(TDataArray)s managed by @classname.
    // @name is NOT owned by @classname.
    property NewDataSets: TIDataArrayList read FNewDataSets write FNewDataSets;
  end;

  TPestTransform = (ptNoTransform, ptLog, ptFixed, ptTied);
  TPestChangeLimitation = (pclRelative, pclFactor, pclAbsolute);

  TPilotPointObsGrp = class(TPhastCollectionItem)
  private
    FObsGroupName: string;
    FLayer: Integer;
    FObsGroup: IObservationGroup;
    FParamFamily: string;
    procedure SetLayer(const Value: Integer);
    procedure SetObsGroupName(const Value: string);
    function GetObsGroupName: string;
    procedure SetParamFamily(const Value: string);
  public
    procedure Assign(Source: TPersistent); override;
    function IsSame(OtherItem: TPilotPointObsGrp): Boolean;
    // @name is a @link(PestObsGroupUnit.TPestObservationGroup).
    property ObsGroup: IObservationGroup read FObsGroup write FObsGroup;
  published
    Property ObsGroupName: string read GetObsGroupName write SetObsGroupName;
    property Layer: Integer read FLayer write SetLayer;
    property ParamFamily: string read FParamFamily write SetParamFamily;
  end;

  TPPObsGrpCollection = class(TPhastCollection)
  private
    FModel: IModelMuseModel;
    function GetItem(Index: Integer): TPilotPointObsGrp;
    procedure SetItem(Index: Integer; const Value: TPilotPointObsGrp);
  public
    Constructor Create(Model: IModelMuseModel);
    function Add: TPilotPointObsGrp;
    function IsSame(OtherCollection: TPPObsGrpCollection): Boolean;
    property Items[Index: Integer]: TPilotPointObsGrp read GetItem
      write SetItem; default;
    function GetGroupNameByLayerAndFamily(Layer: integer; const ParamFamily: string): string;
    procedure SetGroupNameByLayerAndFamily(Layer: integer; const ParamFamily: string; const GroupName: string);
  end;

  // @name represents a MODFLOW parameter
  TModflowParameter = class abstract (TOrderedItem, IModflowParameter)
  private
    // See @link(ParameterType).
    FParameterType: TParameterType;
    // See @link(Value).
    FValue: double;
    FTransform: TPestTransform;
    FStoredOffset: TRealStorage;
    FStoredScale: TRealStorage;
    FChangeLimitation: TPestChangeLimitation;
    FStoredLowerBound: TRealStorage;
    FTiedParameterName: string;
    FParameterGroup: string;
    FStoredUpperBound: TRealStorage;
    FStoredAbsoluteN: TRealStorage;
    FUseInitialValuePriorInfo: Boolean;
    FRegularizationGroup: string;
    FAddedToPval: Boolean;
    FStoredInitialValuePriorInfoWeight: TRealStorage;
    FPilotPointObsGrpCollection: TPPObsGrpCollection;
    procedure NotifyHufKx;
    procedure NotifyHufKy;
    procedure NotifyHufKz;
    procedure NotifyHufSS;
    procedure NotifyHufSy;
    function GetLowerBound: double;
    function GetUpperBound: double;
    procedure SetChangeLimitation(const Value: TPestChangeLimitation);
    procedure SetLowerBound(const Value: double);
    procedure SetParameterGroup(const Value: string);
    procedure SetStoredLowerBound(const Value: TRealStorage);
    procedure SetStoredOffset(const Value: TRealStorage);
    procedure SetStoredScale(const Value: TRealStorage);
    procedure SetStoredUpperBound(const Value: TRealStorage);
    procedure SetTiedParameterName(const Value: string);
    procedure SetTransform(const Value: TPestTransform);
    procedure SetUpperBound(const Value: double);
    function GetOffset: double;
    function GetScale: double;
    procedure SetOffset(const Value: double);
    procedure SetScale(const Value: double);
    procedure SetStoredAbsoluteN(const Value: TRealStorage);
    function GetAbsoluteN: double;
    procedure SetAbsoluteN(const Value: double);
    procedure SetUseInitialValuePriorInfo(const Value: Boolean);
    procedure SetRegularizationGroup(const Value: string);
    procedure SetStoredInitialValuePriorInfoWeight(const Value: TRealStorage);
    function GetInitialValuePriorInfoWeight: double;
    procedure SetInitialValuePriorInfoWeight(const Value: double);
    procedure SetPilotPointObsGrpCollection(const Value: TPPObsGrpCollection);
    function GetParameterName: string;
    function GetValue: double;
  protected
    // See @link(ParameterName).
    FParameterName: string;
    // See @link(ParameterType).
    procedure SetParameterType(const Value: TParameterType); virtual;
    // See @link(ParameterName).
    procedure SetParameterName(const Value: string); virtual; abstract;
    // See @link(Value).
    procedure SetValue(AValue : double); virtual;
  public
    constructor Create(Collection: TCollection); override;
    procedure NotifyParamChange(const Value: TParameterType);
    // @name copies @link(ParameterName), @link(ParameterType), @link(Value)
    // and @link(FForeignId) from source.  (@link(FForeignId) gets assigned the
    // value of the Source's ID not the Source's @link(FForeignId).
    procedure Assign(Source: TPersistent); override;
    // @name tests whether @1ink(ParameterName), @link(ParameterType)
    // @link(Value) are the same as or different from those of AnotherItem.
    function IsSame(AnotherItem: TOrderedItem): boolean; override;
    // @name destroys @classname.  If @link(ParameterType)
    // in [ptRCH, ptEVT, ptETS, ptCHD, ptGHB, ptQ, ptRIV, ptDRN, ptDRT]
    // All @link(TScreenObject)s that use @classname will have it removed from
    // them.
    Destructor Destroy; override;
    // PARLBND in PEST
    property LowerBound: double read GetLowerBound write SetLowerBound;
    // PARUBND in PEST
    property UpperBound: double read GetUpperBound write SetUpperBound;
    // SCALE in PEST
    property Scale: double read GetScale write SetScale;
    // OFFSET in PEST
    property Offset: double read GetOffset write SetOffset;
    // Absolute(N) and ABSPARMAX(N) in PEST
    property AbsoluteN: double read GetAbsoluteN write SetAbsoluteN;
    property AddedToPval: Boolean read FAddedToPval write FAddedToPval;
    property InitialValuePriorInfoWeight: double
      read GetInitialValuePriorInfoWeight write SetInitialValuePriorInfoWeight;
  published
    // @name is the name of the parameter.  All parameter names must be unique
    // but ensuring that they are unique is left up to the GUI rather than
    // being validated by @classname.
    // In UCODE and PEST, parameter names can be up to 12 characters in length.
    // PARNME in PEST
    property ParameterName: string read GetParameterName write SetParameterName;
    // @name indicates what type of parameter this is.
    property ParameterType: TParameterType read FParameterType
      write SetParameterType;
    // @name is the value assigned to the parameter.
    // PARVAL1 in PEST
    property Value: double read GetValue write SetValue;
    // PARTRANS in PEST
    property Transform: TPestTransform read FTransform write SetTransform;
    // PARCHGLIM in PEST
    property ChangeLimitation: TPestChangeLimitation read FChangeLimitation
      write SetChangeLimitation;
    // PARLBND in PEST
    property StoredLowerBound: TRealStorage read FStoredLowerBound
      write SetStoredLowerBound;
    // PARUBND in PEST
    property StoredUpperBound: TRealStorage read FStoredUpperBound
      write SetStoredUpperBound;
    // PARGP in PEST
    property ParameterGroup: string read FParameterGroup write SetParameterGroup;
    // SCALE in PEST
    property StoredScale: TRealStorage read FStoredScale write SetStoredScale;
    // OFFSET in PEST
    property StoredOffset: TRealStorage read FStoredOffset write SetStoredOffset
      Stored False;
    // DERCOM in PEST is not currently supported.

    // PARTIED in PEST
    property TiedParameterName: string read FTiedParameterName
      write SetTiedParameterName;
    // Absolute(N) and ABSPARMAX(N) in PEST
    property StoredAbsoluteN: TRealStorage read FStoredAbsoluteN
      write SetStoredAbsoluteN;
    // @name determines whether or not the parameter will be included in
    // a prior information equation setting it equal to its initial value.
    property UseInitialValuePriorInfo: Boolean read FUseInitialValuePriorInfo
      write SetUseInitialValuePriorInfo Stored True;
    property StoredInitialValuePriorInfoWeight: TRealStorage
      read FStoredInitialValuePriorInfoWeight
      write SetStoredInitialValuePriorInfoWeight;
    // @name is the regularization group of the parameter in the
    // initial value prior information equation.
    property RegularizationGroup: string read FRegularizationGroup
      write SetRegularizationGroup Stored True;
    property PilotPointObsGrpCollection: TPPObsGrpCollection
      read FPilotPointObsGrpCollection write SetPilotPointObsGrpCollection
      Stored True;
  end;

function ParmeterTypeToStr(ParmType: TParameterType): string;
function CorrectParamName(const Value: string): string;

const
  Mf15ParamType: TParameterTypes = [ptRCH, ptETS, ptHFB, ptPEST, ptCHD,
    ptGHB, ptQ, ptRIV, ptDRN, ptPEST];

  Mf2005ParamType: TParameterTypes = [ptLPF_HK, ptLPF_HANI, ptLPF_VK,
    ptLPF_VANI, ptLPF_SS, ptLPF_SY, ptLPF_VKCB, ptRCH, ptEVT, ptETS,
    ptCHD, ptGHB, ptQ,
    ptRIV, ptDRN, ptDRT, ptSFR, ptHFB,
    ptHUF_HK, ptHUF_HANI, ptHUF_VK, ptHUF_VANI, ptHUF_SS, ptHUF_SY,
    ptHUF_SYTP, ptHUF_KDEP, ptHUF_LVDA, ptSTR, ptQMAX, ptPEST];

  SutraParamType: TParameterTypes = [ptPEST];

implementation

uses
  ModflowBoundaryInterfaceUnit,
  ModflowTransientListParameterInterfaceUnit,
  ModflowSfrParamIcalcInterfaceUnit,
  Generics.Collections,
  Generics.Defaults, Math,
  PhastModelInterfaceUnit,
  LockedGlobalVariableChangersInterfaceUnit;

function ParmeterTypeToStr(ParmType: TParameterType): string;
begin
  case ParmType of
    ptUndefined: result := 'Undefined';
    ptLPF_HK: result := 'HK' ;
    ptLPF_HANI: result := 'HANI' ;
    ptLPF_VK: result := 'VK' ;
    ptLPF_VANI: result := 'VANI' ;
    ptLPF_SS: result := 'SS' ;
    ptLPF_SY: result := 'SY' ;
    ptLPF_VKCB: result := 'VKCB' ;
    ptRCH: result := 'RCH' ;
    ptEVT: result := 'EVT' ;
    ptETS: result := 'ETS' ;
    ptCHD: result := 'CHD' ;
    ptGHB: result := 'GHB' ;
    ptQ: result := 'Q' ;
    ptRIV: result := 'RIV' ;
    ptDRN: result := 'DRN' ;
    ptDRT: result := 'DRT' ;
    ptHUF_SYTP: result := 'SYTP' ;
    ptHUF_LVDA: result := 'LVDA' ;
    ptSTR: result := 'STR' ;
    ptQMAX: result := 'QMAX' ;
    ptPEST: result := 'PEST' ;
    else Assert(False);
  end;
end;

constructor TOrderedCollection.Create(ItemClass: TCollectionItemClass;
  Model: IModelForTOrderedCollection);
begin
  inherited Create(ItemClass);
  FModel := Model;
end;

function TOrderedCollection.FindMatchingItem(
  AnOrderedItem: TOrderedItem): TOrderedItem;
var
  Index: Integer;
  AnItem: TOrderedItem;
begin
  result := nil;
  for Index := 0 to Count - 1 do
  begin
    AnItem := Items[Index] as TOrderedItem;
    if AnItem.ID = AnOrderedItem.FForeignId then
    begin
      result := AnItem;
      Exit;
    end;
  end;
end;

function TOrderedCollection.First: TCollectionItem;
begin
  result := Items[0];
end;

function TOrderedCollection.GetCount: Integer;
begin
  result := inherited Count;
end;

function TOrderedCollection.IsSame(
  AnOrderedCollection: TOrderedCollection): boolean;
var
  Index: Integer;
begin
  result := Count = AnOrderedCollection.Count;
  if result then
  begin
    for Index := 0 to Count - 1 do
    begin
      result := (Items[Index] as TOrderedItem).IsSame(
        AnOrderedCollection.Items[Index] as TOrderedItem);
      if not result then Exit;
    end;
  end;
end;

function TOrderedCollection.Last: TCollectionItem;
begin
  result := Items[Count-1];
end;

function TOrderedCollection.QueryInterface(const IID: TGUID; out Obj): HRESULT;
const
  E_NOINTERFACE = HRESULT($80004002);
begin
  if GetInterface(IID, Obj) then
    result := 0
  else
    result := E_NOINTERFACE;
end;

procedure TOrderedCollection.SetCount(const Value: Integer);
var
  ExistingCount: integer;
begin
  Assert(Value >= 0);
  ExistingCount := inherited Count;
  while ExistingCount < Value do
  begin
    Add;
    Inc(ExistingCount);
  end;
  while ExistingCount > Value do
  begin
    Last.Free;
    Dec(ExistingCount);
  end;
end;

function TOrderedCollection.SortItems: Boolean;
begin
  result := False;
end;

function TOrderedCollection._AddRef: Integer;
begin
  result := -1;
end;

function TOrderedCollection._Release: Integer;
begin
  result := -1;
end;

procedure TOrderedCollection.Assign(Source: TPersistent);
var
  Index: integer;
  AnotherOrderedCollection: TOrderedCollection;
  AnItem: TOrderedItem;
  ForeignItem: TOrderedItem;
  ID_Array: array of integer;
  ItemIndex: Integer;
  ItemList: TList<TOrderedItem>;
  function FindUnitByForeignId(ForeignId: integer): TOrderedItem;
  var
    Index: integer;
    AnItem: TOrderedItem;
  begin
    result := nil;
    for Index := 0 to AnotherOrderedCollection.Count - 1 do
    begin
      AnItem := AnotherOrderedCollection.Items[Index] as TOrderedItem;
      if AnItem.FForeignId = ForeignId then
      begin
        result := AnItem;
        Exit;
      end;
    end;
  end;
begin
  // if Assign is updated, update IsSame too.
  AnotherOrderedCollection := Source as TOrderedCollection;
  if not IsSame(AnotherOrderedCollection) then
  begin
    Capacity := Max(Count, AnotherOrderedCollection.Count);
    if FModel = nil then
    begin
      SetLength(ID_Array, AnotherOrderedCollection.Count);
      for Index := 0 to AnotherOrderedCollection.Count - 1 do
      begin
        AnItem := AnotherOrderedCollection.Items[Index] as TOrderedItem;
        ID_Array[Index] := AnItem.ID;
      end;
      BeginUpdate;
      try
        While Count > AnotherOrderedCollection.Count do
        begin
          Delete(Count -1);
        end;
        While Count < AnotherOrderedCollection.Count do
        begin
          Add;
        end;
        for ItemIndex := 0 to Count - 1 do
        begin
          Items[ItemIndex].Assign(
            AnotherOrderedCollection.Items[ItemIndex]);
        end;
      finally
        EndUpdate;
      end;
//      inherited;
      for Index := 0 to Count - 1 do
      begin
        AnItem := Items[Index] as TOrderedItem;
        AnItem.FForeignId := ID_Array[Index];
      end;
    end
    else
    begin
      { TODO :
It isn't clear that FInsertionNeeded is actually needed.
Make exhaustive tests to see if it is needed.}
      for Index := 0 to AnotherOrderedCollection.Count - 1 do
      begin
        ForeignItem := AnotherOrderedCollection.Items[Index] as TOrderedItem;
        ForeignItem.FInsertionNeeded := True;
      end;

      for Index := Count - 1 downto 0 do
      begin
        AnItem := Items[Index] as TOrderedItem;
        ForeignItem := FindUnitByForeignId(AnItem.ID);
        if ForeignItem = nil then
        begin
          Delete(Index);
        end
        else
        begin
          AnItem.Assign(ForeignItem);
          ForeignItem.FInsertionNeeded := False;
        end;
      end;

      for Index := 0 to AnotherOrderedCollection.Count - 1 do
      begin
        ForeignItem := AnotherOrderedCollection.Items[Index] as TOrderedItem;
        if (ForeignItem.FForeignId = -1) or
          ForeignItem.FInsertionNeeded then
        begin
          AnItem := Insert(Index) as TOrderedItem;
          AnItem.Assign(ForeignItem);
        end;
      end;

      // Test to make sure everything seems right.
      Assert(Count = AnotherOrderedCollection.Count);

      if SortItems then
      begin
        ItemList := TList<TOrderedItem>.Create;
        try
          for Index := 0 to Count - 1 do
          begin
            ItemList.Add(Items[Index] as TOrderedItem);
          end;
          ItemList.Sort(TComparer<TOrderedItem>.Construct(
            function (const L, R: TOrderedItem): integer
            begin
              result := L.FNewIndex - R.FNewIndex;
            end)
            );
          for index := 0 to ItemList.Count - 1 do
          begin
            ItemList[index].Index := index;
          end;
        finally
          ItemList.Free;
        end;
      end;
    end;
  end;
end;

{ TOrderedItem }

procedure TOrderedItem.Assign(Source: TPersistent);
var
  AnotherItem: TOrderedItem;
begin
  AnotherItem := Source as TOrderedItem;
  if AlwaysAssignForeignId or (not IsSame(AnotherItem)) then
  begin
    FForeignId := AnotherItem.ID;
  end;
  FNewIndex := AnotherItem.Index;
end;

constructor TOrderedItem.Create(Collection: TCollection);
begin
  inherited;
  FForeignId := -1;
end;

procedure TOrderedItem.InvalidateModel;
begin
  if Collection <> nil then
  begin
    (Collection as TOrderedCollection).InvalidateModel;
  end;
end;

function TOrderedItem.IsSame(AnotherItem: IOrderedItem): boolean;
begin
  result := IsSame(AnotherItem as TOrderedItem);
end;

function TOrderedItem.Model: IModelForTOrderedCollection;
begin
  if Collection = nil then
  begin
    result := nil;
  end
  else
  begin
    result := (Collection as TOrderedCollection).Model;
  end;
end;

function TOrderedItem.QueryInterface(const IID: TGUID; out Obj): HRESULT;
const
  E_NOINTERFACE = HRESULT($80004002);
begin
  if GetInterface(IID, Obj) then
    result := 0
  else
    result := E_NOINTERFACE;
end;

function TOrderedItem.GetOnInvalidateModelEvent: TNotifyEvent;
begin
  if Model = nil then
  begin
    result := nil;
  end
  else
  begin
    result := Model.Invalidate;
  end;
end;

procedure TOrderedCollection.InvalidateModel;
begin
  If (FModel <> nil) and (IGlobalModel <> nil) then
  begin
    { TODO -cRefactor : Consider replacing FModel with a TNotifyEvent. }
    FModel.Invalidate(self);
  end;
end;

procedure TLayerOwnerCollection.ClearNewDataSets;
begin
  Assert(FNewDataSets <> nil);
  FNewDataSets.Clear;
end;

procedure TLayerOwnerCollection.RemoveNewDataSets;
var
  DataArray: IDataArray;
  Index: integer;
  ChildIndex: Integer;
  ChildModel: IModelForTOrderedCollection;
  ChildDataArray: IDataArray;
  PhastModel: IPhastModelForTLayerOwnerCollection;
begin
  Assert(FNewDataSets <> nil);
  Assert(FModel <> nil);
  if not FModel.QueryInterface(IPhastModelForTLayerOwnerCollection, PhastModel) = S_OK then
  begin
    PhastModel:= nil;
  end;
  for Index := 0 to FNewDataSets.Count - 1 do
  begin
    DataArray := FNewDataSets[Index];
    if PhastModel <> nil then
    begin
      for ChildIndex := 0 to PhastModel.GetChildModelCount - 1 do
      begin
        ChildModel := PhastModel.GetChildModel(ChildIndex);
        if ChildModel <> nil then
        begin
          ChildDataArray := ChildModel.GetDataArrayInterface.GetDataSetByNameI(DataArray.Name);
          Assert(ChildDataArray <> nil);
          ChildModel.RemoveVariables(ChildDataArray);
          ChildModel.GetDataArrayInterface.ExtractDataSetI(ChildDataArray);
          ChildDataArray.Free;
        end;
      end;
    end;
    FModel.RemoveVariables(DataArray);
    FModel.GetDataArrayInterface.ExtractDataSetI(DataArray);
    DataArray.Free;
  end;
  ClearNewDataSets;
end;

procedure TLayerOwnerCollection.AddOwnedDataArray(DataArray: IDataArray);
begin
  if (FNewDataSets <> nil) then
  begin
    FNewDataSets.Add(DataArray);
  end;
end;

procedure TModflowParameter.Assign(Source: TPersistent);
Var
  SourceParameter: TModflowParameter;
begin
  // if Assign is updated, update IsSame too.
  if Source is TModflowParameter then
  begin
    SourceParameter := TModflowParameter(Source);
    ParameterName := SourceParameter.ParameterName;
    ParameterType := SourceParameter.ParameterType;
    Value := SourceParameter.Value;
    FForeignId := SourceParameter.ID;

    LowerBound := SourceParameter.LowerBound;
    UpperBound := SourceParameter.UpperBound;
    Scale := SourceParameter.Scale;
    Offset := SourceParameter.Offset;
    Transform := SourceParameter.Transform;
    ChangeLimitation := SourceParameter.ChangeLimitation;
    ParameterGroup := SourceParameter.ParameterGroup;
    TiedParameterName := SourceParameter.TiedParameterName;
    AbsoluteN := SourceParameter.AbsoluteN;
    UseInitialValuePriorInfo := SourceParameter.UseInitialValuePriorInfo;
    InitialValuePriorInfoWeight := SourceParameter.InitialValuePriorInfoWeight;
    RegularizationGroup := SourceParameter.RegularizationGroup;
    PilotPointObsGrpCollection := SourceParameter.PilotPointObsGrpCollection;
  end;
  inherited;
end;

function CorrectParamName(const Value: string): string;
var
  Index: integer;
begin
  result := Trim(Value);
  if Length(result) >= 1 then
  begin
    if not CharInSet(result[1], ['_', 'A'..'Z', 'a'..'z', '_']) then
    begin
      result[1] := '_';
    end;
  end;
  for Index := 2 to Length(result) - 1 do
  begin
    if not CharInSet(result[Index], ['_', 'A'..'Z', 'a'..'z', '0'..'9', '_']) then
    begin
      result[Index] := '_';
    end;
  end;
end;

constructor TModflowParameter.Create(Collection: TCollection);
begin
  inherited;
  FStoredOffset := TRealStorage.Create;
  FStoredOffset.OnChange := OnInvalidateModelEvent;
  FStoredScale := TRealStorage.Create;
  FStoredScale.OnChange := OnInvalidateModelEvent;
  FStoredLowerBound := TRealStorage.Create;
  FStoredLowerBound.OnChange := OnInvalidateModelEvent;
  FStoredUpperBound := TRealStorage.Create;
  FStoredUpperBound.OnChange := OnInvalidateModelEvent;
  FStoredAbsoluteN := TRealStorage.Create;
  FStoredAbsoluteN.OnChange := OnInvalidateModelEvent;
  FStoredInitialValuePriorInfoWeight := TRealStorage.Create;
  FStoredInitialValuePriorInfoWeight.Value := 1;
  FStoredInitialValuePriorInfoWeight.OnChange := OnInvalidateModelEvent;
  FPilotPointObsGrpCollection := TPPObsGrpCollection.Create(Model);
  Scale := 1;
  FUseInitialValuePriorInfo := True;
end;

destructor TModflowParameter.Destroy;
var
  LocalModel: IModelForTOrderedCollection;
  ScreenObjectIndex: Integer;
  ScreenObject: IScreenObject;
  Boundary: IModflowParamBoundary;
begin
  FPilotPointObsGrpCollection.Free;
  if ParameterType in [ptRCH, ptEVT, ptETS, ptCHD, ptGHB, ptQ, ptRIV, ptDRN, ptDRT] then
  begin
    if (Collection as TOrderedCollection).Model <> nil then
    begin
      LocalModel := TOrderedCollection(Collection).Model as IModelForTOrderedCollection;
      for ScreenObjectIndex := 0 to LocalModel.GetScreenObjectCount - 1 do
      begin
        ScreenObject := LocalModel.ScreenObjectInterfaces[ScreenObjectIndex];
        Boundary := ScreenObject.GetMfBoundaryI(ParameterType);
        if Boundary <> nil then
        begin
          Boundary.DeleteParam(self);
        end;
      end;
    end;
  end;
  FStoredInitialValuePriorInfoWeight.Free;
  FStoredAbsoluteN.Free;
  FStoredUpperBound.Free;
  FStoredLowerBound.Free;
  FStoredScale.Free;
  FStoredOffset.Free;
  inherited;
end;

function TModflowParameter.GetAbsoluteN: double;
begin
  result := StoredAbsoluteN.Value;
end;

function TModflowParameter.GetInitialValuePriorInfoWeight: double;
begin
  result := StoredInitialValuePriorInfoWeight.Value;
end;

function TModflowParameter.GetLowerBound: double;
begin
  result := StoredLowerBound.Value;
end;

function TModflowParameter.GetOffset: double;
begin
  result := StoredOffset.Value;
end;

function TModflowParameter.GetParameterName: string;
begin
  result := FParameterName;
end;

function TModflowParameter.GetScale: double;
begin
  result := StoredScale.Value;
end;

function TModflowParameter.GetUpperBound: double;
begin
  result := StoredUpperBound.Value;
end;

function TModflowParameter.GetValue: double;
begin
  Result := FValue;
end;

procedure TModflowParameter.NotifyHufSy;
var
  PhastModel: IModelForTModflowParameter;
begin
  if Model <> nil then
  begin
    PhastModel := Model as IModelForTModflowParameter;
    PhastModel.NotifyHufSy
  end;
end;

procedure TModflowParameter.NotifyParamChange(const Value: TParameterType);
begin
  case Value of
    ptUndefined: ;
    ptLPF_HK: ;
    ptLPF_HANI: ;
    ptLPF_VK: ;
    ptLPF_VANI: ;
    ptLPF_SS: ;
    ptLPF_SY: ;
    ptLPF_VKCB: ;
    ptRCH: ;
    ptEVT: ;
    ptETS: ;
    ptCHD: ;
    ptGHB: ;
    ptQ: ;
    ptRIV: ;
    ptDRN: ;
    ptDRT: ;
    ptSFR: ;
    ptHFB: ;
    ptHUF_HK:
      begin
        NotifyHufKx;
        NotifyHufKy;
        NotifyHufKz;
      end;
    ptHUF_HANI:
      begin
        NotifyHufKy;
      end;
    ptHUF_VK:
      begin
        NotifyHufKz;
      end;
    ptHUF_VANI:
      begin
        NotifyHufKz;
      end;
    ptHUF_SS:
      begin
        NotifyHufSS;
      end;
    ptHUF_SY:
      begin
        NotifyHufSY;
      end;
    ptHUF_SYTP: ;
    ptHUF_KDEP:
      begin
        NotifyHufKx;
        NotifyHufKy;
        NotifyHufKz;
      end;
    ptHUF_LVDA: ;
    ptSTR: ;
    ptQMAX: ;
    ptPEST: ;
    else Assert(False);
  end;
end;

procedure TModflowParameter.NotifyHufSS;
var
  PhastModel: IModelForTModflowParameter;
begin
  if Model <> nil then
  begin
    PhastModel := Model as IModelForTModflowParameter;
    PhastModel.NotifyHufSS
  end;
end;

procedure TModflowParameter.NotifyHufKz;
var
  PhastModel: IModelForTModflowParameter;
begin
  if Model <> nil then
  begin
    PhastModel := Model as IModelForTModflowParameter;
    PhastModel.NotifyHufKz;
  end;
end;

procedure TModflowParameter.NotifyHufKy;
var
  PhastModel: IModelForTModflowParameter;
begin
  if Model <> nil then
  begin
    PhastModel := Model as IModelForTModflowParameter;
    PhastModel.NotifyHufKy;
  end;
end;

procedure TModflowParameter.NotifyHufKx;
var
  PhastModel: IModelForTModflowParameter;
begin
  if Model <> nil then
  begin
    PhastModel := Model as IModelForTModflowParameter;
    PhastModel.NotifyHufKx;
  end;
end;

function TModflowParameter.IsSame(AnotherItem: TOrderedItem): boolean;
var
  AnotherParameter: TModflowParameter;
begin
  Assert(AnotherItem is TModflowParameter);
  AnotherParameter := TModflowParameter(AnotherItem);
  result :=
    (ParameterName = AnotherParameter.ParameterName) and
    (ParameterType = AnotherParameter.ParameterType) and
    (Value = AnotherParameter.Value) and
    (LowerBound = AnotherParameter.LowerBound) and
    (UpperBound = AnotherParameter.UpperBound) and
    (Scale = AnotherParameter.Scale) and
    (Offset = AnotherParameter.Offset) and
    (Transform = AnotherParameter.Transform) and
    (ChangeLimitation = AnotherParameter.ChangeLimitation) and
    (ParameterGroup = AnotherParameter.ParameterGroup) and
    (TiedParameterName = AnotherParameter.TiedParameterName) and
    (AbsoluteN = AnotherParameter.AbsoluteN) and
    (UseInitialValuePriorInfo = AnotherParameter.UseInitialValuePriorInfo) and
    (InitialValuePriorInfoWeight = AnotherParameter.InitialValuePriorInfoWeight) and
    (RegularizationGroup = AnotherParameter.RegularizationGroup) and
    PilotPointObsGrpCollection.IsSame(AnotherParameter.PilotPointObsGrpCollection);
end;

procedure TModflowParameter.SetAbsoluteN(const Value: double);
begin
  StoredAbsoluteN.Value := Value;
end;

procedure TModflowParameter.SetChangeLimitation(
  const Value: TPestChangeLimitation);
begin
  if FChangeLimitation <> Value then
  begin
    FChangeLimitation := Value;
    InvalidateModel;
  end;
end;

procedure TModflowParameter.SetInitialValuePriorInfoWeight(const Value: double);
begin
  StoredInitialValuePriorInfoWeight.Value := Value;
end;

procedure TModflowParameter.SetLowerBound(const Value: double);
begin
  StoredLowerBound.Value := Value;
end;

procedure TModflowParameter.SetOffset(const Value: double);
begin
  StoredOffset.Value := Value;
end;

procedure TModflowParameter.SetParameterGroup(const Value: string);
begin
  SetCaseSensitiveStringProperty(FParameterGroup, Value);
//  FParameterGroup := Value;
end;

procedure TModflowParameter.SetParameterType(const Value: TParameterType);
const
  HufParam = [ptHUF_HK, ptHUF_KDEP, ptHUF_HANI, ptHUF_VK,
      ptHUF_VANI, ptHUF_SS, ptHUF_SY];
var
  PhastModel: IModelForTModflowParameter;
  ScreenObject: IScreenObject;
  Position: Integer;
  ObjectIndex: Integer;
  LocalParamInterFace: IModflowTransientListParameter;
  Parameters: IModflowParameters;
begin
  if FParameterType <> Value then
  begin
    if (FParameterType in HufParam) or (Value in HufParam) then
    begin
      NotifyParamChange(FParameterType);
      NotifyParamChange(Value);
    end;

    if Model <> nil then
    begin
      PhastModel := Model as IModelForTModflowParameter;

      case FParameterType of
        ptUndefined: ;
        ptLPF_HK: ;
        ptLPF_HANI: ;
        ptLPF_VK: ;
        ptLPF_VANI: ;
        ptLPF_SS: ;
        ptLPF_SY: ;
        ptLPF_VKCB: ;
        ptRCH:
          begin
            if QueryInterface(IModflowTransientListParameter,
              LocalParamInterFace) <> 0 then
            begin
              Assert(False)
            end;
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              Parameters := ScreenObject.RchParameters;
              if Parameters <> nil then
              begin
                Position := Parameters.IndexOfParam(LocalParamInterFace);
                if Position >= 0 then
                begin
                  Parameters.Delete(Position);
                end;
              end;
            end;
          end;
        ptEVT:
          begin
            if QueryInterface(IModflowTransientListParameter,
              LocalParamInterFace) <> 0 then
            begin
              Assert(False)
            end;
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              Parameters := ScreenObject.EvtParameters;
              if Parameters <> nil then
              begin
                Position := Parameters.IndexOfParam(LocalParamInterFace);
                if Position >= 0 then
                begin
                  Parameters.Delete(Position);
                end;
              end;
            end;
          end;
        ptETS:
          begin
            if QueryInterface(IModflowTransientListParameter,
              LocalParamInterFace) <> 0 then
            begin
              Assert(False)
            end;
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              Parameters := ScreenObject.EtsParameters;
              if Parameters <> nil then
              begin
                Position := Parameters.IndexOfParam(LocalParamInterFace);
                if Position >= 0 then
                begin
                  Parameters.Delete(Position);
                end;
              end;
            end;
          end;
        ptCHD:
          begin
            if QueryInterface(IModflowTransientListParameter,
              LocalParamInterFace) <> 0 then
            begin
              Assert(False)
            end;
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              Parameters := ScreenObject.ChdParameters;
              if Parameters <> nil then
              begin
                Position := Parameters.IndexOfParam(LocalParamInterFace);
                if Position >= 0 then
                begin
                  Parameters.Delete(Position);
                end;
              end;
            end;
          end;
        ptGHB:
          begin
            if QueryInterface(IModflowTransientListParameter,
              LocalParamInterFace) <> 0 then
            begin
              Assert(False)
            end;
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              Parameters := ScreenObject.GhbParameters;
              if Parameters <> nil then
              begin
                Position := Parameters.IndexOfParam(LocalParamInterFace);
                if Position >= 0 then
                begin
                  Parameters.Delete(Position);
                end;
              end;
            end;
          end;
        ptQ:
          begin
            if QueryInterface(IModflowTransientListParameter,
              LocalParamInterFace) <> 0 then
            begin
              Assert(False)
            end;
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              Parameters := ScreenObject.WelParameters;
              if Parameters <> nil then
              begin
                Position := Parameters.IndexOfParam(LocalParamInterFace);
                if Position >= 0 then
                begin
                  Parameters.Delete(Position);
                end;
              end;
            end;
          end;
        ptRIV:
          begin
            if QueryInterface(IModflowTransientListParameter,
              LocalParamInterFace) <> 0 then
            begin
              Assert(False)
            end;
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              Parameters := ScreenObject.RivParameters;
              if Parameters <> nil then
              begin
                Position := Parameters.IndexOfParam(LocalParamInterFace);
                if Position >= 0 then
                begin
                  Parameters.Delete(Position);
                end;
              end;
            end;
          end;
        ptDRN:
          begin
            if QueryInterface(IModflowTransientListParameter,
              LocalParamInterFace) <> 0 then
            begin
              Assert(False)
            end;
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              Parameters := ScreenObject.DrnParameters;
              if Parameters <> nil then
              begin
                Position := Parameters.IndexOfParam(LocalParamInterFace);
                if Position >= 0 then
                begin
                  Parameters.Delete(Position);
                end;
              end;
            end;
          end;
        ptDRT:
          begin
            if QueryInterface(IModflowTransientListParameter,
              LocalParamInterFace) <> 0 then
            begin
              Assert(False)
            end;
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              Parameters := ScreenObject.DrtParameters;
              if Parameters <> nil then
              begin
                Position := Parameters.IndexOfParam(LocalParamInterFace);
                if Position >= 0 then
                begin
                  Parameters.Delete(Position);
                end;
              end;
            end;
          end;
        ptSFR:
          begin
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              ScreenObject.DeleteSfrParameter(ParameterName);
            end;
          end;
        ptHFB:
          begin
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              ScreenObject.DeleteHfbParameter(ParameterName);
            end;
          end;
        ptHUF_HK: ;
        ptHUF_HANI: ;
        ptHUF_VK: ;
        ptHUF_VANI: ;
        ptHUF_SS: ;
        ptHUF_SY: ;
        ptHUF_SYTP: ;
        ptHUF_KDEP: ;
        ptHUF_LVDA: ;
        ptSTR:
          begin
            Assert(False);
            if QueryInterface(IModflowTransientListParameter,
              LocalParamInterFace) <> 0 then
            begin
              Assert(False)
            end;
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              Parameters := ScreenObject.StrParameters;
              if Parameters <> nil then
              begin
                Position := Parameters.IndexOfParam(LocalParamInterFace);
                if Position >= 0 then
                begin
                  Parameters.Delete(Position);
                end;
              end;
            end;
          end;
        ptQMAX:
          begin
            if QueryInterface(IModflowTransientListParameter,
              LocalParamInterFace) <> 0 then
            begin
              Assert(False)
            end;
            for ObjectIndex := 0 to PhastModel.ScreenObjectCount - 1 do
            begin
              ScreenObject := PhastModel.ScreenObjectInterfaces[ObjectIndex];
              Parameters := ScreenObject.FmpWellParameters;
              if Parameters <> nil then
              begin
                Position := Parameters.IndexOfParam(LocalParamInterFace);
                if Position >= 0 then
                begin
                  Parameters.Delete(Position);
                end;
              end;
            end;
          end;
        ptPEST: ;
        else Assert(False);
      end;
      if (FParameterType = ptPEST) or  (Value = ptPEST) then
      begin
        (Model as IModelForTCustomDefinedGlobalObject).
          ChangeGlobalVariable(ParameterName, Value);
      end;
    end;

    FParameterType := Value;
    InvalidateModel;
  end;
end;

procedure TModflowParameter.SetPilotPointObsGrpCollection(
  const Value: TPPObsGrpCollection);
begin
  FPilotPointObsGrpCollection.Assign(Value);
end;

procedure TModflowParameter.SetRegularizationGroup(const Value: string);
begin
  SetCaseSensitiveStringProperty(FRegularizationGroup, Value);
end;

procedure TModflowParameter.SetUseInitialValuePriorInfo(const Value: Boolean);
begin
  FUseInitialValuePriorInfo := Value;
end;

procedure TModflowParameter.SetScale(const Value: double);
begin
  StoredScale.Value := Value;
end;

procedure TModflowParameter.SetStoredAbsoluteN(const Value: TRealStorage);
begin
  FStoredAbsoluteN.Assign(Value);
end;

procedure TModflowParameter.SetStoredInitialValuePriorInfoWeight(
  const Value: TRealStorage);
begin
  FStoredInitialValuePriorInfoWeight.Assign(Value);
end;

procedure TModflowParameter.SetStoredLowerBound(const Value: TRealStorage);
begin
  FStoredLowerBound.Assign(Value);
end;

procedure TModflowParameter.SetStoredOffset(const Value: TRealStorage);
begin
  FStoredOffset.Assign(Value);
end;

procedure TModflowParameter.SetStoredScale(const Value: TRealStorage);
begin
  FStoredScale.Assign(Value);
end;

procedure TModflowParameter.SetStoredUpperBound(const Value: TRealStorage);
begin
  FStoredUpperBound.Assign(Value);
end;

procedure TModflowParameter.SetTiedParameterName(const Value: string);
begin
  SetCaseSensitiveStringProperty(FTiedParameterName, Value);
end;

procedure TModflowParameter.SetTransform(const Value: TPestTransform);
begin
  if FTransform <> Value then
  begin
    FTransform := Value;
    InvalidateModel;
  end;
end;

procedure TModflowParameter.SetUpperBound(const Value: double);
begin
  StoredUpperBound.Value := Value;
end;

procedure TModflowParameter.SetValue(AValue : double);
var
//  PhastModel: IModelForTOrderedCollection;
  ScreenObject: IScreenObject;
  ScreenObjectIndex: Integer;
begin
  if FValue <> AValue then
  begin
    FValue := AValue;
    if Model <> nil then
    begin
      if ParameterType in [ptHUF_HK, ptHUF_KDEP]  then
      begin
        NotifyHufKx;
      end;
      if ParameterType in [ptHUF_HK, ptHUF_KDEP, ptHUF_HANI]  then
      begin
        NotifyHufKy;
      end;
      if ParameterType in [ptHUF_HK, ptHUF_KDEP, ptHUF_VK, ptHUF_VANI]  then
      begin
        NotifyHufKz
      end;
      if ParameterType = ptHUF_SS  then
      begin
        NotifyHufSs;
      end;
      if ParameterType = ptHUF_SY  then
      begin
        NotifyHufSy;
      end;
      if ParameterType = ptRCH then
      begin
        Model.InvalidateMfRchRate(nil);
      end;
      if ParameterType = ptEVT then
      begin
        Model.InvalidateMfEvtEvapRate(nil);
      end;
      if ParameterType = ptETS then
      begin
        Model.InvalidateMfEtsEvapRate(nil);
      end;
      if ParameterType = ptETS then
      begin
        Model.InvalidateMfEtsEvapRate(nil);
      end;
    end;
    if (ParameterType = ptHFB) then
    begin
      if Model <> nil then
      begin
        for ScreenObjectIndex := 0 to Model.ScreenObjectCount - 1 do
        begin
          ScreenObject := Model.ScreenObjectInterfaces[ScreenObjectIndex];
          ScreenObject.HandleChangedHfbParameter(ParameterName);
        end;
      end;
    end;
    InvalidateModel;
  end;
end;

function TEnhancedOrderedCollection.IndexOf(Item: TOrderedItem): integer;
var
  Index: Integer;
begin
  result := -1;
  for Index := 0 to Count - 1 do
  begin
    if Items[Index] = Item then
    begin
      result := Index;
      break;
    end;
  end;
end;

procedure TEnhancedOrderedCollection.Remove(Item: TOrderedItem);
var
  Index: integer;
begin
  Index := IndexOf(Item);
  if Index >= 0 then
  begin
    Delete(Index);
  end;
end;

procedure TOrderedItem.SetRealProperty(var AField: double; NewValue: double);
begin
  if NewValue < -1.79769313486231E308 then
  begin
    NewValue := -1.79769313486231E308;
  end
  else if NewValue > 1.79769313486231E308 then
  begin
    NewValue := 1.79769313486231E308;
  end;
  if AField <> NewValue then
  begin
    AField := NewValue;
    InvalidateModel;
  end;
end;

function TOrderedItem._AddRef: Integer;
begin
  result := -1;
end;

function TOrderedItem._Release: Integer;
begin
  result := -1;
end;

procedure TOrderedItem.SetCaseInsensitiveStringProperty(var AField: string;
  NewValue: string);
begin
  if AnsiCompareText(AField, NewValue) <> 0 then
  begin
    AField := NewValue;
    InvalidateModel;
  end;
end;

procedure TOrderedItem.SetCaseSensitiveStringProperty(var AField: string;
  const NewValue: string);
begin
  if AField <> NewValue then
  begin
    AField := NewValue;
    InvalidateModel;
  end;
end;

procedure TOrderedItem.SetBooleanProperty(var AField: boolean; const NewValue: boolean);
begin
  if AField <> NewValue then
  begin
    AField := NewValue;
    InvalidateModel;
  end;
end;

procedure TOrderedItem.SetIntegerProperty(var AField: Integer;
  const NewValue: Integer);
begin
  if AField <> NewValue then
  begin
    AField := NewValue;
    InvalidateModel;
  end;
end;

function TFormulaOrderedItem.CreateBlockFormulaObject(
  Orientation: TDataSetOrientation): IFormulaObject;
var
  LocalModel: IModelForTOrderedCollection;
begin
  LocalModel := Model;
  if LocalModel = nil then
  begin
    LocalModel := IGlobalModelForOrderedCollection;
  end;
  result := LocalModel.CreateBlockFormulaObjectI(Orientation);// as TFormulaObject;
end;

function TFormulaOrderedItem.GetScreenObjectI: IScreenObject;
begin
  result := ScreenObject as TObserver as IScreenObject;
end;

procedure TFormulaOrderedItem.UpdateFormulaBlocks(Value: string; Position: integer;
  var FormulaObject: IFormulaObject);
var
  Compiler: TRbwParser;
  LocalObserver: TObserver;
begin
  if FormulaObject.Formula <> Value then
  begin
    if Model <> nil then
    begin
      Compiler := Model.FormulaCompiler[dso3D, eaBlocks];
      LocalObserver := Observer[Position];
      UpdateFormulaDependencies(FormulaObject.Formula, Value, LocalObserver,
        Compiler);
    end;
    InvalidateModel;
    if IGlobalModelForOrderedCollection <> nil then
    begin
      if (IGlobalModelForOrderedCollection <> nil)
        and not(csDestroying in (IGlobalModelForOrderedCollection as TComponent).ComponentState)
        and not IGlobalModelForOrderedCollection.Clearing then
      begin
        FormulaObject.ScreenObject := ScreenObjectI;
        try
          IGlobalModelForOrderedCollection.ChangeFormula(FormulaObject, Value, eaBlocks,
            OnRemoveSubscription, OnRestoreSubscription, self);
        finally
          FormulaObject.ScreenObject := nil;
        end;
      end;
    end;
  end;
end;

procedure TFormulaOrderedItem.UpdateFormulaDependencies(OldFormula: string;
  var NewFormula: string; Observer: TObserver; Compiler: TRbwParser);
begin
  if (ScreenObject = nil) then
  begin
    Exit;
  end;

  if Model.Clearing then
  begin
    Exit;
  end;

  Model.UpdateFormulaDependencies(OldFormula, NewFormula, Observer, Compiler,
    ScreenObjectI);
end;

procedure TFormulaOrderedItem.UpdateFormulaNodes(Value: string;
  Position: integer; var FormulaObject: IFormulaObject);
var
  Compiler: TRbwParser;
  LocalObserver: TObserver;
begin
  if FormulaObject.Formula <> Value then
  begin
    if Model <> nil then
    begin
      Compiler := Model.FormulaCompiler[dso3D, eaNodes];
      LocalObserver := Observer[Position];
      UpdateFormulaDependencies(FormulaObject.Formula, Value, LocalObserver,
        Compiler);
    end;
    InvalidateModel;
    if (IGlobalModelForOrderedCollection <> nil)
      and not(csDestroying in (IGlobalModelForOrderedCollection as TComponent).ComponentState)
      and not IGlobalModelForOrderedCollection.Clearing then
    begin
      IGlobalModelForOrderedCollection.ChangeFormula(FormulaObject, Value, eaNodes,
        OnRemoveSubscription, OnRestoreSubscription, self);
    end;
  end;
end;

{ TCustomObjectOrderedCollection }

constructor TCustomObjectOrderedCollection.Create(
  ItemClass: TCollectionItemClass;
  Model: IModelForTOrderedCollection; AScreenObject: IScreenObject);
begin
  inherited Create(ItemClass, Model);
  FScreenObject := AScreenObject;
end;


{ TPestMethodItem }

procedure TPestMethodItem.Assign(Source: TPersistent);
begin
  if Source is TPestMethodItem then
  begin
    PestParamMethod := TPestMethodItem(Source).PestParamMethod;
  end
  else
  begin
    inherited;
  end;
end;

function TPestMethodItem.IsSame(AnotherItem: TOrderedItem): boolean;
begin
  if AnotherItem is TPestMethodItem then
  begin
    result := PestParamMethod = TPestMethodItem(AnotherItem).PestParamMethod;
  end
  else
  begin
    result := False;
  end;
end;

procedure TPestMethodItem.SetPestParamMethod(const Value: TPestParamMethod);
begin
  if FPestParamMethod <> Value then
  begin
    FPestParamMethod := Value;
    InvalidateModel;
  end;

end;

{ TPestMethodCollection }

constructor TGwtPestMethodCollection.Create(Model: IModelForTOrderedCollection);
begin
  inherited Create(TPestMethodItem, Model);
end;

function TGwtPestMethodCollection.GetCount: Integer;
var
  MobileComponentCount: Integer;
begin
  if (IGlobalModelForOrderedCollection <> nil) and IGlobalModelForOrderedCollection.GwtUsed then
  begin
    MobileComponentCount := (IGlobalModelForOrderedCollection
      as IModelForTGwtPestMethodCollection).GetMobileComponentCount;
    if inherited GetCount < MobileComponentCount then
    begin
      inherited Count := MobileComponentCount
    end;
  end;
  result := inherited;
end;

function TGwtPestMethodCollection.GetItems(const Index: Integer): TPestMethodItem;
var
  LocalModel: IModelForTGwtPestMethodCollection;
begin
  LocalModel := Model as IModelForTGwtPestMethodCollection;
  if LocalModel = nil then
  begin
    LocalModel := IGlobalModel as IModelForTGwtPestMethodCollection;
  end;
  if (LocalModel <> nil)
    and (Count < LocalModel.GetMobileComponentCount) then
  begin
    Count := LocalModel.GetMobileComponentCount;
  end;
  result := inherited Items[Index] as TPestMethodItem;
end;

procedure TGwtPestMethodCollection.SetItems(const Index: Integer;
  const Value: TPestMethodItem);
begin
  inherited Items[Index] := Value;
end;

{ TPilotPointObsGrp }

procedure TPilotPointObsGrp.Assign(Source: TPersistent);
var
  SrcGrp: TPilotPointObsGrp;
begin
  if Source is TPilotPointObsGrp then
  begin
    SrcGrp := TPilotPointObsGrp(Source);
    Layer := SrcGrp.Layer;
    ParamFamily := SrcGrp.ParamFamily;
    ObsGroupName := SrcGrp.ObsGroupName;
  end
  else
  begin
    inherited;
  end;
end;

function TPilotPointObsGrp.GetObsGroupName: string;
begin
  if FObsGroup <> nil then
  begin
    FObsGroupName := FObsGroup.ObsGroupName;
  end;
  result := FObsGroupName
end;

function TPilotPointObsGrp.IsSame(OtherItem: TPilotPointObsGrp): Boolean;
begin
  result := (Layer = OtherItem.Layer)
    and (ParamFamily = OtherItem.ParamFamily)
    and (ObsGroupName = OtherItem.ObsGroupName);
end;

procedure TPilotPointObsGrp.SetLayer(const Value: Integer);
begin
  FLayer := Value;
end;

procedure TPilotPointObsGrp.SetObsGroupName(const Value: string);
var
  LocalModel: IModelForTPilotPointObsGrp;
begin
  FObsGroupName := Value;
  if (Collection as TPPObsGrpCollection).FModel <> nil then
  begin
    LocalModel := (Collection as TPPObsGrpCollection).FModel as IModelForTPilotPointObsGrp;
    FObsGroup := LocalModel.GetObsGroupFromName(Value);
    if FObsGroup <> nil then
    begin
      FObsGroupName := FObsGroup.ObsGroupName;
    end;
  end;

end;

procedure TPilotPointObsGrp.SetParamFamily(const Value: string);
begin
  FParamFamily := Value;
end;

{ TPPObsGrpCollection }

function TPPObsGrpCollection.Add: TPilotPointObsGrp;
begin
  result := inherited Add as TPilotPointObsGrp;
end;


constructor TPPObsGrpCollection.Create(Model: IModelMuseModel);
var
  InvalidateEvent: TNotifyEvent;
begin
  FModel := Model;
  InvalidateEvent := nil;
  inherited Create(TPilotPointObsGrp, InvalidateEvent);
end;

function TPPObsGrpCollection.GetGroupNameByLayerAndFamily(Layer: integer; const ParamFamily: string): string;
var
  Index: Integer;
begin
  result := '';
  for Index := 0 to Count - 1 do
  begin
    if (Items[Index].Layer = Layer) and (Items[Index].ParamFamily = ParamFamily) then
    begin
      result := Items[Index].ObsGroupName;
      break;
    end;
  end;
end;

function TPPObsGrpCollection.GetItem(Index: Integer): TPilotPointObsGrp;
begin
  result := inherited Items[Index] as TPilotPointObsGrp;
end;

function TPPObsGrpCollection.IsSame(
  OtherCollection: TPPObsGrpCollection): Boolean;
var
  Index: Integer;
begin
  result := Count = OtherCollection.Count;
  if result then
  begin
    for Index := 0 to Count - 1 do
    begin
      result := Items[Index].IsSame(OtherCollection[Index]);
      if not result then
      begin
        break;
      end;
    end;
  end;
end;

procedure TPPObsGrpCollection.SetGroupNameByLayerAndFamily(Layer: integer;
  const ParamFamily: string; const GroupName: string);
var
  Item: TPilotPointObsGrp;
  Index: Integer;
begin
  for Index := 0 to Count - 1 do
  begin
    if (Items[Index].Layer = Layer) and (Items[Index].ParamFamily = ParamFamily) then
    begin
      if GroupName = '' then
      begin
        Items[Index].Free;
      end
      else
      begin
        Items[Index].ObsGroupName := GroupName;
      end;
      Exit;
    end;
  end;
  if GroupName <> '' then
  begin
    Item := Add;
    Item.Layer := Layer;
    Item.ParamFamily := ParamFamily;
    Item.ObsGroupName := GroupName;
  end;
end;

procedure TPPObsGrpCollection.SetItem(Index: Integer;
  const Value: TPilotPointObsGrp);
begin
  inherited Items[Index] := Value;
end;

{ TLandUsePestMethodCollection }

constructor TLandUsePestMethodCollection.Create(Model: IModelForTOrderedCollection);
begin
  inherited Create(TPestMethodItem, Model);
end;

function TLandUsePestMethodCollection.GetCount: Integer;
var
  LocalModel: IModelForTLandUsePestMethodCollection;
begin
  if (Model <> nil) and Model.GwtUsed  then
  begin
    LocalModel := Model as IModelForTLandUsePestMethodCollection;
    if inherited GetCount < LocalModel.CropCount then
    begin
      inherited Count := LocalModel.CropCount;
    end;
  end;
  result := inherited;
end;

function TLandUsePestMethodCollection.GetItems(
  const Index: Integer): TPestMethodItem;
var
  LocalModel: IModelForTLandUsePestMethodCollection;
begin
  LocalModel := Model as IModelForTLandUsePestMethodCollection;
  if LocalModel = nil then
  begin
    LocalModel := IGlobalModel as IModelForTLandUsePestMethodCollection;
  end;
  if (LocalModel <> nil)
    and (Count < LocalModel.CropCount) then
  begin
    Count := LocalModel.CropCount;
  end;
  result := inherited Items[Index] as TPestMethodItem;
end;

procedure TLandUsePestMethodCollection.SetItems(const Index: Integer;
  const Value: TPestMethodItem);
begin
  inherited Items[Index] := Value;
end;

end.
