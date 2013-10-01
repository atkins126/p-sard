unit sardClasses;
{**
 *  This file is part of the "SARD"
 *
 * @license   Apache License Version 2.0
 *            included in this distribution,
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

{$IFDEF FPC}
{$mode objfpc}
{$ENDIF}
{$H+}{$M+}

{TODO:
  Check S is not empty before push
  Push with the scanner class and id

  Result := Integer + Float <-- it convert to float or not, hmmm not sure
}

interface

uses
  Classes, SysUtils, Contnrs;

type
  Float = type extended;
  Int = type Int64;

type
  EsardException = class(Exception)
  private
    FCode: Cardinal;
  public
    property Code: Cardinal read FCode write FCode;
  end;

  EsardParserException = class(Exception)
  private
    FLine: Integer;
    FColumn: Integer;
  public
    constructor Create(const Msg: string; const Column, Line: Integer);
    property Column: Integer read FColumn write FColumn;
    property Line: Integer read FLine write FLine;
  end;

  //Base classes

  { TsardObject }

  TsardObject = class(TObject)
  protected
    procedure Created; virtual;
  public
    procedure AfterConstruction; override;
  end;

  { TsardObjectList }

  TsardObjectList = class(TObjectList)
  protected
    procedure Created; virtual;
  public
    procedure AfterConstruction; override;
  end;

  TsardControl = (ctlDeclare, ctlAssign, ctlOpenBracket, ctlCloseBracket, ctlOpenSquare, ctlCloseSquare, ctlOpenBlock, ctlCloseBlock, ctlStart, ctlStop, ctlComma, ctlSemicolon);
  TsardBracketKind = (brBracket, brSquare, brCurly);// and (), [], {} or maybe <>
  TsardTokinKind = (tkComment, tkIdentifier, tkNumber, tkSpace, tkString, tkSymbol, tkUnknown);

  TsardScannerID = type Integer;

  TsardScanners = class;
  TsardFeeder = class;
  TsardParser = class;

  TsardScannerClass = class of TsardScanner;

  { TsardScanner }

  TsardScanner = class(TsardObject)
  private
    FScanners: TsardScanners;
  protected
    procedure Scan(const Text: string; var Column: Integer); virtual; abstract;
    function Accept(const Text: string; var Column: Integer): Boolean; virtual;
    function DetectScanner(const Text: string; var Column: Integer): Integer;
    procedure SelectScanner(AScannerClass: TsardScannerClass);
  public
    Index: TsardScannerID;
    Collected: string; //buffer
    Scanner: TsardScannerID;
    constructor Create(vScanners: TsardScanners); virtual;
    destructor Destroy; override;
    property Scanners: TsardScanners read FScanners;
  end;

  { TsardScanners }

  TsardScanners = class(TsardObjectList)
  private
    FLine: Integer;
    FParser: TsardParser;
    FScannerID: TsardScannerID;
    function GetItem(Index: Integer): TsardScanner;
    procedure SetParser(AValue: TsardParser);
  public
    constructor Create(vParser: TsardParser);
    function DetectScanner(const Text: string; var Column: Integer): Integer;
    procedure SwitchScanner(NextScanner: TsardScannerID);
    procedure SelectScanner(ScannerClass: TsardScannerClass);
    function Find(const ScannerClass: TsardScannerClass): TsardScanner;
    procedure ScanLine(const Text: string; const ALine: Integer);
    function RegisterScanner(ScannerClass: TsardScannerClass): TsardScannerID;
    property Items[Index: Integer]: TsardScanner read GetItem; default;
    property ScannerID: TsardScannerID read FScannerID;
    property Parser: TsardParser read FParser ;//write SetParser;
    property Line: Integer read FLine;
  end;

  { TsardFeeder }

  TsardFeeder = class(TsardObject)
  private
    FActive: Boolean;
    FVersion: string;
    FCharset: string;
    FScanners: TsardScanners;//TODO use stacker
    procedure SetScanners(AValue: TsardScanners);
  protected
    procedure DoStart; virtual;
    procedure DoStop; virtual;
  public
    constructor Create(vScanners: TsardScanners);
    destructor Destroy; override;
    procedure ScanLine(const Text: string; const Line: Integer);
    procedure Scan(const Lines: TStrings);
    //procedure Scan(const FileName: string); overload; //TODO
    //procedure Scan(const Stream: TStream); overload; //TODO
    //procedure Scan(const Stream: IStream); overload; //TODO

    procedure Start;
    procedure Stop;
    property Active: Boolean read FActive write FActive;
    property Version: string read FVersion write FVersion;
    property Charset: string read FCharset write FCharset;
    property Scanners: TsardScanners read FScanners write SetScanners;

  end;

  TsrdType = (tpNone, tpObject, tpNumber, tpString, tpComment);

  { TsardParser }

  TsardParser = class(TsardObject)
  protected
    procedure Start; virtual;
    procedure Stop; virtual;
  public
    procedure TriggerOpen(vBracket: TsardBracketKind); virtual; abstract;
    procedure TriggerClose(vBracket: TsardBracketKind); virtual; abstract;
    procedure TriggerToken(AToken: String; AType: TsrdType); virtual; abstract;
    procedure TriggerOperator(AOperator: TsardObject); virtual; abstract;
    procedure TriggerControl(AControl: TsardControl); virtual; abstract;
  end;

  TsardStack = class;

  TsardStackItem = class(TsardObject)
  protected
    AnObject: TObject;
    Parent: TsardStackItem;
  public
    Owner: TsardStack;
    Level: Integer;
  end;

  { TsardStack }

  TsardStack = class(TsardObject)
  private
    FCount: Integer;
    FCurrentItem: TsardStackItem;
  protected
    function GetParent: TObject;
    function GetCurrent: TObject;
    procedure AfterPush; virtual;
    procedure BeforePop; virtual;
  public
    function IsEmpty: Boolean;
    procedure Push(vObject: TObject);
    procedure Pop;
    function Pull: TObject; //Pop but do not delete delete the ibject
    function Peek: TObject;
    property Current: TObject read GetCurrent;
    property Parent: TObject read GetParent;
    property CurrentItem: TsardStackItem read FCurrentItem;
    property Count: Integer read FCount;
  end;

  { TsardCustomEngine }

  TsardCustomEngine = class(TsardObject)
  private
  protected
    procedure Check; virtual;
    procedure Created; override;
  public
    {
      Open mean first char in it, like Numbers must start with number 0..9 but can contain a..z
        or Identifier start a..z or _ but can contain numbers
    }
    function IsWhiteSpace(vChar: AnsiChar; vOpen: Boolean = True): Boolean; virtual; abstract;
    function IsControl(vChar: AnsiChar): Boolean; virtual; abstract;
    function IsOperator(vChar: AnsiChar; vOpen: Boolean = True): Boolean; virtual; abstract;
    function IsNumber(vChar: AnsiChar; vOpen: Boolean = True): Boolean; virtual; abstract;
    function IsIdentifier(vChar: AnsiChar; vOpen: Boolean = True): Boolean; virtual;
  end;

procedure RaiseError(AError: string);
function ScanCompare(S: string; const Text: string; const Index: Integer): Boolean;
function ScanText(S: string; const Text: string; var Index: Integer): Boolean;

implementation

uses
  StrUtils;

procedure RaiseError(AError: string);
begin
  raise EsardException.Create(AError) at
    get_caller_addr(get_frame),
    get_caller_frame(get_frame);
end;

function ScanCompare(S: string; const Text: string; const Index: Integer): Boolean;
begin
  Result := (Length(Text) - Index) >= length(S);
  if Result then
    Result := LowerCase(MidStr(Text, Index, Length(S))) = LowerCase(S); //caseinsensitive
end;

function ScanText(S: string; const Text: string; var Index: Integer): Boolean;
begin
  Result := (Length(Text) - Index) >= length(S);
  if Result then
    Result := LowerCase(MidStr(Text, Index, Length(S))) = LowerCase(S); //caseinsensitive
  if Result then
    Index := Index + Length(S);
end;

{ TsardParser }

procedure TsardParser.Start;
begin
end;

procedure TsardParser.Stop;
begin
end;


{ TsardObjectList }

procedure TsardObjectList.Created;
begin
end;

procedure TsardObjectList.AfterConstruction;
begin
  inherited AfterConstruction;
  Created;
end;

{ TsardObject }

procedure TsardObject.Created;
begin
end;

procedure TsardObject.AfterConstruction;
begin
  inherited AfterConstruction;
  Created;
end;

{ TsardCustomEngine }

procedure TsardCustomEngine.Check;
begin
end;

procedure TsardCustomEngine.Created;
begin
  inherited Created;
  Check;
end;

function TsardCustomEngine.IsIdentifier(vChar: AnsiChar; vOpen: Boolean): Boolean;
begin
  Result := not IsWhiteSpace(vChar) and not IsControl(vChar) and not IsOperator(vChar, vOpen);
  if vOpen then
    Result := Result and not IsNumber(vChar, vOpen);
end;

{ TsardParser }

procedure TsardStack.Pop;
var
  aItem: TsardStackItem;
  aObject: TObject;
begin
  if FCurrentItem = nil then
    raise EsardException.Create('Stack is empty');
  aObject := FCurrentItem.AnObject;
  aItem := FCurrentItem;
  FCurrentItem := aItem.Parent;
  Dec(FCount);
  aItem.Free;
  aObject.Free;
  BeforePop;
end;

function TsardStack.GetParent: TObject;
begin
  if FCurrentItem = nil then
    Result := nil
  else if FCurrentItem.Parent = nil then
    Result := nil
  else
    Result := FCurrentItem.Parent.AnObject;
end;

function TsardStack.GetCurrent: TObject;
begin
{  if FCurrentItem = nil then
    RaiseError('Stack is empty');}
  if FCurrentItem = nil then
    Result := nil
  else
    Result := FCurrentItem.AnObject;
end;

procedure TsardStack.AfterPush;
begin
end;

procedure TsardStack.BeforePop;
begin
end;

function TsardStack.IsEmpty: Boolean;
begin
  Result := FCurrentItem = nil;
end;

function TsardStack.Peek: TObject;
begin
  if FCurrentItem = nil then
    RaiseError('Stack is empty');
  Result := FCurrentItem.AnObject;
end;

function TsardStack.Pull: TObject;
var
  aItem: TsardStackItem;
begin
  if FCurrentItem = nil then
    RaiseError('Stack is empty');
  Result := FCurrentItem.AnObject;
  aItem := FCurrentItem;
  FCurrentItem := aItem.Parent;
  aItem.Free;
  Dec(FCount);
  BeforePop;
end;

procedure TsardStack.Push(vObject: TObject);
var
  aItem: TsardStackItem;
begin
  if vObject = nil then
    RaiseError('Can''t push nil');
  aItem := TsardStackItem.Create;
  aItem.AnObject := vObject;
  aItem.Parent := FCurrentItem;
  aItem.Owner := Self;
  if FCurrentItem = nil then
    aItem.Level := 0
  else
    aItem.Level := FCurrentItem.Level + 1;
  FCurrentItem := aItem;
  Inc(FCount);
  AfterPush;
end;

function FormatColLine(Column, Line: Integer): string;
begin
   Result := #13'Line Number ' + IntToStr(Line) + ', Column ' + IntToStr(Column)
end;

constructor EsardParserException.Create(const Msg: string; const Column, Line: Integer);
begin
  inherited Create(Msg +  #13 +FormatColLine(Column, Line));
  FLine := Line;
  FColumn := Column;
end;

{ TsardScanner }

function TsardScanner.Accept(const Text: string; var Column: Integer): Boolean;
begin
  Result := False;
end;

function TsardScanner.DetectScanner(const Text: string; var Column: Integer): Integer;
begin
  Result := Scanners.DetectScanner(Text, Column);
end;

procedure TsardScanner.SelectScanner(AScannerClass: TsardScannerClass);
begin
  Scanners.SelectScanner(AScannerClass);
end;

constructor TsardScanner.Create(vScanners: TsardScanners);
begin
  inherited Create;
  FScanners := vScanners;
end;

destructor TsardScanner.Destroy;
begin
  inherited Destroy;
end;

{ TsardScanners }

function TsardScanners.GetItem(Index: Integer): TsardScanner;
begin
  Result := inherited Items[Index] as TsardScanner;
end;

procedure TsardScanners.SetParser(AValue: TsardParser);
begin
  if FParser = AValue then
    Exit;
  FParser := AValue;
end;

constructor TsardScanners.Create(vParser: TsardParser);
begin
  inherited Create;
  FParser := vParser;
end;

function TsardScanners.DetectScanner(const Text: string; var Column: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to Count - 1 do
  begin
    if (Items[i].Index <> Result) and Items[i].Accept(Text, Column) then
    begin
      Result := i;
      break;
    end;
  end;
  if Result < 0 then
    RaiseError('Scanner not found:' + Text[Column]);
  SwitchScanner(Result);
end;

function TsardScanners.Find(const ScannerClass: TsardScannerClass): TsardScanner;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to Count - 1 do
  begin
    if ScannerClass = Items[i].ClassType then
    begin
      Result := Items[i];
      break;
    end;
  end;
end;

function TsardScanners.RegisterScanner(ScannerClass: TsardScannerClass): TsardScannerID;
var
  aScanner: TsardScanner;
begin
  aScanner := ScannerClass.Create(Self);
  Result := Add(aScanner);
  aScanner.Index := Result;
end;

procedure TsardFeeder.Stop;
begin
  if not FActive then
    RaiseError('File already closed');
  Scanners.Parser.Stop;
  DoStop;
  FActive := False;
end;


procedure TsardFeeder.Start;
begin
  if FActive then
    RaiseError('File already opened');
  FActive := True;
  DoStart;
  Scanners.Parser.Start;
end;

procedure TsardFeeder.SetScanners(AValue: TsardScanners);
begin
  if FScanners =AValue then Exit;
  if Active then
    RaiseError('You can not set scanner when started!');
  FScanners :=AValue;
end;

procedure TsardFeeder.DoStart;
begin
end;

procedure TsardFeeder.DoStop;
begin
end;

procedure TsardScanners.SwitchScanner(NextScanner: TsardScannerID);
begin
  if FScannerID <> NextScanner then
  begin
    FScannerID := NextScanner;
  end;
end;

procedure TsardScanners.SelectScanner(ScannerClass: TsardScannerClass);
var
  aScanner: TsardScanner;
begin
  aScanner := Find(ScannerClass);
  if aScanner = nil then
    RaiseError('Scanner not found');
  SwitchScanner(aScanner.Index);
end;

constructor TsardFeeder.Create(vScanners: TsardScanners);
begin
  inherited Create;
  FVersion := '1.0';
  {$ifdef FPC}
  FCharset := 'utf-8';
  {$else}
  FCharset := 'iso-8859-1';
  {$endif}

  FScanners := vScanners;
end;

destructor TsardFeeder.Destroy;
begin
  inherited Destroy;
end;

procedure TsardFeeder.ScanLine(const Text: string; const Line: Integer);
begin
  if not Active then
    RaiseError('Feeder not started');
  Scanners.ScanLine(Text, Line);
end;

procedure TsardScanners.ScanLine(const Text: string; const ALine: Integer);
var
  Column, OldColumn: Integer;
  OldScanner: TsardScannerID;
  l: Integer;
begin
  FLine := ALine;
  Column := 1; //start of pascal string is 1
  l := Length(Text);
  while (Column <= l) do
  begin
    OldColumn := Column;
    OldScanner := FScannerID;
    try
      Items[ScannerID].Scan(Text, Column);
      if Column <= Length(Text) then
        DetectScanner(Text, Column);

      if (OldColumn = Column) and (OldScanner = FScannerID) then
        RaiseError('Feeder in loop with: ' + Items[FScannerID].ClassName);
    except
      on E: EsardException do
      begin
        raise EsardParserException.Create(E.Message, Column, Line);
      end;
    end;
  end;
end;

procedure TsardFeeder.Scan(const Lines: TStrings);
var
  i: Integer;
begin
  Start;
  for i := 0 to Lines.Count -1 do
  begin
    ScanLine(Lines[i] + #13, i);
  end;
  Stop;
end;

end.
