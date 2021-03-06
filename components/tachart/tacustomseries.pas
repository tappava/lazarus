{
 *****************************************************************************
  See the file COPYING.modifiedLGPL.txt, included in this distribution,
  for details about the license.
 *****************************************************************************

  Basic types for TAChart series.

  Authors: Alexander Klenin

}
unit TACustomSeries;

{$H+}

interface

uses
  Classes, GraphType, Graphics, IntfGraphics, SysUtils,
  TAChartAxis, TAChartUtils, TACustomSource, TADrawUtils, TAGraph, TALegend,
  TASources, TAStyles, TATextElements, TATypes;

const
  DEF_AXIS_INDEX = -1;

type
  TNearestPointParams = record
    FDistFunc: TPointDistFunc;
    FOptimizeX: Boolean;
    FPoint: TPoint;
    FRadius: Integer;
    FTargets: TNearestPointTargets;
  end;

  TNearestPointResults = record
    FDist: Integer;
    FImg: TPoint;
    FIndex: Integer;        // Point index
    FXIndex: Integer;       // Index to be used in Source.GetX()
    FYIndex: Integer;       // Index to be used in Source.GetY()
    FValue: TDoublePoint;
  end;

  TChartAxisIndex = -1..MaxInt;

  { TCustomChartSeries }

  TCustomChartSeries = class(TBasicChartSeries)
  strict private
    FAxisIndexX: TChartAxisIndex;
    FAxisIndexY: TChartAxisIndex;
    FLegend: TChartSeriesLegend;
    FToolTargets: TNearestPointTargets;
    FTitle: String;
    procedure SetAxisIndexX(AValue: TChartAxisIndex);
    procedure SetAxisIndexY(AValue: TChartAxisIndex);
    procedure SetLegend(AValue: TChartSeriesLegend);

  protected
    procedure AfterAdd; override;
    procedure GetLegendItems(AItems: TChartLegendItems); virtual; abstract;
    procedure GetLegendItemsBasic(AItems: TChartLegendItems); override;
    function GetShowInLegend: Boolean; override;
    procedure SetActive(AValue: Boolean); override;
    procedure SetDepth(AValue: TChartDistance); override;
    procedure SetShadow(AValue: TChartShadow); override;
    procedure SetShowInLegend(AValue: Boolean); override;
    procedure SetTitle(AValue: String); virtual;
    procedure SetTransparency(AValue: TChartTransparency); override;
    procedure SetZPosition(AValue: TChartDistance); override;
    procedure StyleChanged(Sender: TObject);
    procedure UpdateParentChart;

  protected
    procedure ReadState(Reader: TReader); override;
    procedure SetParentComponent(AParent: TComponent); override;

  strict protected
    // Set series bounds in axis coordinates.
    // Some or all bounds may be left unset, in which case they will be ignored.
    procedure GetBounds(var ABounds: TDoubleRect); virtual; abstract;
    function GetIndex: Integer; override;
    function LegendTextSingle: String;
    function LegendTextStyle(AStyle: TChartStyle): String;
    procedure SetIndex(AValue: Integer); override;
    function TitleIsStored: Boolean; virtual;
    property ToolTargets: TNearestPointTargets
      read FToolTargets write FToolTargets default [nptPoint];

  public
    function AxisToGraph(const APoint: TDoublePoint): TDoublePoint; inline;
    function AxisToGraphX(AX: Double): Double; override;
    function AxisToGraphY(AY: Double): Double; override;
    function GetAxisX: TChartAxis;
    function GetAxisY: TChartAxis;
    function GetAxisBounds(AAxis: TChartAxis; out AMin, AMax: Double): Boolean; override;
    function GetGraphBounds: TDoubleRect; override;
    function GraphToAxis(APoint: TDoublePoint): TDoublePoint;
    function GraphToAxisX(AX: Double): Double; override;
    function GraphToAxisY(AY: Double): Double; override;
    function IsRotated: Boolean;

  public
    procedure Assign(ASource: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetNearestPoint(
      const AParams: TNearestPointParams;
      out AResults: TNearestPointResults): Boolean; virtual;
    function GetParentComponent: TComponent; override;
    procedure GetSingleLegendItem(AItems: TChartLegendItems);
    function HasParent: Boolean; override;

    property AxisIndexX: TChartAxisIndex
      read FAxisIndexX write SetAxisIndexX default DEF_AXIS_INDEX;
    property AxisIndexY: TChartAxisIndex
      read FAxisIndexY write SetAxisIndexY default DEF_AXIS_INDEX;
    property Title: String read FTitle write SetTitle stored TitleIsStored;

  published
    property Legend: TChartSeriesLegend read FLegend write SetLegend;
    property Shadow;
    property ShowInLegend: Boolean
      read GetShowInLegend write SetShowInLegend stored false default true;
      deprecated;
    property Transparency;
  end;

  TChartGetMarkEvent = procedure (
    out AFormattedMark: String; AIndex: Integer) of object;

  { TChartSeries }

  TChartSeries = class(TCustomChartSeries)
  strict private
    FBuiltinSource: TCustomChartSource;
    FListener: TListener;
    FMarks: TChartMarks;
    FOnGetMark: TChartGetMarkEvent;
    FSource: TCustomChartSource;
    FStyles: TChartStyles;
    FStylesListener: TListener;

    function GetSource: TCustomChartSource;
    function IsSourceStored: boolean;
    procedure SetMarks(AValue: TChartMarks);
    procedure SetOnGetMark(AValue: TChartGetMarkEvent);
    procedure SetSource(AValue: TCustomChartSource);
    procedure SetStyles(AValue: TChartStyles);
  protected
    procedure AfterAdd; override;
    procedure AfterDraw; override;
    procedure BeforeDraw; override;
    procedure GetBounds(var ABounds: TDoubleRect); override;
    function GetGraphPoint(AIndex: Integer): TDoublePoint; overload;
    function GetGraphPoint(AIndex, AXIndex, AYIndex: Integer): TDoublePoint; overload;
    function GetGraphPointX(AIndex: Integer): Double; overload; inline;
    function GetGraphPointX(AIndex, AXIndex: Integer): Double; overload; inline;
    function GetGraphPointY(AIndex: Integer): Double; overload; inline;
    function GetGraphPointY(AIndex, AYIndex: Integer): Double; overload; inline;
    function GetSeriesColor: TColor; virtual;
    function GetXMaxVal: Double;
    procedure SourceChanged(ASender: TObject); virtual;
    procedure VisitSources(
      AVisitor: TChartOnSourceVisitor; AAxis: TChartAxis; var AData); override;
  strict protected
    function LegendTextPoint(AIndex: Integer): String; inline;
  protected
    property Styles: TChartStyles read FStyles write SetStyles;
  public
    procedure Assign(ASource: TPersistent); override;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

  public
    function  GetColor(AIndex: Integer): TColor;
    procedure GetMax(out X, Y: Double);
    procedure GetMin(out X, Y: Double);
    function  GetXImgValue(AIndex: Integer): Integer;
    function  GetXMax: Double;
    function  GetXMin: Double;
    function  GetXValue(AIndex: Integer): Double;
    function  GetXValues(AIndex, AXIndex: Integer): Double;
    function  GetYImgValue(AIndex: Integer): Integer;
    function  GetYMax: Double;
    function  GetYMin: Double;
    function  GetYValue(AIndex: Integer): Double;
    function  GetYValues(AIndex, AYIndex: Integer): Double;
    procedure SetColor(AIndex: Integer; AColor: TColor); inline;
    procedure SetText(AIndex: Integer; AValue: String); inline;
    procedure SetXValue(AIndex: Integer; AValue: Double); inline;
    procedure SetXValues(AIndex, AXIndex: Integer; AValue: Double);
    procedure SetYValue(AIndex: Integer; AValue: Double); inline;
    procedure SetYValues(AIndex, AYIndex: Integer; AValue: Double);
  public
    function Add(
      AValue: Double;
      AXLabel: String = ''; AColor: TColor = clTAColor): Integer; inline;
    function AddArray(const AValues: array of Double): Integer;
    function AddNull(ALabel: String = ''; AColor: TColor = clTAColor): Integer; inline;
    function AddX(
      AX: Double; ALabel: String = ''; AColor: TColor = clTAColor): Integer; inline;
    function AddXY(
      AX, AY: Double;
      AXLabel: String = ''; AColor: TColor = clTAColor): Integer; overload; inline;
    function AddXY(
      AX, AY: Double; const AYList: array of Double;
      AXLabel: String = ''; AColor: TColor = clTAColor): Integer; overload;
    function AddY(
      AY: Double; ALabel: String = ''; AColor: TColor = clTAColor): Integer; inline;
    procedure BeginUpdate;
    procedure Clear; virtual;
    function Count: Integer; inline;
    procedure Delete(AIndex: Integer); virtual;
    procedure EndUpdate;
    function Extent: TDoubleRect; virtual;
    function FormattedMark(
      AIndex: Integer; AFormat: String = ''; AYIndex: Integer = 0): String;
    function IsEmpty: Boolean; override;
    function ListSource: TListChartSource;
    property Source: TCustomChartSource
      read GetSource write SetSource stored IsSourceStored;
  public
    // for Delphi compatibility
    function LastValueIndex: Integer; inline;
    function MaxXValue: Double;
    function MinXValue: Double;
    function MaxYValue: Double;
    function MinYValue: Double;
    property XValue[AIndex: Integer]: Double read GetXValue write SetXValue;
    property XValues[AIndex, AXIndex: Integer]: Double read GetXValues write SetXValues;
    property YValue[AIndex: Integer]: Double read GetYValue write SetYValue;
    property YValues[AIndex, AYIndex: Integer]: Double read GetYValues write SetYValues;
  published
    property Active default true;
    property Marks: TChartMarks read FMarks write SetMarks;
    property ShowInLegend;
    property Title;
    property ZPosition;
  published
    property OnGetMark: TChartGetMarkEvent read FOnGetMark write SetOnGetMark;
  end;

  TLabelDirection = (ldLeft, ldTop, ldRight, ldBottom);

  TLinearMarkPositions = (lmpOutside, lmpPositive, lmpNegative, lmpInside, lmpInsideCenter);

  TSeriesPointerCustomDrawEvent = procedure (
    ASender: TChartSeries; ADrawer: IChartDrawer; AIndex: Integer;
    ACenter: TPoint) of object;

  TSeriesPointerStyleEvent = procedure (ASender: TChartSeries;
    AValueIndex: Integer; var AStyle: TSeriesPointerStyle) of object;

  { TBasicPointSeries }

  TBasicPointSeries = class(TChartSeries)
  strict private
    FMarkPositions: TLinearMarkPositions;
    FOnCustomDrawPointer: TSeriesPointerCustomDrawEvent;
    FOnGetPointerStyle: TSeriesPointerStyleEvent;
    function GetLabelDirection(AIndex: Integer): TLabelDirection;
    procedure SetMarkPositions(AValue: TLinearMarkPositions);
    procedure SetPointer(AValue: TSeriesPointer);
    procedure SetStacked(AValue: Boolean);
    procedure SetUseReticule(AValue: Boolean);
  strict protected
    FGraphPoints: array of TDoublePoint;
    FLoBound: Integer;
    FMinXRange: Double;
    FPointer: TSeriesPointer;
    FStacked: Boolean;
    FUpBound: Integer;
    FUseReticule: Boolean;
    FOptimizeX: Boolean;

    procedure AfterDrawPointer(
      ADrawer: IChartDrawer; AIndex: Integer; const APos: TPoint); virtual;
    procedure DrawLabels(ADrawer: IChartDrawer);
    procedure DrawPointers(ADrawer: IChartDrawer; AStyleIndex: Integer = 0;
      UseDataColors: Boolean = false);
    procedure FindExtentInterval(
      const AExtent: TDoubleRect; AFilterByExtent: Boolean);
    function GetLabelDataPoint(AIndex: Integer): TDoublePoint; virtual;
    procedure GetLegendItemsRect(AItems: TChartLegendItems; ABrush: TBrush);
    function GetXRange(AX: Double; AIndex: Integer): Double;
    function GetZeroLevel: Double; virtual;
    function NearestXNumber(var AIndex: Integer; ADir: Integer): Double;
    procedure PrepareGraphPoints(
      const AExtent: TDoubleRect; AFilterByExtent: Boolean);
    function ToolTargetDistance(const AParams: TNearestPointParams;
      AGraphPt: TDoublePoint; APointIdx, AXIdx, AYIdx: Integer): Integer; virtual;
    procedure UpdateGraphPoints(AIndex: Integer; ACumulative: Boolean); overload; inline;
    procedure UpdateGraphPoints(AIndex, ALo, AUp: Integer; ACumulative: Boolean); overload;
    procedure UpdateMinXRange;

    property Pointer: TSeriesPointer read FPointer write SetPointer;
    property Stacked: Boolean read FStacked write SetStacked;
  protected
    procedure AfterAdd; override;
    procedure UpdateMargins(ADrawer: IChartDrawer; var AMargins: TRect); override;
    property OnCustomDrawPointer: TSeriesPointerCustomDrawEvent
      read FOnCustomDrawPointer write FOnCustomDrawPointer;
    property OnGetPointerStyle: TSeriesPointerStyleEvent
      read FOnGetPointerStyle write FOnGetPointerStyle;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  public
    procedure Assign(ASource: TPersistent); override;
    function Extent: TDoubleRect; override;
    function GetNearestPoint(
      const AParams: TNearestPointParams;
      out AResults: TNearestPointResults): Boolean; override;
    procedure MovePoint(var AIndex: Integer; const ANewPos: TDoublePoint); override;
    procedure MovePointEx(var AIndex: Integer; AXIndex, AYIndex: Integer;
      const ANewPos: TDoublePoint); override;
    property MarkPositions: TLinearMarkPositions
      read FMarkPositions write SetMarkPositions default lmpOutside;
    property ToolTargets default [nptPoint, nptYList];
    property UseReticule: Boolean
      read FUseReticule write SetUseReticule default false;
    property ExtentPointIndexFirst: Integer read FLoBound;
    property ExtentPointIndexLast: Integer read FUpBound;
  end;

  function CreateLazIntfImage(
    out ARawImage: TRawImage; const ASize: TPoint): TLazIntfImage;

implementation

uses
  Math, PropEdits, StrUtils, TAGeometry, TAMath, Types;

function CreateLazIntfImage(
  out ARawImage: TRawImage; const ASize: TPoint): TLazIntfImage;
begin
  ARawImage.Init;
  ARawImage.Description.Init_BPP32_B8G8R8A8_BIO_TTB(ASize.X, ASize.Y);
  ARawImage.CreateData(true);
  Result := TLazIntfImage.Create(0, 0);
  Result.SetRawImage(ARawImage);
end;

{ TCustomChartSeries }

procedure TCustomChartSeries.AfterAdd;
begin
  Legend.SetOwner(FChart);
  Shadow.SetOwner(FChart);
end;

procedure TCustomChartSeries.Assign(ASource: TPersistent);
begin
  if ASource is TCustomChartSeries then
    with TCustomChartSeries(ASource) do begin
      Self.FAxisIndexX := FAxisIndexX;
      Self.FAxisIndexY := FAxisIndexY;
      Self.Legend := FLegend;
      Self.FTitle := FTitle;
      Self.FToolTargets := FToolTargets;
    end;
  inherited Assign(ASource);
end;

function TCustomChartSeries.AxisToGraph(
  const APoint: TDoublePoint): TDoublePoint;
begin
  Result := DoublePoint(AxisToGraphX(APoint.X), AxisToGraphY(APoint.Y));
  if IsRotated then
    Exchange(Result.X, Result.Y);
end;

function TCustomChartSeries.AxisToGraphX(AX: Double): Double;
begin
  Result := TransformByAxis(FChart.AxisList, AxisIndexX).AxisToGraph(AX)
end;

function TCustomChartSeries.AxisToGraphY(AY: Double): Double;
begin
  Result := TransformByAxis(FChart.AxisList, AxisIndexY).AxisToGraph(AY)
end;

constructor TCustomChartSeries.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FActive := true;
  FAxisIndexX := DEF_AXIS_INDEX;
  FAxisIndexY := DEF_AXIS_INDEX;
  FLegend := TChartSeriesLegend.Create(FChart);
  FToolTargets := [nptPoint];
  FShadow := TChartShadow.Create(FChart);
end;

destructor TCustomChartSeries.Destroy;
begin
  FreeAndNil(FLegend);
  FreeAndNil(FShadow);
  inherited;
end;

function TCustomChartSeries.GetAxisBounds(AAxis: TChartAxis;
  out AMin, AMax: Double): Boolean;
var
  ex: TDoubleRect;
begin
  if (AAxis.Index = AxisIndexX) or (AAxis.Index = AxisIndexY) then begin
    ex := EmptyExtent;
    GetBounds(ex);
    with ex do begin
      UpdateBoundsByAxisRange(FChart.AxisList, AxisIndexX, a.X, b.X);
      UpdateBoundsByAxisRange(FChart.AxisList, AxisIndexY, a.Y, b.Y);
      if IsRotated then begin
        Exchange(a.X, a.Y);
        Exchange(b.X, b.Y);
      end;
    end;
    AMin := TDoublePointBoolArr(ex.a)[AAxis.IsVertical];
    AMax := TDoublePointBoolArr(ex.b)[AAxis.IsVertical];
    Result := true;
  end else
    Result := false;
end;

function TCustomChartSeries.GetAxisX: TChartAxis;
begin
  if InRange(AxisIndexX, 0, FChart.AxisList.Count - 1) then
    Result := FChart.AxisList[AxisIndexX]
  else
    Result := FChart.BottomAxis;
end;

function TCustomChartSeries.GetAxisY: TChartAxis;
begin
  if InRange(AxisIndexY, 0, FChart.AxisList.Count - 1) then
    Result := FChart.AxisList[AxisIndexY]
  else
    Result := FChart.LeftAxis;
end;

function TCustomChartSeries.GetGraphBounds: TDoubleRect;
begin
  Result := EmptyExtent;
  GetBounds(Result);
  with Result do begin
    UpdateBoundsByAxisRange(FChart.AxisList, AxisIndexX, a.X, b.X);
    UpdateBoundsByAxisRange(FChart.AxisList, AxisIndexY, a.Y, b.Y);
    TransformByAxis(FChart.AxisList, AxisIndexX).UpdateBounds(a.X, b.X);
    TransformByAxis(FChart.AxisList, AxisIndexY).UpdateBounds(a.Y, b.Y);
    if IsRotated then begin
      Exchange(a.X, a.Y);
      Exchange(b.X, b.Y);
    end;
  end;
end;

function TCustomChartSeries.GetIndex: Integer;
begin
  Result := FChart.Series.List.IndexOf(Self);
end;

procedure TCustomChartSeries.GetLegendItemsBasic(AItems: TChartLegendItems);
var
  i, oldCount: Integer;
begin
  oldCount := AItems.Count;
  if Assigned(Legend.OnDraw) then
    for i := 0 to Legend.UserItemsCount - 1 do
      AItems.Add(TLegendItemUserDrawn.Create(i, Legend.OnDraw, LegendTextSingle))
  else
    GetLegendItems(AItems);
  for i := oldCount to AItems.Count - 1 do begin
    AItems[i].Owner := Self;
    Legend.InitItem(AItems[i], i - oldCount, FChart.Legend);
  end;
end;

function TCustomChartSeries.GetNearestPoint(
  const AParams: TNearestPointParams;
  out AResults: TNearestPointResults): Boolean;
begin
  Unused(AParams);
  AResults.FDist := MaxInt;
  AResults.FImg := Point(0, 0);
  AResults.FIndex := 0;
  AResults.FValue := ZeroDoublePoint;
  Result := false;
end;

function TCustomChartSeries.GetParentComponent: TComponent;
begin
  Result := FChart;
end;

function TCustomChartSeries.GetShowInLegend: Boolean;
begin
  Result := Legend.Visible;
end;

procedure TCustomChartSeries.GetSingleLegendItem(AItems: TChartLegendItems);
var
  oldMultiplicity: TLegendMultiplicity;
begin
  ParentChart.DisableRedrawing;
  oldMultiplicity := Legend.Multiplicity;
  try
    Legend.Multiplicity := lmSingle;
    GetLegendItemsBasic(AItems);
  finally
    Legend.Multiplicity := oldMultiplicity;
    ParentChart.EnableRedrawing;
  end;
end;

function TCustomChartSeries.GraphToAxis(APoint: TDoublePoint): TDoublePoint;
begin
  if IsRotated then
    Exchange(APoint.X, APoint.Y);
  Result := DoublePoint(GraphToAxisX(APoint.X), GraphToAxisY(APoint.Y));
end;

function TCustomChartSeries.GraphToAxisX(AX: Double): Double;
begin
  Result := TransformByAxis(FChart.AxisList, AxisIndexX).GraphToAxis(AX)
end;

function TCustomChartSeries.GraphToAxisY(AY: Double): Double;
begin
  Result := TransformByAxis(FChart.AxisList, AxisIndexY).GraphToAxis(AY)
end;

function TCustomChartSeries.HasParent: Boolean;
begin
  Result := true;
end;

function TCustomChartSeries.IsRotated: Boolean;
begin
  Result :=
    (AxisIndexX >= 0) and FChart.AxisList[AxisIndexX].IsVertical and
    (AxisIndexY >= 0) and not FChart.AxisList[AxisIndexY].IsVertical;
end;

function TCustomChartSeries.LegendTextSingle: String;
begin
  if Legend.Format = '' then
    Result := Title
  else
    Result := Format(Legend.Format, [Title, Index]);
end;

function TCustomChartSeries.LegendTextStyle(AStyle: TChartStyle): String;
begin
  if Legend.Format = '' then
    Result := AStyle.Text
  else
    Result := Format(Legend.Format, [AStyle.Text, AStyle.Index]);
end;

procedure TCustomChartSeries.ReadState(Reader: TReader);
begin
  inherited ReadState(Reader);
  if Reader.Parent is TChart then
    (Reader.Parent as TChart).AddSeries(Self);
end;

procedure TCustomChartSeries.SetActive(AValue: Boolean);
begin
  if FActive = AValue then exit;
  FActive := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetAxisIndexX(AValue: TChartAxisIndex);
begin
  if FAxisIndexX = AValue then exit;
  FAxisIndexX := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetAxisIndexY(AValue: TChartAxisIndex);
begin
  if FAxisIndexY = AValue then exit;
  FAxisIndexY := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetDepth(AValue: TChartDistance);
begin
  if FDepth = AValue then exit;
  FDepth := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetIndex(AValue: Integer);
begin
  with FChart.Series.List do
    Move(Index, EnsureRange(AValue, 0, Count - 1));
end;

procedure TCustomChartSeries.SetLegend(AValue: TChartSeriesLegend);
begin
  if FLegend = AValue then exit;
  FLegend.Assign(AValue);
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetParentComponent(AParent: TComponent);
begin
  if not (csLoading in ComponentState) then
    (AParent as TChart).AddSeries(Self);
end;

procedure TCustomChartSeries.SetShadow(AValue: TChartShadow);
begin
  if FShadow = AValue then exit;
  FShadow.Assign(AValue);
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetShowInLegend(AValue: Boolean);
begin
  Legend.Visible := AValue;
end;

procedure TCustomChartSeries.SetTitle(AValue: String);
begin
  if FTitle = AValue then exit;
  FTitle := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetTransparency(AValue: TChartTransparency);
begin
  if FTransparency = AValue then exit;
  FTransparency := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.SetZPosition(AValue: TChartDistance);
begin
  if FZPosition = AValue then exit;
  FZPosition := AValue;
  UpdateParentChart;
end;

procedure TCustomChartSeries.StyleChanged(Sender: TObject);
begin
  if ParentChart <> nil then
    ParentChart.StyleChanged(Sender);
end;

function TCustomChartSeries.TitleIsStored: Boolean;
begin
  Result := Title <> '';
end;

procedure TCustomChartSeries.UpdateParentChart;
begin
  if ParentChart <> nil then
    ParentChart.StyleChanged(Self);
end;

{ TChartSeries }

function TChartSeries.Add(AValue: Double; AXLabel: String; AColor: TColor): Integer;
begin
  Result := AddXY(GetXMaxVal + 1, AValue, AXLabel, AColor);
end;

function TChartSeries.AddArray(const AValues: array of Double): Integer;
var
  a: Double;
begin
  Result := ListSource.Count;
  for a in AValues do
    Add(a);
end;

function TChartSeries.AddNull(ALabel: String; AColor: TColor): Integer;
begin
  Result := ListSource.Add(SafeNan, SafeNan, ALabel, AColor);
end;

function TChartSeries.AddX(AX: Double; ALabel: String; AColor: TColor): Integer;
begin
  Result := ListSource.Add(AX, SafeNan, ALabel, AColor);
end;

function TChartSeries.AddXY(
  AX, AY: Double; const AYList: array of Double;
  AXLabel: String; AColor: TColor): Integer;
begin
  Result := ListSource.Add(AX, AY, AXLabel, AColor);
  ListSource.SetYList(Result, AYList);
end;

function TChartSeries.AddXY(
  AX, AY: Double; AXLabel: String; AColor: TColor): Integer;
begin
  Result := ListSource.Add(AX, AY, AXLabel, AColor);
end;

function TChartSeries.AddY(AY: Double; ALabel: String; AColor: TColor): Integer;
begin
  Result := Add(AY, ALabel, AColor);
end;

procedure TChartSeries.AfterAdd;
begin
  inherited;
  Marks.SetOwner(FChart);
  Marks.Arrow.SetOwner(FChart);
  Marks.Margins.SetOwner(FChart);
end;

procedure TChartSeries.AfterDraw;
begin
  inherited AfterDraw;
  Source.AfterDraw;
end;

procedure TChartSeries.Assign(ASource: TPersistent);
begin
  if ASource is TChartSeries then
    with TChartSeries(ASource) do begin
      Self.Marks.Assign(FMarks);
      Self.FOnGetMark := FOnGetMark;
      Self.Source := FSource;
      Self.Styles := FStyles;
    end;
  inherited Assign(Source);
end;

procedure TChartSeries.BeforeDraw;
begin
  inherited BeforeDraw;
  Source.BeforeDraw;
end;

procedure TChartSeries.BeginUpdate;
begin
  ListSource.BeginUpdate;
end;

procedure TChartSeries.Clear;
begin
  ListSource.Clear;
end;

function TChartSeries.Count: Integer;
begin
  Result := Source.Count;
end;

function TChartSeries.LastValueIndex: Integer;
begin
  Result := Source.Count - 1;
end;

constructor TChartSeries.Create(AOwner: TComponent);
const
  BUILTIN_SOURCE_NAME = 'Builtin';
begin
  inherited Create(AOwner);

  FListener := TListener.Create(@FSource,  @SourceChanged);
  FBuiltinSource := TListChartSource.Create(Self);
  FBuiltinSource.Name := BUILTIN_SOURCE_NAME;
  FBuiltinSource.Broadcaster.Subscribe(FListener);
  FMarks := TChartMarks.Create(FChart);
  FStylesListener := TListener.Create(@FStyles,  @StyleChanged);
end;

procedure TChartSeries.Delete(AIndex: Integer);
begin
  ListSource.Delete(AIndex);
end;

destructor TChartSeries.Destroy;
begin
  FreeAndNil(FListener);
  FreeAndNil(FBuiltinSource);
  FreeAndNil(FMarks);
  FreeAndNil(FStylesListener);
  inherited;
end;

procedure TChartSeries.EndUpdate;
begin
  ListSource.EndUpdate;
  UpdateParentChart;
end;

function TChartSeries.Extent: TDoubleRect;
begin
  Result := Source.ExtentCumulative;
end;

function TChartSeries.FormattedMark(
  AIndex: Integer; AFormat: String; AYIndex: Integer): String;
begin
  if Assigned(FOnGetMark) then
    FOnGetMark(Result, AIndex)
  else
    Result := Source.FormatItem(
      IfThen(AFormat = '', Marks.Format, AFormat), AIndex, AYIndex);
end;

procedure TChartSeries.GetBounds(var ABounds: TDoubleRect);
var
  i: Integer;
begin
  if not Active or (Count = 0) then exit;
  with Extent do
    for i := Low(coords) to High(coords) do
      if not IsInfinite(coords[i]) then
        ABounds.coords[i] := coords[i];
end;

function TChartSeries.GetColor(AIndex: Integer): TColor;
begin
  Result := ColorDef(Source[AIndex]^.Color, GetSeriesColor);
end;

function TChartSeries.GetGraphPoint(AIndex: Integer): TDoublePoint;
begin
  Result.X := GetGraphPointX(AIndex);
  Result.Y := GetGraphPointY(AIndex);
  if IsRotated then
    Exchange(Result.X, Result.Y);
end;

function TChartSeries.GetGraphPoint(AIndex, AXIndex, AYIndex: Integer): TDoublePoint;
begin
  Result.X := GetGraphPointX(AIndex, AXIndex);
  Result.Y := GetGraphPointY(AIndex, AYIndex);
  if IsRotated then
    Exchange(Result.X, Result.Y);
end;

function TChartSeries.GetGraphPointX(AIndex: Integer): Double;
begin
  Result := AxisToGraphX(Source[AIndex]^.X);
end;

function TChartSeries.GetGraphPointX(AIndex, AXIndex: Integer): Double;
begin
  Result := AxisToGraphX(Source[AIndex]^.GetX(AXIndex));
end;

function TChartSeries.GetGraphPointY(AIndex: Integer): Double;
begin
  Result := AxisToGraphY(Source[AIndex]^.Y);
end;

function TChartSeries.GetGraphPointY(AIndex, AYIndex: Integer): Double;
begin
  Result := AxisToGraphY(Source[AIndex]^.GetY(AYIndex));
end;

procedure TChartSeries.GetMax(out X, Y: Double);
begin
  X := Source.XOfMax;
  Y := Extent.b.Y;
end;

procedure TChartSeries.GetMin(out X, Y: Double);
begin
  X := Source.XOfMin;
  Y := Extent.a.Y;
end;

function TChartSeries.GetSeriesColor: TColor;
begin
  Result := clTAColor;
end;

function TChartSeries.GetSource: TCustomChartSource;
begin
  if Assigned(FSource) then
    Result := FSource
  else
    Result := FBuiltinSource;
end;

function TChartSeries.GetXImgValue(AIndex: Integer): Integer;
begin
  Result := ParentChart.XGraphToImage(Source[AIndex]^.X);
end;

function TChartSeries.GetXMax: Double;
begin
  Result := Extent.b.X;
end;

function TChartSeries.MaxXValue: Double;
begin
  Result := Extent.b.X;
end;

function TChartSeries.GetXMaxVal: Double;
begin
  if Count > 0 then
    Result := Source[Count - 1]^.X
  else
    Result := 0;
end;

function TChartSeries.GetXMin: Double;
begin
  Result := Extent.a.X;
end;

function TChartSeries.MinXValue: Double;
begin
  Result := Extent.a.X;
end;

function TChartSeries.GetXValue(AIndex: Integer): Double;
begin
  Result := Source[AIndex]^.X;
end;

function TChartSeries.GetXValues(AIndex, AXIndex: Integer): Double;
begin
  if AXIndex = 0 then
    Result := Source[AIndex]^.X
  else
    Result := Source[AIndex]^.XList[AXIndex - 1];
end;

function TChartSeries.GetYImgValue(AIndex: Integer): Integer;
begin
  Result := ParentChart.YGraphToImage(Source[AIndex]^.Y);
end;

function TChartSeries.GetYMax: Double;
begin
  Result := Extent.b.Y;
end;

function TChartSeries.MaxYValue: Double;
begin
  Result := Extent.b.Y;
end;

function TChartSeries.GetYMin: Double;
begin
  Result := Extent.a.Y;
end;

function TChartSeries.MinYValue: Double;
begin
  Result := Extent.a.Y;
end;

function TChartSeries.GetYValue(AIndex: Integer): Double;
begin
  Result := Source[AIndex]^.Y;
end;

function TChartSeries.GetYValues(AIndex, AYIndex: Integer): Double;
begin
  if AYIndex = 0 then
    Result := GetYValue(AIndex)
  else
    Result := Source[AIndex]^.YList[AYIndex - 1];
end;

function TChartSeries.IsEmpty: Boolean;
begin
  Result := Count = 0;
end;

function TChartSeries.IsSourceStored: boolean;
begin
  Result := FSource <> nil;
end;

function TChartSeries.LegendTextPoint(AIndex: Integer): String;
begin
  Result := FormattedMark(AIndex, Legend.Format);
end;

function TChartSeries.ListSource: TListChartSource;
begin
  if not (Source is TListChartSource) then
    raise EEditableSourceRequired.Create('Editable chart source required');
  Result := Source as TListChartSource;
end;

procedure TChartSeries.SetColor(AIndex: Integer; AColor: TColor);
begin
  ListSource.SetColor(AIndex, AColor);
end;

procedure TChartSeries.SetMarks(AValue: TChartMarks);
begin
  if FMarks = AValue then exit;
  FMarks.Assign(AValue);
end;

procedure TChartSeries.SetOnGetMark(AValue: TChartGetMarkEvent);
begin
  if TMethod(FOnGetMark) = TMethod(AValue) then exit;
  FOnGetMark := AValue;
  UpdateParentChart;
end;

procedure TChartSeries.SetSource(AValue: TCustomChartSource);
begin
  if FSource = AValue then exit;
  if FListener.IsListening then
    Source.Broadcaster.Unsubscribe(FListener);
  FSource := AValue;
  Source.Broadcaster.Subscribe(FListener);
  SourceChanged(Self);
end;

procedure TChartSeries.SetStyles(AValue: TChartStyles);
begin
  if FStyles = AValue then exit;
  if FStylesListener.IsListening then
    Styles.Broadcaster.Unsubscribe(FStylesListener);
  FStyles := AValue;
  if Styles <> nil then
    Styles.Broadcaster.Subscribe(FStylesListener);
  UpdateParentChart;
end;

procedure TChartSeries.SetText(AIndex: Integer; AValue: String);
begin
  ListSource.SetText(AIndex, AValue);
end;

procedure TChartSeries.SetXValue(AIndex: Integer; AValue: Double); inline;
begin
  ListSource.SetXValue(AIndex, AValue);
end;

procedure TChartSeries.SetXValues(AIndex, AXIndex: Integer; AValue: Double);
begin
  if AXIndex = 0 then
    ListSource.SetXValue(AIndex, AValue)
  else
    ListSource.Item[AIndex]^.XList[AXIndex - 1] := AValue;
end;

procedure TChartSeries.SetYValue(AIndex: Integer; AValue: Double); inline;
begin
  ListSource.SetYValue(AIndex, AValue);
end;

procedure TChartSeries.SetYValues(AIndex, AYIndex: Integer; AValue: Double);
begin
  if AYIndex = 0 then
    ListSource.SetYValue(AIndex, AValue)
  else
    ListSource.Item[AIndex]^.YList[AYIndex - 1] := AValue;
end;

procedure TChartSeries.SourceChanged(ASender: TObject);
begin
  StyleChanged(ASender);
end;

procedure TChartSeries.VisitSources(
  AVisitor: TChartOnSourceVisitor; AAxis: TChartAxis; var AData);
begin
  if (AAxis = GetAxisX) or (AAxis = GetAxisY) then
    AVisitor(Source, AData);
end;

{ TBasicPointSeries }

procedure TBasicPointSeries.AfterAdd;
begin
  inherited AfterAdd;
  if Pointer <> nil then
    Pointer.SetOwner(ParentChart);
end;

procedure TBasicPointSeries.AfterDrawPointer(
  ADrawer: IChartDrawer; AIndex: Integer; const APos: TPoint);
begin
  Unused(ADrawer);
  Unused(AIndex, APos);
end;

procedure TBasicPointSeries.Assign(ASource: TPersistent);
begin
  if ASource is TBasicPointSeries then
    with TBasicPointSeries(ASource) do begin
      Self.FMarkPositions := MarkPositions;
      if Self.FPointer <> nil then
        Self.FPointer.Assign(Pointer);
      Self.Stacked := Stacked;
      Self.FUseReticule := UseReticule;
    end;
  inherited Assign(ASource);
end;

constructor TBasicPointSeries.Create(AOwner: TComponent);
begin
  inherited;
  FOptimizeX := true;
  ToolTargets := [nptPoint, nptYList];
end;

destructor TBasicPointSeries.Destroy;
begin
  FreeAndNil(FPointer);
  inherited;
end;

procedure TBasicPointSeries.DrawLabels(ADrawer: IChartDrawer);
var
  prevLabelPoly: TPointArray;

  procedure DrawLabel(
    const AText: String; const ADataPoint: TPoint; ADir: TLabelDirection);
  const
    OFFSETS: array [TLabelDirection] of TPoint =
      ((X: -1; Y: 0), (X: 0; Y: -1), (X: 1; Y: 0), (X: 0; Y: 1));
  var
    center: TPoint;
  begin
    if AText = '' then exit;

    if Marks.RotationCenter = rcCenter then
      center := ADataPoint + OFFSETS[ADir] * Marks.CenterOffset(ADrawer, AText)
    else
      center := ADataPoint + OFFSETS[ADir] * Marks.CenterHeightOffset(ADrawer, AText);
    Marks.DrawLabel(ADrawer, ADataPoint, center, AText, prevLabelPoly);
  end;

var
  y: Double;
  g, gl: TDoublePoint;
  i, si: Integer;
  ld: TLabelDirection;
  style: TChartStyle;
  lfont: TFont;
begin
  if not Marks.IsMarkLabelsVisible then exit;

  lfont := TFont.Create;
  try
    lfont.Assign(Marks.LabelFont);
    ParentChart.DisableRedrawing;

    for i := 0 to Count - 1 do begin
      if IsNan(Source[i]^.Point) then continue;
      g := GetLabelDataPoint(i);
      ld := GetLabelDirection(i);
      for si := 0 to Source.YCount - 1 do begin
        if Styles <> nil then begin
          style := Styles.StyleByIndex(si);
          if style.UseFont then
            Marks.LabelFont.Assign(style.Font)
          else
            Marks.LabelFont.Assign(lfont);
        end;
        if si = 0 then
          y := Source[i]^.y - GetZeroLevel
        else begin
          y := Source[i]^.YList[si-1];
          if IsRotated then
            g.X += AxisToGraphY(y)
          else
            g.Y += AxisToGraphY(y);
        end;
        gl := g;
        if FMarkPositions = lmpInsideCenter then begin
          if IsRotated then
            gl.X -= AxisToGraphX(y)/2
          else
            gl.Y -= AxisToGraphY(y)/2;
        end;
        with ParentChart do
          if
            (Marks.YIndex = MARKS_YINDEX_ALL) or (Marks.YIndex = si) and
            IsPointInViewPort(gl)
          then
            DrawLabel(FormattedMark(i, '', si), GraphToImage(gl), ld);
      end;
    end;

  finally
    Marks.LabelFont.Assign(lfont);
    ParentChart.EnableRedrawing;
    lfont.Free;
  end;
end;

{ Draws the pointers of the series.
  If ChartStyles are attached to the series then the pointer brush is determined
  by the style with the specified index. }
procedure TBasicPointSeries.DrawPointers(ADrawer: IChartDrawer;
  AStyleIndex: Integer = 0; UseDataColors: Boolean = false);
var
  i: Integer;
  p: TDoublePoint;
  ai: TPoint;
  ps, saved_ps: TSeriesPointerStyle;
  brushAlreadySet: boolean;
  c: TColor;
begin
  Assert(Pointer <> nil, 'Series pointer');
  if (not Pointer.Visible) or (Length(FGraphPoints) = 0) then exit;
  for i := FLoBound to FUpBound do begin
    p := FGraphPoints[i - FLoBound];
    if not ParentChart.IsPointInViewPort(p) then continue;
    ai := ParentChart.GraphToImage(p);
    if Assigned(FOnCustomDrawPointer) then
      FOnCustomDrawPointer(Self, ADrawer, i, ai)
    else begin
      if Assigned(FOnGetPointerStyle) then begin
        saved_ps := Pointer.Style;
        ps := saved_ps;
        FOnGetPointerStyle(self, i, ps);
        Pointer.SetOwner(nil);   // avoid recursion
        Pointer.Style := ps;
      end;
      brushAlreadySet := (Styles <> nil) and
        (AStyleIndex < Styles.Styles.Count) and
        Styles.Styles[AStyleIndex].UseBrush;
      if brushAlreadySet then
        Styles.Apply(ADrawer, AStyleIndex);
      if UseDataColors then c := Source[i]^.Color else c := clTAColor;
      Pointer.Draw(ADrawer, ai, c, brushAlreadySet);
      AfterDrawPointer(ADrawer, i, ai);
      if Assigned(FOnGetPointerStyle) then begin
        Pointer.Style := saved_ps;
        Pointer.SetOwner(ParentChart);
      end;
    end;
  end;
end;

function TBasicPointSeries.Extent: TDoubleRect;
begin
  if FStacked then
    Result := Source.ExtentCumulative
  else
    Result := Source.ExtentList;
end;

// Find an interval of x-values intersecting the extent.
// Requires monotonic (but not necessarily increasing) axis transformation.
procedure TBasicPointSeries.FindExtentInterval(
  const AExtent: TDoubleRect; AFilterByExtent: Boolean);
var
  axisExtent: TDoubleInterval;
begin
  FLoBound := 0;
  FUpBound := Count - 1;
  if AFilterByExtent then begin
    with AExtent do
      if IsRotated then
        axisExtent := DoubleInterval(GraphToAxisY(a.Y), GraphToAxisY(b.Y))
      else
        axisExtent := DoubleInterval(GraphToAxisX(a.X), GraphToAxisX(b.X));
    Source.FindBounds(axisExtent.FStart, axisExtent.FEnd, FLoBound, FUpBound);
    FLoBound := Max(FLoBound - 1, 0);
    FUpBound := Min(FUpBound + 1, Count - 1);
  end;
end;

function TBasicPointSeries.GetLabelDataPoint(AIndex: Integer): TDoublePoint;
begin
  Result := GetGraphPoint(AIndex);
end;

function TBasicPointSeries.GetLabelDirection(AIndex: Integer): TLabelDirection;
const
  DIR: array [Boolean, Boolean] of TLabelDirection =
    ((ldTop, ldBottom), (ldRight, ldLeft));
var
  isNeg: Boolean;
begin
  case MarkPositions of
    lmpOutside: isNeg := Source[AIndex]^.Y < GetZeroLevel;
    lmpPositive: isNeg := false;
    lmpNegative: isNeg := true;
    lmpInside: isNeg := Source[AIndex]^.Y >= GetZeroLevel;
    lmpInsideCenter: isNeg := Source[AIndex]^.Y < GetZeroLevel;
  end;
  Result := DIR[IsRotated, isNeg];
end;

procedure TBasicPointSeries.GetLegendItemsRect(
  AItems: TChartLegendItems; ABrush: TBrush);
var
  i: Integer;
  li: TLegendItemBrushRect;
  s: TChartStyle;
begin
  case Legend.Multiplicity of
    lmSingle:
      begin
        li := TLegendItemBrushRect.Create(ABrush, LegendTextSingle);
        li.TextFormat := Legend.TextFormat;
        AItems.Add(li);
      end;
    lmPoint:
      for i := 0 to Count - 1 do begin
        li := TLegendItemBrushRect.Create(ABrush, LegendTextPoint(i));
        li.Color := GetColor(i);
        li.TextFormat := Legend.TextFormat;
        AItems.Add(li);
      end;
    lmStyle:
      if Styles <> nil then
        for s in Styles.Styles do
          AItems.Add(TLegendItemBrushRect.Create(
            IfThen(s.UseBrush, s.Brush, ABrush) as TBrush, LegendTextStyle(s)
          ));
  end;
end;

function TBasicPointSeries.GetNearestPoint(
  const AParams: TNearestPointParams;
  out AResults: TNearestPointResults): Boolean;

  function GetGrabBound(ARadius: Integer): Double;
  begin
    if IsRotated then
      Result := ParentChart.YImageToGraph(AParams.FPoint.Y + ARadius)
    else
      Result := ParentChart.XImageToGraph(AParams.FPoint.X + ARadius);
    Result := GraphToAxisX(Result);
  end;

var
  dist, tmpDist, i, j, lb, ub: Integer;
  sp, tmpSp: TDoublePoint;
  pt, tmpPt: TDoublePoint;
begin
  AResults.FDist := Sqr(AParams.FRadius) + 1;  // the dist func does not calc sqrt
  AResults.FIndex := -1;
  AResults.FXIndex := 0;
  AResults.FYIndex := 0;
  if FOptimizeX and AParams.FOptimizeX then
    Source.FindBounds(
      GetGrabBound(-AParams.FRadius),
      GetGrabBound( AParams.FRadius), lb, ub)
  else begin
    lb := 0;
    ub := Count - 1;
  end;

  dist := AResults.FDist;
  for i := lb to ub do begin
    sp := Source[i]^.Point;
    if IsNan(sp) then
      continue;

    // Since axis transformation may be non-linear, the distance should be
    // measured in screen coordinates. With high zoom ratios this may lead to
    // an integer overflow, so ADistFunc should use saturation arithmetics.

    // Find nearest point of datapoint at (x, y)
    if (nptPoint in AParams.FTargets) and (nptPoint in ToolTargets) then
    begin
      pt := AxisToGraph(sp);
      dist := Min(dist, ToolTargetDistance(AParams, pt, i, 0, 0));
    end;

    // Find nearest point to additional y values (at x).
    // In case of stacked data points check the stacked values.
    if (dist > 0) and (nptYList in AParams.FTargets) and (nptYList in ToolTargets)
    then begin
      tmpSp := sp;
      for j := 0 to Source.YCount - 2 do begin
        if FStacked then
          tmpSp.Y += Source[i]^.YList[j] else
          tmpSp.Y := Source[i]^.YList[j];
        tmpPt := AxisToGraph(tmpSp);
        tmpDist := ToolTargetDistance(AParams, tmpPt, i, 0, j + 1);
        if tmpDist < dist then begin
          dist := tmpDist;
          sp := tmpSp;
          pt := tmpPt;
          AResults.FYIndex := j + 1;    // FYIndex = 0 refers to the regular y
        end;
      end;
    end;

    // Find nearest point of additional x values (at y)
    if (dist > 0) and (nptXList in AParams.FTargets) and (nptXList in ToolTargets)
    then begin
      tmpSp := sp;
      for j := 0 to Source.XCount - 2 do begin
        tmpSp.X := Source[i]^.XList[j];
        tmpPt := AxisToGraph(tmpSp);
        tmpDist := ToolTargetDistance(AParams, tmpPt, i, j + 1, 0);
        if tmpDist < dist then begin
          dist := tmpDist;
          sp := tmpSp;
          pt := tmpPt;
          AResults.FXIndex := j + 1;   // FXindex = 0 refers to the regular x
        end;
      end;
    end;

    // The case nptCustom is not handled here, it depends on the series type.
    // TBarSeries, for example, checks whether AParams.FPoint is inside a bar.

    if dist >= AResults.FDist then
      continue;

    AResults.FDist := dist;
    AResults.FIndex := i;
    AResults.FValue := sp;
    AResults.FImg := ParentChart.GraphToImage(pt);
    if dist = 0 then break;
  end;
  Result := AResults.FIndex >= 0;
end;

function TBasicPointSeries.GetXRange(AX: Double; AIndex: Integer): Double;
var
  wl, wr: Double;
  i: Integer;
begin
  i := AIndex - 1;
  wl := Abs(AX - NearestXNumber(i, -1));
  i := AIndex + 1;
  wr := Abs(AX - NearestXNumber(i, +1));
  Result := NumberOr(SafeMin(wl, wr), 1.0);
end;

function TBasicPointSeries.GetZeroLevel: Double;
begin
  Result := 0.0;
end;

procedure TBasicPointSeries.MovePoint(
  var AIndex: Integer; const ANewPos: TDoublePoint);
var
  p: TDoublePoint;
begin
  if not InRange(AIndex, 0, Count - 1) then exit;
  p := GraphToAxis(ANewPos);
  with ListSource do begin
    AIndex := SetXValue(AIndex, p.X);
    SetYValue(AIndex, p.Y);
  end;
end;

procedure TBasicPointSeries.MovePointEx(var AIndex: Integer;
  AXIndex, AYIndex: Integer; const ANewPos: TDoublePoint);
var
  sp: TDoublePoint;
  sum: Double;
  j: Integer;
begin
  Unused(AXIndex);

  if not InRange(AIndex, 0, Count - 1) then
    exit;

  sp := GraphToAxis(ANewPos);
  case AYIndex of
   -1: begin
        // ListSource.SetXValue(AIndex, sp.X);
        // ListSource.SetYValue(AIndex, sp.Y);
       end;
    0: begin
         ListSource.SetXValue(AIndex, sp.X);
         ListSource.SetYValue(AIndex, sp.Y);
       end;
    else
      if FStacked then begin
        sum := 0;
        for j := 0 to AYIndex - 1 do
          sum := sum + YValues[AIndex, j];
        YValues[AIndex, AYIndex] := sp.Y - sum;
      end else
        YValues[AIndex, AYIndex] := sp.Y;
      UpdateParentChart;
  end;
end;

function TBasicPointSeries.NearestXNumber(
  var AIndex: Integer; ADir: Integer): Double;
begin
  while InRange(AIndex, 0, Count - 1) do
    with Source[AIndex]^ do
      if IsNan(X) then
        AIndex += ADir
      else
        exit(AxisToGraphX(X));
  Result := SafeNan;
end;

procedure TBasicPointSeries.PrepareGraphPoints(
  const AExtent: TDoubleRect; AFilterByExtent: Boolean);
var
  i: Integer;
begin
  FindExtentInterval(AExtent, AFilterByExtent);

  SetLength(FGraphPoints, Max(FUpBound - FLoBound + 1, 0));
  if (AxisIndexX < 0) and (AxisIndexY < 0) then
    // Optimization: bypass transformations in the default case.
    for i := FLoBound to FUpBound do
      with Source[i]^ do
        FGraphPoints[i - FLoBound] := DoublePoint(X, Y)
  else
    for i := FLoBound to FUpBound do
      FGraphPoints[i - FLoBound] := GetGraphPoint(i);
end;

procedure TBasicPointSeries.SetMarkPositions(AValue: TLinearMarkPositions);
begin
  if FMarkPositions = AValue then exit;
  FMarkPositions := AValue;
  UpdateParentChart;
end;

procedure TBasicPointSeries.SetPointer(AValue: TSeriesPointer);
begin
  FPointer.Assign(AValue);
  UpdateParentChart;
end;

procedure TBasicPointSeries.SetStacked(AValue: Boolean);
begin
  if FStacked = AValue then exit;
  FStacked := AValue;
  UpdateParentChart;
end;

procedure TBasicPointSeries.SetUseReticule(AValue: Boolean);
begin
  if FUseReticule = AValue then exit;
  FUseReticule := AValue;
  UpdateParentChart;
end;

function TBasicPointSeries.ToolTargetDistance(const AParams: TNearestPointParams;
  AGraphPt: TDoublePoint; APointIdx, AXIdx, AYIdx: Integer): Integer;
var
  pt: TPoint;
begin
  Unused(APointIdx);
  Unused(AXIdx, AYIdx);
  pt := ParentChart.GraphToImage(AGraphPt);
  Result := AParams.FDistFunc(AParams.FPoint, pt);
end;

procedure TBasicPointSeries.UpdateGraphPoints(AIndex, ALo, AUp: Integer;
  ACumulative: Boolean);
var
  i, j: Integer;
  y: Double;
begin
  if IsRotated then
    for i := ALo to AUp do
    begin
      if ACumulative then begin
        y := Source[i]^.Y;
        for j := 0 to AIndex do
          y += Source[i]^.YList[j];
        FGraphPoints[i - ALo].X := AxisToGraphY(y);
      end else
        FGraphPoints[i - Alo].X := AxisToGraphY(Source[i]^.YList[AIndex]);
    end
  else
    for i := ALo to AUp do
    begin
      if ACumulative then begin
        y := Source[i]^.Y;
        for j := 0 to AIndex do
          y += Source[i]^.YList[j];
        FGraphPoints[i - ALo].Y := AxisToGraphY(y);
      end else
        FGraphPoints[i - Alo].Y := AxisToGraphY(Source[i]^.YList[AIndex]);
    end;
end;

procedure TBasicPointSeries.UpdateGraphPoints(AIndex: Integer;
  ACumulative: Boolean);
begin
  UpdateGraphPoints(AIndex, FLoBound, FUpBound, ACumulative);
end;

procedure TBasicPointSeries.UpdateMargins(
  ADrawer: IChartDrawer; var AMargins: TRect);
var
  i, dist: Integer;
  labelText: String;
  dir: TLabelDirection;
  m: array [TLabelDirection] of Integer absolute AMargins;
  zero: Double;
  gp: TDoublePoint;
  valueIsPositive: Boolean;
begin
  if not Marks.IsMarkLabelsVisible or not Marks.AutoMargins then exit;
  if MarkPositions = lmpInsideCenter then exit;

  zero := GetZeroLevel;
  for i := 0 to Count - 1 do begin
    gp := GetGraphPoint(i);
    if not ParentChart.IsPointInViewPort(gp) then continue;
    labelText := FormattedMark(i);
    if labelText = '' then continue;

    valueIsPositive := TDoublePointBoolArr(gp)[not IsRotated] > zero;
    dir := GetLabelDirection(i);

    with Marks.MeasureLabel(ADrawer, labelText) do
      dist := IfThen(dir in [ldLeft, ldRight], cx, cy);
    if Marks.DistanceToCenter then
      dist := dist div 2;

    if valueIsPositive then begin
      if Marks.DistanceToCenter then
        case dir of
          ldBottom: dir := ldTop;
          ldLeft: dir := ldRight;
        end;
      if dir in [ldTop, ldRight] then
        m[dir] := Max(m[dir], dist + Marks.Distance);
    end else begin
      if Marks.DistanceToCenter then
        case dir of
          ldTop: dir := ldBottom;
          ldRight: dir := ldLeft;
        end;
      if dir in [ldBottom, ldLeft] then
        m[dir] := Max(m[dir], dist + Marks.Distance);
    end;
  end;
end;

procedure TBasicPointSeries.UpdateMinXRange;
var
  x, prevX: Double;
  i: Integer;
begin
  if Count < 2 then begin
    FMinXRange := 1.0;
    exit;
  end;
  x := Source[0]^.X;
  prevX := Source[1]^.X;
  FMinXRange := Abs(x - prevX);
  for i := 2 to Count - 1 do begin
    x := Source[i]^.X;
    FMinXRange := SafeMin(Abs(x - prevX), FMinXRange);
    prevX := x;
  end;
end;

procedure SkipObsoleteProperties;
begin
  RegisterPropertyEditor(
    TypeInfo(Boolean), TCustomChartSeries,
    'ShowInLegend', THiddenPropertyEditor);
end;

initialization
  SkipObsoleteProperties;

end.

