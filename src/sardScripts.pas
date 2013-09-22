unit sardScripts;
{**
 *  This file is part of the "SARD"
 *
 * @license   Apache License Version 2.0
 *            included in this distribution
 * @author    Zaher Dirkey <zaher at parmaja dot com>
 *}

{$IFDEF FPC}
{$mode objfpc}
{$ENDIF}
{$H+}{$M+}

(* Example

object: {
  v1:=10+10;
  v2:int=10;
  v3:=v2-v1;
  =proc1(v3);
};

*)

{TODO

  IsWhiteSpace
else
  IsControl
else
  IsSymbol
else
  IsNumber
else
  so it is Identifier

Any Symbol it is an open for operator
}

interface

uses
  Classes, SysUtils,
  sardClasses, sardObjects;

const
  sEOL = [#0, #13, #10];
  sWhitespace = sEOL + [' ', #9];

  sNumberOpenChars = ['0'..'9'];
  sNumberChars = sNumberOpenChars + ['.', 'x', 'h', 'a'..'f'];

  sColorOpenChars = ['#'];
  sColorChars = sColorOpenChars + ['0'..'9', 'a'..'f'];

  sBracketOpoenChars = ['(', '[', '{'];
  sBracketCloseChars = [')', ']', '}'];
  sBracketChars = sBracketOpoenChars + sBracketCloseChars;

  aControlsOpenChars = [':', '~', ',', ';'] + sBracketChars;
  sControlsChars = aControlsOpenChars + ['='];

  sOperatorOpenChars = ['+', '-', '*', '/', '^', '&', '|', '!', '=', '$', '@']; //<--Stupid idea, need to make it as array

  IDENTIFIER_OPEN_CHARS = ['A'..'Z', 'a'..'z', '_'];
  IDENTIFIER_CHARS = IDENTIFIER_OPEN_CHARS + ['0'..'9', '.']; //for : xdebug send tag like xdebug:message

type
  TsardTokenKinds = (tknOperator, tknControl, tknIdentifier, tknString, tknNumber, tknColor, tknComment);

  { TsardScript }

  TsardScript = class(TsardFeeder)
  private
  protected
  public
    constructor Create; override;
  end;

  { TsardScriptParser }

  TsardScriptParser = class(TsardParser)
  protected
  public
    CurrentBlock: TsrdoBlock;
    CurrentOperator: TsrdoOperator;
    constructor Create(ABlock: TsrdoBlock);
    procedure TriggerOpen(vBracket: TsardBracketKind); override;
    procedure TriggerClose(vBracket: TsardBracketKind); override;
    procedure TriggerToken(Token: String; TokenID: Integer); override;
    procedure TriggerControl(AControl: TsardControl); override;
    procedure TriggerOperator(AOperator: TsardObject); override;
  end;

  { TsardStartScanner }

  TsardStart_Scanner = class(TsardScanner)
  protected
    procedure Scan(const Text: string; var Column: Integer; const Line: Integer);  override;
    function Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean; override;
  end;

  { TsardWhitespaceScanner }

  TsardWhitespace_Scanner = class(TsardScanner)
  protected
    procedure Scan(const Text: string; var Column: Integer; const Line: Integer);  override;
    function Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;  override;
  end;

  { TsardIdentifierScanner }

  TsardIdentifier_Scanner = class(TsardScanner)
  protected
    procedure Scan(const Text: string; var Column: Integer; const Line: Integer);  override;
    function Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;  override;
  end;

  { TsardNumberScanner }

  TsardNumber_Scanner = class(TsardScanner)
  protected
    procedure Scan(const Text: string; var Column: Integer; const Line: Integer);  override;
    function Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;  override;
  end;

  { TsardControl_Scanner }

  TsardControl_Scanner = class(TsardScanner)
  protected
    procedure Scan(const Text: string; var Column: Integer; const Line: Integer);  override;
    function Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;  override;
  end;

  { TsardOperatorScanner }

  TsardOperator_Scanner = class(TsardScanner)
  protected
    procedure Scan(const Text: string; var Column: Integer; const Line: Integer);  override;
    function Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;  override;
  end;

  { TsardLineCommentScanner }

  TsardLineComment_Scanner = class(TsardScanner)
  protected
    procedure Scan(const Text: string; var Column: Integer; const Line: Integer);  override;
    function Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean; override;
  end;

  { TsardBlockCommentScanner }

  TsrdoBlockComment_Scanner = class(TsardScanner)
  protected
    procedure Scan(const Text: string; var Column: Integer; const Line: Integer);  override;
    function Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean; override;
  end;

  { TsardSQStringScanner }

  TsardSQString_Scanner = class(TsardScanner)
  protected
    procedure Scan(const Text: string; var Column: Integer; const Line: Integer);  override;
    function Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean; override;
  end;

  { TsardDQStringScanner }

  TsardDQString_Scanner = class(TsardScanner)
  protected
    procedure Scan(const Text: string; var Column: Integer; const Line: Integer);  override;
    function Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean; override;
  end;

implementation

uses
  StrUtils;

{ TsardScriptParser }

constructor TsardScriptParser.Create(ABlock: TsrdoBlock);
begin
  inherited Create;
  CurrentBlock := ABlock;
end;

procedure TsardScriptParser.TriggerOpen(vBracket: TsardBracketKind);
begin
end;

procedure TsardScriptParser.TriggerClose(vBracket: TsardBracketKind);
begin
end;

procedure TsardScriptParser.TriggerToken(Token: String; TokenID: Integer);
begin
  case TsardTokenKinds(TokenID) of
    tknNumber:
    begin
      if pos('.', Token) > 0 then
      begin
        with TsrdoFloat.Create do
        begin
          CurrentBlock.Statement.Add(CurrentOperator, This);
          Value := StrToFloat(Token);
        end;
        CurrentOperator := nil;//<--bad idea, use Stack
      end
      else
      begin
        with TsrdoInteger.Create do
        begin
          CurrentBlock.Statement.Add(CurrentOperator, This);
          Value := StrToInt64(Token);
        end;
        CurrentOperator := nil;
      end;
    end;
    tknString:
    begin
      with TsrdoString.Create do
      begin
        CurrentBlock.Statement.Add(CurrentOperator, This);
        Value := Token;
      end;
      CurrentOperator := nil;
    end;
  end;
end;

procedure TsardScriptParser.TriggerControl(AControl: TsardControl);
begin
end;

procedure TsardScriptParser.TriggerOperator(AOperator: TsardObject);
begin
  if CurrentOperator <> nil then
    raise EsardException.Create('Operator already set');
  CurrentOperator := AOperator as TsrdoOperator;
end;

{ TsardControlScanner }

procedure TsardControl_Scanner.Scan(const Text: string; var Column: Integer; const Line: Integer);
var
  b: AnsiChar;
begin
  b := Text[Column];
  if b = '(' then //TODO need to improve it, my brain is off
    Scanners.Parser.TriggerOpen(brBracket)
  else if b = '[' then
    Scanners.Parser.TriggerOpen(brSquare)
  else if b = '{' then
    Scanners.Parser.TriggerOpen(brCurly)
  else if b = ')' then
    Scanners.Parser.TriggerClose(brBracket)
  else if b = ']' then
    Scanners.Parser.TriggerClose(brSquare)
  else if b = '}' then
    Scanners.Parser.TriggerClose(brCurly)
  else if b = ';' then
    Scanners.Parser.TriggerControl(ctlFinish)
  else if b = ',' then
    Scanners.Parser.TriggerControl(ctlSplit)
  else if b = ':' then
    Scanners.Parser.TriggerControl(ctlDeclare)
  else if b = '~' then
    Scanners.Parser.TriggerControl(ctlLink);
  Inc(Column);
end;

function TsardControl_Scanner.Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;
begin
  Result := Text[Column] in aControlsOpenChars;
end;

{ TsardScript }

constructor TsardScript.Create;
begin
  inherited Create;

  with Scanners do
  begin
    RegisterScanner(TsardStart_Scanner);
    RegisterScanner(TsardWhitespace_Scanner);
    RegisterScanner(TsrdoBlockComment_Scanner);
    RegisterScanner(TsardLineComment_Scanner);
    RegisterScanner(TsardNumber_Scanner);
    RegisterScanner(TsardSQString_Scanner);
    RegisterScanner(TsardDQString_Scanner);
    RegisterScanner(TsardControl_Scanner);
    RegisterScanner(TsardOperator_Scanner); //Register it after comment because comment take /*
    RegisterScanner(TsardIdentifier_Scanner);//Last one
  end;
  //FOffScanner := scanIdentifier;
end;

{ TsardNumberScanner }

procedure TsardNumber_Scanner.Scan(const Text: string; var Column: Integer; const Line: Integer);
var
  l, c: Integer;
begin
  c := Column;
  l := Length(Text);
  while (Column <= l) and (Text[Column] in sNumberChars) do
    Inc(Column);
  Scanners.Parser.TriggerToken(MidStr(Text, c, Column - c), Ord(tknNumber));
end;

function TsardNumber_Scanner.Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;
begin
  Result := Text[Column] in sNumberOpenChars;//need to improve to accept unicode chars
end;

{ TsardOperatorScanner }

procedure TsardOperator_Scanner.Scan(const Text: string; var Column: Integer; const Line: Integer);
var
  c: Integer;
  s: string;
  o: TsrdoOperator;
begin
  c := Column;
  while (Column <= Length(Text)) and (sardEngine.IsOperator(Text[Column])) do //operator is multi char here
    Inc(Column);
  s := MidStr(Text, c, Column - c);
  //o := StrToOperator(s);TODO
  o := sardEngine.Operators.Find(s);
  if o = nil then
    raise EsardException.Create('Unkown operator: ' + s);
  Scanners.Parser.TriggerOperator(o);
end;

function TsardOperator_Scanner.Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;
begin
  Result := sardEngine.IsOperator(Text[Column]);
end;

{ TsardIdentifierScanner }

procedure TsardIdentifier_Scanner.Scan(const Text: string; var Column: Integer; const Line: Integer);
var
  c: Integer;
begin
  c := Column;
  while (Column <= Length(Text)) and (Text[Column] in IDENTIFIER_CHARS) do
    Inc(Column);
  Scanners.Parser.TriggerToken(MidStr(Text, c, Column - c), Ord(tknIdentifier));
end;

function TsardIdentifier_Scanner.Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;
begin
  Result := Text[Column] in IDENTIFIER_OPEN_CHARS;//need to improve to accept unicode chars
end;

{ TsardDQStringScanner }

procedure TsardDQString_Scanner.Scan(const Text: string; var Column: Integer; const Line: Integer);
var
  c: Integer;
begin
  c := Column;
  while (Column <= Length(Text)) and not (Text[Column] = '"') do //TODO Escape, not now
    Inc(Column);
  Scanners.Parser.TriggerToken(MidStr(Text, c, Column - c), Ord(tknString));
end;

function TsardDQString_Scanner.Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;
begin
  Result := CheckText('"', Text, Column);
end;

{ TsardSQStringScanner }

procedure TsardSQString_Scanner.Scan(const Text: string; var Column: Integer; const Line: Integer);
var
  c: Integer;
begin
  c := Column;
  while (Column <= Length(Text)) and not (Text[Column] = '''') do //TODO Escape, not now
    Inc(Column);
  Scanners.Parser.TriggerToken(MidStr(Text, c, Column - c), Ord(tknString));
end;

function TsardSQString_Scanner.Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;
begin
  Result := CheckText('''', Text, Column);
end;

{ TsardBlockCommentScanner }

procedure TsrdoBlockComment_Scanner.Scan(const Text: string; var Column: Integer; const Line: Integer);
begin
  while (Column <= Length(Text)) do
  begin
    if (CheckText('*/', Text, Column)) then
    begin
      Inc(Column, 2);//2 chars
      break;
    end;
    Inc(Column);
  end;
end;

function TsrdoBlockComment_Scanner.Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;
begin
  Result := CheckText('/*', Text, Column);
end;

{ TsardLineComment_Scanner }

procedure TsardLineComment_Scanner.Scan(const Text: string; var Column: Integer; const Line: Integer);
begin
  while (Column <= Length(Text)) and not (Text[Column] in sEOL) do //TODO ignore quoted strings
    Inc(Column);
  //Scanners.Parser.TriggerToken(MidStr(Text, c, Column - c)); ignore comment
end;

function TsardLineComment_Scanner.Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;
begin
  Result := CheckText('//', Text, Column);
end;

{ TsardWhitespace_Scanner }

procedure TsardWhitespace_Scanner.Scan(const Text: string; var Column: Integer; const Line: Integer);
begin
  while (Column <= Length(Text)) and (Text[Column] in sWhitespace) do
    Inc(Column);
end;

function TsardWhitespace_Scanner.Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;
begin
  Result := Text[Column] in sWhitespace;
end;

{ TsardStart_Scanner }

procedure TsardStart_Scanner.Scan(const Text: string; var Column: Integer; const Line: Integer);
begin
end;

function TsardStart_Scanner.Accept(const Text: string; var Column: Integer; const Line: Integer): Boolean;
begin
  Result := False;//Start not accept the scan, it is only when starting scan
end;

end.
