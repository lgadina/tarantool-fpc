unit Tarantool.Exceptions;
{$I Tarantool.Options.inc}
interface
uses SysUtils;

type

  { ETarantoolException }

  ETarantoolException = class(Exception)
  private
    FErrorCode: Cardinal;
  public
    property ErrorCode: Cardinal read FErrorCode;
    constructor Create(const AErrorCode: Cardinal; const AMessage: String);
    constructor CreateFmt(const AErrorCode: Cardinal; const AMessage: String;  const args : array of const);
  end;
  ETarantoolInvalidValue = class(ETarantoolException);
  ETarantoolInvalidUpdateOperation = class(ETarantoolException);

implementation

{ ETarantoolException }

constructor ETarantoolException.Create(const AErrorCode: Cardinal;
  const AMessage: String);
begin
  FErrorCode:= AErrorCode;
  inherited Create(AMessage);
end;

constructor ETarantoolException.CreateFmt(const AErrorCode: Cardinal;
  const AMessage: String; const args: array of const);
begin
 FErrorCode:= AErrorCode;
 inherited CreateFmt(AMessage, args);
end;

end.
