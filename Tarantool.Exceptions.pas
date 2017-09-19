unit Tarantool.Exceptions;

interface
uses SysUtils;

type
  ETarantoolException = class(Exception);
  ETarantoolInvalidValue = class(ETarantoolException);
  ETarantoolInvalidUpdateOperation = class(ETarantoolException);

implementation

end.
