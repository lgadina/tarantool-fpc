﻿{$I Tarantool.Options.Inc}

(*
   unit Owner: D10.Mofen, qdac.swish
      welcome to report bug: 185511468(qq), 185511468@qq.com
   Web site   : https://github.com/ymofen/msgpack-delphi

  * Delphi 2007 (tested)
  * XE5, XE7 (tested)

   + first release
     2014-08-15 13:05:13

   + add array support
     2014-08-19 12:18:47

   + add andriod support
     2014-09-08 00:45:27
	
   * fixed int32, int64 parse bug< integer, int64 parse zero>
     2014-11-09 22:35:27

   + add EncodeToFile/DecodeFromFile
     2014-11-13 12:30:58

   * fix  asVariant = null (thanks for cyw(26890954))
     2014-11-14 09:05:52

   * fix AsInteger = -1 bug (thanks for cyw(26890954))
     2014-11-14 12:15:52

   * fix AsInteger = -127 bug
     check int64/integer/cardinal/word/shortint/smallint/byte assign, encode,decode, read
     2014-11-14 12:30:38

   * fix AsFloat = 2.507182 bug
     thanks fo [珠海]-芒果  1939331207
     2014-11-21 12:37:04

   * add AddArrayChild func
     2015-03-25 17:47:28


   samples:
     lvMsgPack:=TSimpleMsgPack.Create;
     lvMsgPack.S['root.child01'] := 'abc';

     //save to stream
     lvMsgPack.EncodeToStream(pvStream);


Copyright (c) 2014, ymofen, swish
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

     

*)
unit Tarantool.SimpleMsgPack;

interface

uses
  classes, SysUtils
  {$IFDEF UNICODE}, Generics.Collections{$ELSE}, Contnrs{$ENDIF}
  {$IFDEF MSWINDOWS}, Windows{$ENDIF}
  ,Variants;

type
  {$IFNDEF FPC}
  {$IF RTLVersion<25}
    IntPtr=Integer;
  {$IFEND IntPtr}
  {$ENDIF}

  {$IFNDEF FPC}
   {$if CompilerVersion < 18} //before delphi 2007
     TBytes = array of Byte;
   {$ifend}
  {$ENDIF}

  TMsgPackType = (mptUnknown, mptNull, mptMap, mptArray, mptString, mptInteger,
  mptBoolean, mptFloat, mptSingle, mptDateTime, mptBinary);

  // reserved
  IMsgPack = interface
    ['{37D3E479-7A46-435A-914D-08FBDA75B50E}'] 
  end;

  // copy from qmsgPack
  TMsgPackValue= packed record
    ValueType:Byte;
    case Integer of
      0:(U8Val:Byte);
      1:(I8Val:Shortint);
      2:(U16Val:Word);
      3:(I16Val:Smallint);
      4:(U32Val:Cardinal);
      5:(I32Val:Integer);
      6:(U64Val:UInt64);
      7:(I64Val:Int64);
      //8:(F32Val:Single);
      //9:(F64Val:Double);
      10:(BArray:array[0..16] of Byte);
  end;

  TMsgPackSetting = class(TObject)
  private
    FCaseSensitive: Boolean;
  public
    property CaseSensitive: Boolean read FCaseSensitive write FCaseSensitive;
  end;



  { TSimpleMsgPack }

  TSimpleMsgPack = class(TObject)
  private
    FParent:TSimpleMsgPack;
    //FLowerName:String;
    //FName:String;
    FValue:TBytes;
    FKeyName: TBytes;
    FDataType:TMsgPackType;
    FKeyType: TMsgPackType;
  {$IFDEF UNICODE}
    FChildren: TObjectList<TSimpleMsgPack>;
  {$ELSE}
    FChildren: TObjectList;
  {$ENDIF}

    procedure InnerAddToChildren(pvDataType: TMsgPackType; obj: TSimpleMsgPack);
    function InnerAdd(pvDataType: TMsgPackType): TSimpleMsgPack; overload;
    function InnerAdd():TSimpleMsgPack; overload;
    function GetCount: Integer;
    procedure InnerEncodeToStream(pvStream:TStream);
    procedure InnerParseFromStream(pvStream: TStream);

    procedure setName(pvName:string); overload;
    procedure setName(pvName: Int64); overload;
    procedure setName(pvName: Boolean); overload;
    procedure setName(pvName: Double); overload;
    procedure setName(pvName: Single); overload;
  private
    function getAsString: String;
    procedure setAsString(pvValue:string);

    function getAsInteger: Int64;
    procedure setAsInteger(pvValue:Int64);
    function GetAsBoolean: Boolean;
    procedure SetAsBoolean(const Value: Boolean);

    procedure SetAsFloat(const Value: Double);
    function GetAsFloat: Double;

    procedure SetAsDateTime(const Value: TDateTime);
    function GetAsDateTime: TDateTime;

    function GetAsVariant: Variant;
    procedure SetAsVariant(const Value: Variant);

    procedure SetAsSingle(const Value: Single);
    function GetAsSingle: Single;

    procedure SetAsBytes(const Value: TBytes);
    function GetAsBytes: TBytes;
    
    procedure checkObjectDataType(ANewType: TMsgPackType);

    function findObj(pvName:string): TSimpleMsgPack;
    function indexOf(pvName:string): Integer;
    function indexOfCaseSensitive(pvName:string): Integer;
    function indexOfIgnoreSensitive(pvLowerCaseName: string): Integer;


  private
    function GetII(pvPath: Integer): Int64;
    function GetKeyAsBoolean: Boolean;
    function GetKeyAsFloat: Double;
    function GetKeyAsInt64: Int64;
    function GetKeyAsInteger: Integer;
    function GetKeyAsSingle: Single;
    function GetKeyAsString: String;
    function GetName: String;
    function GetOO(pvPath: Integer): TSimpleMsgPack;
    function GetSS(pvPath: Integer): string;


    /// <summary>
    ///   find object index by a path 
    /// </summary>
    function InnerFindPathObject(pvPath: string; var vParent: TSimpleMsgPack; var
        vIndex: Integer): TSimpleMsgPack;

    function GetO(pvPath: String): TSimpleMsgPack;
    procedure SetII(pvPath: Integer; AValue: Int64);
    procedure SetKeyAsBoolean(AValue: Boolean);
    procedure SetKeyAsFloat(AValue: Double);
    procedure SetKeyAsInt64(AValue: Int64);
    procedure SetKeyAsInteger(AValue: Integer);
    procedure SetKeyAsSingle(AValue: Single);
    procedure SetKeyAsString(AValue: String);
    procedure SetO(pvPath: String; const Value: TSimpleMsgPack);

    function GetS(pvPath: String): string;
    procedure SetOO(pvPath: Integer; AValue: TSimpleMsgPack);
    procedure SetS(pvPath: String; const Value: string);

    function GetI(pvPath: String): Int64;
    procedure SetI(pvPath: String; const Value: Int64);

    function GetB(pvPath: String): Boolean;
    procedure SetB(pvPath: String; const Value: Boolean);
    
    function GetD(pvPath: String): Double;
    procedure SetD(pvPath: String; const Value: Double);

    function GetItems(AIndex: Integer): TSimpleMsgPack;
    procedure SetSS(pvPath: Integer; AValue: string);
    function GetBB(pvPath: Integer): Boolean;
    procedure SetBB(pvPath: Integer; const Value: Boolean);
    function GetDD(pvPath: Integer): Double;
    procedure SetDD(pvPath: Integer; const Value: Double);


  public
    constructor Create; overload;
    constructor Create(AType: TMsgPackType); overload;


    destructor Destroy; override;

    procedure clear;

    property Count: Integer read GetCount;

    procedure LoadBinaryFromStream(pvStream: TStream; pvLen: cardinal = 0);
    procedure SaveBinaryToStream(pvStream:TStream);

    procedure LoadBinaryFromFile(pvFileName:String);
    procedure SaveBinaryToFile(pvFileName:String);

    procedure EncodeToStream(pvStream:TStream);
    procedure EncodeToFile(pvFileName:string);


    procedure DecodeFromStream(pvStream:TStream);
    procedure DecodeFromFile(pvFileName:string);

    function EncodeToBytes: TBytes;
    procedure DecodeFromBytes(pvBytes:TBytes);
    //function EncodeToString(AIndent: Boolean): String;

    function Add(pvNameKey, pvValue: string): TSimpleMsgPack; overload;
    function Add(pvNameKey: string; pvValue: Int64): TSimpleMsgPack; overload;
    function Add(pvNameKey: string; pvValue: TBytes): TSimpleMsgPack; overload;
    function Add(pvNameKey: String): TSimpleMsgPack; overload;

    function Add(pvNameKey: Integer): TSimpleMsgPack; overload;

    function Add():TSimpleMsgPack; overload;

    procedure Add(ANode: TSimpleMsgPack); overload;

    function Add(AName: String; AType: TMsgPackType): TSimpleMsgPack; overload;
    function Add(AName: Integer; AType: TMsgPackType): TSimpleMsgPack; overload;
    function Add(AType: TMsgPackType): TSimpleMsgPack; overload;

    function AddArrayChild():TSimpleMsgPack;

    function ForcePathObject(pvPath:string): TSimpleMsgPack;

    /// <summary>
    ///  remove and free object
    ///    false : object is not found!
    /// </summary>
    function DeleteObject(pvPath:String):Boolean;

    property AsInteger:Int64 read getAsInteger write setAsInteger;
    property AsString:string read getAsString write setAsString;
    property AsBoolean: Boolean read GetAsBoolean write SetAsBoolean;
    property AsFloat: Double read GetAsFloat write SetAsFloat;
    property AsSingle: Single read GetAsSingle write SetAsSingle;
    property AsDateTime: TDateTime read GetAsDateTime write SetAsDateTime;
    property AsVariant: Variant read GetAsVariant write SetAsVariant;

    property AsBytes: TBytes read GetAsBytes write SetAsBytes;

    property O[pvPath: String]: TSimpleMsgPack read GetO write SetO;
    property OO[pvPath: Integer]: TSimpleMsgPack read GetOO write SetOO;
    property S[pvPath: String]: string read GetS write SetS;
    property SS[pvPath: Integer]: string read GetSS write SetSS;
    property I[pvPath: String]: Int64 read GetI write SetI;
    property II[pvPath: Integer]: Int64 read GetII write SetII;
    property B[pvPath: String]: Boolean read GetB write SetB;
    property BB[pvPath: Integer]: Boolean read GetBB write SetBB;
    property D[pvPath: String]: Double read GetD write SetD;
    property DD[pvPath: Integer]: Double read GetDD write SetDD;

    property Items[AIndex: Integer]: TSimpleMsgPack read GetItems; default;
    property Name: String read GetName;
    property DataType: TMsgPackType read FDataType;
    property KeyType: TMsgPackType read FKeyType;
    property KeyAsInt64: Int64 read GetKeyAsInt64 write SetKeyAsInt64;
    property KeyAsInteger: Integer read GetKeyAsInteger write SetKeyAsInteger;
    property KeyAsSingle: Single read GetKeyAsSingle write SetKeyAsSingle;
    property KeyAsFloat: Double read GetKeyAsFloat write SetKeyAsFloat;
    property KeyAsString: String read GetKeyAsString write SetKeyAsString;
    property KeyAsBoolean: Boolean read GetKeyAsBoolean write SetKeyAsBoolean;
  end;

{$IFDEF  DUMP_MSG_PACK}
procedure DumpObjMsgPack(AObj: TSimpleMsgPack; Ident: Word; ParentName: String);
{$ENDIF}

function MPO(const AValue: Int64): TSimpleMsgPack; overload;
function MPO(const AValue: RawByteString): TSimpleMsgPack; overload;
function MPO(const AValue: Double): TSimpleMsgPack; overload;
function MPO(const AValue: Single): TSimpleMsgPack; overload;
function MPO(const AValue: Boolean): TSimpleMsgPack; overload;
function MPO(const AValue: Variant): TSimpleMsgPack; overload;

implementation

uses strutils
//, superobject
;

resourcestring
  SVariantConvertNotSupport = 'type to convert not support!。';
  SCannotAddChild = 'Can''t add child in this node!';


function swap16(const v): Word;
begin
  // FF, EE : EE->1, FF->2
  PByte(@result)^ := PByte(IntPtr(@v) + 1)^;
  PByte(IntPtr(@result) + 1)^ := PByte(@v)^;
end;

function swap32(const v): Cardinal;
begin
  // FF, EE, DD, CC : CC->1, DD->2, EE->3, FF->4
  PByte(@result)^ := PByte(IntPtr(@v) + 3)^;
  PByte(IntPtr(@result) + 1)^ := PByte(IntPtr(@v) + 2)^;
  PByte(IntPtr(@result) + 2)^ := PByte(IntPtr(@v) + 1)^;
  PByte(IntPtr(@result) + 3)^ := PByte(@v)^;
end;

function swap64(const v): Int64;
begin
  // FF, EE, DD, CC, BB, AA, 99, 88 : 88->1 ,99->2 ....
  PByte(@result)^ := PByte(IntPtr(@v) + 7)^;
  PByte(IntPtr(@result) + 1)^ := PByte(IntPtr(@v) + 6)^;
  PByte(IntPtr(@result) + 2)^ := PByte(IntPtr(@v) + 5)^;
  PByte(IntPtr(@result) + 3)^ := PByte(IntPtr(@v) + 4)^;
  PByte(IntPtr(@result) + 4)^ := PByte(IntPtr(@v) + 3)^;
  PByte(IntPtr(@result) + 5)^ := PByte(IntPtr(@v) + 2)^;
  PByte(IntPtr(@result) + 6)^ := PByte(IntPtr(@v) + 1)^;
  PByte(IntPtr(@result) + 7)^ := PByte(@v)^;
end;

// v and outVal is can't the same value
procedure swap64Ex(const v; out outVal);
begin
  // FF, EE, DD, CC, BB, AA, 99, 88 : 88->1 ,99->2 ....
  PByte(@outVal)^ := PByte(IntPtr(@v) + 7)^;
  PByte(IntPtr(@outVal) + 1)^ := PByte(IntPtr(@v) + 6)^;
  PByte(IntPtr(@outVal) + 2)^ := PByte(IntPtr(@v) + 5)^;
  PByte(IntPtr(@outVal) + 3)^ := PByte(IntPtr(@v) + 4)^;
  PByte(IntPtr(@outVal) + 4)^ := PByte(IntPtr(@v) + 3)^;
  PByte(IntPtr(@outVal) + 5)^ := PByte(IntPtr(@v) + 2)^;
  PByte(IntPtr(@outVal) + 6)^ := PByte(IntPtr(@v) + 1)^;
  PByte(IntPtr(@outVal) + 7)^ := PByte(@v)^;
end;

// v and outVal is can't the same value
procedure swap32Ex(const v; out outVal);
begin
  // FF, EE, DD, CC : CC->1, DD->2, EE->3, FF->4
  PByte(@outVal)^ := PByte(IntPtr(@v) + 3)^;
  PByte(IntPtr(@outVal) + 1)^ := PByte(IntPtr(@v) + 2)^;
  PByte(IntPtr(@outVal) + 2)^ := PByte(IntPtr(@v) + 1)^;
  PByte(IntPtr(@outVal) + 3)^ := PByte(@v)^;
end;

// v and outVal is can't the same value
procedure swap16Ex(const v; out outVal);
begin
  // FF, EE : EE->1, FF->2
  PByte(@outVal)^ := PByte(IntPtr(@v) + 1)^;
  PByte(IntPtr(@outVal) + 1)^ := PByte(@v)^;
end;

// overload swap, result type is integer, because single maybe NaN
function swap(v:Single): Integer; overload;
begin
  swap32Ex(v, Result);
end;

// overload swap
function swap(v:word): Word; overload;
begin
  swap16Ex(v, Result);
end;

// overload swap
function swap(v:Cardinal):Cardinal; overload;
begin
  swap32Ex(v, Result);
end;

// swap , result type is Int64, because Double maybe NaN
function swap(v:Double): Int64; overload;
begin
  swap64Ex(v, Result);
end;


// copy from qstring
function BinToHex(p: Pointer; l: Integer; ALowerCase: Boolean): string;
const
  B2HConvert: array [0 .. 15] of Char = ('0', '1', '2', '3', '4', '5', '6',
    '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F');
  B2HConvertL: array [0 .. 15] of Char = ('0', '1', '2', '3', '4', '5', '6',
    '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f');
var
  pd: PChar;
  pb: PByte;
begin
  if SizeOf(Char) = 2 then
  begin
    SetLength(Result, l shl 1);
  end else
  begin
    SetLength(Result, l);
  end;
  pd := PChar(Result);
  pb := p;
  if ALowerCase then
  begin
    while l > 0 do
    begin
      pd^ := B2HConvertL[pb^ shr 4];
      Inc(pd);
      pd^ := B2HConvertL[pb^ and $0F];
      Inc(pd);
      Inc(pb);
      Dec(l);
    end;
  end
  else
  begin
    while l > 0 do
    begin
      pd^ := B2HConvert[pb^ shr 4];
      Inc(pd);
      pd^ := B2HConvert[pb^ and $0F];
      Inc(pd);
      Inc(pb);
      Dec(l);
    end;
  end;
end;



function getFirst(var strPtr: PChar; splitChars: TSysCharSet): string;
var
  oPtr:PChar;
  l:Cardinal;
begin
  oPtr := strPtr;
  Result := '';
  while True do
  begin
    if (strPtr^ in splitChars) then
    begin
      l := strPtr - oPtr;
      if l > 0 then
      begin
      {$IFDEF UNICODE}
        SetLength(Result, l);
        Move(oPtr^, PChar(Result)^, l shl 1);
      {$ELSE}
        SetLength(Result, l);
        Move(oPtr^, PChar(Result)^, l);
      {$ENDIF}
        break;
      end;
    end else if (strPtr^ = #0) then
    begin
      l := strPtr - oPtr;
      if l > 0 then
      begin
      {$IFDEF UNICODE}
        SetLength(Result, l);
        Move(oPtr^, PChar(Result)^, l shl 1);
      {$ELSE}
        SetLength(Result, l);
        Move(oPtr^, PChar(Result)^, l);
      {$ENDIF}
      end;
      break;
    end;
    Inc(strPtr);
  end;
end;


function Utf8DecodeEx(pvValue:{$IFDEF UNICODE}TBytes{$ELSE}AnsiString{$ENDIF}; len:Cardinal):string;
{$IFDEF UNICODE}
var             
  lvBytes:TBytes;
{$ENDIF}
begin
{$IFDEF UNICODE}
  lvBytes := TEncoding.Convert(TEncoding.UTF8, TEncoding.Unicode, pvValue);
  SetLength(Result, Length(lvBytes) shr 1);
  Move(lvBytes[0], PChar(Result)^, Length(lvBytes));
{$ELSE}
  result:= UTF8Decode(pvValue);
{$ENDIF}
end;

function Utf8EncodeEx(pvValue:string):{$IFDEF UNICODE}TBytes{$ELSE}AnsiString{$ENDIF};
{$IFDEF UNICODE}
var
  lvBytes:TBytes;
  len:Cardinal;
{$ENDIF}
begin
{$IFDEF UNICODE}
  len := length(pvValue) shl 1;
  SetLength(lvBytes, len);
  Move(PChar(pvValue)^, lvBytes[0], len);
  Result := TEncoding.Convert(TEncoding.Unicode, TEncoding.UTF8, lvBytes);
{$ELSE}
  result:= UTF8Encode(pvValue);
{$ENDIF}
end;


// copy from qmsgPack
procedure writeString(pvValue: string; pvStream: TStream);
var

  lvRawData:{$IFDEF UNICODE}TBytes{$ELSE}AnsiString{$ENDIF};
  l:Integer;
  lvValue:TMsgPackValue;
begin
  lvRawData := Utf8EncodeEx(pvValue);
  l:=Length(lvRawData);

  //
  //fixstr stores a byte array whose length is upto 31 bytes:
  //+--------+========+
  //|101XXXXX|  data  |
  //+--------+========+
  //
  //str 8 stores a byte array whose length is upto (2^8)-1 bytes:
  //+--------+--------+========+
  //|  0xd9  |YYYYYYYY|  data  |
  //+--------+--------+========+
  //
  //str 16 stores a byte array whose length is upto (2^16)-1 bytes:
  //+--------+--------+--------+========+
  //|  0xda  |ZZZZZZZZ|ZZZZZZZZ|  data  |
  //+--------+--------+--------+========+
  //
  //str 32 stores a byte array whose length is upto (2^32)-1 bytes:
  //+--------+--------+--------+--------+--------+========+
  //|  0xdb  |AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|  data  |
  //+--------+--------+--------+--------+--------+========+
  //
  //where
  //* XXXXX is a 5-bit unsigned integer which represents N
  //* YYYYYYYY is a 8-bit unsigned integer which represents N
  //* ZZZZZZZZ_ZZZZZZZZ is a 16-bit big-endian unsigned integer which represents N
  //* AAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA is a 32-bit big-endian unsigned integer which represents N
  //* N is the length of data

  if L<=31 then
  begin
    lvValue.ValueType:=$A0+Byte(L);
    pvStream.WriteBuffer(lvValue.ValueType,1);
  end
  else if L<=255 then
  begin
    lvValue.ValueType:=$d9;
    lvValue.U8Val:=Byte(L);
    pvStream.WriteBuffer(lvValue,2);
  end
  else if L<=65535 then
  begin
    lvValue.ValueType:=$da;
    lvValue.U16Val:=((L shr 8) and $FF) or ((L shl 8) and $FF00);
    pvStream.Write(lvValue,3);
  end else
  begin
    lvValue.ValueType:=$db;
    lvValue.BArray[0]:=(L shr 24) and $FF;
    lvValue.BArray[1]:=(L shr 16) and $FF;
    lvValue.BArray[2]:=(L shr 8) and $FF;
    lvValue.BArray[3]:=L and $FF;
    pvStream.WriteBuffer(lvValue,5);
  end;

  pvStream.Write(PByte(lvRawData)^, l);
end;

procedure WriteBinary(p: PByte; l: Integer; pvStream: TStream);
var
  lvValue:TMsgPackValue;
begin
  if l <= 255 then
  begin
    lvValue.ValueType := $C4;
    lvValue.U8Val := Byte(l);
    pvStream.WriteBuffer(lvValue, 2);
  end
  else if l <= 65535 then
  begin
    lvValue.ValueType := $C5;
    lvValue.BArray[0] := (l shr 8) and $FF;
    lvValue.BArray[1] := l and $FF;
    pvStream.WriteBuffer(lvValue, 3);
  end
  else
  begin
    lvValue.ValueType := $C6;
    lvValue.BArray[0] := (l shr 24) and $FF;
    lvValue.BArray[1] := (l shr 16) and $FF;
    lvValue.BArray[2] := (l shr 8) and $FF;
    lvValue.BArray[3] := l and $FF;
    pvStream.WriteBuffer(lvValue, 5);
  end;
  pvStream.WriteBuffer(p^, l);
end;

// copy from qmsgPack
procedure WriteInt(const iVal: Int64; AStream: TStream);
var
  lvValue:TMsgPackValue;
begin
  if iVal>=0 then
    begin
    if iVal<=127 then
      begin
      lvValue.U8Val:=Byte(iVal);
      AStream.WriteBuffer(lvValue.U8Val,1);
      end
    else if iVal<=255 then//UInt8
      begin
      lvValue.ValueType:=$cc;
      lvValue.U8Val:=Byte(iVal);
      AStream.WriteBuffer(lvValue,2);
      end
    else if iVal<=65535 then
      begin
      lvValue.ValueType:=$cd;
      lvValue.BArray[0]:=(iVal shr 8);
      lvValue.BArray[1]:=(iVal and $FF);
      AStream.WriteBuffer(lvValue,3);
      end
    else if iVal<=Cardinal($FFFFFFFF) then
      begin
      lvValue.ValueType:=$ce;
      lvValue.BArray[0]:=(iVal shr 24) and $FF;
      lvValue.BArray[1]:=(iVal shr 16) and $FF;
      lvValue.BArray[2]:=(iVal shr 8) and $FF;
      lvValue.BArray[3]:=iVal and $FF;
      AStream.WriteBuffer(lvValue,5);
      end
    else
      begin
      lvValue.ValueType:=$cf;
      lvValue.BArray[0]:=(iVal shr 56) and $FF;
      lvValue.BArray[1]:=(iVal shr 48) and $FF;
      lvValue.BArray[2]:=(iVal shr 40) and $FF;
      lvValue.BArray[3]:=(iVal shr 32) and $FF;
      lvValue.BArray[4]:=(iVal shr 24) and $FF;
      lvValue.BArray[5]:=(iVal shr 16) and $FF;
      lvValue.BArray[6]:=(iVal shr 8) and $FF;
      lvValue.BArray[7]:=iVal and $FF;
      AStream.WriteBuffer(lvValue,9);
      end;
    end
  else//<0
    begin
    if iVal<=Low(Integer) then  //-2147483648  // 64 bit
    begin
      lvValue.ValueType:=$d3;
      lvValue.BArray[0]:=(iVal shr 56) and $FF;
      lvValue.BArray[1]:=(iVal shr 48) and $FF;
      lvValue.BArray[2]:=(iVal shr 40) and $FF;
      lvValue.BArray[3]:=(iVal shr 32) and $FF;
      lvValue.BArray[4]:=(iVal shr 24) and $FF;
      lvValue.BArray[5]:=(iVal shr 16) and $FF;
      lvValue.BArray[6]:=(iVal shr 8) and $FF;
      lvValue.BArray[7]:=iVal and $FF;
      AStream.WriteBuffer(lvValue,9);
    end
    else if iVal<=Low(SmallInt) then     // -32768    // 32 bit
      begin
      lvValue.ValueType:=$d2;
      lvValue.BArray[0]:=(iVal shr 24) and $FF;
      lvValue.BArray[1]:=(iVal shr 16) and $FF;
      lvValue.BArray[2]:=(iVal shr 8) and $FF;
      lvValue.BArray[3]:=iVal and $FF;
      AStream.WriteBuffer(lvValue,5);
      end
    else if iVal<=-128 then
      begin
      lvValue.ValueType:=$d1;
      lvValue.BArray[0]:=(iVal shr 8);
      lvValue.BArray[1]:=(iVal and $FF);
      AStream.WriteBuffer(lvValue,3);
      end
    else if iVal<-32 then
      begin
      lvValue.ValueType:=$d0;
      lvValue.I8Val:=iVal;
      AStream.WriteBuffer(lvValue,2);
      end
    else
      begin
      lvValue.I8Val:=iVal;
      AStream.Write(lvValue.I8Val,1);
      end;
    end;//End <0
end;

procedure WriteFloat(pvVal: Double; AStream: TStream);
var
  lvValue:TMsgPackValue;
begin 
  lvValue.i64Val := swap(pvVal);
  lvValue.ValueType := $CB;
  AStream.WriteBuffer(lvValue, 9);
end;

procedure WriteSingle(pvVal: Single; AStream: TStream);
var
  lvValue:TMsgPackValue;
begin
  lvValue.I32Val := swap(pvVal);
  lvValue.ValueType := $CA;
  AStream.WriteBuffer(lvValue, 5);
end;

procedure WriteNull(pvStream:TStream);
var
  lvByte:Byte;
begin
  lvByte := $C0;
  pvStream.Write(lvByte, 1);
end;

procedure WriteBoolean(pvValue:Boolean; pvStream:TStream);
var
  lvByte:Byte;
begin
  if pvValue then lvByte := $C3 else lvByte := $C2;
  pvStream.Write(lvByte, 1);
end;


/// <summary>
///  copy from qmsgpack
/// </summary>
procedure writeArray(obj:TSimpleMsgPack; pvStream:TStream);
var
  c, i:Integer;
  lvValue:TMsgPackValue;
  lvNode:TSimpleMsgPack;
begin
  C:=obj.Count;

  if C <= 15 then
  begin
    lvValue.ValueType := $90 + C;
    pvStream.WriteBuffer(lvValue.ValueType, 1);
  end
  else if C <= 65535 then
  begin
    lvValue.ValueType := $DC;
    lvValue.BArray[0] := (C shr 8) and $FF;
    lvValue.BArray[1] := C and $FF;
    pvStream.WriteBuffer(lvValue, 3);
  end
  else
  begin
    lvValue.ValueType := $DD;
    lvValue.BArray[0] := (C shr 24) and $FF;
    lvValue.BArray[1] := (C shr 16) and $FF;
    lvValue.BArray[2] := (C shr 8) and $FF;
    lvValue.BArray[3] := C and $FF;
    pvStream.WriteBuffer(lvValue, 5);
  end;

  for I := 0 to C-1 do
  begin
    lvNode:=TSimpleMsgPack(obj.FChildren[I]);
    lvNode.InnerEncodeToStream(pvStream);
  end;
end;

procedure writeMap(obj:TSimpleMsgPack; pvStream:TStream);
var
  c, i:Integer;
  lvValue:TMsgPackValue;
  lvNode:TSimpleMsgPack;
begin
  C:=obj.Count;
  if C<=15 then
  begin
    lvValue.ValueType:=$80+C;
    pvStream.WriteBuffer(lvValue.ValueType,1);
  end
  else if C<=65535 then
  begin
    lvValue.ValueType:=$de;
    lvValue.BArray[0]:=(C shr 8) and $FF;
    lvValue.BArray[1]:=C and $FF;
    pvStream.WriteBuffer(lvValue,3);
  end
  else
  begin
    lvValue.ValueType:=$df;
    lvValue.BArray[0]:=(C shr 24) and $FF;
    lvValue.BArray[1]:=(C shr 16) and $FF;
    lvValue.BArray[2]:=(C shr 8) and $FF;
    lvValue.BArray[3]:=C and $FF;
    pvStream.WriteBuffer(lvValue,5);
  end;
  for I := 0 to C-1 do
  begin
    lvNode:=TSimpleMsgPack(obj.FChildren[I]);
//    k := StrToIntDef(lvNode.FName, -1);
    case lvNode.KeyType of
      mptString: writeString(lvNode.KeyAsString, pvStream);
      mptInteger: WriteInt(lvNode.KeyAsInt64, pvStream);
      mptSingle: WriteSingle(lvNode.KeyAsSingle, pvStream);
      mptFloat: WriteFloat(lvNode.KeyAsFloat, pvStream);
      mptBoolean: WriteBoolean(lvNode.KeyAsBoolean, pvStream);
    end;

    //if IntToStr(k) = lvNode.FName then
    // WriteInt(k, pvStream)
    //else
    // writeString(lvNode.FName, pvStream);
    lvNode.InnerEncodeToStream(pvStream);
  end;
end;

function EncodeDateTime(pvVal: TDateTime): string;
var
  AValue: TDateTime;
begin
  AValue := pvVal;
  if AValue - Trunc(AValue) = 0 then // Date
    Result := FormatDateTime('yyyy-MM-dd', AValue)
  else
  begin
    if Trunc(AValue) = 0 then
      Result := FormatDateTime('hh:nn:ss.zzz', AValue)
    else
      Result := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', AValue);
  end;
end;


constructor TSimpleMsgPack.Create;
begin
  inherited Create;
  {$IFDEF UNICODE}
    FChildren := TObjectList<TSimpleMsgPack>.Create(true);
  {$ELSE}
    FChildren := TObjectList.Create(true);
  {$ENDIF}
   FKeyType := mptUnknown;
end;

constructor TSimpleMsgPack.Create(AType: TMsgPackType);
begin
  Create;
  FDataType := AType;
end;

procedure TSimpleMsgPack.DecodeFromBytes(pvBytes: TBytes);
var
  lvStream:TStream;
begin
  lvStream := TMemoryStream.Create;
  try
    lvStream.Write(pvBytes[0], Length(pvBytes));
    lvStream.Position := 0;
    DecodeFromStream(lvStream);
  finally
    lvStream.Free;
  end;

end;


{
function TSimpleMsgPack.EncodeToString(AIndent: Boolean): String;
var Obj: ISuperObject;


    function CreateJSONObject(AParent, AItem: TSimpleMsgPack): ISuperObject;
    var
        i: Integer;
        Obj: ISuperObject;
    begin
      if AItem.DataType in [mptArray, mptMap] then
      begin
       if (AParent <> nil) and (AParent.DataType = mptMap) then
       begin
         Result := SO();
         Result.O[AItem.KeyAsString] := TSuperObject.Create(stArray);
         Obj := Result.O[AItem.KeyAsString];
       end else
       begin
         Result := TSuperObject.Create(stArray);
         Obj := Result;
       end;
         for i := 0 to AItem.Count - 1 do
           Obj.AsArray.Add(CreateJSONObject(AItem, AItem[i]));
      end else
      begin
       Result := SO();
       if AItem.DataType = mptInteger then
       begin
         if (AParent <> nil) and (AParent.DataType = mptMap) then
          Result.I[AItem.KeyAsString] := AItem.AsInteger
         else
          Result := SO(AItem.AsInteger);
       end else
       if AItem.DataType = mptString then
       begin
         if (AParent <> nil) and (AParent.DataType = mptMap) then
          Result.S[AItem.KeyAsString] := AItem.AsString
         else
          Result := SO(QuotedStr(AItem.AsString));
       end;
      end;
    end;

begin
  Obj := CreateJSONObject(nil, Self);
  Result := Obj.AsJSon(AIndent);
end;
}

procedure TSimpleMsgPack.DecodeFromFile(pvFileName: string);
var
  lvFileStream:TFileStream;
begin
  if FileExists(pvFileName) then
  begin
    lvFileStream := TFileStream.Create(pvFileName, fmOpenRead);
    try
      DecodeFromStream(lvFileStream);
    finally
      lvFileStream.Free;
    end;
  end;
end;

procedure TSimpleMsgPack.DecodeFromStream(pvStream: TStream);
begin
  InnerParseFromStream(pvStream);
end;

function TSimpleMsgPack.DeleteObject(pvPath: String): Boolean;
var
  lvParent, lvObj:TSimpleMsgPack;
  j:Integer;
begin
  lvObj := InnerFindPathObject(pvPath, lvParent, j);
  Result := lvObj <> nil;
  if Result then
  begin
    lvParent.FChildren.Delete(j);
  end;
end;

destructor TSimpleMsgPack.Destroy;
begin
  FChildren.Clear;
  FChildren.Free;
  FChildren := nil;
  inherited Destroy;
end;

function TSimpleMsgPack.Add(pvNameKey, pvValue: string): TSimpleMsgPack;
begin
  Result := InnerAdd(mptMap);
  Result.KeyAsString := pvNameKey;
  Result.AsString := pvValue;
end;

function TSimpleMsgPack.Add(pvNameKey: string; pvValue: Int64): TSimpleMsgPack;
begin
  Result := InnerAdd(mptMap);
  Result.KeyAsString := pvNameKey;
  Result.AsInteger := pvValue;
end;


function TSimpleMsgPack.Add: TSimpleMsgPack;
begin
  Result := InnerAdd(mptMap);
end;

procedure TSimpleMsgPack.Add(ANode: TSimpleMsgPack);
begin
  InnerAddToChildren(mptArray, ANode);
end;

function TSimpleMsgPack.Add(AName: String; AType: TMsgPackType): TSimpleMsgPack;
begin
  Result := InnerAdd(mptMap);
  Result.FDataType := AType;
  Result.KeyAsString := AName;
end;

function TSimpleMsgPack.Add(AName: Integer;
  AType: TMsgPackType): TSimpleMsgPack;
begin
  Result :=  GetOO(AName);
  if Result <> nil then
  begin
    if Result.DataType = mptUnknown then
     Result.FDataType := AType
    else
    if Result.DataType <> AType then
      raise Exception.Create('Already exists and type mismatch!');
  end else
  begin
   Result := InnerAdd(mptMap);
   Result.FDataType := AType;
   Result.KeyAsInt64 := AName;
  end;
end;

function TSimpleMsgPack.Add(AType: TMsgPackType): TSimpleMsgPack;
begin
  Result := InnerAdd;
  Result.FDataType := AType;
end;

function TSimpleMsgPack.AddArrayChild: TSimpleMsgPack;
begin
  if FDataType <> mptArray then
  begin
    clear();
    FDataType := mptArray;
  end;
  Result := InnerAdd;
end;

function TSimpleMsgPack.Add(pvNameKey: string; pvValue: TBytes): TSimpleMsgPack;
begin
  Result := InnerAdd(mptMap);
  Result.KeyAsString := pvNameKey;
  Result.FDataType := mptBinary;
  Result.FValue := pvValue;
end;

function TSimpleMsgPack.Add(pvNameKey:String): TSimpleMsgPack;
begin
  Result := InnerAdd(mptMap);
  Result.KeyAsString := pvNameKey;
  Result.FKeyType := mptString;
end;

function TSimpleMsgPack.Add(pvNameKey: Integer): TSimpleMsgPack;
begin
  Result := InnerAdd(mptMap);
  Result.KeyAsInt64 := pvNameKey;
end;

procedure TSimpleMsgPack.checkObjectDataType(ANewType: TMsgPackType);
begin
  if (FDataType <> ANewType) then
  begin
    FDataType := ANewType;
  end;
end;

procedure TSimpleMsgPack.clear;
begin
  FChildren.Clear;
  FDataType := mptNull;
  SetLength(FValue, 0);
end;

function TSimpleMsgPack.EncodeToBytes: TBytes;
var
  lvStream:TStream;
begin
  lvStream := TMemoryStream.Create;
  try
    EncodeToStream(lvStream);
    lvStream.Position := 0;
    SetLength(Result, lvStream.size);
    lvStream.Read(Result[0], lvStream.Size);
  finally
    lvStream.Free;
  end;
end;

procedure TSimpleMsgPack.EncodeToFile(pvFileName: string);
var
  lvFileStream:TFileStream;
begin
  if FileExists(pvFileName) then
    lvFileStream := TFileStream.Create(pvFileName, fmOpenWrite)
  else
    lvFileStream := TFileStream.Create(pvFileName, fmCreate);
  try
    lvFileStream.Size := 0;
    EncodeToStream(lvFileStream);
  finally
    lvFileStream.Free;
  end;
end;

procedure TSimpleMsgPack.EncodeToStream(pvStream: TStream);
begin
  InnerEncodeToStream(pvStream);
end;

function TSimpleMsgPack.findObj(pvName:string): TSimpleMsgPack;
var
  w:Integer;
begin
  w := indexOfCaseSensitive(pvName);
  if w <> -1 then
  begin
    Result := TSimpleMsgPack(FChildren[w]);
  end else
  begin
    Result := nil;
  end;
end;

function TSimpleMsgPack.ForcePathObject(pvPath:string): TSimpleMsgPack;
var
  lvName:string;
  ss1:string;
  sPtr:PChar;
  lvTempObj, lvParent:TSimpleMsgPack;
  j:Integer;
begin
  Result := nil;
  ss1 := pvPath;

  lvParent := Self;
  sPtr := PChar(ss1);
  while sPtr^ <> #0 do
  begin
    lvName := getFirst(sPtr, ['.', '/','\']);
    if lvName = '' then
    begin
      Break;
    end else
    begin
      if sPtr^ = #0 then
      begin           // end
        j := lvParent.indexOf(lvName);
        if j <> -1 then
        begin
          Result := TSimpleMsgPack(lvParent.FChildren[j]);
        end else
        begin
          Result := lvParent.Add(lvName);
        end;
      end else
      begin
        // find childrean
        lvTempObj := lvParent.findObj(lvName);
        if lvTempObj = nil then
        begin
          lvParent := lvParent.Add(lvName);
        end else
        begin
          lvParent := lvTempObj;
        end;
      end;
    end;
    if sPtr^ = #0 then Break;
    Inc(sPtr);
  end;
end;

function TSimpleMsgPack.GetAsBoolean: Boolean;
begin
  if FDataType = mptBoolean then
    Result := PBoolean(FValue)^
  else if FDataType = mptString then
    Result := StrToBoolDef(AsString, False)
  else if FDataType = mptInteger then
    Result := (AsInteger <> 0)
  else if FDataType in [mptNull, mptUnknown] then
    Result := False
  else
    Result := False;

end;

function TSimpleMsgPack.GetAsBytes: TBytes;
begin
  Result := FValue;
end;

function TSimpleMsgPack.GetAsDateTime: TDateTime;
begin
  if FDataType in [mptDateTime, mptFloat] then
    Result := PDouble(FValue)^
  else if FDataType = mptSingle then
    Result := PSingle(FValue)^
  else if FDataType = mptString then
  begin
    Result := StrToDateTimeDef(GetAsString, 0);
  end
  else if FDataType in [mptInteger] then
    Result := AsInteger
  else
    Result := 0;
end;

function TSimpleMsgPack.GetAsFloat: Double;
begin
  if FDataType in [mptFloat, mptDateTime] then
    Result := PDouble(FValue)^
  else if FDataType = mptSingle then
    Result := PSingle(FValue)^
  else if FDataType = mptBoolean then
    Result := Integer(AsBoolean)
  else if FDataType = mptString then
    Result := StrToFloatDef(AsString, 0)
  else if FDataType = mptInteger then
    Result := AsInteger
  else
    Result := 0;
end;

function TSimpleMsgPack.getAsInteger: Int64;
begin
  case FDataType of
    mptInteger: Result:=PInt64(FValue)^;
  else
    Result := 0;
  end;
end;

function TSimpleMsgPack.GetAsSingle: Single;
begin
  if FDataType in [mptFloat, mptDateTime] then
    Result := PDouble(FValue)^
  else if FDataType = mptSingle then
    Result := PSingle(FValue)^
  else if FDataType = mptBoolean then
    Result := Integer(AsBoolean)
  else if FDataType = mptString then
    Result := StrToFloatDef(AsString, 0)
  else if FDataType = mptInteger then
    Result := AsInteger
  else
    Result := 0;
end;

function TSimpleMsgPack.getAsString: String;
var
  l:Cardinal;
begin
  Result := '';
  if FDataType = mptString then
  begin
    l := Length(FValue);
    if l = 0 then
    begin
      Result := '';
    end else if SizeOf(Char) = 2 then
    begin
      SetLength(Result, l shr 1);
      Move(FValue[0],PChar(Result)^, l);
    end else
    begin
      SetLength(Result, l);
      Move(FValue[0],PChar(Result)^, l);
    end;
  end else
  begin
    case FDataType of
      mptUnknown, mptNull:
        Result := '';
      mptInteger:
        Result := IntToStr(AsInteger);
      mptBoolean:
        Result := BoolToStr(AsBoolean, True);
      mptFloat:
        Result := FloatToStrF(AsFloat, ffGeneral, 15, 0);
      mptSingle:
        Result := FloatToStrF(AsSingle, ffGeneral, 7, 0);
      mptBinary:
        Result := BinToHex(@FValue[0], Length(FValue), False);
      mptDateTime:
        Result := EncodeDateTime(AsDateTime);
//      mptArray:
//        Result := EncodeArray;
//      mptMap:
//        Result := EncodeMap;
//      mptExtended:
//        Result := EncodeExtended;
    else
       Result := '';
    end;
  end;
  //showMessage(Result);
end;

/// <summary>
///   copy from qdac3
/// </summary>
function TSimpleMsgPack.GetAsVariant: Variant;
var
  w: Integer;
  procedure BytesAsVariant;
  var
    L: Integer;
    p:PByte;
  begin
    L := Length(FValue);
    Result := VarArrayCreate([0, L - 1], varByte);
    p:=VarArrayLock(Result);
    Move(FValue[0],p^,L);
    VarArrayUnlock(Result);
  end;

begin
  case FDataType of
    mptNull:
      Result := null;
    mptString:
      Result := AsString;
    mptInteger:
      Result := AsInteger;
    mptFloat:
      Result := AsFloat;
    mptSingle:
      Result := AsSingle;
    mptDateTime:
      Result := AsDateTime;
    mptBoolean:
      Result := AsBoolean;
    mptArray, mptMap:
      begin
        Result := VarArrayCreate([0, Count - 1], varVariant);
        for w := 0 to Count - 1 do
          Result[w] := TSimpleMsgPack(FChildren[w]).AsVariant;
      end;
    mptBinary:
      BytesAsVariant;
  else
    raise Exception.Create(SVariantConvertNotSupport);
  end;
end;

function TSimpleMsgPack.GetB(pvPath: String): Boolean;
var
  lvObj:TSimpleMsgPack;
begin
  lvObj := GetO(pvPath);
  if lvObj = nil then
  begin
    Result := False;
  end else
  begin
    Result := lvObj.AsBoolean;
  end;
end;

function TSimpleMsgPack.GetBB(pvPath: Integer): Boolean;
begin
  Result := GetB(IntToStr(pvPath));
end;

function TSimpleMsgPack.GetCount: Integer;
begin
  Result := FChildren.Count;
end;

function TSimpleMsgPack.GetD(pvPath: String): Double;
var
  lvObj:TSimpleMsgPack;
begin
  lvObj := GetO(pvPath);
  if lvObj = nil then
  begin
    Result := 0;
  end else
  begin
    Result := lvObj.AsFloat;
  end;
end;

function TSimpleMsgPack.GetDD(pvPath: Integer): Double;
begin
  Result := GetD(IntToStr(pvPath));
end;

function TSimpleMsgPack.GetI(pvPath: String): Int64;
var
  lvObj:TSimpleMsgPack;
begin
  lvObj := GetO(pvPath);
  if lvObj = nil then
  begin
    Result := 0;
  end else
  begin
    Result := lvObj.AsInteger;
  end;
end;

function TSimpleMsgPack.GetItems(AIndex: Integer): TSimpleMsgPack;
begin
  Result := TSimpleMsgPack(FChildren[AIndex]);
end;

procedure TSimpleMsgPack.SetSS(pvPath: Integer; AValue: string);
begin
  Add(pvPath).AsString := AValue;
  //SetS(pvPath.ToString, AValue);
end;

function TSimpleMsgPack.GetO(pvPath: String): TSimpleMsgPack;
var
  lvParent:TSimpleMsgPack;
  j:Integer;
begin
  Result := InnerFindPathObject(pvPath, lvParent, j);
end;

procedure TSimpleMsgPack.SetII(pvPath: Integer; AValue: Int64);
var lvObj: TSimpleMsgPack;
begin
  lvObj := ForcePathObject(IntToStr(pvPath));
  lvObj.AsInteger := AValue;
  lvObj.KeyAsInt64 := pvPath;
end;

procedure TSimpleMsgPack.SetKeyAsBoolean(AValue: Boolean);
begin
  setName(AValue);
end;

procedure TSimpleMsgPack.SetKeyAsFloat(AValue: Double);
begin
  setName(AValue);
end;

procedure TSimpleMsgPack.SetKeyAsInt64(AValue: Int64);
begin
  setName(AValue);
end;

procedure TSimpleMsgPack.SetKeyAsInteger(AValue: Integer);
begin
  setName(AValue);
end;

procedure TSimpleMsgPack.SetKeyAsSingle(AValue: Single);
begin
 setName(AValue);
end;

procedure TSimpleMsgPack.SetKeyAsString(AValue: String);
begin
  setName(AValue);
end;

function TSimpleMsgPack.GetS(pvPath: String): string;
var
  lvObj:TSimpleMsgPack;
begin
  lvObj := GetO(pvPath);
  if lvObj = nil then
  begin
    Result := '';
  end else
  begin
    Result := lvObj.AsString;
  end;
end;

procedure TSimpleMsgPack.SetOO(pvPath: Integer; AValue: TSimpleMsgPack);
begin
  AValue.setName(pvPath);
  InnerAddToChildren(mptMap, AValue);
end;

function TSimpleMsgPack.indexOf(pvName:string): Integer;
begin
  Result := indexOfIgnoreSensitive(LowerCase(pvName));
end;

function TSimpleMsgPack.indexOfCaseSensitive(pvName:string): Integer;
var
  j, l: Integer;
  lvObj:TSimpleMsgPack;
begin
  Result := -1;
  l := Length(pvName);
  if l = 0 then exit;
  for j := 0 to FChildren.Count-1 do
  begin
    lvObj := TSimpleMsgPack(FChildren[j]);
    //if Length(lvObj.FName) = l then
    if Length(lvObj.KeyAsString) = l then
    begin
      //if lvObj.FName = pvName then
      if lvObj.KeyAsString = pvName then
      begin
        Result := j;
        break;
      end;
    end;
  end;
end;

function TSimpleMsgPack.indexOfIgnoreSensitive(pvLowerCaseName: string):
    Integer;
var
  j, l: Integer;
  lvObj:TSimpleMsgPack;
  FLowerName: String;
begin
  Result := -1;
  l := Length(pvLowerCaseName);
  if l = 0 then exit;
  for j := 0 to FChildren.Count-1 do
  begin
    lvObj := TSimpleMsgPack(FChildren[j]);
    FLowerName := LowerCase(lvObj.KeyAsString);
    if Length(FLowerName) = l then
    begin
      if FLowerName = pvLowerCaseName then
      begin
        Result := j;
        break;
      end;
    end;
  end;
end;

function TSimpleMsgPack.GetII(pvPath: Integer): Int64;
begin
  Result := GetI(IntToStr(pvPath));
end;

function TSimpleMsgPack.GetKeyAsBoolean: Boolean;
begin
  case FKeyType of
    mptInteger: Result := KeyAsInt64 <> 0;
    mptBoolean: Result := PBoolean(FKeyName)^;
    mptString: TryStrToBool(KeyAsString, Result);
   else
    Result := False;
  end;
end;

function TSimpleMsgPack.GetKeyAsFloat: Double;
begin
  case FKeyType of
    mptInteger: Result := KeyAsInt64;
    mptFloat, mptDateTime: Result := PDouble(FKeyName)^;
    mptSingle: Result := PSingle(FKeyName)^;
    mptBoolean: Result := Integer(KeyAsBoolean);
    mptString: TryStrToFloat(KeyAsString, Result);
    mptNull, mptUnknown, mptBinary, mptArray: Result := 0;
  end;
end;

function TSimpleMsgPack.GetKeyAsInt64: Int64;
begin
  case FKeyType of
    mptInteger: Result := PInt64(FKeyName)^;
    mptFloat, mptDateTime: Result := Trunc(PDouble(FKeyName)^);
    mptSingle: Result := Trunc(PSingle(FKeyName)^);
    mptBoolean: Result := Integer(KeyAsBoolean);
    mptString: Result := Trunc(KeyAsFloat);
    mptNull, mptUnknown, mptBinary, mptArray: Result := 0;
  end;
end;

function TSimpleMsgPack.GetKeyAsInteger: Integer;
begin
  Result := KeyAsInt64;
end;

function TSimpleMsgPack.GetKeyAsSingle: Single;
begin
  case FKeyType of
    mptInteger: Result := KeyAsInt64;
    mptFloat, mptDateTime: Result := PDouble(FKeyName)^;
    mptSingle: Result := PSingle(FKeyName)^;
    mptBoolean: Result := Integer(KeyAsBoolean);
    mptString: TryStrToFloat(KeyAsString, Result);
    mptNull, mptUnknown, mptBinary, mptArray: Result := 0;
  end;
end;

function TSimpleMsgPack.GetKeyAsString: String;
begin
  case FKeyType of
    mptString: Result := StringOf(FKeyName);
    mptInteger: Result := IntToStr(KeyAsInt64);
    mptBoolean: Result := BoolToStr(KeyAsBoolean);
    mptSingle: Result := FloatToStr(KeyAsSingle);
    mptFloat: Result := FloatToStr(KeyAsFloat);
  end;
end;

function TSimpleMsgPack.GetName: String;
begin
  Result := KeyAsString;
end;

function TSimpleMsgPack.GetOO(pvPath: Integer): TSimpleMsgPack;
begin
  Result := GetO(IntToStr(pvPath));
end;

function TSimpleMsgPack.GetSS(pvPath: Integer): string;
begin
  Result := GetS(IntToStr(pvPath));
end;

function TSimpleMsgPack.InnerAdd(pvDataType: TMsgPackType): TSimpleMsgPack;
begin
  Result := TSimpleMsgPack.Create;
  Result.FDataType := mptUnknown;
  InnerAddToChildren(pvDataType, Result);
end;

function TSimpleMsgPack.InnerAdd: TSimpleMsgPack;
begin
  if self.FDataType in [mptMap, mptArray] then
  begin
    Result := TSimpleMsgPack.Create;
    Result.FDataType := mptUnknown;
    Result.FParent := self;
    FChildren.Add(Result);
  end else
  begin
    raise Exception.Create(SCannotAddChild);
  end;



end;

procedure TSimpleMsgPack.InnerAddToChildren(pvDataType: TMsgPackType; obj:
    TSimpleMsgPack);
begin
  checkObjectDataType(pvDataType);
  obj.FParent := self;
  FChildren.Add(obj);
end;

procedure TSimpleMsgPack.InnerEncodeToStream(pvStream:TStream);
begin
  case FDataType of
    mptUnknown, mptNull: WriteNull(pvStream);
    mptMap: writeMap(Self, pvStream);
    mptArray: writeArray(Self, pvStream);
    mptString: writeString(Self.getAsString, pvStream);
    mptInteger: WriteInt(self.getAsInteger, pvStream);
    mptBoolean: WriteBoolean(self.GetAsBoolean, pvStream);
    mptDateTime, mptFloat: WriteFloat(GetAsFloat, pvStream);
    mptSingle: WriteSingle(GetAsSingle, pvStream);
    mptBinary: WriteBinary(PByte(@FValue[0]), Length(FValue), pvStream);
  end;
end;

function TSimpleMsgPack.InnerFindPathObject(pvPath: string; var vParent:
    TSimpleMsgPack; var vIndex: Integer): TSimpleMsgPack;
var
  lvName:string;
  ss1:string;
  sPtr:PChar;
  lvTempObj, lvParent:TSimpleMsgPack;
  j:Integer;
begin
  ss1 := pvPath;
  
  Result := nil;
  
  lvParent := Self;
  sPtr := PChar(ss1);
  while sPtr^ <> #0 do
  begin
    lvName := getFirst(sPtr, ['.', '/','\']);
    if lvName = '' then
    begin
      Break;
    end else
    begin
      if sPtr^ = #0 then
      begin           // end
        j := lvParent.indexOf(lvName);
        if j <> -1 then
        begin
          Result := TSimpleMsgPack(lvParent.FChildren[j]);
          vIndex := j;
          vParent := lvParent;
        end else
        begin
          Break;
        end;
      end else
      begin
        // find childrean
        lvTempObj := lvParent.findObj(lvName);
        if lvTempObj = nil then
        begin
          Break;
        end else
        begin
          lvParent := lvTempObj;
        end;
      end;
    end;
    if sPtr^ = #0 then Break;
    Inc(sPtr);
  end;
end;

procedure TSimpleMsgPack.InnerParseFromStream(pvStream: TStream);
var
  lvByte:Byte;
  lvBData: array[0..15] of Byte;
  lvSwapData: array[0..7] of Byte;
  lvAnsiStr:{$IFDEF UNICODE}TBytes{$ELSE}AnsiString{$ENDIF};
  l, j:Cardinal;
  i64 :Int64;
  lvObj:TSimpleMsgPack;
begin
  pvStream.Read(lvByte, 1);
  if lvByte in [$00 .. $7F] then   //positive fixint	0xxxxxxx	0x00 - 0x7f
  begin
    //  +--------+
    //  |0XXXXXXX|
    //  +--------+
    setAsInteger(lvByte);
  end else if lvByte in [$80 .. $8F] then //fixmap	1000xxxx	0x80 - 0x8f
  begin
    FDataType := mptMap;
    SetLength(FValue, 0);
    FChildren.Clear;
    l := lvByte - $80;
    if l > 0 then  // check is empty ele
    begin
      for j := 0 to l - 1 do
      begin
        lvObj := InnerAdd(mptMap);

        // map key
        lvObj.InnerParseFromStream(pvStream);
        lvObj.FKeyType := lvObj.DataType;
        case lvObj.DataType of
          mptBoolean:  ;
          mptString: lvObj.KeyAsString :=  lvObj.getAsString;
          mptInteger: lvObj.KeyAsInt64 := lvObj.AsInteger;
        end;

          // value
        lvObj.InnerParseFromStream(pvStream);
      end;
    end;
  end else if lvByte in [$90 .. $9F] then //fixarray	1001xxxx	0x90 - 0x9f
  begin
    FDataType := mptArray;
    SetLength(FValue, 0);
    FChildren.Clear;

    l := lvByte - $90;
    if l > 0 then  // check is empty ele
    begin
      for j := 0 to l - 1 do
      begin
        lvObj := InnerAdd(mptArray);
        // value
        lvObj.InnerParseFromStream(pvStream);
      end;
    end;
  end else if lvByte in [$A0 .. $BF] then //fixstr	101xxxxx	0xa0 - 0xbf
  begin
    l := lvByte - $A0;   // str len
    if l > 0 then
    begin

      SetLength(lvAnsiStr, l);
      pvStream.Read(PByte(lvAnsiStr)^, l);
      setAsString(UTF8DecodeEx(lvAnsiStr, l));

//      SetLength(lvBytes, l + 1);
//      lvBytes[l] := 0;
//      pvStream.Read(lvBytes[0], l);
//      setAsString(UTF8Decode(PAnsiChar(@lvBytes[0])));
    end else
    begin
      setAsString('');
    end;
  end else if lvByte in [$E0 .. $FF] then
  begin
    //  negative fixnum stores 5-bit negative integer
    //  +--------+
    //  |111YYYYY|
    //  +--------+
    setAsInteger(Shortint(lvByte));
  end else
  begin
    case lvByte of
      $C0: // null
        begin
          FDataType := mptNull;
          SetLength(FValue, 0);
        end;
      $C1: // (never used)
        raise Exception.Create('(never used) type $c1');
      $C2: // False
        begin
          SetAsBoolean(False);
        end;
      $C3: // True
        begin
          SetAsBoolean(True);
        end;
      $C4: // 短二进制，最长255字节
        begin
          FDataType := mptBinary;

          l := 0; // fill zero
          pvStream.Read(l, 1);

          SetLength(FValue, l);
          pvStream.Read(FValue[0], l);
        end;
      $C5: // 二进制，16位，最长65535B
        begin
          FDataType := mptBinary;

          l := 0; // fill zero
          pvStream.Read(l, 2);
          l := swap16(l);

          SetLength(FValue, l);
          pvStream.Read(FValue[0], l);
        end;
      $C6: // 二进制，32位，最长2^32-1
        begin
          FDataType := mptBinary;

          l := 0; // fill zero
          pvStream.Read(l, 4);
          l := swap32(l);

          SetLength(FValue, l);
          pvStream.Read(FValue[0], l);
        end;
      $c7,$c8,$c9:      //ext 8	11000111	0xc7, ext 16	11001000	0xc8, ext 32	11001001	0xc9
        begin
          raise Exception.Create('(ext8,ext16,ex32) type $c7,$c8,$c9');
        end;
      $CA: // float 32
        begin
          pvStream.Read(lvBData[0], 4);

          swap32Ex(lvBData[0], lvSwapData[0]);

          AsSingle := PSingle(@lvSwapData[0])^;
        end;
      $cb: // Float 64
        begin

          pvStream.Read(lvBData[0], 8);

          // swap to int64, and lvBData is not valid double value (for IEEE)
          i64 := swap64(lvBData[0]);

          //
          AsFloat := PDouble(@i64)^;

         // AsFloat := swap(PDouble(@lvBData[0])^);
        end;
      $cc: // UInt8
        begin
          //      uint 8 stores a 8-bit unsigned integer
          //      +--------+--------+
          //      |  0xcc  |ZZZZZZZZ|
          //      +--------+--------+
          l := 0;
          pvStream.Read(l, 1);
          setAsInteger(l);
        end;
      $cd:
        begin
          //    uint 16 stores a 16-bit big-endian unsigned integer
          //    +--------+--------+--------+
          //    |  0xcd  |ZZZZZZZZ|ZZZZZZZZ|
          //    +--------+--------+--------+
          l := 0;
          pvStream.Read(l, 2);
          l := swap16(l);
          SetAsInteger(Word(l));
        end;
      $ce:
        begin
          //  uint 32 stores a 32-bit big-endian unsigned integer
          //  +--------+--------+--------+--------+--------+
          //  |  0xce  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ
          //  +--------+--------+--------+--------+--------+
          l := 0;
          pvStream.Read(l, 4);
          l := swap32(l);
          setAsInteger(Cardinal(l));
        end;
      $cf:
        begin
          //  uint 64 stores a 64-bit big-endian unsigned integer
          //  +--------+--------+--------+--------+--------+--------+--------+--------+--------+
          //  |  0xcf  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
          //  +--------+--------+--------+--------+--------+--------+--------+--------+--------+
          i64 := 0;
          pvStream.Read(i64, 8);
          i64 := swap64(i64);
          setAsInteger(i64);
        end;
      $dc: // array 16
        begin
          //      +--------+--------+--------+~~~~~~~~~~~~~~~~~+
          //      |  0xdc  |YYYYYYYY|YYYYYYYY|    N objects    |
          //      +--------+--------+--------+~~~~~~~~~~~~~~~~~+
          FDataType := mptArray;
          SetLength(FValue, 0);
          FChildren.Clear; 

          l := 0; // fill zero
          pvStream.Read(l, 2);

          l := swap16(l);
          if l > 0 then  // check is empty ele
          begin
            for j := 0 to l - 1 do
            begin
              lvObj := InnerAdd(mptArray);
              // value
              lvObj.InnerParseFromStream(pvStream);
            end;
          end;
        end;
      $dd: // Array 32
        begin
        //  +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+
        //  |  0xdd  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|    N objects    |
        //  +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+
          FDataType := mptArray;
          SetLength(FValue, 0);
          FChildren.Clear;


          l := 0; // fill zero
          pvStream.Read(l, 4);

          l := swap32(l);
          if l > 0 then  // check is empty ele
          begin
            for j := 0 to l - 1 do
            begin
              lvObj := InnerAdd(mptArray);
              // value
              lvObj.InnerParseFromStream(pvStream);
            end;
          end;
        end;
      $d9:   //str 8 , 255
        begin
          //  str 8 stores a byte array whose length is upto (2^8)-1 bytes:
          //  +--------+--------+========+
          //  |  0xd9  |YYYYYYYY|  data  |
          //  +--------+--------+========+
          l := 0;
          pvStream.Read(l, 1);
          if l > 0 then  // check is empty ele
          begin
            SetLength(lvAnsiStr, l);
            pvStream.Read(PByte(lvAnsiStr)^, l);
            setAsString(UTF8DecodeEx(lvAnsiStr, l));
          end else
          begin
            setAsString('');
          end;
  //        SetLength(lvBytes, l + 1);
  //        lvBytes[l] := 0;
  //        pvStream.Read(lvBytes[0], l);
  //        setAsString(UTF8Decode(PAnsiChar(@lvBytes[0])));
        end;
      $DE: // Object map 16
        begin
          //    +--------+--------+--------+~~~~~~~~~~~~~~~~~+
          //    |  0xde  |YYYYYYYY|YYYYYYYY|   N*2 objects   |
          //    +--------+--------+--------+~~~~~~~~~~~~~~~~~+
          FDataType := mptMap;
          SetLength(FValue, 0);
          FChildren.Clear;


          l := 0; // fill zero
          pvStream.Read(l, 2);
          l := swap16(l);
          if l > 0 then  // check is empty ele
          begin
            for j := 0 to l - 1 do
            begin
              lvObj := InnerAdd(mptMap);
              // map key
              lvObj.InnerParseFromStream(pvStream);
              lvObj.setName(lvObj.getAsString);

              // value
              lvObj.InnerParseFromStream(pvStream);
            end;
          end;
        end;
      $DF: //Object map 32
        begin
          //    +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+
          //    |  0xdf  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|   N*2 objects   |
          //    +--------+--------+--------+--------+--------+~~~~~~~~~~~~~~~~~+
          FDataType := mptMap;
          SetLength(FValue, 0);
          FChildren.Clear;


          l := 0; // fill zero
          pvStream.Read(l, 4);

          l := swap32(l);
          if l > 0 then  // check is empty ele
          begin
            for j := 0 to l - 1 do
            begin
              lvObj := InnerAdd(mptMap);

              // map key
              lvObj.InnerParseFromStream(pvStream);
              lvObj.setName(lvObj.getAsString);

              // value
              lvObj.InnerParseFromStream(pvStream);
            end;
          end;
        end;
      $da:    // str 16
        begin
          //      str 16 stores a byte array whose length is upto (2^16)-1 bytes:
          //      +--------+--------+--------+========+
          //      |  0xda  |ZZZZZZZZ|ZZZZZZZZ|  data  |
          //      +--------+--------+--------+========+

          l := 0; // fill zero
          pvStream.Read(l, 2);
          l := swap16(l);
          if l > 0 then  // check is empty ele
          begin
            SetLength(lvAnsiStr, l);
            pvStream.Read(PByte(lvAnsiStr)^, l);
            setAsString(UTF8DecodeEx(lvAnsiStr, l));
          end else
          begin
            setAsString('');
          end;

  //        SetLength(lvBytes, l + 1);
  //        lvBytes[l] := 0;
  //        pvStream.Read(lvBytes[0], l);
  //        setAsString(UTF8Decode(PAnsiChar(@lvBytes[0])));
        end;
      $db:    // str 16
        begin
          //  str 32 stores a byte array whose length is upto (2^32)-1 bytes:
          //  +--------+--------+--------+--------+--------+========+
          //  |  0xdb  |AAAAAAAA|AAAAAAAA|AAAAAAAA|AAAAAAAA|  data  |
          //  +--------+--------+--------+--------+--------+========+

          l := 0; // fill zero
          pvStream.Read(l, 4);
          l := swap32(l);
          if l > 0 then  // check is empty ele
          begin
            SetLength(lvAnsiStr, l);
            pvStream.Read(PByte(lvAnsiStr)^, l);
            setAsString(UTF8DecodeEx(lvAnsiStr, l));
          end else
          begin
            setAsString('');
          end;


  //        SetLength(lvBytes, l + 1);
  //        lvBytes[l] := 0;
  //        pvStream.Read(lvBytes[0], l);
  //        setAsString(UTF8Decode(PAnsiChar(@lvBytes[0])));
        end;
      $d0:   //int 8
        begin
          //      int 8 stores a 8-bit signed integer
          //      +--------+--------+
          //      |  0xd0  |ZZZZZZZZ|
          //      +--------+--------+

          l := 0;
          pvStream.Read(l, 1);
          SetAsInteger(ShortInt(l));
        end;
      $d1:
        begin
          //    int 16 stores a 16-bit big-endian signed integer
          //    +--------+--------+--------+
          //    |  0xd1  |ZZZZZZZZ|ZZZZZZZZ|
          //    +--------+--------+--------+

          l := 0;
          pvStream.Read(l, 2);
          l := swap16(l);
          SetAsInteger(SmallInt(l));
        end;

      $d2:
        begin
          //  int 32 stores a 32-bit big-endian signed integer
          //  +--------+--------+--------+--------+--------+
          //  |  0xd2  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
          //  +--------+--------+--------+--------+--------+
          l := 0;
          pvStream.Read(l, 4);
          l := swap32(l);
          setAsInteger(Integer(l));
        end;
      $d3:
      begin
        //  int 64 stores a 64-bit big-endian signed integer
        //  +--------+--------+--------+--------+--------+--------+--------+--------+--------+
        //  |  0xd3  |ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|ZZZZZZZZ|
        //  +--------+--------+--------+--------+--------+--------+--------+--------+--------+
        i64 := 0;
        pvStream.Read(i64, 8);
        i64 := swap64(i64);
        setAsInteger(Int64(i64));
      end;   
    end;
  end;
end;

procedure TSimpleMsgPack.LoadBinaryFromFile(pvFileName:String);
var
  lvFileStream:TFileStream;
begin
  if FileExists(pvFileName) then
  begin
    lvFileStream := TFileStream.Create(pvFileName, fmOpenRead);
    try
      LoadBinaryFromStream(lvFileStream);
    finally
      lvFileStream.Free;
    end;
  end;
end;

procedure TSimpleMsgPack.LoadBinaryFromStream(pvStream: TStream; pvLen:
    cardinal = 0);
begin
  FDataType := mptBinary;
  if pvLen = 0 then
  begin
    pvStream.Position := 0;
    SetLength(FValue, pvStream.Size);
    pvStream.Read(FValue[0], pvStream.Size);
  end else
  begin
    SetLength(FValue, pvLen);
    pvStream.ReadBuffer(FValue[0], pvLen);
  end;
end;

procedure TSimpleMsgPack.SaveBinaryToFile(pvFileName: String);
var
  lvFileStream:TFileStream;
begin
  if FileExists(pvFileName) then
  begin
    if not DeleteFile(PChar(pvFileName)) then
      RaiseLastOSError;
  end;
  lvFileStream := TFileStream.Create(pvFileName, fmCreate);
  try
    lvFileStream.WriteBuffer(FValue[0], Length(FValue));
  finally
    lvFileStream.Free;
  end;
end;

procedure TSimpleMsgPack.SaveBinaryToStream(pvStream: TStream);
begin
  pvStream.WriteBuffer(FValue[0], Length(FValue));
end;

procedure TSimpleMsgPack.SetAsBoolean(const Value: Boolean);
begin
  FDataType := mptBoolean;
  SetLength(FValue, 1);
  PBoolean(@FValue[0])^ := Value;
end;

procedure TSimpleMsgPack.SetAsBytes(const Value: TBytes);
begin
  FDataType := mptBinary;
  FValue := Value;
end;

procedure TSimpleMsgPack.SetAsDateTime(const Value: TDateTime);
begin
  FDataType := mptDateTime;
  SetLength(FValue, SizeOf(TDateTime));
  PDouble(@FValue[0])^ := Value;
end;

procedure TSimpleMsgPack.SetAsFloat(const Value: Double);
begin
  FDataType := mptFloat;
  SetLength(FValue, SizeOf(Double));
  PDouble(@FValue[0])^ := Value;
end;

procedure TSimpleMsgPack.setAsInteger(pvValue: Int64);
begin
  FDataType := mptInteger;
  SetLength(FValue, SizeOf(Int64));
  PInt64(@FValue[0])^ := pvValue;
end;

procedure TSimpleMsgPack.SetAsSingle(const Value: Single);
begin
  FDataType := mptSingle;
  SetLength(FValue, SizeOf(Single));
  PSingle(FValue)^ := Value;
end;

procedure TSimpleMsgPack.setAsString(pvValue: string);
begin
  FDataType := mptString;
  if SizeOf(Char) = 2 then
  begin
    SetLength(FValue, length(pvValue) shl 1);
    Move(PChar(pvValue)^, FValue[0], Length(FValue));
  end else
  begin
    SetLength(FValue, length(pvValue));
    Move(PChar(pvValue)^, FValue[0], Length(FValue));
  end;
end;

/// <summary>
///   copy from qdac3
/// </summary>
procedure TSimpleMsgPack.SetAsVariant(const Value: Variant);
var
  j: Integer;
  AType: TVarType;
  procedure VarAsBytes;
  var
    L: Integer;
    p: PByte;
  begin
    FDataType := mptBinary;
    L := VarArrayHighBound(Value, 1) + 1;
    SetLength(FValue, L);
    p := VarArrayLock(Value);
    Move(p^, FValue[0], L);
    VarArrayUnlock(Value);
  end;
begin
  if VarIsArray(Value) then
  begin
    AType := VarType(Value);
    if (AType and varTypeMask) = varByte then
      VarAsBytes
    else
    begin
      checkObjectDataType(mptArray);
      FChildren.Clear;
      for j := VarArrayLowBound(Value, VarArrayDimCount(Value))
        to VarArrayHighBound(Value, VarArrayDimCount(Value)) do
        Add.AsVariant := Value[j];
    end;
  end
  else
  begin
    case VarType(Value) of
      varSmallInt, varInteger, varByte, varShortInt, varWord,
        varLongWord, varInt64:
        AsInteger := Value;
      varSingle, varDouble, varCurrency:
        AsFloat := Value;
      varDate:
        AsDateTime := Value;
      varOleStr, varString{$IFDEF UNICODE}, varUString{$ENDIF}:
        AsString := Value;
      varBoolean:
        AsBoolean := Value;
      varNull,varEmpty,varUnknown:
        begin
          FDataType:=mptNull;
          SetLength(FValue, 0);
        end;
      varUInt64:
        AsInteger := Value;
    else
      // null
      ;//raise Exception.Create(SVariantConvertNotSupport);
    end;
  end;
end;

procedure TSimpleMsgPack.SetB(pvPath: String; const Value: Boolean);
var
  lvObj:TSimpleMsgPack;
begin
  lvObj := ForcePathObject(pvPath);
  lvObj.AsBoolean := Value;
end;

procedure TSimpleMsgPack.SetBB(pvPath: Integer; const Value: Boolean);
begin
  Add(pvPath).AsBoolean := Value;
end;

procedure TSimpleMsgPack.SetD(pvPath: String; const Value: Double);
var
  lvObj:TSimpleMsgPack;
begin
  lvObj := ForcePathObject(pvPath);
  lvObj.AsFloat := Value;
end;

procedure TSimpleMsgPack.SetDD(pvPath: Integer; const Value: Double);
begin
  Add(pvPath).AsFloat := Value;
end;

procedure TSimpleMsgPack.SetI(pvPath: String; const Value: Int64);
var
  lvObj:TSimpleMsgPack;
begin
  lvObj := ForcePathObject(pvPath);
  lvObj.AsInteger := Value;
end;

procedure TSimpleMsgPack.setName(pvName: string);
begin
//  FName := pvName;
//  FLowerName := LowerCase(FName);
  FKeyType := mptString;
  FKeyName := BytesOf(pvName);
end;

procedure TSimpleMsgPack.setName(pvName: Int64);
begin
  FKeyType := mptInteger;
  SetLength(FKeyName, SizeOf(Int64));
  PInt64(@FKeyName[0])^ := pvName;
end;

procedure TSimpleMsgPack.setName(pvName: Boolean);
begin
  FKeyType := mptBoolean;
  SetLength(FKeyName, 1);
  FKeyName[0] := Integer(pvName);
end;

procedure TSimpleMsgPack.setName(pvName: Double);
begin
  FKeyType := mptFloat;
  SetLength(FKeyName, sizeof(Double));
  PDouble(@FKeyName[0])^ := pvName;
end;

procedure TSimpleMsgPack.setName(pvName: Single);
begin
  FKeyType := mptSingle;
  SetLength(FKeyName, sizeof(Single));
  PSingle(@FKeyName[0])^ := pvName;
end;

procedure TSimpleMsgPack.SetO(pvPath: String; const Value: TSimpleMsgPack);
var
  lvName:String;
  ss1:String;
  sPtr:PChar;
  lvTempObj, lvParent:TSimpleMsgPack;
  j:Integer;
begin
  ss1 := pvPath;

  lvParent := Self;
  sPtr := PChar(ss1);
  while sPtr^ <> #0 do
  begin
    lvName := getFirst(sPtr, ['.', '/','\']);
    if lvName = '' then
    begin
      Break;
    end else
    begin
      if sPtr^ = #0 then
      begin           // end
        j := lvParent.indexOf(lvName);
        if j <> -1 then
        begin
          lvTempObj := TSimpleMsgPack(lvParent.FChildren[j]);
          lvParent.FChildren[j] := Value;
          lvTempObj.Free;  // free old
        end else
        begin
          Value.setName(lvName);
          lvParent.InnerAddToChildren(mptMap, Value);
        end;
      end else
      begin
        // find childrean
        lvTempObj := lvParent.findObj(lvName);
        if lvTempObj = nil then
        begin
          lvParent := lvParent.Add(lvName);
        end else
        begin
          lvParent := lvTempObj;
        end;
      end;
    end;
    if sPtr^ = #0 then Break;
    Inc(sPtr);
  end;
end;

procedure TSimpleMsgPack.SetS(pvPath: String; const Value: string);
var
  lvObj:TSimpleMsgPack;
begin
  lvObj := ForcePathObject(pvPath);
  lvObj.AsString := Value;
end;


type
  TMsgPackTypeHelper = record helper for TMsgPackType
  public
    function ToString: String;
  end;

procedure DumpObjMsgPack(AObj: TSimpleMsgPack; Ident: Word; ParentName: String);
var i: Integer;
begin
  if AObj.Name <> '' then
   Write(' ':Ident*2, 'Object=', AObj.DataType.ToString, ' Name=', AObj.Name)
 else
   Write(' ':Ident*2, 'Object=', AObj.DataType.ToString);
  if AObj.DataType in [mptArray, mptMap] then
  begin
    if AObj.Count = 0 then
     Write(' <empty>', #13#10)
    else
     Write(' Count:', AObj.Count, #13#10);
   for I := 0 to AObj.Count - 1 do
    DumpObjMsgPack(AObj.Items[i], Ident + 1, AObj.Name);
  end else
  if AObj.DataType = mptInteger then
    Write(' Value=0x', IntToHex(AObj.AsInteger, 8), #13#10)
  else
    Write(' Value=',AObj.AsString, #13#10);
  if Ident = 0 then
   Writeln('/*************************************************/');
end;



{ TMsgPackTypeHelper }

function TMsgPackTypeHelper.ToString: String;
const
  Str: array[TMsgPackType] of String = ('Unknown', 'Null', 'Map', 'Array', 'String', 'Integer',
  'Boolean', 'Float', 'Single', 'DateTime', 'Binary');
begin
  Result := Str[Self];
end;


function MPO(const AValue: Int64): TSimpleMsgPack; overload;
begin
  Result := TSimpleMsgPack.Create(mptInteger);
  Result.AsInteger := AValue;
end;

function MPO(const AValue: RawByteString): TSimpleMsgPack; overload;
begin
  Result := TSimpleMsgPack.Create(mptString);
  Result.AsString := AValue;
end;

function MPO(const AValue: Double): TSimpleMsgPack; overload;
begin
  Result := TSimpleMsgPack.Create(mptFloat);
  Result.AsFloat := AValue;
end;

function MPO(const AValue: Single): TSimpleMsgPack; overload;
begin
  Result := TSimpleMsgPack.Create(mptSingle);
  Result.AsSingle := AValue;
end;

function MPO(const AValue: Boolean): TSimpleMsgPack; overload;
begin
  Result := TSimpleMsgPack.Create(mptBoolean);
  Result.AsBoolean := AValue;
end;


function MPO(const AValue: Variant): TSimpleMsgPack; overload;
begin
  Result := TSimpleMsgPack.Create;
  Result.AsVariant := AValue;
end;

end.
