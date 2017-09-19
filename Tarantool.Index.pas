unit Tarantool.Index;

interface
uses Tarantool.Interfaces;


implementation
uses Classes
 , Tarantool.UserKeys
 , Tarantool.ServerResponse
 , Tarantool.Variants
 , Tarantool.Iterator
 , Tarantool.SelectRequest
 , Tarantool.UpdateRequest
 , Tarantool.DeleteRequest
 , Tarantool.Utils
 , Variants
 ;

type
  TTNTIndex = class(TTNTResponce, ITNTIndex)
  private
    FSpaceId: Int64;
    FIid: Int64;
    FName: String;
    FType: String;
    FOpts: Variant;
    FParts: ITNTParts;
    procedure SetSpaceId(const Value: Int64);
    function GetSpaceId: Int64;
    function GetIId: Int64;
    function GetName: String;
    function GetOpts: Variant;
    function GetType: String;
    function GetParts: ITNTParts;
  public
    constructor Create(APacker: ITNTPacker; AConnection: ITNTConnection); override;
    constructor CreateFromTuple(AArr: ITNTPackerArray; AConnection: ITNTConnection);

    function Select(AKeys: Variant; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;
    function Select(AKeys: Variant; ALimit: Integer; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;
    function Select(AKeys: Variant; ALimit: Integer; AOffset: Integer; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;
    function SelectAll: ITNTTuple;

    function Update(AKeys: Variant; AUpdateDef: ITNTUpdateDefinition): ITNTTuple;

    procedure Delete(AKeys: Variant);

    property SpaceId: Int64 read GetSpaceId write SetSpaceId;
    property IId: Int64 read GetIId;
    property Name: String read GetName;
    property &Type: String read GetType;
    property Opts: Variant read GetOpts;
    property Parts: ITNTParts read GetParts;
  end;

  TTNTIndexList = class(TTNTResponce, ITNTIndexList)
  private
    FIndex: TInterfaceList;
    function GetIndex(AIndex: Integer): ITNTIndex;
    function GetCount: Integer;
    function GetNameIndex(AName: String): ITNTIndex;
  public
    constructor Create(APacker: ITNTPacker; AConnection: ITNTConnection); override;
    destructor Destroy; override;
    property index[AIndex: Integer]: ITNTIndex read GetIndex; default;
    property NameIndex[AName: String]: ITNTIndex read GetNameIndex;
    property Count: Integer read GetCount;
  end;

  TTNTPart = class(TInterfacedObject, ITNTPart)
  private
    FId: Int64;
    FName: String;
    FType: String;
    function GetId: Int64;
    function GetName: String;
    function GetType: String;
    procedure SetName(const Value: String);
  public
    constructor Create(AArray: ITNTPackerArray);
    property Id: Int64 read GetId;
    property Name: String read GetName write SetName;
    property &Type: String read GetType;
  end;

  TTNTPartList = class(TInterfacedObject, ITNTParts)
  private
    FList: TInterfaceList;
    function GetPart(Index: Integer): ITNTPart;
    function GetCount: Integer;
  public
    constructor Create(APacker: ITNTPackerArray);
    destructor Destroy; override;
    property Part[Index: Integer]: ITNTPart read GetPart; default;
    property Count: Integer read GetCount;
  end;

{ TTNTIndex }

constructor TTNTIndex.Create(APacker: ITNTPacker; AConnection: ITNTConnection);
begin
  inherited;
  With APacker.Body.UnpackArray(tnData).UnpackArray(0) do
  begin
   FSpaceId := UnpackInteger(0);
   FIid := UnpackInteger(1);
   FName := UnpackString(2);
   FType := UnpackString(3);
   FOpts := TNTVariant(UnpackMap(4));
   FParts := TTNTPartList.Create(UnpackArray(5));
  end;
end;

constructor TTNTIndex.CreateFromTuple(AArr: ITNTPackerArray;
  AConnection: ITNTConnection);
begin
  inherited Create(nil, AConnection);
  FSpaceId := AArr.UnpackInteger(0);
  FIid := AArr.UnpackInteger(1);
  FName := AArr.UnpackString(2);
  FType := AArr.UnpackString(3);
  FOpts := TNTVariant(AArr.UnpackMap(4));
  FParts := TTNTPartList.Create(AArr.UnpackArray(5));
end;

procedure TTNTIndex.Delete(AKeys: Variant);
var DeleteCmd: ITNTDelete;
begin
 DeleteCmd := NewDelete(FSpaceId, FIid, AKeys);
 Connection.WriteToTarantool(DeleteCmd);
 Connection.ReadFromTarantool(TGUID.Empty);
end;

function TTNTIndex.GetIId: Int64;
begin
 Result := FIid;
end;

function TTNTIndex.GetName: String;
begin
 Result := FName;
end;

function TTNTIndex.GetOpts: Variant;
begin
 Result := FOpts
end;

function TTNTIndex.GetParts: ITNTParts;
begin
 Result := FParts;
end;

function TTNTIndex.GetSpaceId: Int64;
begin
 Result := FSpaceId;
end;

function TTNTIndex.GetType: String;
begin
 Result := FType;
end;

function TTNTIndex.Select(AKeys: Variant; ALimit: Integer;
  AIterator: TTarantoolIterator): ITNTTuple;
begin
 Result := Select(AKeys, ALimit, 0, AIterator);
end;

function TTNTIndex.Select(AKeys: Variant;
  AIterator: TTarantoolIterator): ITNTTuple;
begin
 Result := Select(AKeys, 0, 0, AIterator);
end;

function TTNTIndex.Select(AKeys: Variant; ALimit, AOffset: Integer;
  AIterator: TTarantoolIterator): ITNTTuple;
var SelectCmd: ITNTSelect;
begin
  SelectCmd := SelectRequest(FSpaceId, FIid, AKeys, AOffset, ALimit, AIterator);
  Connection.WriteToTarantool(SelectCmd);
  Result := Connection.ReadFromTarantool(ITNTTuple) as ITNTTuple;
end;

function TTNTIndex.SelectAll: ITNTTuple;
var SelectCmd: ITNTSelect;
begin
 SelectCmd := SelectRequest(FSpaceId, -1, null);
 Connection.WriteToTarantool(SelectCmd);
 Result := Connection.ReadFromTarantool(ITNTTuple) as ITNTTuple;
end;

procedure TTNTIndex.SetSpaceId(const Value: Int64);
begin
  FSpaceId := Value;
end;

function TTNTIndex.Update(AKeys: Variant;
  AUpdateDef: ITNTUpdateDefinition): ITNTTuple;
var UpdateCmd: ITNTUpdate;
begin
  UpdateCmd := NewUpdate(FSpaceId, FIid, AKeys, AUpdateDef);
  Connection.WriteToTarantool(UpdateCmd);
  Result := Connection.ReadFromTarantool(ITNTTuple) as ITNTTuple;
end;

{ TTNTIndexList }

constructor TTNTIndexList.Create(APacker: ITNTPacker; AConnection: ITNTConnection);
var Arr: ITNTPackerArray;
    i: Integer;
begin
 inherited;
 FIndex := TInterfaceList.Create;
 Arr := APacker.Body.UnpackArray(tnData);
 if Assigned(Arr) then
 begin
   for i := 0 to Arr.Count - 1 do
     begin
       FIndex.Add(TTNTIndex.CreateFromTuple(Arr.UnpackArray(i), AConnection))
     end;
 end;
end;

destructor TTNTIndexList.Destroy;
begin
  FIndex.Free;
  inherited;
end;

function TTNTIndexList.GetCount: Integer;
begin
 Result := FIndex.Count;
end;

function TTNTIndexList.GetIndex(AIndex: Integer): ITNTIndex;
begin
 Result := FIndex[AIndex] as ITNTIndex;
end;

function TTNTIndexList.GetNameIndex(AName: String): ITNTIndex;
var i: Integer;
begin
 Result := nil;
 for i := 0 to Count - 1 do
   if AName = index[i].Name then
    begin
      Result := Index[i];
      Break;
    end;
end;

{ TTNTPartList }

constructor TTNTPartList.Create(APacker: ITNTPackerArray);
var i: Integer;
begin
 FList := TInterfaceList.Create;
 for i := 0 to APacker.Count - 1 do
     FList.Add(TTNTPart.Create(APacker.UnpackArray(i)));
end;

destructor TTNTPartList.Destroy;
begin
  FList.Free;
  inherited;
end;

function TTNTPartList.GetCount: Integer;
begin
 Result := FList.Count;
end;

function TTNTPartList.GetPart(Index: Integer): ITNTPart;
begin
 Result := FList[Index] as ITNTPart;
end;

{ TTNTPart }

constructor TTNTPart.Create(AArray: ITNTPackerArray);
begin
 FId := AArray.UnpackInteger(0);
 FType := AArray.UnpackString(1);
end;

function TTNTPart.GetId: Int64;
begin
 Result := FId;
end;

function TTNTPart.GetName: String;
begin
 Result := FName;
end;

function TTNTPart.GetType: String;
begin
 Result := FType;
end;

procedure TTNTPart.SetName(const Value: String);
begin
 FName := Value;
end;

initialization
  RegisterResponseClass(ITNTIndex, TTNTIndex);
  RegisterResponseClass(ITNTIndexList, TTNTIndexList);

finalization


end.
