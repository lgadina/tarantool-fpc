unit Tarantool.Index;

interface
uses Tarantool.Interfaces;

type
  ITNTIndex = interface(ITNTResponce)
    ['{CB7C7CC1-9413-40AF-BF77-EE8745D3F9A3}']
  end;

  ITNTIndexList = interface(ITNTResponce)
    ['{80318FE8-EAB2-4604-B1E5-D5ECAFF3E70A}']
  end;

implementation
uses System.Classes, Tarantool.UserKeys, Tarantool.ServerResponse;

type
  TTNTIndex = class(TTNTResponce)
  private
    FSpaceId: Int64;
    FIid: Int64;
    FName: String;
    FType: String;
    procedure SetSpaceId(const Value: Int64);
    function GetSpaceId: Int64;
  public
    constructor Create(APacker: IPacker; AConnection: ITNTConnection); override;
    constructor CreateFromTuple(AArr: IPackerArray; AConnection: ITNTConnection);
    property SpaceId: Int64 read GetSpaceId write SetSpaceId;
  end;

  TTNTIndexList = class(TTNTResponce, ITNTIndexList)
  private
    FIndex: TInterfaceList;
  public
    constructor Create(APacker: IPacker; AConnection: ITNTConnection); override;
    destructor Destroy; override;
  end;

{ TTNTIndex }

constructor TTNTIndex.Create(APacker: IPacker; AConnection: ITNTConnection);
begin
  inherited;
  With APacker.Body.UnpackArray(tnData).UnpackArray(0) do
  begin
   FSpaceId := UnpackInteger(0);
   FIid := UnpackInteger(1);
   FName := UnpackString(2);
   FType := UnpackString(3);
  end;
end;

constructor TTNTIndex.CreateFromTuple(AArr: IPackerArray;
  AConnection: ITNTConnection);
begin
  inherited Create(nil, AConnection);
  FSpaceId := AArr.UnpackInteger(0);
  FIid := AArr.UnpackInteger(1);
  FName := AArr.UnpackString(2);
  FType := AArr.UnpackString(3);
end;

function TTNTIndex.GetSpaceId: Int64;
begin
 Result := FSpaceId;
end;

procedure TTNTIndex.SetSpaceId(const Value: Int64);
begin
  FSpaceId := Value;
end;

{ TTNTIndexList }

constructor TTNTIndexList.Create(APacker: IPacker; AConnection: ITNTConnection);
var Arr: IPackerArray;
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

initialization
  RegisterResponseClass(ITNTIndex, TTNTIndex);
  RegisterResponseClass(ITNTIndexList, TTNTIndexList);

finalization


end.
