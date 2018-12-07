unit Tarantool.Variants.DateTimeUnixSerialization;

{$I Tarantool.Options.inc}

interface
uses Tarantool.Variants
{$IFDEF USE_RTTI_CONTEXT}
, RTTI
{$ELSE}
,  TypInfo
{$ENDIF}
;

type
  TTNTDateTimeUnixSerializer = class(TTNTCustomSerializer, ITNTSerializer)
  protected
    procedure ToObject(AObject: TObject; APropInfo: {$IFDEF USE_RTTI_CONTEXT}TRttiProperty{$ELSE}PPropInfo{$ENDIF}; AValue: Variant); override;
    function ToVariant(AObject: TObject; APropInfo: {$IFDEF USE_RTTI_CONTEXT}TRttiProperty{$ELSE}PPropInfo{$ENDIF}): Variant; override;
  end;


implementation

uses DateUtils;

{ TTNTDateTimeUnixSerializer }

procedure TTNTDateTimeUnixSerializer.ToObject(AObject: TObject; APropInfo:
  {$IFDEF USE_RTTI_CONTEXT}TRttiProperty{$ELSE}PPropInfo{$ENDIF}; AValue: Variant);
var
{$IFDEF USE_RTTI_CONTEXT}
   Value: TValue;
{$ELSE}
   Value: TDateTime;
{$ENDIF}
begin
 {$IFDEF USE_RTTI_CONTEXT}
   Value := TValue.From<TDateTime>(UnixToDateTime(AValue));
   APropInfo.SetValue(AObject, Value);
 {$ELSE}
   Value := UnixToDateTime(AValue);
   SetFloatProp(AObject, APropInfo, Value);
 {$ENDIF}
end;

function TTNTDateTimeUnixSerializer.ToVariant(AObject: TObject; APropInfo:
  {$IFDEF USE_RTTI_CONTEXT}TRttiProperty{$ELSE}PPropInfo{$ENDIF}): Variant;
var
{$IFDEF USE_RTTI_CONTEXT}
   Value: TValue;
{$ELSE}
   Value: TDateTime;
{$ENDIF}
begin
 {$IFDEF USE_RTTI_CONTEXT}
   Value := APropInfo.GetValue(AObject);
   Result := DateTimeToUnix(Value.AsExtended);
 {$ELSE}
   Value := GetFloatProp(AObject, APropInfo);
   Result := DateTimeToUnix(Value);
 {$ENDIF}
end;

initialization
  TNTRegisterCustomSerializer(TypeInfo(TDateTime), TTNTDateTimeUnixSerializer);
end.
