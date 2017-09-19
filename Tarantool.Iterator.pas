unit Tarantool.Iterator;

interface

{$SCOPEDENUMS ON}
type
  TTarantoolIterator = (
        None         = -1,
        Eq           = 0,
        Req          = 1,
        All          = 2,
        Lt           = 3,
        Le           = 4,
        Ge           = 5,
        Gt           = 6,
        BitAllSet    = 7,
        BitAnySet    = 8,
        BitAllNotSet = 9
        );
{$SCOPEDENUMS OFF}

implementation

end.
