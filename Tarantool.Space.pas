unit Tarantool.Space;

interface


implementation

uses System.SysUtils
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
 , Tarantool.Exceptions, Variants
 ;

type
  TTNTFieldType = (tftString, tftUnsigned, tftMap, tftArray);

  TTNTSpace = class(TTNTResponce, ITNTSpace)
  private
    FSpaceId: Int64;
    FName: string;
    FEngine: String;
    FFieldCount: Int64;
    FOwnerId: Int64;
    FIndexList: ITNTIndexList;
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
  protected
    type
      TTNTField = class
      private
        FName: String;
        FFieldType: TTNTFieldType;
      public
        property Name: String read FName;
        property FieldType: TTNTFieldType read FFieldType;
      end;
  protected

  public
    constructor Create(APacker: ITNTPacker; AConnection: ITNTConnection); override;
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
    function Update(AIndexId: Integer; AKeys: Variant; AUpdateDef: ITNTUpdateDefinition): ITNTTuple;
    function UpdateDefinition: ITNTUpdateDefinition;
    function Upsert(AValues: Variant; AUpdateDef: ITNTUpdateDefinition): ITNTTuple;
    procedure Delete(AIndex: Int64; AKeys: Variant);
    function Call(AFunctionName: string; AArguments: Variant): ITNTTuple;
    function Eval(AExpression: string; AArguments: Variant): ITNTTuple;
  end;


{ TTNTSpace }

function TTNTSpace.Call(AFunctionName: string; AArguments: Variant): ITNTTuple;
begin
 Result := Connection.Call(AFunctionName, AArguments);
end;

constructor TTNTSpace.Create(APacker: ITNTPacker; AConnection: ITNTConnection);
var Maps: ITNTPackerMap;
    Flds: ITNTPackerArray;
    i, j: Integer;
    Select: ITNTSelect;
begin
  inherited;
  With APacker.Body.UnpackArray(tnData).UnpackArray(0) do
  begin
   FSpaceId := UnpackInteger(0);
   FOwnerId := UnpackInteger(1);
   FName := UnpackString(2);
   FEngine := UnpackString(3);
   FFieldCount := UnpackInteger(4);
   Maps := UnpackMap(5);
   if Maps.Count > 0 then
    begin

    end;
   Flds := UnpackArray(6);
   if Flds.Count > 0 then
    begin
     for i := 0 to Flds.Count - 1 do
       begin
         Maps := Flds.UnpackMap(i);
         Maps.UnpackString('name');
         Maps.UnpackString('type');
       end;
    end;
  end;
  Select := SelectRequest(VIndexSpaceId, VIndexIdIndexId, FSpaceId);
  Connection.WriteToTarantool(Select);
  FIndexList := Connection.ReadFromTarantool(ITNTIndexList) as ITNTIndexList;
  if Flds.Count > 0 then
    for i := 0 to FIndexList.Count - 1 do
     for j := 0 to FIndexList[i].Parts.Count - 1 do
      if FIndexList[i].Parts[j].Id < Flds.Count then
        FIndexList[i].Parts[j].Name := Flds.UnpackMap(FIndexList[i].Parts[j].Id).UnpackString('name');
end;

procedure TTNTSpace.Delete(AIndex: Int64; AKeys: Variant);
var DeleteCmd: ITNTDelete;
begin
 DeleteCmd := NewDelete(FSpaceId, AIndex, AKeys);
 Connection.WriteToTarantool(DeleteCmd);
 Connection.ReadFromTarantool(TGUID.Empty);
end;

function TTNTSpace.Eval(AExpression: string; AArguments: Variant): ITNTTuple;
begin
 Result := Connection.Eval(AExpression, AArguments);
end;

function TTNTSpace.GetEngine: String;
begin
 Result := FEngine;
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
  Result := Connection.ReadFromTarantool(ITNTTuple) as ITNTTuple;
end;

function TTNTSpace.Replace(AValues: TTNTInsertValues; ATuple: TBytes): ITNTTuple;
var ReplaceCmd: ITNTReplace;
begin
  ReplaceCmd := NewReplace(FSpaceId, AValues, ATuple);
  Connection.WriteToTarantool(ReplaceCmd);
  Result := Connection.ReadFromTarantool(ITNTTuple) as ITNTTuple;
end;

function TTNTSpace.Replace(AValues: Variant): ITNTTuple;
var ReplaceCmd: ITNTReplace;
begin
  ReplaceCmd := NewReplace(FSpaceId, AValues);
  Connection.WriteToTarantool(ReplaceCmd);
  Result := Connection.ReadFromTarantool(ITNTTuple) as ITNTTuple;
end;

function TTNTSpace.Insert(AValues: TTNTInsertValues; ATuple: TBytes): ITNTTuple;
var InsertCmd: ITNTInsert;
begin
  InsertCmd := NewInsert(FSpaceId, AValues, ATuple);
  Connection.WriteToTarantool(InsertCmd);
  Result := Connection.ReadFromTarantool(ITNTTuple) as ITNTTuple;
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
 Result := Connection.ReadFromTarantool(ITNTTuple) as ITNTTuple;
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

function TTNTSpace.Update(AIndexId: Integer; AKeys: Variant;
  AUpdateDef: ITNTUpdateDefinition): ITNTTuple;
var UpdateCmd: ITNTUpdate;
begin
  UpdateCmd := NewUpdate(FSpaceId, AIndexId, AKeys, AUpdateDef);
  Connection.WriteToTarantool(UpdateCmd);
  Result := Connection.ReadFromTarantool(ITNTTuple) as ITNTTuple;
end;

function TTNTSpace.UpdateDefinition: ITNTUpdateDefinition;
begin
 Result := Tarantool.UpdateRequest.UpdateDefinition;
end;

function TTNTSpace.Upsert(AValues: Variant;
  AUpdateDef: ITNTUpdateDefinition): ITNTTuple;
var UpsertCmd: ITNTUpsert;
begin
 UpsertCmd := NewUpsert(FSpaceId, AValues, AUpdateDef);
 Connection.WriteToTarantool(UpsertCmd);
 Result := Connection.ReadFromTarantool(ITNTTuple) as ITNTTuple;
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

initialization

  RegisterResponseClass(ITNTSpace, TTNTSpace);


end.
