unit sardJSONReaders;
{**
*  This file is part of the "SARD"
*
* @license   The MIT License (MIT)
*            Included in this distribution
* @author    Zaher Dirkey <zaher at parmaja dot com>
*}

{$IFDEF FPC}
{$mode delphi}
{$ENDIF}
{$H+}{$M+}

interface

uses
  Classes, SysUtils, TypInfo, Variants,
  mnUtils, mnClasses, mnRTTIUtils,
  sardClasses, sardParsers, sardStandards;

type
  TJSONParser = class;

  { TJSONController }

  TJSONController = class(TController)
  protected
  public
    procedure SetControl(Control: TSardControl); override;
  end;

  { TJSONCollector }

  TJSONCollector = class(TCollector)
  private
  protected
    procedure DoControl(AControl: TSardControl); override;
  public
    function IsInitial: Boolean; override;
    procedure Reset; override;
  end;

  { TJSONCollectorElement }

  TJSONCollectorElement = class(TJSONCollector)
  private
    Name: string;
  protected
    type
      TExpect = (elmName, elmValue);
    var
      Expect: TExpect;
    ParentObject: TObject;
    CurrentObject: TObject;
  public
    constructor Create(AParser: TParser; AParentObject, ACurrentObject: TObject);
    procedure Reset; override;
    procedure DoToken(Token: TSardToken); override;
    procedure DoControl(AControl: TSardControl); override;
  end;

  { TJSONCollectorValue }

  TJSONCollectorValue = class(TJSONCollector)
  private
  protected
    type
      TExpect = (valValue, valNext);
    var
      Expect: TExpect;
    CurrentObject: TObject;
    Name: string;
  public
    constructor Create(AParser: TParser; AName: string; AObject: TObject);
    procedure Reset; override;
    procedure DoToken(Token: TSardToken); override;
    procedure DoControl(AControl: TSardControl); override;
  end;

  { TJSONCollectorArray }

  TJSONCollectorArray = class(TJSONCollector)
  private
  protected
    type
      TExpect = (aryValue, aryNext);
    var
      Expect: TExpect;
    ParentObject: TObject; //element with array value created
    //CurrentObject: TObject;
    Name: string;
  public
    constructor Create(AParser: TParser; AName: string; AParentObject: TObject);
    procedure Reset; override;
    procedure DoToken(Token: TSardToken); override;
    procedure DoControl(AControl: TSardControl); override;
  end;

  { TJSONLexer }

  TJSONLexer = class(TLexer)
  protected
    const
      sWhitespace = sEOL + [' ', #8];
      sNumberOpenChars = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      sNumberChars = sNumberOpenChars + ['.', 'x', 'h', 'a', 'b', 'c', 'd', 'e', 'f'];
      sSymbolChars = ['"', '''', '\']; //deprecated;
      sIdentifierSeparator = '.';
  public
    constructor Create; override;
    function IsEOL(vChar: Char): Boolean; override;
    function IsWhiteSpace(vChar: char; vOpen: Boolean =true): Boolean; override;
    function IsControl(vChar: Char): Boolean; override;
    function IsOperator(vChar: Char): Boolean; override;
    function IsNumber(vChar: Char; vOpen: Boolean =true): Boolean; override;
    function IsSymbol(vChar: Char): Boolean; override;
    function IsIdentifier(vChar: Char; vOpen: Boolean =true): Boolean;
  end;

  TJSONType = (
    jtString,
    jtNumber,
    jtObject,
    jtArray
  );

  { TJSONParser }

  TJSONParser = class(TParser)
  protected
    Lexer: TLexer;
    procedure DoQueue;
    procedure NeedObject(AParentObject: TObject; AName: string; out AObject: TObject); virtual;
    procedure SetObjectValue(AObject: TObject; AName: string; AValue: string; AType: TJSONType); virtual;
  public
    constructor Create(ALexer: TLexer; AObject: TObject); virtual;
    destructor Destroy; override;

    procedure SetToken(Token: TSardToken); override;
    procedure SetControl(AControl: TSardControl); override;
    procedure Start; override;
    procedure Stop; override;
  end;

  TJSONParserClass = class of TJSONParser;

  { TSourceWriter }

  TSourceWriter = class abstract(TObject)
  public
    TabWidth: Integer;
    constructor Create;
    procedure Add(S: string); virtual; abstract; overload;
    procedure Add(Level: Integer = 1; S: string = ''); overload;
    procedure NewLine; virtual; abstract;
  end;

  { TStringSourceWriter }

  TStringSourceWriter = class(TSourceWriter)
  private
    FStrings: TStrings;
    FLine: string;
  public
    constructor Create(Strings: TStrings);
    destructor Destroy; override;
    procedure Add(S: string); override;
    procedure NewLine; override;
  end;

  { TRTTIJSONParser }

  TRTTIJSONParser = class(TJSONParser)
  protected
    procedure SetObjectValue(AObject: TObject; AName: string; AValue: string; AType: TJSONType); override;
  end;

  { TJSONObject }

  TJSONObject = class abstract(TSardObject)
  public
    procedure WriteTo(Writer: TSourceWriter; LastOne:Boolean; Level: Integer); virtual;
  end;

  TJSONValue = class;

  { TJSONElement }

  TJSONElement = class(TJSONObject)
  private
    FName: string;
    FValue: TJSONValue;
    procedure SetName(AValue: string);
    procedure SetValue(AValue: TJSONValue);
  public
    procedure WriteTo(Writer: TSourceWriter; LastOne:Boolean; Level: Integer); override;
  published
    property Value: TJSONValue read FValue write SetValue;
    property Name: string read FName write SetName;
  end;

  { TJSONRoot }

  TJSONRoot = class(TJSONElement)
  public
    procedure WriteTo(Writer: TSourceWriter; LastOne:Boolean; Level: Integer); override;
  end;

  TJSONElementClass = class of TJSONElement;

  { TJSONValue }

  TJSONValue = class abstract(TJSONObject)
  private
    FParent: TJSONElement;
  public
    constructor Create(AParent: TJSONElement);
    procedure WriteTo(Writer: TSourceWriter; LastOne:Boolean; Level: Integer); override;
    property Parent: TJSONElement read FParent;
  end;

  TJSONValueClass = class of TJSONValue;

  { TJSONString_Value }

  TJSONString_Value = class(TJSONValue)
  private
    FText: string;
  public
    procedure WriteTo(Writer: TSourceWriter; LastOne: Boolean; Level: Integer); override;
    constructor Create(AParent: TJSONElement; AText: string); overload;
  published
    property Text: string read FText write FText;
  end;

  { TJSONNumber_Value }

  TJSONNumber_Value = class(TJSONValue)
  private
    FNumber: string;
  public
    procedure WriteTo(Writer: TSourceWriter; LastOne:Boolean; Level: Integer); override;
    constructor Create(AParent: TJSONElement; ANumber: string); overload;
  published
    property Number: string read FNumber write FNumber;
  end;

  { TJSONItems }

  TJSONItems = class(TmnObjectList<TJSONElement>)
  public
  end;

  { TJSONObject_Value }

  TJSONObject_Value = class(TJSONValue)
  private
    FItems: TJSONItems;
  public
    procedure Created; override;
    destructor Destroy; override;
    procedure NeedObject(AJSONName: string; out AJSONObject: TObject);
    procedure Add(Value: TJSONElement); overload;
    procedure WriteTo(Writer: TSourceWriter; LastOne:Boolean; Level: Integer); override;
    property Items: TJSONItems read FItems;
  published
  end;

  { TJSONList }

  TJSONList = class(TmnObjectList<TJSONValue>)
  public
  end;

  { TJSONArray_Value }

  TJSONArray_Value = class(TJSONValue)
  private
    FItems: TJSONList;
  public
    procedure Created; override;
    destructor Destroy; override;
    procedure Add(Value: TJSONValue); overload;
    procedure WriteTo(Writer: TSourceWriter; LastOne: Boolean; Level: Integer); override;
    property Items: TJSONList read FItems;
  published
  end;

//--------------------

 { TDOMJSONParser }

  TDOMJSONParser = class(TJSONParser)
  protected
    type
      TJSONClass = class(TmnNamedObject)
      public
        JSONClass: TJSONValueClass;
      end;

      { TJSONClasses }

      TJSONClasses = class(TmnNamedObjectList<TJSONClass>)
      public
        procedure Add(AName: string; AValueClass: TJSONValueClass);
      end;

  protected
    JSONClasses: TJSONClasses;
    procedure NeedObject(AParentObject: TObject; AJSONName: string; out AJSONObject: TObject); override;
    procedure SetObjectValue(AObject: TObject; AName: string; AValue: string; AType: TJSONType); override;
  public
    procedure Created; override;
    destructor Destroy; override;
  end;

  { TJSONScanner }

  TJSONScanner = class(TScanner)
  protected
    FParserClass: TJSONParserClass;
    FRoot: TObject;
    function CreateParser: TParser; override;
  public
    constructor Create(ARoot: TObject; AParserClass: TJSONParserClass);
    procedure Compile(Lines: TStringList);
    property Root: TObject read FRoot;
  end;

implementation

uses
  StrUtils;

{ TSourceWriter }

constructor TSourceWriter.Create;
begin
  inherited Create;
  TabWidth := 4;
end;

procedure TSourceWriter.Add(Level: Integer; S: string);
begin
  Add(StringOfChar(' ', Level * TabWidth) + S);
end;

{ TJSONCollectorArray }

constructor TJSONCollectorArray.Create(AParser: TParser; AName: string; AParentObject: TObject);
begin
  inherited Create(AParser);
  Name := AName;
  ParentObject := AParentObject;
end;

procedure TJSONCollectorArray.Reset;
begin
  inherited Reset;
  Expect := Low(Expect);
end;

procedure TJSONCollectorArray.DoToken(Token: TSardToken);
begin
  RaiseError('No token for array!');
end;

procedure TJSONCollectorArray.DoControl(AControl: TSardControl);
begin
  case AControl.Code of
    ctlOpenArray:
    begin
      Parser.Push(TJSONCollectorValue.Create(Parser, Name, ParentObject));
    end;
    ctlCloseArray:
    begin
      Parser.SetAction([paPop]);
      Reset;
    end;
    ctlNext:
    begin
      Parser.Push(TJSONCollectorValue.Create(Parser, Name, ParentObject));
      Reset;
    end;
    else
      inherited;
  end;
end;

{ TStringSourceWriter }

constructor TStringSourceWriter.Create(Strings: TStrings);
begin
  inherited Create;
  FStrings := Strings;
end;

destructor TStringSourceWriter.Destroy;
begin
  if FLine <> '' then
    NewLine;
  inherited Destroy;
end;

procedure TStringSourceWriter.Add(S: string);
begin
  FLine := FLine + S;
end;

procedure TStringSourceWriter.NewLine;
begin
  FStrings.Add(FLine);
  FLine := '';
end;

{ TJSONRoot }

procedure TJSONRoot.WriteTo(Writer: TSourceWriter; LastOne: Boolean; Level: Integer);
begin
  Value.WriteTo(Writer, LastOne, Level);
end;

{ TJSONNumber_Value }

procedure TJSONNumber_Value.WriteTo(Writer: TSourceWriter; LastOne: Boolean; Level: Integer);
begin
  Writer.Add(Number);
  inherited;
end;

constructor TJSONNumber_Value.Create(AParent: TJSONElement; ANumber: string);
begin
  inherited Create(AParent);
  FNumber := ANumber;
end;

{ TJSONValue }

constructor TJSONValue.Create(AParent: TJSONElement);
begin
  inherited Create;
  FParent := AParent;
end;

procedure TJSONValue.WriteTo(Writer: TSourceWriter; LastOne: Boolean; Level: Integer);
begin
  if Self = nil then
    Writer.Add('null');
  if not LastOne then
    Writer.Add(',');
  Writer.NewLine;
end;

{ TJSONObject }

procedure TJSONObject.WriteTo(Writer: TSourceWriter; LastOne: Boolean; Level: Integer);
begin

end;

{ TJSONString_Value }

procedure TJSONString_Value.WriteTo(Writer: TSourceWriter; LastOne: Boolean; Level: Integer);
begin
  Writer.Add(QuoteStr(Text, '"'));
  inherited;
end;

constructor TJSONString_Value.Create(AParent: TJSONElement; AText: string);
begin
  inherited Create(AParent);
  FText := AText;
end;

{ TJSONArray_Value }

procedure TJSONArray_Value.Created;
begin
  inherited;
  FItems := TJSONList.Create;
end;

destructor TJSONArray_Value.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

procedure TJSONArray_Value.Add(Value: TJSONValue);
begin
  Items.Add(Value);
end;

procedure TJSONArray_Value.WriteTo(Writer: TSourceWriter; LastOne: Boolean; Level: Integer);
var
  Itm: TJSONValue;
begin
  Writer.Add('[');
  Writer.NewLine;
  for Itm in Items do
  begin
    Writer.Add(Level + 1);
    Itm.WriteTo(Writer, itm = Items.Last , Level + 1);
  end;
  Writer.Add(Level, ']');
  inherited;
end;

{ TJSONObject_Value }

procedure TJSONObject_Value.Created;
begin
  inherited;
  FItems := TJSONItems.Create;
end;

destructor TJSONObject_Value.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

procedure TJSONObject_Value.NeedObject(AJSONName: string; out AJSONObject: TObject);
begin
  AJSONObject := TJSONElement.Create;
  (AJSONObject as TJSONElement).Name := AJSONName;
  Add((AJSONObject as TJSONElement));
end;

procedure TJSONObject_Value.Add(Value: TJSONElement);
begin
  Items.Add(Value);
end;

procedure TJSONObject_Value.WriteTo(Writer: TSourceWriter; LastOne: Boolean; Level: Integer);
var
  Itm: TJSONElement;
begin
  Writer.Add('{');
  Writer.NewLine;
  for Itm in Items do
    Itm.WriteTo(Writer, itm = Items.Last , Level + 1);
  Writer.Add(Level, '}');
  inherited;
end;

{ TJSONElement }

procedure TJSONElement.SetValue(AValue: TJSONValue);
begin
  if FValue <> AValue then
  begin
    if (AValue.Parent <> nil) and (AValue.Parent <> self) then
      RaiseError('Value have parent we can`t move it to another parent');
    FreeAndNil(FValue);
    FValue := AValue;
    FValue.FParent := Self;
  end;
end;

procedure TJSONElement.SetName(AValue: string);
begin
  if FName =AValue then Exit;
  FName :=AValue;
end;

procedure TJSONElement.WriteTo(Writer: TSourceWriter; LastOne: Boolean; Level: Integer);
begin
  Writer.Add(Level, QuoteStr(Name, '"') + ': ');
  if Value = nil then
    RaiseError('Value is null for: ' + Name)
  else
    Value.WriteTo(Writer, LastOne, Level);
end;

{ TJSONClasses }

procedure TDOMJSONParser.TJSONClasses.Add(AName: string; AValueClass: TJSONValueClass);
var
  Item: TJSONClass;
begin
  Item := TJSONClass.Create;
  Item.Name := AName;
  Item.JSONClass := AValueClass;
  inherited Add(Item);
end;

{ TDOMJSONParser }

procedure TDOMJSONParser.NeedObject(AParentObject: TObject; AJSONName: string; out AJSONObject: TObject);
begin
  if not ((AParentObject as TJSONElement).Value is TJSONObject_Value) then
    RaiseError('Value is not object');
  ((AParentObject as TJSONElement).Value as TJSONObject_Value).NeedObject(AJSONName, AJSONObject);
end;

procedure TDOMJSONParser.SetObjectValue(AObject: TObject; AName: string; AValue: string; AType: TJSONType);
var
  v: TJSONValue;
  e: TJSONElement;
begin
  if AObject = nil then
    RaiseError('Can not assign value to nil element');

  e := AObject as TJSONElement;

  if (e.Value <> nil) and not(e.Value is TJSONArray_Value) then
    RaiseError('Value is already set and it is not array: ' + e.Value.ClassName);

  case AType of
    jtNumber: v :=  TJSONNumber_Value.Create(nil, AValue);
    jtString: v :=  TJSONString_Value.Create(nil, AValue);
    jtObject: v := TJSONObject_Value.Create(nil);
    jtArray: v := TJSONArray_Value.Create(nil);
  end;

  if (e.Value is TJSONArray_Value) then
    (e.Value as TJSONArray_Value).Add(v)
  else
    e.Value :=  v;
end;

procedure TDOMJSONParser.Created;
begin
  inherited Created;
  JSONClasses := TJSONClasses.Create;
  JSONClasses.Add('', TJSONString_Value);
  JSONClasses.Add('String', TJSONString_Value);
  JSONClasses.Add('Number', TJSONNumber_Value);
  JSONClasses.Add('Object', TJSONObject_Value);
  JSONClasses.Add('Array', TJSONArray_Value);
end;

destructor TDOMJSONParser.Destroy;
begin
  FreeAndNil(JSONClasses);
  inherited Destroy;
end;

{ TRTTIJSONParser }

procedure TRTTIJSONParser.SetObjectValue(AObject: TObject; AName: string; AValue: string; AType: TJSONType);
begin
  SetPropertyValue(AObject, AName, AValue);
end;

{ TJSONCollectorValue }

constructor TJSONCollectorValue.Create(AParser: TParser; AName: string; AObject: TObject);
begin
  inherited Create(AParser);
  Name := AName;
  CurrentObject := AObject;
end;

procedure TJSONCollectorValue.Reset;
begin
  inherited Reset;
  Expect := Low(Expect);
end;

procedure TJSONCollectorValue.DoToken(Token: TSardToken);
begin
  if Expect = valValue then
  begin
    if (Token.TokenType = typeIdentifier) or (Token.TokenType = typeString) then
      (Parser as TJSONParser).SetObjectValue(CurrentObject, Name, DequoteStr(Token.Value), jtString)
    else if (Token.TokenType = typeNumber) then
      (Parser as TJSONParser).SetObjectValue(CurrentObject, Name, DequoteStr(Token.Value), jtNumber);
    Inc(Expect);
  end
  else
    RaiseError('Value not expcted: ' + Token.Value);
end;

procedure TJSONCollectorValue.DoControl(AControl: TSardControl);
begin
  case AControl.Code of
    ctlOpenBlock:
    begin
      if Expect = valValue then
      begin
        (Parser as TJSONParser).SetObjectValue(CurrentObject, Name, '', jtObject);
        Parser.Push(TJSONCollectorElement.Create(Parser, CurrentObject, nil));
        Inc(Expect);
        //TODO Reset if not strict mode
      end
      else
        inherited;
    end;
    ctlCloseBlock:
    begin
      if Expect = valNext then
      begin
        Parser.SetAction([paPass, paPop]);
      end
      else
        inherited;
    end;
    ctlOpenArray:
    begin
      if Expect = valValue then
      begin
        (Parser as TJSONParser).SetObjectValue(CurrentObject, Name, '', jtArray);
        Parser.Push(TJSONCollectorArray.Create(Parser, Name, CurrentObject));
        Parser.SetAction([paPass]);
        Inc(Expect);
      end
      else
        inherited;
    end;
    ctlCloseArray:
    begin
      if Expect = valNext then
      begin
        Parser.SetAction([paPass, paPop]);
      end
      else
        inherited;
    end;
    ctlStop: //ctlStop using stop if file ended after value, we treat it as comma, but in Element collector we will check if that error
    begin
      if Expect = valNext then
      begin
        Parser.SetAction([paPass, paPop]);
        Reset;
      end
      else
        inherited;
    end;
    ctlNext:
    begin
      if Expect = valNext then
      begin
        Parser.SetAction([paPass, paPop]); //paPass pass it to array to push another value collection, but element should ignore it
        Reset;
      end
      else
        inherited;
    end;
    else
      inherited;
  end;
end;

{ TJSONCollectorElement }

constructor TJSONCollectorElement.Create(AParser: TParser; AParentObject, ACurrentObject: TObject);
begin
  inherited Create(AParser);
  CurrentObject := ACurrentObject;
  ParentObject := AParentObject;
end;

procedure TJSONCollectorElement.Reset;
begin
  inherited Reset;
  Name := '';
  Expect := Low(Expect);
end;

procedure TJSONCollectorElement.DoToken(Token: TSardToken);
begin
  if (Token.TokenType = typeIdentifier) or (Token.TokenType = typeString) then
  begin
    if Expect = elmName then
    begin
      if Name <> '' then
        RaiseError('Name already set: ' + Name);
      Name := DequoteStr(Token.Value, '"');
      //Inc(Expect);
    end
    else
      RaiseError('Name expected');
  end
  else
    RaiseError('Name expected');
end;

procedure TJSONCollectorElement.DoControl(AControl: TSardControl);
begin
  case AControl.Code of
    ctlStart:
      Parser.Push(TJSONCollectorValue.Create(Parser, '', CurrentObject));
    ctlAssign:
    begin
      if Expect = elmName then
      begin
        (Parser as TJSONParser).NeedObject(ParentObject, Name, CurrentObject);
        Parser.Push(TJSONCollectorValue.Create(Parser, Name, CurrentObject));
        Inc(Expect);
      end
      else
        inherited;
    end;
    ctlCloseBlock:
    begin
      if Expect = elmValue then
      begin
        Parser.SetAction([paPop]);
        Reset;
      end
      else
        inherited;
    end;
    ctlNext:
    begin
      if Expect = elmValue then
      begin
        Reset; //good if it come from values of array
      end
      else
        inherited;
    end;
    else
      inherited;
  end;
end;

{ TJSONCollector }

procedure TJSONCollector.DoControl(AControl: TSardControl);
begin
  case AControl.Code of
    ctlStart: ;
    ctlStop:
    begin
      if Parser.Count > 1 then
        RaiseError('Incomplete Code');
    end
    else
      RaiseError('Not Expected ' + AControl.Name);
  end;
end;

function TJSONCollector.IsInitial: Boolean;
begin
  Result := false;
end;

procedure TJSONCollector.Reset;
begin
end;

procedure TJSONController.SetControl(Control: TSardControl);
begin
  with (Collector as TJSONCollector) do
  begin
  end;
end;

{ TJSONScanner }

function TJSONScanner.CreateParser: TParser;
begin
  Result := FParserClass.Create(Current, FRoot);
end;

constructor TJSONScanner.Create(ARoot: TObject; AParserClass: TJSONParserClass);
begin
  inherited Create;
  FRoot := ARoot;
  FParserClass := AParserClass;
  Add(TJSONLexer.Create);
end;

procedure TJSONScanner.Compile(Lines: TStringList);
begin
  Scan(Lines);
end;

{ TJSONParser }

procedure TJSONParser.SetToken(Token: TSardToken);
begin
  Current.SetToken(Token);
  DoQueue;
  FActions := [];
end;

procedure TJSONParser.SetControl(AControl: TSardControl);
begin
  inherited;
  if Current = nil then
    RaiseError('There is no current collector');
  Current.SetControl(AControl);
  while true do
  begin
    DoQueue;
    if (paPass in Actions) then
    begin
      FActions := FActions - [paPass];
      Current.SetControl(AControl)
    end
    else
      break;
  end;
end;

procedure TJSONParser.DoQueue;
begin
  if (paPop in actions) then
  begin
    FActions := FActions - [paPop];
    Pop;
  end;

  if (NextCollector <> nil) then
  begin
    Push(NextCollector);
    FNextCollector := nil;
  end
end;

procedure TJSONParser.NeedObject(AParentObject: TObject; AName: string; out AObject: TObject);
begin
  AObject := nil;
end;

procedure TJSONParser.SetObjectValue(AObject: TObject; AName: string; AValue: string; AType: TJSONType);
begin
end;

constructor TJSONParser.Create(ALexer: TLexer; AObject: TObject);
begin
  inherited Create;
  Lexer := ALexer;
  Push(TJSONCollectorElement.Create(Self, nil, AObject));
end;

destructor TJSONParser.Destroy;
begin
  inherited;
end;

procedure TJSONParser.Start;
begin
  inherited;
  if Current <> nil then
    SetControl(Lexer.Controls.GetControl(ctlStart));
end;

procedure TJSONParser.Stop;
begin
  inherited;
  if Current <> nil then //not already finished
    SetControl(Lexer.Controls.GetControl(ctlStop));
end;

{ TJSONLexer }

constructor TJSONLexer.Create;
begin
  inherited;
  with Symbols do
  begin
  end;

  with Controls do
  begin
    Add('', ctlStart, 'Start');
    Add('', ctlStop, 'Stop');

    Add('(', ctlOpenParams);
    Add('[', ctlOpenArray);
    Add('{', ctlOpenBlock);
    Add(')', ctlCloseParams);
    Add(']', ctlCloseArray);
    Add('}', ctlCloseBlock);
    Add(',', ctlNext);
    Add(':', ctlAssign);
  end;

  with (Self) do
  begin
    Add(TWhitespace_Tokenizer.Create);
    Add(TComment_Tokenizer.Create);
    Add(TLineComment_Tokenizer.Create);
    Add(TNumber_Tokenizer.Create);
    Add(TDQString_Tokenizer.Create);
    Add(TControl_Tokenizer.Create);
    Add(TIdentifier_Tokenizer.Create);//Sould be last one
  end;
end;

function TJSONLexer.IsEOL(vChar: Char): Boolean;
begin
  Result := CharInSet(vChar, sEOL);
end;

function TJSONLexer.IsWhiteSpace(vChar: char; vOpen: Boolean): Boolean;
begin
  Result := CharInSet(vChar, sWhitespace);
end;

function TJSONLexer.IsControl(vChar: Char): Boolean;
begin
  Result := Controls.IsOpenBy(vChar);
end;

function TJSONLexer.IsOperator(vChar: Char): Boolean;
begin
  Result := Operators.IsOpenBy(vChar);
end;

function TJSONLexer.IsNumber(vChar: Char; vOpen: Boolean): Boolean;
begin
  if (vOpen) then
    Result := CharInSet(vChar, sNumberOpenChars)
  else
    Result := CharInSet(vChar, sNumberChars);
end;

function TJSONLexer.IsSymbol(vChar: Char): Boolean;
begin
  Result := CharInSet(vChar, sSymbolChars) or Symbols.IsOpenBy(vChar);
end;

function TJSONLexer.IsIdentifier(vChar: Char; vOpen: Boolean): Boolean;
begin
  Result := inherited isIdentifier(vChar, vOpen); //we do not need to override it, but it is nice to see it here
end;

end.
