unit CocoaWSCommon;

{$mode objfpc}{$H+}
{$modeswitch objectivec1}
{.$DEFINE COCOA_DEBUG_SETBOUNDS}

interface

uses
  Types,
  CGGeometry, CocoaAll,
  Classes, Controls, SysUtils,
  //
  WSControls, LCLType, LMessages, LCLProc, Graphics, Forms,
  CocoaPrivate, CocoaGDIObjects, CocoaCaret, CocoaUtils, LCLMessageGlue;

type
  { TLCLCommonCallback }

  TLCLCommonCallback = class(TObject, ICommonCallBack)
  private
    class var
      // Store state of key modifiers so that we can emulate keyup/keydown
      // of keys like control, option, command, caps lock, shift
      PrevKeyModifiers: NSUInteger;
    var
      FPropStorage: TStringList;
      FContext: TCocoaContext;
      FHasCaret: Boolean;
      FBoundsReportedToChildren: boolean;
      FIsOpaque:boolean;
      FIsEventRouting:boolean;
    function GetHasCaret: Boolean;
    procedure SetHasCaret(AValue: Boolean);
    function GetIsOpaque: Boolean;
    procedure SetIsOpaque(AValue: Boolean);
    function GetShouldBeEnabled: Boolean;
  protected
    FTarget: TWinControl;
    class function CocoaModifiersToKeyState(AModifiers: NSUInteger): PtrInt; static;
    class function CocoaPressedMouseButtonsToKeyState(AMouseButtons: NSUInteger): PtrInt; static;
    procedure OffsetMousePos(var Point: NSPoint);
    procedure ScreenMousePos(var Point: NSPoint);
  public
    Owner: NSObject;
    Frame: NSObject;
    class constructor Create;
    constructor Create(AOwner: NSObject; ATarget: TWinControl); virtual;
    destructor Destroy; override;
    function GetPropStorage: TStringList;
    function GetContext: TCocoaContext;
    function GetTarget: TObject;
    function GetCallbackObject: TObject;
    function GetCaptureControlCallback: ICommonCallBack;
    function MouseUpDownEvent(Event: NSEvent; AForceAsMouseUp: Boolean = False): Boolean; virtual;
    function KeyEvent(Event: NSEvent; AForceAsKeyDown: Boolean = False): Boolean; virtual;
    procedure MouseClick; virtual;
    function MouseMove(Event: NSEvent): Boolean; virtual;
    function scrollWheel(Event: NSEvent): Boolean; virtual;
    procedure frameDidChange(sender: id); virtual;
    procedure boundsDidChange(sender: id); virtual;
    procedure BecomeFirstResponder; virtual;
    procedure ResignFirstResponder; virtual;
    procedure DidBecomeKeyNotification; virtual;
    procedure DidResignKeyNotification; virtual;
    procedure SendOnChange; virtual;
    procedure SendOnTextChanged; virtual; // text controls (like spin) respond to OnChange for this event, but not for SendOnChange
    procedure scroll(isVert: Boolean; Pos: Integer); virtual;
    function DeliverMessage(var Msg): LRESULT; virtual; overload;
    function DeliverMessage(Msg: Cardinal; WParam: WParam; LParam: LParam): LResult; virtual; overload;
    procedure Draw(ControlContext: NSGraphicsContext; const bounds, dirty: NSRect); virtual;
    procedure DrawBackground(ctx: NSGraphicsContext; const bounds, dirtyRect: NSRect); virtual;
    procedure DrawOverlay(ControlContext: NSGraphicsContext; const bounds, dirty: NSRect); virtual;
    function ResetCursorRects: Boolean; virtual;

    property HasCaret: Boolean read GetHasCaret write SetHasCaret;
    property Target: TWinControl read FTarget;
    property IsOpaque: Boolean read GetIsOpaque write SetIsOpaque;
  end;

  TLCLCommonCallBackClass = class of TLCLCommonCallBack;

  { TCocoaWSWinControl }

  { TCocoaWSControl }

  TCocoaWSControl = class(TWSControl)
  published
    class function GetCanvasScaleFactor(const AControl: TControl): Double; override;
  end;

  { TCocoaWSWinControl }

  TCocoaWSWinControl = class(TWSWinControl)
  private
    class procedure ArrangeTabOrder(const AWinControl: TWinControl);
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure DestroyHandle(const AWinControl: TWinControl); override;
    class function GetCanvasScaleFactor(const AControl: TControl): Double; override;
    class procedure SetText(const AWinControl: TWinControl; const AText: String); override;
    class function GetText(const AWinControl: TWinControl; var AText: String): Boolean; override;
    class function GetTextLen(const AWinControl: TWinControl; var ALength: Integer): Boolean; override;

    class function  GetClientBounds(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class function  GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean; override;
    class procedure GetPreferredSize(const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer; WithThemeSpace: Boolean); override;
    class procedure SetBounds(const AWinControl: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer); override;
    class procedure SetCursor(const AWinControl: TWinControl; const ACursor: HCursor); override;
    class procedure SetFont(const AWinControl: TWinControl; const AFont: TFont); override;
    class procedure SetColor(const AWinControl: TWinControl); override;
    class procedure SetChildZPosition(const AWinControl, AChild: TWinControl; const AOldPos, ANewPos: Integer; const AChildren: TFPList); override;
    class procedure ShowHide(const AWinControl: TWinControl); override;
    class procedure Invalidate(const AWinControl: TWinControl); override;
  end;


  { TLCLCustomControlCallback }

  TLCLCustomControlCallback = class(TLCLCommonCallback)
  public
    function MouseMove(Event: NSEvent): Boolean; override;
    function MouseUpDownEvent(Event: NSEvent; AForceAsMouseUp: Boolean = False): Boolean; override;
  end;

  { TCocoaWSCustomControl }

  TCocoaWSCustomControl = class(TWSCustomControl)
  published
    class function CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
  end;

// Utility WS functions

function EmbedInScrollView(AView: NSView): TCocoaScrollView;

implementation

uses
  CocoaInt;

var
  LastMouse: TLastMouseInfo;

{$I mackeycodes.inc}

function EmbedInScrollView(AView: NSView): TCocoaScrollView;
var
  r: TRect;
  p: NSView;
begin
  if not Assigned(AView) then
    Exit(nil);
  r := AView.lclFrame;
  p := AView.superview;
  Result := TCocoaScrollView.alloc.initWithFrame(NSNullRect);
  if Assigned(p) then p.addSubView(Result);
  Result.lclSetFrame(r);
  Result.setHidden(p.isHidden);
  Result.setDocumentView(AView);
  AView.setHidden(false);
  SetViewDefaults(Result);
end;

function EmbedInManualScrollView(AView: NSView): TCocoaManualScrollView;
var
  r: TRect;
  p: NSView;
begin
  if not Assigned(AView) then
  begin
    Result:=nil;
    Exit;
  end;
  r := AView.lclFrame;
  p := AView.superview;
  Result := TCocoaManualScrollView.alloc.initWithFrame(NSNullRect);
  if Assigned(p) then p.addSubView(Result);
  Result.lclSetFrame(r);
  Result.setHidden(p.isHidden);
  Result.setDocumentView(AView);
  AView.setHidden(false);
  SetViewDefaults(Result);
end;

{ TLCLCustomControlCallback }

function TLCLCustomControlCallback.MouseMove(Event: NSEvent): Boolean;
begin
  inherited MouseMove(Event);
  Result:=True;
end;

function TLCLCustomControlCallback.MouseUpDownEvent(Event: NSEvent; AForceAsMouseUp: Boolean = False): Boolean;
begin
  inherited MouseUpDownEvent(Event, AForceAsMouseUp);
  Result := True;
end;


{ TLCLCommonCallback }

function TLCLCommonCallback.GetHasCaret: Boolean;
begin
  Result := FHasCaret;
end;

procedure TLCLCommonCallback.SetHasCaret(AValue: Boolean);
begin
  FHasCaret := AValue;
end;

class function TLCLCommonCallback.CocoaModifiersToKeyState(AModifiers: NSUInteger): PtrInt;
begin
  Result := 0;
  if AModifiers and NSShiftKeyMask <> 0 then
    Result := Result or MK_SHIFT;
  if AModifiers and NSControlKeyMask <> 0 then
    Result := Result or MK_CONTROL;
  if AModifiers and NSAlternateKeyMask <> 0 then
    Result := Result or $20000000;
end;

class function TLCLCommonCallback.CocoaPressedMouseButtonsToKeyState(AMouseButtons: NSUInteger): PtrInt;
begin
  Result := 0;
  if AMouseButtons and (1 shl 0) <> 0 then
    Result := Result or MK_LBUTTON;
  if AMouseButtons and (1 shl 1) <> 0 then
    Result := Result or MK_RBUTTON;
  if AMouseButtons and (1 shl 2) <> 0 then
    Result := Result or MK_MBUTTON;
  if AMouseButtons and (1 shl 3) <> 0 then
    Result := Result or MK_XBUTTON1;
  if AMouseButtons and (1 shl 4) <> 0 then
    Result := Result or MK_XBUTTON2;
end;

procedure TLCLCommonCallback.OffsetMousePos(var Point: NSPoint);
var
  lView: NSView;
begin
  if Owner.isKindOfClass(NSWindow) then
    Point.y := NSWindow(Owner).contentView.bounds.size.height - Point.y
  else
  begin
    lView := GetNSObjectView(Owner);
    if lView <> nil then
    begin
      lView.lclOffsetMousePos(Point);
      //Point := lView.convertPoint_fromView(Point, nil);
      //if not lView.isFlipped then
        //Point.y := lView.bounds.size.height - Point.y;
    end;
  end;
end;

procedure TLCLCommonCallback.ScreenMousePos(var Point: NSPoint);
var
  f: NSRect;
  lWindow: NSWindow;
begin
  lWindow := NSWindow(GetNSObjectWindow(Owner));
  if lWindow <> nil then
  begin
    f := lWindow.frame;
    Point.x := Point.x+f.origin.x;
    Point.y := lWindow.screen.frame.size.height- f.origin.y - Point.y;
  end;
end;

class constructor TLCLCommonCallback.Create;
begin
  PrevKeyModifiers := 0;
end;

constructor TLCLCommonCallback.Create(AOwner: NSObject; ATarget: TWinControl);
begin
  inherited Create;
  Owner := AOwner;
  Frame := AOwner;
  FTarget := ATarget;
  FContext := nil;
  FHasCaret := False;
  FPropStorage := TStringList.Create;
  FPropStorage.Sorted := True;
  FPropStorage.Duplicates := dupAccept;
  FBoundsReportedToChildren:=false;
  FIsOpaque:=false;
  FIsEventRouting:=false;
end;

destructor TLCLCommonCallback.Destroy;
begin
  FContext.Free;
  FPropStorage.Free;
  FTarget := nil;
  inherited Destroy;
end;

function TLCLCommonCallback.GetPropStorage: TStringList;
begin
  Result := FPropStorage;
end;

function TLCLCommonCallback.GetContext: TCocoaContext;
begin
  Result := FContext;
end;

function TLCLCommonCallback.GetTarget: TObject;
begin
  Result := Target;
end;

function TLCLCommonCallback.GetCallbackObject: TObject;
begin
  Result := Self;
end;

function TLCLCommonCallback.GetCaptureControlCallback: ICommonCallBack;
var
  obj: NSObject;
  lCaptureView: NSView;
begin
  Result := nil;
  if CocoaWidgetSet.CaptureControl = 0 then Exit;
  obj := NSObject(CocoaWidgetSet.CaptureControl);
  lCaptureView := GetNSObjectView(obj);
  if (obj <> Owner) and (lCaptureView <> Owner) and not FIsEventRouting then
  begin
    Result := lCaptureView.lclGetCallback;
  end;
end;

function MacKeyToVK(KeyCode: Word): Word; // according to mackeycodes.inc this is risky
begin
  case KeyCode of
    MK_QWERTY_Q: Result := VK_Q;
    MK_QWERTY_W: Result := VK_W;
    MK_QWERTY_E: Result := VK_E;
    MK_QWERTY_R: Result := VK_R;
    MK_QWERTY_T: Result := VK_T;
    MK_QWERTY_Y: Result := VK_Y;
    MK_QWERTY_U: Result := VK_U;
    MK_QWERTY_I: Result := VK_I;
    MK_QWERTY_O: Result := VK_O;
    MK_QWERTY_P: Result := VK_P;
    MK_QWERTY_A: Result := VK_A;
    MK_QWERTY_S: Result := VK_S;
    MK_QWERTY_D: Result := VK_D;
    MK_QWERTY_F: Result := VK_F;
    MK_QWERTY_G: Result := VK_G;
    MK_QWERTY_H: Result := VK_H;
    MK_QWERTY_J: Result := VK_J;
    MK_QWERTY_K: Result := VK_K;
    MK_QWERTY_L: Result := VK_L;
    MK_QWERTY_Z: Result := VK_Z;
    MK_QWERTY_X: Result := VK_X;
    MK_QWERTY_C: Result := VK_C;
    MK_QWERTY_V: Result := VK_V;
    MK_QWERTY_B: Result := VK_B;
    MK_QWERTY_N: Result := VK_N;
    MK_QWERTY_M: Result := VK_M;
    //MK_QWERTY_LEFTBR:  Result := VK_;
    //MK_QWERTY_RIGHTBR: = 30;
    MK_QWERTY_BACKSLASH: Result := VK_BACK;

    //MK_QWERTY_SEMICOLON: Result := VK_s
    //MK_QWERTY_QUOTE: = 39;
    //MK_QWERTY_ENTER: = 36;

    //MK_QWERTY_COMMA: := 43;
    //MK_QWERTY_PERIOD: := 47;
    //MK_QWERTY_FRWSLASH: := 44;

  else
    Result:=VK_UNKNOWN;
  end;
end;


function TLCLCommonCallback.KeyEvent(Event: NSEvent; AForceAsKeyDown: Boolean): Boolean;
var
  UTF8VKCharacter: TUTF8Char; // char without modifiers, used for VK_ key value
  UTF8Character: TUTF8Char;   // char to send via IntfUtf8KeyPress
  KeyChar : char;          // Ascii char, when possible (xx_(SYS)CHAR)
  VKKeyChar: char;         // Ascii char without modifiers
  SendChar: boolean;       // Should we send char?
  VKKeyCode: word;         // VK_ code
  IsSysKey: Boolean;       // Is alt (option) key down?
  KeyData: PtrInt;         // Modifiers (ctrl, alt, mouse buttons...)
  eventType: NSEventType;

(*
  Mac keycodes handling is not so straight. For an explanation, see
  mackeycodes.inc
  In this function, we do the following:
   1) Get the raw keycode, if it is a known "non-printable" key, translate it
      to a known VK_ keycode.
      This will be reported via xx_KeyDown/KeyUP messages only, and we can stop
      here.
   2) else, we must send both KeyDown/KeyUp and IntfUTF8KeyPress/xx_(SYS)CHAR
      So, get the unicode character and the "ascii" character (note: if it's
      not a true ascii character (>127) use the Mac character).
    2a) Try to determine a known VK_ keycode (e.g: VK_A, VK_SPACE and so on)
    2b) If no VK_ keycode exists, use a dummy keycode to trigger LCL events
        (see later in the code for a more in depth explanation)
*)

  function TranslateMacKeyCode : boolean;
  var
    KeyCode: word;
  begin
    Result := False;
    SendChar := False;
    VKKeyCode := VK_UNKNOWN;

    IsSysKey := (Event.modifierFlags and NSCommandKeyMask) <> 0;
    KeyData := (Ord(Event.isARepeat) + 1) or Event.keyCode shl 16;
    if (Event.modifierFlags and NSAlternateKeyMask) <> 0 then
      KeyData := KeyData or $20000000;   // So that MsgKeyDataToShiftState recognizes Alt key, see bug 30129
    KeyCode := Event.keyCode;

    //non-printable keys (see mackeycodes.inc)
    //for these keys, only send keydown/keyup (not char or UTF8KeyPress)
    case KeyCode of
      MK_F1       : VKKeyCode:=VK_F1;
      MK_F2       : VKKeyCode:=VK_F2;
      MK_F3       : VKKeyCode:=VK_F3;
      MK_F4       : VKKeyCode:=VK_F4;
      MK_F5       : VKKeyCode:=VK_F5;
      MK_F6       : VKKeyCode:=VK_F6;
      MK_F7       : VKKeyCode:=VK_F7;
      MK_F8       : VKKeyCode:=VK_F8;
      MK_F9       : VKKeyCode:=VK_F9;
      MK_F10      : VKKeyCode:=VK_F10;
      MK_F11      : VKKeyCode:=VK_F11;
      MK_F12      : VKKeyCode:=VK_F12;
      MK_F13      : VKKeyCode:=VK_SNAPSHOT;
      MK_F14      : VKKeyCode:=VK_SCROLL;
      MK_F15      : VKKeyCode:=VK_PAUSE;
      MK_POWER    : VKKeyCode:=VK_SLEEP; //?
      MK_TAB      : VKKeyCode:=VK_TAB; //strangely enough, tab is "non printable"
      MK_INS      : VKKeyCode:=VK_INSERT;
      MK_DEL      : VKKeyCode:=VK_DELETE;
      MK_HOME     : VKKeyCode:=VK_HOME;
      MK_END      : VKKeyCode:=VK_END;
      MK_PAGUP    : VKKeyCode:=VK_PRIOR;
      MK_PAGDN    : VKKeyCode:=VK_NEXT;
      MK_UP       : VKKeyCode:=VK_UP;
      MK_DOWN     : VKKeyCode:=VK_DOWN;
      MK_LEFT     : VKKeyCode:= VK_LEFT;
      MK_RIGHT    : VKKeyCode:= VK_RIGHT;
      MK_NUMLOCK  : VKKeyCode:= VK_NUMLOCK;
    end;

    if VKKeyCode <> VK_UNKNOWN then
    begin
      //stop here, we won't send char or UTF8KeyPress
      Result := True;
      Exit;
    end;

    // check non-translated characters
    UTF8VKCharacter := NSStringToString(Event.charactersIgnoringModifiers);
    if Length(UTF8VKCharacter) > 0 then
    begin
      if UTF8VKCharacter[1] <= #127 then
        VKKeyChar := UTF8VKCharacter[1];
    end;

    //printable keys
    //for these keys, send char or UTF8KeyPress
    UTF8Character := NSStringToString(Event.characters);

    if Length(UTF8Character) > 0 then
    begin
      SendChar := True;

      if Utf8Character[1] <= #127 then
        KeyChar := Utf8Character[1];

      // the VKKeyCode is independent of the modifier
      // => use the VKKeyChar instead of the KeyChar
      case VKKeyChar of
        'a'..'z': VKKeyCode:=VK_A+ord(VKKeyChar)-ord('a');
        'A'..'Z': VKKeyCode:=ord(VKKeyChar);
        #27     : VKKeyCode:=VK_ESCAPE;
        #8      : VKKeyCode:=VK_BACK;
        ' '     : VKKeyCode:=VK_SPACE;
        #13     : VKKeyCode:=VK_RETURN;
        '0'..'9':
          case KeyCode of
            MK_NUMPAD0: VKKeyCode:=VK_NUMPAD0;
            MK_NUMPAD1: VKKeyCode:=VK_NUMPAD1;
            MK_NUMPAD2: VKKeyCode:=VK_NUMPAD2;
            MK_NUMPAD3: VKKeyCode:=VK_NUMPAD3;
            MK_NUMPAD4: VKKeyCode:=VK_NUMPAD4;
            MK_NUMPAD5: VKKeyCode:=VK_NUMPAD5;
            MK_NUMPAD6: VKKeyCode:=VK_NUMPAD6;
            MK_NUMPAD7: VKKeyCode:=VK_NUMPAD7;
            MK_NUMPAD8: VKKeyCode:=VK_NUMPAD8;
            MK_NUMPAD9: VKKeyCode:=VK_NUMPAD9
            else VKKeyCode:=ord(VKKeyChar);
          end;
        else
        case KeyCode of
          MK_PADDIV  : VKKeyCode:=VK_DIVIDE;
          MK_PADMULT : VKKeyCode:=VK_MULTIPLY;
          MK_PADSUB  : VKKeyCode:=VK_SUBTRACT;
          MK_PADADD  : VKKeyCode:=VK_ADD;
          MK_PADDEC  : VKKeyCode:=VK_DECIMAL;
          MK_BACKSPACE:
            begin
              VKKeyCode := VK_BACK;
              VKKeyChar := #8;
              UTF8Character := #8;
            end;
          MK_PADENTER:
            begin
              VKKeyCode:=VK_RETURN;
              VKKeyChar:=#13;
              UTF8Character:=VKKeyChar;
            end;
          MK_TILDE: VKKeyCode := VK_OEM_3;
          MK_MINUS: VKKeyCode := VK_OEM_MINUS;
          MK_EQUAL: VKKeyCode := VK_OEM_PLUS;
          MK_BACKSLASH:    VKKeyCode := VK_OEM_5;
          MK_LEFTBRACKET:  VKKeyCode := VK_OEM_4;
          MK_RIGHTBRACKET: VKKeyCode := VK_OEM_6;
          MK_SEMICOLON:    VKKeyCode := VK_OEM_1;
          MK_QUOTE:  VKKeyCode := VK_OEM_7;
          MK_COMMA:  VKKeyCode := VK_OEM_COMMA;
          MK_PERIOD: VKKeyCode := VK_OEM_PERIOD;
          MK_SLASH:  VKKeyCode := VK_OEM_2;
        else
          VKKeyCode := MacKeyToVK(KeyCode); // according to mackeycodes.inc this is risky
        end;
      end;

      if VKKeyCode = VK_UNKNOWN then
      begin
        // There is no known VK_ code for this characther. Use a dummy keycode
        // (E8, which is unused by Windows) so that KeyUp/KeyDown events will be
        // triggered by LCL.
        // Note: we can't use the raw mac keycode, since it could collide with
        // well known VK_ keycodes (e.g on my italian ADB keyboard, keycode for
        // "&egrave;" is 33, which is the same as VK_PRIOR)
        VKKeyCode := $E8;
      end;
      Result := True;
    end;
  end;

  function LCLCharToMacEvent(const AUTF8Char: AnsiString): Boolean;
  begin
    Result := False;
    if AUTF8Char = '' then
      Exit;
    // TODO
  end;

  function HandleKeyDown: Boolean;
  var
    KeyMsg: TLMKeyDown;
    CharMsg: TLMChar;
    OrigChar: AnsiString;
  begin
    Result := True;

    // create the CN_KEYDOWN message
    FillChar(KeyMsg, SizeOf(KeyMsg), 0);
    if IsSysKey then
      KeyMsg.Msg := CN_SYSKEYDOWN
    else
      KeyMsg.Msg := CN_KEYDOWN;
    KeyMsg.KeyData := KeyData;
    KeyMsg.CharCode := VKKeyCode;

    // is the key combination help key (Cmd + ?)
    if SendChar and IsSysKey and (UTF8Character = '?') then
      Application.ShowHelpForObject(Target);

    // widget can filter some keys from being send to cocoa control
    //if Widget.FilterKeyPress(IsSysKey, UTF8Character) then Result := noErr;

    //Send message to LCL
    if VKKeyCode <> VK_UNKNOWN then
    begin
      if (DeliverMessage(KeyMsg) <> 0) or (KeyMsg.CharCode = VK_UNKNOWN) then
      begin
        // the LCL handled the key
        NotifyApplicationUserInput(Target, KeyMsg.Msg);
        Exit;
      end;

      // Here is where we (interface) can do something with the key
      // Call the standard handler. Only Up/Down events are notified.
      //Widget.ProcessKeyEvent(KeyMsg);

      //Send a LM_(SYS)KEYDOWN
      if IsSysKey then
        KeyMsg.Msg := LM_SYSKEYDOWN
      else
        KeyMsg.Msg := LM_KEYDOWN;
      if (DeliverMessage(KeyMsg) <> 0) or (KeyMsg.CharCode = VK_UNKNOWN) then
      begin
        NotifyApplicationUserInput(Target, KeyMsg.Msg);
        Exit;
      end;
    end;

    if KeyMsg.CharCode = 0 then Exit;

    //We should send a character
    if SendChar then
    begin
      // send the UTF8 keypress
      OrigChar := UTF8Character;
      if Target.IntfUTF8KeyPress(UTF8Character, 1, IsSysKey) then
      begin
        // the LCL has handled the key
        Exit;
      end;
      if OrigChar <> UTF8Character then
        LCLCharToMacEvent(UTF8Character);

      // create the CN_CHAR / CN_SYSCHAR message
      FillChar(CharMsg, SizeOf(CharMsg), 0);
      if IsSysKey then
        CharMsg.Msg := CN_SYSCHAR
      else
        CharMsg.Msg := CN_CHAR;
      CharMsg.KeyData := KeyData;
      CharMsg.CharCode := ord(KeyChar);

      //Send message to LCL
      if (DeliverMessage(CharMsg) <> 0) or (CharMsg.CharCode=VK_UNKNOWN) then
      begin
        // the LCL handled the key
        NotifyApplicationUserInput(Target, CharMsg.Msg);
        Exit;
      end;

      if CharMsg.CharCode = 0 then Exit;

      if CharMsg.CharCode <> ord(KeyChar) then
        LCLCharToMacEvent(Char(CharMsg.CharCode));

      //Send a LM_(SYS)CHAR
      if IsSysKey then
        CharMsg.Msg := LM_SYSCHAR
      else
        CharMsg.Msg := LM_CHAR;

      if DeliverMessage(CharMsg) <> 0 then
        // "LN_CHAR" should be delivivered only after Cocoa processed the key
        // todo: in the current code, Cocoa has not processed the key yet
        // it must be rewritten.
        NotifyApplicationUserInput(Target, CharMsg.Msg);
    end;
    Result := False;
  end;

  function HandleKeyUp: Boolean;
  var
    KeyMsg: TLMKeyUp;
  begin
    Result := True;

    // create the CN_KEYUP message
    FillChar(KeyMsg, SizeOf(KeyMsg), 0);
    if IsSysKey then
      KeyMsg.Msg := CN_SYSKEYUP
    else
      KeyMsg.Msg := CN_KEYUP;
    KeyMsg.KeyData := KeyData;
    KeyMsg.CharCode := VKKeyCode;

    //Send message to LCL
    if VKKeyCode <> VK_UNKNOWN then
    begin
      if (DeliverMessage(KeyMsg) <> 0) or (KeyMsg.CharCode = VK_UNKNOWN) then
      begin
        // the LCL has handled the key
        NotifyApplicationUserInput(Target, KeyMsg.Msg);
        Exit;
      end;

      //Here is where we (interface) can do something with the key
      //Call the standard handler.
      //Widget.ProcessKeyEvent(KeyMsg);

      //Send a LM_(SYS)KEYUP
      if IsSysKey then
        KeyMsg.Msg := LM_SYSKEYUP
      else
        KeyMsg.Msg := LM_KEYUP;
      if DeliverMessage(KeyMsg) <> 0 then
      begin
        // the LCL handled the key
        NotifyApplicationUserInput(Target, KeyMsg.Msg);
        Exit;
      end;
    end;
    Result := False;
  end;

  function HandleFlagsChanged: Boolean;
  const
    cModifiersOfInterest: NSUInteger = (NSControlKeyMask or NSShiftKeyMask or NSAlphaShiftKeyMask or NSAlternateKeyMask or NSCommandKeyMask);
  var
    CurMod, Diff: NSUInteger;
  begin
    Result := False;
    SendChar := False;
    CurMod := Event.modifierFlags;
    //see what changed. we only care of bits 16 through 20
    Diff := (PrevKeyModifiers xor CurMod) and cModifiersOfInterest;

    case Diff of
      0          : Exit;  //nothing (that we cared of) changed
      NSControlKeyMask   : VKKeyCode := VK_CONTROL; //command mapped to control
      NSShiftKeyMask     : VKKeyCode := VK_SHIFT;
      NSAlphaShiftKeyMask: VKKeyCode := VK_CAPITAL; //caps lock
      NSAlternateKeyMask : VKKeyCode := VK_MENU;    //option is alt
      NSCommandKeyMask   : VKKeyCode := VK_LWIN;    //meta... map to left Windows Key?
    end;
    KeyData := CocoaModifiersToKeyState(CurMod);

    //diff is now equal to the mask of the bit that changed, so we can determine
    //if this change is a keydown (PrevKeyModifiers didn't have the bit set) or
    //a keyup (PrevKeyModifiers had the bit set)
    if (PrevKeyModifiers and Diff) = 0 then
      Result := HandleKeyDown
    else
      Result := HandleKeyUp;

    PrevKeyModifiers := CurMod;
  end;

begin
  eventType := Event.type_;
  if AForceAsKeyDown then
    eventType := NSKeyDown;

  case eventType of
    NSKeyDown:
      begin
        if not TranslateMacKeyCode then
          Exit(False);
        Result := HandleKeyDown;
      end;
    NSKeyUp:
      begin
        if not TranslateMacKeyCode then
          Exit(False);
        Result := HandleKeyUp;
      end;
    NSFlagsChanged:
      Result := HandleFlagsChanged;
  else
    Result := False;
  end;
end;

procedure TLCLCommonCallback.MouseClick;
begin
  LCLSendClickedMsg(Target);
end;

function TLCLCommonCallback.MouseUpDownEvent(Event: NSEvent; AForceAsMouseUp: Boolean = False): Boolean;
const
  MSGKINDUP: array[0..3] of Integer = (LM_LBUTTONUP, LM_RBUTTONUP, LM_MBUTTONUP, LM_XBUTTONUP);
var
  Msg: TLMMouse;
  MsgContext: TLMContextMenu;
  MousePos: NSPoint;
  MButton: NSInteger;
  lCaptureControlCallback: ICommonCallback;
  //Str: string;
  lEventType: NSEventType;
begin
  if Assigned(Owner) and not Owner.lclIsEnabled then
  begin
    Result := True; // Cocoa should not handle the message.
    Exit;           // LCL should not get the notification either, as the control is disabled.
  end;

  // If LCL control is provided and it's in designing state.
  // The default resolution: Notify LCL about event, but don't let Cocoa
  // do anything with it. (Result=true)
  Result := Assigned(Target) and (csDesigning in Target.ComponentState);

  lCaptureControlCallback := GetCaptureControlCallback();
  //Str := (Format('MouseUpDownEvent Target=%s Self=%x CaptureControlCallback=%x', [Target.name, PtrUInt(Self), PtrUInt(lCaptureControlCallback)]));
  if lCaptureControlCallback <> nil then
  begin
    FIsEventRouting:=true;
    Result := lCaptureControlCallback.MouseUpDownEvent(Event);
    FIsEventRouting:=false;
    exit;
  end;

  FillChar(Msg, SizeOf(Msg), #0);

  MousePos := Event.locationInWindow;
  OffsetMousePos(MousePos);

  Msg.Keys := CocoaModifiersToKeyState(Event.modifierFlags) or CocoaPressedMouseButtonsToKeyState(NSEvent.pressedMouseButtons);

  Msg.XPos := Round(MousePos.X);
  Msg.YPos := Round(MousePos.Y);

  MButton := event.buttonNumber;
  if MButton >= 3 then
  begin
    // high word of XButton messages indicate the X button which is pressed
    Msg.Keys := Msg.Keys or (MButton - 2) shl 16;
    MButton := 3;
  end;

  lEventType := Event.type_;
  if AForceAsMouseUp then
    lEventType := NSLeftMouseUp;
  case lEventType of
    NSLeftMouseDown,
    NSRightMouseDown,
    NSOtherMouseDown:
    begin
      Msg.Msg := CheckMouseButtonDownUp(TLCLIntfHandle(Owner),FTarget,LastMouse,
        FTarget.ClientToScreen(Point(Msg.XPos, Msg.YPos)),MButton+1,True);
      case LastMouse.ClickCount of
        2: Msg.Keys := msg.Keys or MK_DOUBLECLICK;
        3: Msg.Keys := msg.Keys or MK_TRIPLECLICK;
        4: Msg.Keys := msg.Keys or MK_QUADCLICK;
      end;

      NotifyApplicationUserInput(Target, Msg.Msg);
      DeliverMessage(Msg);

      // TODO: Check if Cocoa has special context menu check event
      if (Event.type_ = NSRightMouseDown) and (GetTarget is TControl) then
      begin
        FillChar(MsgContext, SizeOf(MsgContext), #0);
        MsgContext.Msg := LM_CONTEXTMENU;
        MsgContext.hWnd := HWND(Owner);
        MousePos := Event.locationInWindow;
        ScreenMousePos(MousePos);
        MsgContext.XPos := Round(MousePos.X);
        MsgContext.YPos := Round(MousePos.Y);
        DeliverMessage(MsgContext);
      end;
    end;
    NSLeftMouseUp,
    NSRightMouseUp,
    NSOtherMouseUp:
    begin
      Msg.Msg := CheckMouseButtonDownUp(TLCLIntfHandle(Owner),FTarget,LastMouse,
        FTarget.ClientToScreen(Point(Msg.XPos, Msg.YPos)),MButton+1,False);
      case LastMouse.ClickCount of
        2: Msg.Keys := msg.Keys or MK_DOUBLECLICK;
        3: Msg.Keys := msg.Keys or MK_TRIPLECLICK;
        4: Msg.Keys := msg.Keys or MK_QUADCLICK;
      end;

      NotifyApplicationUserInput(Target, Msg.Msg);
      DeliverMessage(Msg);
    end;
  end;

  //debugln('MouseUpDownEvent:'+DbgS(Msg.Msg)+' Target='+Target.name+);
end;

function TLCLCommonCallback.MouseMove(Event: NSEvent): Boolean;
var
  Msg: TLMMouseMove;
  MousePos: NSPoint;
  i: integer;
  rect: TRect;
  mp: TPoint;
  obj: NSObject;
  callback: ICommonCallback;
  targetControl: TWinControl;
  childControl:TWinControl;
begin
  if Assigned(Owner) and not Owner.lclIsEnabled then
  begin
    Result := True; // Cocoa should not handle the message.
    Exit;           // LCL should get the notification either.
  end;

  // If LCL control is provided and it's in designing state.
  // The default resolution: Notify LCL about event, but don't let Cocoa
  // do anything with it. (Result=true)
  Result := Assigned(Target) and (csDesigning in Target.ComponentState);

  MousePos := Event.locationInWindow;
  OffsetMousePos(MousePos);
  mp.X:=round(MousePos.x);
  mp.Y:=round(MousePos.y);

  rect:=Owner.lclClientFrame;
  targetControl:=nil;

  callback := GetCaptureControlCallback();
  if callback <> nil then
  begin
    FIsEventRouting:=true;
    Result := callback.MouseMove(Event);
    FIsEventRouting:=false;
    exit;
  end
  else
  begin
    rect:=Target.BoundsRect;
    OffsetRect(rect, -rect.left, -rect.Top);
    if (event.type_ = NSMouseMoved) and (not Types.PtInRect(rect, mp)) then
      // do not send negative coordinates (unless dragging mouse)
      Exit;

    if assigned(Target.Parent) and not Types.PtInRect(rect, mp) then
       targetControl:=Target.Parent // outside myself then route to parent
    else
    for i:=Target.ControlCount-1 downto 0  do // otherwise check, if over child and route to child
      if Target.Controls[i] is TWinControl then
      begin
        childControl:=TWinControl(Target.Controls[i]);
        rect:=childControl.BoundsRect;
        if  Types.PtInRect(rect, mp) then
        begin
          targetControl:=childControl;
          break;
        end;
      end;
  end;

  if assigned(targetControl) and not FIsEventRouting then
  begin
    if not targetControl.HandleAllocated then Exit; // Fixes crash due to events being sent after ReleaseHandle
    FIsEventRouting:=true;
    // debugln(Target.name+' -> '+targetControl.Name+'- is parent:'+dbgs(targetControl=Target.Parent)+' Point: '+dbgs(mp)+' Rect'+dbgs(rect));
    obj := GetNSObjectView(NSObject(targetControl.Handle));
    if obj = nil then Exit;
    callback := obj.lclGetCallback;
    if callback = nil then Exit; // Avoids crashes
    result := callback.MouseMove(Event);
    FIsEventRouting := false;
    exit;
  end;

  // debugln('Send to: '+Target.name+' Point: '+dbgs(mp));

  FillChar(Msg, SizeOf(Msg), #0);
  Msg.Msg := LM_MOUSEMOVE;
  Msg.Keys := CocoaModifiersToKeyState(Event.modifierFlags) or CocoaPressedMouseButtonsToKeyState(NSEvent.pressedMouseButtons);
  Msg.XPos := mp.X;
  Msg.YPos := mp.Y;

  //debugln('MouseMove x='+dbgs(MousePos.X)+' y='+dbgs(MousePos.Y)+' Target='+Target.Name);

  NotifyApplicationUserInput(Target, Msg.Msg);
  Result := DeliverMessage(Msg) <> 0;
end;

function TLCLCommonCallback.scrollWheel(Event: NSEvent): Boolean;
var
  Msg: TLMMouseEvent;
  MousePos: NSPoint;
  MButton: NSInteger;
begin
  Result := False; // allow cocoa to handle message

  if Assigned(Target) and (not (csDesigning in Target.ComponentState) and not Owner.lclIsEnabled) then
    Exit;

  MousePos := Event.locationInWindow;
  OffsetMousePos(MousePos);

  MButton := event.buttonNumber;
  if MButton >= 3 then
     MButton := 3;

  FillChar(Msg, SizeOf(Msg), #0);

  Msg.Button := MButton;
  Msg.X := round(MousePos.X);
  Msg.Y := round(MousePos.Y);
  Msg.State :=  TShiftState(integer(CocoaModifiersToKeyState(Event.modifierFlags)));

  // Some info on event.deltaY can be found here:
  // https://developer.apple.com/library/mac/releasenotes/AppKit/RN-AppKitOlderNotes/
  // It says that deltaY=1 means 1 line, and in the LCL 1 line is 120
  if event.deltaY <> 0 then
  begin
    Msg.Msg := LM_MOUSEWHEEL;
    Msg.WheelDelta := round(event.deltaY * 120);
  end
  else
  if event.deltaX <> 0 then
  begin
    Msg.Msg := LM_MOUSEHWHEEL;
    Msg.WheelDelta := round(event.deltaX * 120);
  end
  else
    // Filter out empty events - See bug 28491
    Exit;

  NotifyApplicationUserInput(Target, Msg.Msg);
  Result := DeliverMessage(Msg) <> 0;
end;

procedure TLCLCommonCallback.frameDidChange(sender: id);
begin
  boundsDidChange(sender);
end;

procedure TLCLCommonCallback.boundsDidChange(sender: id);
var
  NewBounds, OldBounds: TRect;
  PosMsg: TLMWindowPosChanged;
  Resized, Moved, ClientResized: Boolean;
  SizeType: Integer;
begin
  NewBounds := Frame.lclFrame;

  //debugln('Newbounds='+ dbgs(newbounds));
  // send window pos changed
  PosMsg.Msg := LM_WINDOWPOSCHANGED;
  PosMsg.Result := 0;
  New(PosMsg.WindowPos);
  try
    with PosMsg.WindowPos^ do
    begin
      hWndInsertAfter := 0;
      x := NewBounds.Left;
      y := NewBounds.Right;
      cx := NewBounds.Right - NewBounds.Left;
      cy := NewBounds.Bottom - NewBounds.Top;
      flags := 0;
    end;
    LCLMessageGlue.DeliverMessage(Target, PosMsg);
  finally
    Dispose(PosMsg.WindowPos);
  end;

  OldBounds := Target.BoundsRect;
  //debugln('OldBounds Target='+Target.Name+':'+ dbgs(OldBounds));

  Resized :=
    (OldBounds.Right - OldBounds.Left <> NewBounds.Right - NewBounds.Left) or
    (OldBounds.Bottom - OldBounds.Top <> NewBounds.Bottom - NewBounds.Top);

  Moved :=
    (OldBounds.Left <> NewBounds.Left) or
    (OldBounds.Top <> NewBounds.Top);

  ClientResized := (sender <> Frame)
    and not EqualRect(Target.ClientRect, Frame.lclClientFrame);

  // update client rect
  if ClientResized or Resized or Target.ClientRectNeedsInterfaceUpdate then
  begin
    Target.InvalidateClientRectCache(false);
    ClientResized := True;
  end;

  // then send a LM_SIZE message
  if Resized or ClientResized then
  begin
    LCLSendSizeMsg(Target, NewBounds.Right - NewBounds.Left,
      NewBounds.Bottom - NewBounds.Top, Owner.lclWindowState, True);
  end;

  // then send a LM_MOVE message
  if Moved then
  begin
    LCLSendMoveMsg(Target, NewBounds.Left,
      NewBounds.Top, Move_SourceIsInterface);
  end;

  if not FBoundsReportedToChildren then // first time we need this to update non cocoa based client rects
  begin
    Target.InvalidateClientRectCache(true);
    FBoundsReportedToChildren:=true;
  end;

end;

procedure TLCLCommonCallback.BecomeFirstResponder;
begin
  LCLSendSetFocusMsg(Target);
end;

procedure TLCLCommonCallback.ResignFirstResponder;
begin
  LCLSendKillFocusMsg(Target);
end;

procedure TLCLCommonCallback.DidBecomeKeyNotification;
begin
  LCLSendActivateMsg(Target, WA_ACTIVE, false);
  LCLSendSetFocusMsg(Target);
end;

procedure TLCLCommonCallback.DidResignKeyNotification;
begin
  LCLSendActivateMsg(Target, WA_INACTIVE, false);
  LCLSendKillFocusMsg(Target);
end;

procedure TLCLCommonCallback.SendOnChange;
begin
  SendSimpleMessage(Target, LM_CHANGED);
end;

procedure TLCLCommonCallback.SendOnTextChanged;
begin
  SendSimpleMessage(Target, CM_TEXTCHANGED);
end;

procedure TLCLCommonCallback.scroll(isVert: Boolean; Pos: Integer);
var
  LMScroll: TLMScroll;
  b: Boolean;
begin
  FillChar(LMScroll{%H-}, SizeOf(LMScroll), #0);
  //todo: this should be a part of a parameter
  //LMScroll.ScrollBar := Target.Handle;

  if IsVert then
    LMScroll.Msg := LM_VSCROLL
  else
    LMScroll.Msg := LM_HSCROLL;

  LMScroll.Pos := Pos;
  LMScroll.ScrollCode := SB_THUMBPOSITION; //SIF_POS;

  LCLMessageGlue.DeliverMessage(Target, LMScroll);
end;

function TLCLCommonCallback.DeliverMessage(var Msg): LRESULT;
begin
  Result := LCLMessageGlue.DeliverMessage(Target, Msg);
end;

function TLCLCommonCallback.DeliverMessage(Msg: Cardinal; WParam: WParam; LParam: LParam): LResult;
var
  Message: TLMessage;
begin
  Message.Msg := Msg;
  Message.WParam := WParam;
  Message.LParam := LParam;
  Message.Result := 0;
  Result := DeliverMessage(Message);
end;

procedure TLCLCommonCallback.Draw(ControlContext: NSGraphicsContext;
  const bounds, dirty: NSRect);
var
  PS: PPaintStruct;
  nsr:NSRect;
begin
  // todo: think more about draw call while previous draw still active
  if Assigned(FContext) then
    Exit;
  FContext := TCocoaContext.Create(ControlContext);
  FContext.isControlDC := True;
  try
    // debugln('Draw '+Target.name+' bounds='+Dbgs(NSRectToRect(bounds))+' dirty='+Dbgs(NSRectToRect(dirty)));
    if FContext.InitDraw(Round(bounds.size.width), Round(bounds.size.height)) then
    begin
      nsr:=dirty;
      nsr.origin.y:=bounds.size.height-dirty.origin.y-dirty.size.height;

      if FIsOpaque and (Target.Color<>clDefault) then
      begin
        FContext.BkMode:=OPAQUE;
        FContext.BkColor:=Target.Color;
        FContext.BackgroundFill(nsr);
        //debugln('Background '+Target.name+Dbgs(NSRectToRect(dirty)));
      end;

      New(PS);
      try
        FillChar(PS^, SizeOf(TPaintStruct), 0);
        PS^.hdc := HDC(FContext);
        PS^.rcPaint := NSRectToRect(nsr);
        LCLSendPaintMsg(Target, HDC(FContext), PS);
        if FHasCaret then
          DrawCaret;
      finally
        Dispose(PS);
      end;
    end;
  finally
    FreeAndNil(FContext);
  end;
end;

procedure TLCLCommonCallback.DrawBackground(ctx: NSGraphicsContext; const bounds, dirtyRect: NSRect);
var
  lTarget: TWinControl;
begin
  // Implement Color property
  lTarget := TWinControl(GetTarget());
  if (lTarget.Color <> clDefault) and (lTarget.Color <> clBtnFace) then
  begin
    ColorToNSColor(ColorToRGB(lTarget.Color)).set_();
    NSRectFill(dirtyRect);
  end;
end;

procedure TLCLCommonCallback.DrawOverlay(ControlContext: NSGraphicsContext;
  const bounds, dirty: NSRect);
var
  PS  : TPaintStruct;
  nsr : NSRect;
begin
  // todo: think more about draw call while previous draw still active
  if Assigned(FContext) then
    Exit;
  FContext := TCocoaContext.Create(ControlContext);
  FContext.isControlDC := True;
  FContext.isDesignDC := True;
  try
    // debugln('Draw '+Target.name+' bounds='+Dbgs(NSRectToRect(bounds))+' dirty='+Dbgs(NSRectToRect(dirty)));
    if FContext.InitDraw(Round(bounds.size.width), Round(bounds.size.height)) then
    begin
      nsr:=dirty;
      nsr.origin.y:=bounds.size.height-dirty.origin.y-dirty.size.height;

      FillChar(PS, SizeOf(TPaintStruct), 0);
      PS.hdc := HDC(FContext);
      PS.rcPaint := NSRectToRect(nsr);
      LCLSendPaintMsg(Target, HDC(FContext), @PS);
    end;
  finally
    FreeAndNil(FContext);
  end;
end;

function TLCLCommonCallback.ResetCursorRects: Boolean;
var
  ACursor: TCursor;
  View: NSView;
begin
  Result := False;
  View := CocoaUtils.GetNSObjectView(Owner);
  if View = nil then Exit;
  if not (csDesigning in Target.ComponentState) then
  begin
    ACursor := Screen.Cursor;
    if ACursor = crDefault then
    begin
      // traverse visible child controls
      ACursor := Target.Cursor;
    end;
    Result := ACursor <> crDefault;
    if Result then
      View.addCursorRect_cursor(View.visibleRect, TCocoaCursor(Screen.Cursors[ACursor]).Cursor);
  end;
end;

function TLCLCommonCallback.GetIsOpaque: Boolean;
begin
  Result:= FIsOpaque;
end;

procedure TLCLCommonCallback.SetIsOpaque(AValue: Boolean);
begin
  FIsOpaque:=AValue;
end;

function TLCLCommonCallback.GetShouldBeEnabled: Boolean;
begin
  Result := Assigned(FTarget) and FTarget.Enabled;
end;

{ TCocoaWSControl }

class function TCocoaWSControl.GetCanvasScaleFactor(const AControl: TControl
  ): Double;
begin
  if Assigned(AControl.Parent) then
    Result := AControl.Parent.GetCanvasScaleFactor
  else
    Result := 1;
end;

{ TCocoaWSWinControl }

class procedure TCocoaWSWinControl.ArrangeTabOrder(
  const AWinControl: TWinControl);
var
  lList: TFPList;
  prevControl, curControl: TWinControl;
  lPrevView, lCurView: NSView;
  i: Integer;
begin
  lList := TFPList.Create;
  try
    AWinControl.GetTabOrderList(lList);
    if lList.Count>0 then
      begin
      prevControl := TWinControl(lList.Items[lList.Count-1]);
      lPrevView := GetNSObjectView(NSObject(prevControl.Handle));
      for i := 0 to lList.Count-1 do
      begin
        curControl := TWinControl(lList.Items[i]);
        lCurView := GetNSObjectView(NSObject(curControl.Handle));

        if (lCurView <> nil) and (lPrevView <> nil) then
          lPrevView.setNextKeyView(lCurView);

        lPrevView := lCurView;
      end;
    end;
  finally
    lList.Free;
  end;
end;

class function TCocoaWSWinControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
begin
  Result := TCocoaWSCustomControl.CreateHandle(AWinControl, AParams);
end;

class procedure TCocoaWSWinControl.DestroyHandle(const AWinControl: TWinControl);
var
  obj: NSObject;
  Callback: ICommonCallback;
  CallbackObject: TObject;
  pool: NSAutoreleasePool;
begin
  if not AWinControl.HandleAllocated then
    Exit;
  pool := NSAutoreleasePool.alloc.init;
  obj := NSObject(AWinControl.Handle);
  if obj.isKindOfClass_(NSView) then
  begin
    //todo: removeFromSuperview + autorelease pool seems to be releasing the object
    // retain prevents an error of .release below need to be updated
    // according to the latest Apple recommendations of ATC
    NSView(obj).retain;
    NSView(obj).removeFromSuperview;
  end
  else
  if obj.isKindOfClass_(NSWindow) then
    NSWindow(obj).close;
  pool.release;
  // destroy the callback
  Callback := obj.lclGetCallback;
  if Assigned(Callback) then
  begin
    CallbackObject := Callback.GetCallbackObject;
    Callback := nil;
    obj.lclClearCallback;
    CallbackObject.Free;
  end;
  obj.release;
end;

class function TCocoaWSWinControl.GetCanvasScaleFactor(const AControl: TControl
  ): Double;
begin
  if TWinControl(AControl).HandleAllocated then
    Result := TCocoaWindow(TWinControl(AControl).Handle).backingScaleFactor // ToDo: use userSpaceScaleFactor for Mac OSX 10.6
  else
    Result := 1;
end;

class procedure TCocoaWSWinControl.SetText(const AWinControl: TWinControl; const AText: String);
var
  obj: NSObject;
  text:string;
begin
  if not AWinControl.HandleAllocated then
    Exit;
  obj := NSObject(AWinControl.Handle);
  text:=AText;
  DeleteAmpersands(text);
  if obj.isKindOfClass_(NSControl) then
    SetNSControlValue(NSControl(obj), text);
end;

class function TCocoaWSWinControl.GetText(const AWinControl: TWinControl; var AText: String): Boolean;
var
  obj: NSObject;
begin
  Result := AWinControl.HandleAllocated;
  if not Result then
    Exit;
  obj := NSObject(AWinControl.Handle);
  Result := obj.isKindOfClass_(NSControl);
  if Result then
    AText := GetNSControlValue(NSControl(obj));
end;

class function TCocoaWSWinControl.GetTextLen(const AWinControl: TWinControl; var ALength: Integer): Boolean;
var
  obj: NSObject;
  s: NSString;
begin
  Result := AWinControl.HandleAllocated;
  if not Result then
    Exit;

  obj := NSObject(AWinControl.Handle);
  Result := obj.isKindOfClass_(NSControl);
  if not Result then Exit;

  s := NSControl(obj).stringValue;
  if Assigned(s) then
    ALength := s.length
  else
    ALength := 0
end;

class function TCocoaWSWinControl.GetClientBounds(const AWincontrol: TWinControl; var ARect: TRect): Boolean;
begin
  Result := AWinControl.HandleAllocated;
  if Result then
    ARect := NSObject(AWinControl.Handle).lclClientFrame;
end;

class function TCocoaWSWinControl.GetClientRect(const AWincontrol: TWinControl; var ARect: TRect): Boolean;
begin
  Result:=(AWinControl.Handle<>0);
  if not Result then Exit;
  ARect:=NSObject(AWinControl.Handle).lclClientFrame;
  if (ARect.Left<>0) or (ARect.Top<>0) then
    OffsetRect(ARect, -ARect.Left, -ARect.Top);
end;

class procedure TCocoaWSWinControl.GetPreferredSize(
  const AWinControl: TWinControl; var PreferredWidth, PreferredHeight: integer;
  WithThemeSpace: Boolean);
var
  lView: NSView;
  Size: NSSize;
begin
  if not AWinControl.HandleAllocated then Exit;

  //todo: GetNSObjectView must be replaced with oop approach
  //      note that client rect might be smaller than the bounds of TWinControl itself
  //      thus extra size should be adapted
  lView := CocoaUtils.GetNSObjectView(NSObject(AWinControl.Handle));
  if lView = nil then Exit;

  //todo: using fittingSize is wrong - it's based on constraints of the control solely.
  //CocoaWidgetset is not using these constrains. As a result, CocoaComboBox
  //produces wrong size: width 3 and height 26 (or OSX 10.9)
  //as well as SpinEdit itself. The better approach is to use intrinsicContentSize method.
  // Felipe: intrinsicContentSize doesn't give any better results in my tests, it results in even smaller controls
  if lView.respondsToSelector(objcselector('fittingSize')) then // fittingSize is 10.7+
  begin
    Size := lView.fittingSize();
    PreferredWidth := Round(Size.width);
    PreferredHeight := Round(Size.height);
  end;
end;

class procedure TCocoaWSWinControl.SetBounds(const AWinControl: TWinControl;
  const ALeft, ATop, AWidth, AHeight: Integer);
begin
  if AWinControl.HandleAllocated then
  begin
    {$IFDEF COCOA_DEBUG_SETBOUNDS}
    writeln(Format('TCocoaWSWinControl.SetBounds: %s Bounds=%s',
      [AWinControl.Name, dbgs(Bounds(ALeft, ATop, AWidth, AHeight))]));
    {$ENDIF}
    NSObject(AWinControl.Handle).lclSetFrame(Bounds(ALeft, ATop, AWidth, AHeight));
  end;
end;

class procedure TCocoaWSWinControl.SetCursor(const AWinControl: TWinControl;
  const ACursor: HCursor);
begin
  //debugln('SetCursor '+AWinControl.name+' '+dbgs(ACursor));
  if CocoaWidgetSet.CurrentCursor<>ACursor then
  begin
    CocoaWidgetSet.CurrentCursor:= ACursor;

    if ACursor<>0 then
      TCocoaCursor(ACursor).SetCursor
    else
      TCocoaCursor.SetDefaultCursor;
  end;
end;

class procedure TCocoaWSWinControl.SetFont(const AWinControl: TWinControl; const AFont: TFont);
var
  Obj: NSObject;
  Cell: NSCell;
  Str: NSAttributedString;
  NewStr: NSMutableAttributedString;
  Dict: NSDictionary;
  Range: NSRange;
begin
  if (AWinControl.HandleAllocated) then
  begin
    Obj := NSObject(AWinControl.Handle);
    if Obj.isKindOfClass(NSScrollView) then
      Obj := NSScrollView(Obj).documentView;
    if Obj.isKindOfClass(NSControl) then
    begin
      Cell := NSCell(NSControl(Obj).cell);
      Cell.setFont(TCocoaFont(AFont.Reference.Handle).Font);
      // try to assign foreground color?
      Str := Cell.attributedStringValue;
      if Assigned(Str) then
      begin
        NewStr := NSMutableAttributedString.alloc.initWithAttributedString(Str);
        Range.location := 0;
        Range.length := NewStr.length;
        if AFont.Color = clDefault then
          NewStr.removeAttribute_range(NSForegroundColorAttributeName, Range)
        else
          NewStr.addAttribute_value_range(NSForegroundColorAttributeName, ColorToNSColor(ColorToRGB(AFont.Color)), Range);
        Cell.setAttributedStringValue(NewStr);
        NewStr.release;
      end;
    end
    else
    if Obj.isKindOfClass(NSText) then
    begin
      NSText(Obj).setFont(TCocoaFont(AFont.Reference.Handle).Font);
      if AFont.Color = clDefault then
        NSText(Obj).setTextColor(nil)
      else
        NSText(Obj).setTextColor(ColorToNSColor(ColorToRGB(AFont.Color)));
    end;
  end;
end;

class procedure TCocoaWSWinControl.SetColor(const AWinControl: TWinControl);
begin
  invalidate(AWinControl);
end;

function indexInList(ctrl: id; l: TFPList): integer;
var
 i : integer;
begin
  for i:=0 to l.Count-1 do
    if PtrUInt(TWinControl(l[i]).Handle)=PtrUInt(ctrl) then
    begin
      Result:=i;
      exit;
    end;
  Result:=-1;
end;

function SortHandles(param1: id; param2: id; param3: Pointer): NSComparisonResult; cdecl;
var
  i1,i2: integer;
begin
  i1:=indexInList(param1, TFPList(param3));
  i2:=indexInList(param2, TFPList(param3));
  if i1<i2 then Result:=NSOrderedDescending
  else if i1>i2 then Result:=NSOrderedAscending
  else Result:=NSOrderedSame;
end;

class procedure TCocoaWSWinControl.SetChildZPosition(const AWinControl,
  AChild: TWinControl; const AOldPos, ANewPos: Integer; const AChildren: TFPList
  );
var
  pr : NSView;
  ch : NSView;
  ab : NSView;
  c  : TObject;
  i  : integer;
begin
  if (not AWinControl.HandleAllocated) or (not AChild.HandleAllocated) then Exit;

  pr:=NSView(AWinControl.Handle);

  //todo: sorting might be a better option than removing / adding a view
  //      (whenever a focused (firstrepsonder view) is moved to front, focus is lost.
  //      if that's not the case for sorting, then sorting *must* be used
  //      current problem, is that during sorting a new order needs to be determined
  //      (the desired order is given in AChildren list).
  //      however, on every comparison, an index must be searched withing a list.
  //      and that might be very slow! (if a lot of sibling controls is present)
  //      instead of a search, it's beter to store the desired sorting order with a view
  //      itself. However, that requires adding additional methods  lclSetNewOrder and lclGetNewOrder
  //
  //pr.sortSubviewsUsingFunction_context(@SortHandles, AChildren);
  //
  // if sorting is used, all code below is not needed

  ch:=NSView(AChild.Handle);

  // The way of changing the order in an array of views
  // is to remove a view and then reinstert it at the new spot
  ch.retain();
  try
    ch.removeFromSuperview();
    if ANewPos=0 then
    begin
      pr.addSubview_positioned_relativeTo(ch, NSWindowBelow, nil)
    end
    else
    begin
      i:=AChildren.Count-ANewPos;
      c:=TObject(AChildren[i]);
      if c is TWinControl then
      begin
        c:=TObject(AChildren[i]);
        ab:=NSView(TWinControl(c).Handle);
      end
      else
        ab:=nil;
      pr.addSubview_positioned_relativeTo(ch, NSWindowAbove, ab);
    end;
  finally
    ch.release();
  end;

  //NSView(AChild.Handle).moveDown
  //inherited SetChildZPosition(AWinControl, AChild, AOldPos, ANewPos, AChildren);
end;

class procedure TCocoaWSWinControl.ShowHide(const AWinControl: TWinControl);
var
  pool: NSAutoreleasePool;   // called outside apploop on startup - therefore has to be enframed by pool
  lShow: Boolean;
begin
  //WriteLn(Format('[TCocoaWSWinControl.ShowHide] AWinControl=%s %s', [AWinControl.Name, AWinControl.ClassName]));
  if AWinControl.HandleAllocated then
  begin
    pool := NSAutoreleasePool.alloc.init;
    lShow := AWinControl.HandleObjectShouldBeVisible;

    NSObject(AWinControl.Handle).lclSetVisible(lShow);

    // TabStop / TabOrder support
    if (AWinControl is TCustomForm) and lShow then
      ArrangeTabOrder(AWinControl);

    pool.release;
  end;
end;

class procedure TCocoaWSWinControl.Invalidate(const AWinControl: TWinControl);
begin
  if AWinControl.HandleAllocated then
     NSObject(AWinControl.Handle).lclInvalidate;
end;

{ TCocoaWSCustomControl }

class function TCocoaWSCustomControl.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  ctrl : TCocoaCustomControl;
  sl   : TCocoaManualScrollView;
  lcl  : TLCLCustomControlCallback;
begin
  ctrl := TCocoaCustomControl(TCocoaCustomControl.alloc.lclInitWithCreateParams(AParams));
  lcl := TLCLCustomControlCallback.Create(ctrl, AWinControl);
  ctrl.callback := lcl;

  sl := EmbedInManualScrollView(ctrl);
  sl.callback := ctrl.callback;
  lcl.frame:=sl;

  Result := TLCLIntfHandle(sl);
end;

end.

