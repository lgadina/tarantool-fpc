unit Tarantool.Space;

interface


implementation

uses SysUtils
 , Tarantool.UserKeys
 , Tarantool.ServerResponse
 , Tarantool.Interfaces
 , Tarantool.SelectRequest
 , Tarantool.Iterator
 , Tarantool.Index
 , Tarantool.InsertRequest
 , Tarantool.UpdateRequest
 , Tarantool.DeleteRequest
 , Tarantool.UpsertRequest
 , Tarantool.Exceptions
 , Tarantool.SimpleMsgPack
 , Tarantool.Utils
 , Variants
 , System.Generics.Collections
 ;

type

  TTNTFieldTypeHelper = record helper for TTNTFieldType
  public
    class function Parse(AStr: string): TTNTFieldType; static;
    function ToString: String;
  end;

  TTNTField = class(TInterfacedObject, ITNTField)
  private
    FName: string;
    FType: TTNTFieldType;
    FIndex: Integer;
    function GetName: String;
    function GetType: TTNTFieldType;
    function GetIndex: Integer;
  public
    constructor CreateFromMap(AMap: ITNTPackerMap; AIndex: Integer);
    property Name: String read GetName;
    property &Type: TTNTFieldType read GetType;
    property Index: Integer read GetIndex;
  end;

  TTNTFieldList = class(TDictionary<String,ITNTField>)

  end;

  TTNTSpace = class(TTNTResponce, ITNTSpace)
  private
    FSpaceId: Int64;
    FName: string;
    FEngine: String;
    FFieldCount: Int64;
    FOwnerId: Int64;
    FIndexList: ITNTIndexList;
    FFields: TTNTFieldList;
    procedure SetEngine(const Value: String);
    procedure SetName(const Value: string);
    procedure SetOwnerId(const Value: Int64);
    procedure SetSpaceId(const Value: Int64);
    function GetEngine: String;
    function GetFieldCount: Int64;
    function GetName: string;
    function GetOwnerId: Int64;
    function GetSpaceId: Int64;
    function GetIndexes: ITNTIndexList;
    function GetField(Index: Integer): ITNTField;
  protected
  public
    constructor Create(APacker: ITNTPacker; AConnection: ITNTConnection; ASpace: ITNTSpace); override;
    destructor Destroy; override;
    property SpaceId: Int64 read GetSpaceId write SetSpaceId;
    property OwnerId: Int64 read GetOwnerId write SetOwnerId;
    property Name: string read GetName write SetName;
    property Engine: String read GetEngine write SetEngine;
    property FieldCount: Int64 read GetFieldCount;
    property Indexes: ITNTIndexList read GetIndexes;
    function Select(AIndexId: Integer; AKeys: Variant; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;
    function Select(AIndexId: Integer; AKeys: Variant; ALimit: Integer; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;
    function Select(AIndexId: Integer; AKeys: Variant; ALimit: Integer; AOffset: Integer; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;

    function Select(AIndexName: string; AKeys: Variant; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;
    function Select(AIndexName: string; AKeys: Variant; ALimit: Integer; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;
    function Select(AIndexName: string; AKeys: Variant; ALimit: Integer; AOffset: Integer; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;

    function SelectAll: ITNTTuple;
    function Insert(AValues: TTNTInsertValues; ATuple: TBytes): ITNTTuple; overload;
    function Insert(AValues: Variant): ITNTTuple; overload;
    function Replace(AValues: TTNTInsertValues; ATuple: TBytes): ITNTTuple; overload;
    function Replace(AValues: Variant): ITNTTuple; overload;
    function Update(AIndexId: Integer; AKeys: Variant; AUpdateDef: ITNTUpdateDefinition): ITNTTuple; overload;
    function Update(AIndexName: String; AKeys: Variant; AUpdateDef: ITNTUpdateDefinition): ITNTTuple; overload;

    function UpdateDefinition: ITNTUpdateDefinition;
    function Upsert(AValues: Variant; AUpdateDef: ITNTUpdateDefinition): ITNTTuple;

    procedure Delete(AIndex: Int64; AKeys: Variant); overload;
    procedure Delete(AIndexName: String; AKeys: Variant); overload;
    procedure Truncate;
    function Call(AFunctionName: string; AArguments: Variant): ITNTTuple;
    function Eval(AExpression: string; AArguments: Variant): ITNTTuple;

    property Field[Index: Integer]: ITNTField read GetField;
    function FieldByName(AName: string): ITNTField;

    function Count: Integer;

  end;


{ TTNTSpace }

function TTNTSpace.Call(AFunctionName: string; AArguments: Variant): ITNTTuple;
begin
 Result := Connection.Call(AFunctionName, AArguments);
end;

function TTNTSpace.Count: Integer;
var Tuple: ITNTTuple;
begin
 Tuple := Eval('return box.space.'+FName+':count()', Null);
 if Tuple <> nil then
  Result := Tuple.Row[0]
 else
  Result := 0;
end;

constructor TTNTSpace.Create(APacker: ITNTPacker; AConnection: ITNTConnection; ASpace: ITNTSpace);
var Maps: ITNTPackerMap;
    Flds: ITNTPackerArray;
    i, j: Integer;
    LSelect: ITNTSelect;
    Fld: ITNTField;
begin
  if APacker.Body.IsExist(tnData) and (APacker.Body.UnpackArray(tnData).Count > 0)
  then
  begin
   inherited;

      FFields := TTNTFieldList.Create();
      With APacker.Body.UnpackArray(tnData).UnpackArray(0) do
      begin
       FSpaceId := UnpackInteger(0);
       FOwnerId := UnpackInteger(1);
       FName := UnpackString(2);
       FEngine := UnpackString(3);
       FFieldCount := UnpackInteger(4);
       Maps := UnpackMap(5);
       Flds := UnpackArray(6);
      end;
      if Flds.Count > 0 then
      begin
        for i := 0 to Flds.Count - 1 do
        begin
          Fld := TTNTField.CreateFromMap(Flds.UnpackMap(i), i);
          FFields.Add(Fld.Name, Fld);
        end;
      end;
      LSelect := SelectRequest(VIndexSpaceId, VIndexIdIndexId, FSpaceId);
      Connection.WriteToTarantool(LSelect);
      FIndexList := Connection.ReadFromTarantool(ITNTIndexList, Self) as ITNTIndexList;
      if Flds.Count > 0 then
      begin
        for i := 0 to FIndexList.Count - 1 do
         for j := 0 to FIndexList[i].Parts.Count - 1 do
          if FIndexList[i].Parts[j].Id < Flds.Count then
          begin
            Fld := Field[FIndexList[i].Parts[j].Id];
            if Fld <> nil then
             FIndexList[i].Parts[j].Name := Fld.Name;
            //FIndexList[i].Parts[j].Name := Flds.UnpackMap(FIndexList[i].Parts[j].Id).UnpackString('name');
          end;
      end;
  end else
   raise ETarantoolException.Create('Space not found');
end;

procedure TTNTSpace.Delete(AIndexName: String; AKeys: Variant);
var Idx: ITNTIndex;
begin
 Idx := FIndexList.NameIndex[AIndexName];
 if Idx = nil then
  raise ETarantoolException.CreateFmt('Index %s not found in space %s', [AIndexName, FName]);
 Idx.Delete(AKeys);
end;

destructor TTNTSpace.Destroy;
begin
  FFields.Free;
  inherited;
end;

procedure TTNTSpace.Delete(AIndex: Int64; AKeys: Variant);
begin
 FIndexList[AIndex].Delete(AKeys);
end;

function TTNTSpace.Eval(AExpression: string; AArguments: Variant): ITNTTuple;
begin
 Result := Connection.Eval(AExpression, AArguments);
end;

function TTNTSpace.FieldByName(AName: string): ITNTField;
begin
 if FFields.ContainsKey(AName) then
   Result := FFields[AName]
 else
   Result := nil;
end;

function TTNTSpace.GetEngine: String;
begin
 Result := FEngine;
end;

function TTNTSpace.GetField(Index: Integer): ITNTField;
var Pair: TPair<String,ITNTField>;
begin
 Result := nil;
 if (FFields.Count > 0) and (Index < FFields.Count) then
 begin
  for Pair in FFields do
   if Pair.Value.Index = Index  then
    begin
      Result := Pair.Value;
      Break;
    end;
 end
 else
  Result := nil;
end;

function TTNTSpace.GetFieldCount: Int64;
begin
 Result := FFieldCount;
end;

function TTNTSpace.GetIndexes: ITNTIndexList;
begin
 Result := FIndexList;
end;

function TTNTSpace.GetName: string;
begin
 Result := FName;
end;

function TTNTSpace.GetOwnerId: Int64;
begin
 Result := FOwnerId;
end;

function TTNTSpace.GetSpaceId: Int64;
begin
 Result := FSpaceId;
end;

function TTNTSpace.Insert(AValues: Variant): ITNTTuple;
var InsertCmd: ITNTInsert;
begin
  InsertCmd := NewInsert(FSpaceId, AValues);
  Connection.WriteToTarantool(InsertCmd);
  Result := Connection.ReadFromTarantool(ITNTTuple, Self) as ITNTTuple;
end;

function TTNTSpace.Replace(AValues: TTNTInsertValues; ATuple: TBytes): ITNTTuple;
var ReplaceCmd: ITNTReplace;
begin
  ReplaceCmd := NewReplace(FSpaceId, AValues, ATuple);
  Connection.WriteToTarantool(ReplaceCmd);
  Result := Connection.ReadFromTarantool(ITNTTuple, Self) as ITNTTuple;
end;

function TTNTSpace.Replace(AValues: Variant): ITNTTuple;
var ReplaceCmd: ITNTReplace;
begin
  ReplaceCmd := NewReplace(FSpaceId, AValues);
  Connection.WriteToTarantool(ReplaceCmd);
  Result := Connection.ReadFromTarantool(ITNTTuple, Self) as ITNTTuple;
end;

function TTNTSpace.Insert(AValues: TTNTInsertValues; ATuple: TBytes): ITNTTuple;
var InsertCmd: ITNTInsert;
begin
  InsertCmd := NewInsert(FSpaceId, AValues, ATuple);
  Connection.WriteToTarantool(InsertCmd);
  Result := Connection.ReadFromTarantool(ITNTTuple, Self) as ITNTTuple;
end;

function TTNTSpace.Select(AIndexId: Integer; AKeys: Variant; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple;
begin
 Result := Select(AIndexId, AKeys, 0, 0, AIterator);
end;

function TTNTSpace.Select(AIndexId: Integer; AKeys: Variant; ALimit: Integer;
  AIterator: TTarantoolIterator): ITNTTuple;
begin
 Result := Select(AIndexId, AKeys, ALimit, 0, AIterator);
end;

function TTNTSpace.Select(AIndexId: Integer; AKeys: Variant; ALimit, AOffset: Integer;
  AIterator: TTarantoolIterator): ITNTTuple;
begin
 Result := FIndexList[AIndexId].Select(AKeys, AOffset, ALimit, AIterator);
end;

function TTNTSpace.SelectAll: ITNTTuple;
var SelectCmd: ITNTSelect;
begin
 SelectCmd := SelectRequest(FSpaceId, -1, null);
 Connection.WriteToTarantool(SelectCmd);
 Result := Connection.ReadFromTarantool(ITNTTuple, Self) as ITNTTuple;
end;

procedure TTNTSpace.SetEngine(const Value: String);
begin
  FEngine := Value;
end;


procedure TTNTSpace.SetName(const Value: string);
begin
  FName := Value;
end;

procedure TTNTSpace.SetOwnerId(const Value: Int64);
begin
  FOwnerId := Value;
end;

procedure TTNTSpace.SetSpaceId(const Value: Int64);
begin
  FSpaceId := Value;
end;

procedure TTNTSpace.Truncate;
begin
  Eval('return box.space.'+FName+':truncate()', null);
end;

function TTNTSpace.Update(AIndexId: Integer; AKeys: Variant;
  AUpdateDef: ITNTUpdateDefinition): ITNTTuple;
begin
  Result := FIndexList[AIndexId].Update(AKeys, AUpdateDef);
end;

function TTNTSpace.Update(AIndexName: String; AKeys: Variant;
  AUpdateDef: ITNTUpdateDefinition): ITNTTuple;
var Idx: ITNTIndex;
begin
 Result := nil;
 Idx := FIndexList.NameIndex[AIndexName];
 if Idx = nil then
  raise ETarantoolException.CreateFmt('Index %s not found in space %s', [AIndexName, FName]);
 Result := Idx.Update(AKeys, AUpdateDef);
end;

function TTNTSpace.UpdateDefinition: ITNTUpdateDefinition;
begin
 Result := Tarantool.UpdateRequest.UpdateDefinition(Self);
end;

function TTNTSpace.Upsert(AValues: Variant;
  AUpdateDef: ITNTUpdateDefinition): ITNTTuple;
var UpsertCmd: ITNTUpsert;
begin
 UpsertCmd := NewUpsert(FSpaceId, AValues, AUpdateDef);
 Connection.WriteToTarantool(UpsertCmd);
 Result := Connection.ReadFromTarantool(ITNTTuple, Self) as ITNTTuple;
end;

function TTNTSpace.Select(AIndexName: string; AKeys: Variant;
  AIterator: TTarantoolIterator): ITNTTuple;
begin
 Result := Select(AIndexName, AKeys, 0, 0, AIterator);
end;

function TTNTSpace.Select(AIndexName: string; AKeys: Variant; ALimit: Integer;
  AIterator: TTarantoolIterator): ITNTTuple;
begin
 Result := Select(AIndexName, AKeys, ALimit, 0, AIterator)
end;

function TTNTSpace.Select(AIndexName: string; AKeys: Variant; ALimit,
  AOffset: Integer; AIterator: TTarantoolIterator): ITNTTuple;
var FIndex: ITNTIndex;
begin
 FIndex := FIndexList.NameIndex[AIndexName];
 if FIndex = nil then
  raise ETarantoolException.CreateFmt('Index %s not found in space %s', [AIndexName, FName]);
 Result := FIndex.Select(AKeys, ALimit, AOffset, AIterator);
end;

{ TTNTField }

constructor TTNTField.CreateFromMap(AMap: ITNTPackerMap; AIndex: Integer);
begin
 FIndex :=  AIndex;
 FName := AMap.UnpackString('name');
 FType := TTNTFieldType.Parse(AMap.UnpackString('type'));
end;

function TTNTField.GetIndex: Integer;
begin
 Result := FIndex;
end;

function TTNTField.GetName: String;
begin
 Result := FName;
end;

function TTNTField.GetType: TTNTFieldType;
begin
 Result := FType;
end;

{ TTNTFieldTypeHelper }
const
  strFieldType : array[TTNTFieldType] of String = ('string', 'unsigned','number', 'map', 'array');


class function TTNTFieldTypeHelper.Parse(AStr: string): TTNTFieldType;
var n: TTNTFieldType;
begin
 Result := TTNTFieldType.tftString;
 for n := low(TTNTFieldType) to High(TTNTFieldType) do
   if strFieldType[n] = AStr then
     begin
       Result := n;
       Break;
     end;
end;

function TTNTFieldTypeHelper.ToString: String;
begin
  Result := strFieldType[Self];
end;

initialization

  RegisterResponseClass(ITNTSpace, TTNTSpace);


end.
