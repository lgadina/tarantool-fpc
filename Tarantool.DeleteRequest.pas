unit Tarantool.DeleteRequest;

interface
uses
  Tarantool.Interfaces;


function NewDelete(ASpaceId, AIndexId: Int64; AKeys: Variant): ITNTDelete;

implementation

uses Tarantool.ClientMessage, Tarantool.CommanCode;

type
  TTNTDelete = class(TTNTClientMessageKeys, ITNTDelete)
  public

  end;

function NewDelete(ASpaceId, AIndexId: Int64; AKeys: Variant): ITNTDelete;
begin
 Result := TTNTDelete.Create(tncDelete);
 Result.SpaceId := ASpaceId;
 Result.IndexId := AIndexId;
 Result.Keys := AKeys;
end;

end.
