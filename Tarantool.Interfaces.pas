unit Tarantool.Interfaces;

interface

uses System.SysUtils
 , IdGlobal
 , Tarantool.SimpleMsgPack
 , Tarantool.Iterator;

type
{$SCOPEDENUMS ON}
  TTNTUpdateOperationCode = (Addition, Subtraction, BitwiseAnd, BitwiseXor, BitwiseOr, Delete, Insert, Assigned, Splice);
{$SCOPEDENUMS OFF}

type
  TTNTInsertValues = array of Variant;
  IPackerMap = interface;
  IPackerArray = interface;
  ITNTCommand = interface;
  ITNTResponce = interface;
  ITNTTuple = interface;
  ITNTUpdateDefinition = interface;

  IPacker = interface
    ['{1758BCE7-8E1F-4EDA-BB92-732C2A611ECA}']
    function GetAsBytes: TIdBytes;
    procedure SetAsBytes(const Value: TIdBytes);

    function Header: IPackerMap;
    function Body: IPackerMap;
    property AsBytes: TIdBytes read GetAsBytes write SetAsBytes;
  end;

  IPackerMap = interface
    ['{22B7EE05-4983-42E6-AF09-E1D0466B18C1}']
    function GetAsBytes: TBytes;
    procedure SetAsBytes(const Value: TBytes);

    function Pack(const AKey: Integer; AValue: Integer): IPackerMap; overload;
    function Pack(const AKey: String; AValue: Integer): IPackerMap; overload;
    function Pack(const AKey: Integer; AValue: string): IPackerMap; overload;
    function Pack(const AKey: String; AValue: string): IPackerMap; overload;
    function Pack(const AKey: Integer; AValue: TBytes): IPackerMap; overload;
    function Pack(const AKey: String; AValue: TBytes): IPackerMap; overload;
    function PackMap(const AKey: Integer): IPackerMap; overload;
    function PackMap(const AKey: String): IPackerMap; overload;
    function PackArray(const AKey: string): IPackerArray; overload;
    function PackArray(const AKey: integer): IPackerArray; overload;
    function Count: Integer;
    function Name(const Index: Integer): String;
    function DataType(const Index: Integer): TMsgPackType;

    function UnpackArray(const AKey: Integer): IPackerArray; overload;
    function UnpackArray(const AKey: String): IPackerArray; overload;
    function UnpackMap(const AKey: Integer): IPackerMap; overload;
    function UnpackMap(const AKey: String): IPackerMap; overload;
    function UnpackInteger(const AKey: Integer): Integer; overload;
    function UnpackString(const AKey: Integer): String; overload;
    function UnpackInteger(const AKey: String): Integer; overload;
    function UnpackString(const AKey: String): String; overload;
    function UnpackVariant(const AKey: string): Variant; overload;
    function UnpackVariant(const AKey: Integer): Variant; overload;

    property AsBytes: TBytes read GetAsBytes write SetAsBytes;
  end;

  IPackerArray = interface
    ['{2DF2CD7E-3129-4047-8AAD-73E61792F96D}']
    function GetAsBytes: TBytes;
    procedure SetAsBytes(const Value: TBytes);

    function Pack(const AValue: Integer): IPackerArray; overload;
    function Pack(const AValue: String): IPackerArray; overload;
    function Pack(const AValue: TBytes): IPackerArray; overload;
    function Pack(const AValue: Boolean): IPackerArray; overload;
    function Pack(const AValue: Variant): IPackerArray; overload;
    function PackArray: IPackerArray;
    function PackMap: IPackerMap;
    function Count: Integer;
    function DataType(const Index: Integer): TMsgPackType;
    function UnpackInteger(const Index: Integer): Integer;
    function UnpackString(const Index: Integer): String;
    function UnpackBytes(const Index: Integer): TBytes;
    function UnpackArray(const Index: Integer): IPackerArray;
    function UnpackMap(const Index: Integer): IPackerMap;
    function UnpackBoolean(const Index: Integer): Boolean;
    function UnpackVariant(const Index: Integer): Variant;
    property AsBytes: TBytes read GetAsBytes write SetAsBytes;

  end;


  ITNTConnection = interface
    ['{673B9391-0893-442E-9CD9-245F3220CF74}']
    function GetUserName: string;
    function GetHostName: string;
    function GetIsReady: boolean;
    function GetPassword: string;
    function GetPort: integer;
    function GetUseSSL: Boolean;
    function GetVersion: String;
    procedure SetHostName(const Value: string);
    procedure SetPassword(const Value: string);
    procedure SetPort(const Value: integer);
    procedure SetUserName(const Value: string);
    procedure SetUseSSL(const Value: Boolean);

    function ReadFromTarantool(AResponseGuid: TGUID): ITNTResponce;
    procedure WriteToTarantool(ACommand: ITNTCommand);

    procedure Open;
    procedure Close;
    function FindSpaceByName(ASpaceName: string): IUnknown;
    property HostName: string read GetHostName write SetHostName;
    property UserName: string read GetUserName write SetUserName;
    property Password: string read GetPassword write SetPassword;
    property Port: integer read GetPort write SetPort;
    property UseSSL: Boolean read GetUseSSL write SetUseSSL;
    property IsReady: boolean read GetIsReady;
    property Version: String read GetVersion;
    function Call(AFunctionName: string; AArguments: Variant): ITNTTuple;
  end;

  ITNTCommand = interface
    ['{FC975180-CD4F-4900-9D36-62DB2346A7EE}']
    function GetCommand: Integer;
    procedure SetRequestId(const Value: Int64);
    function GetRequestId: Int64;
    procedure PackToMessage(APacker: IPacker);
    property Command: Integer read GetCommand;
    property RequestId: Int64 read GetRequestId write SetRequestId;
  end;

  ITNTClientMessage = interface(ITNTCommand)
    ['{0420EBB8-B3C4-41BB-B6C8-88BFA34D3AA8}']
    function GetSpaceId: Int64;
    procedure SetSpaceId(const Value: Int64);

    property SpaceId: Int64 read GetSpaceId write SetSpaceId;
  end;

  ITNTClientMessageIndex = interface(ITNTClientMessage)
    ['{2D13B429-A92A-483D-9344-43A8623B17CA}']
    function GetIndexId: Int64;
    procedure SetIndexId(const Value: Int64);

    property IndexId: Int64 read GetIndexId write SetIndexId;
  end;

  ITNTClientMessageKeys = interface(ITNTClientMessageIndex)
    ['{C32C43C0-A26B-44EA-9054-85C5609B1103}']
    function GetKeys: Variant;
    procedure SetKeys(const Value: Variant);

    property Keys: Variant read GetKeys write SetKeys;
  end;

  ITNTResponce = interface
    ['{B63D9813-A4E7-41A5-9533-4394D22D1945}']
    function GetCode: integer;
    function GetRequestId: Int64;

    property Code: integer read GetCode;
    property RequestId: Int64 read GetRequestId;
  end;

  ITNTInsert = interface(ITNTClientMessage)
    ['{FC219A74-161D-425F-8A78-A7786B6EECE9}']
    function GetTuple: TBytes;
    procedure SetTuple(const Value: TBytes);
    function GetValues: Variant;
    procedure SetValues(const Value: Variant);

    property Values: Variant read GetValues write SetValues;
    property Tuple: TBytes read GetTuple write SetTuple;
  end;

  ITNTReplace = interface(ITNTInsert)
    ['{045A07F1-932E-439A-AE75-17F4E0415D03}']
  end;

  ITNTTuple = interface(ITNTResponce)
  ['{8714FDC8-7882-404F-9C5B-E16BE8F84D90}']
   function GetValues: Variant;
   function GetRowCount: Integer;
   function GetRow(Index: Integer): Variant;
   function GetItemCount(ARowIndex: Integer): Integer;

   property Values: Variant read GetValues;
   property RowCount: Integer read GetRowCount;
   property Row[Index: Integer]: Variant read GetRow;
   property ItemCount[ARowIndex: Integer]: Integer read GetItemCount;
  end;


  ITNTSelect = interface(ITNTCommand)
    ['{7A97EB0F-BD14-4728-B1FE-0E549DCA28E0}']
    procedure SetIndexId(const Value: Int64);
    procedure SetIterator(const Value: TTarantoolIterator);
    procedure SetKeys(const Value: Variant);
    procedure SetLimit(const Value: Int64);
    procedure SetOffset(const Value: Int64);
    procedure SetSpaceId(const Value: Int64);
    function GetIndexId: Int64;
    function GetIterator: TTarantoolIterator;
    function GetKeys: Variant;
    function GetLimit: Int64;
    function GetOffset: Int64;
    function GetSpaceId: Int64;

    property SpaceId: Int64 read GetSpaceId write SetSpaceId;
    property IndexId: Int64 read GetIndexId write SetIndexId;
    property Limit: Int64 read GetLimit write SetLimit;
    property Offset: Int64 read GetOffset write SetOffset;
    property Iterator: TTarantoolIterator read GetIterator write SetIterator;
    property Keys: Variant read GetKeys write SetKeys;
  end;


  ITNTSpace = interface(ITNTResponce)
  ['{3AA2D792-A0C8-426B-91D6-5A52A4EC623B}']
    procedure SetEngine(const Value: String);
    procedure SetName(const Value: string);
    procedure SetOwnerId(const Value: Int64);
    procedure SetSpaceId(const Value: Int64);
    function GetEngine: String;
    function GetFieldCount: Int64;
    function GetName: string;
    function GetOwnerId: Int64;
    function GetSpaceId: Int64;
    function Select(AIndexId: Integer; AKeys: Variant; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;
    function Select(AIndexId: Integer; AKeys: Variant; ALimit: Integer; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;
    function Select(AIndexId: Integer; AKeys: Variant; ALimit: Integer; AOffset: Integer; AIterator: TTarantoolIterator = TTarantoolIterator.Eq): ITNTTuple; overload;

    property SpaceId: Int64 read GetSpaceId write SetSpaceId;
    property OwnerId: Int64 read GetOwnerId write SetOwnerId;
    property Name: string read GetName write SetName;
    property Engine: String read GetEngine write SetEngine;
    property FieldCount: Int64 read GetFieldCount;
    function Insert(AValues: TTNTInsertValues; ATuple: TBytes): ITNTTuple; overload;
    function Insert(AValues: Variant): ITNTTuple; overload;
    function Replace(AValues: TTNTInsertValues; ATuple: TBytes): ITNTTuple; overload;
    function Replace(AValues: Variant): ITNTTuple; overload;
    function Update(AIndexId: Integer; AKeys: Variant; AUpdateDef: ITNTUpdateDefinition): ITNTTuple;
    function UpdateDefinition: ITNTUpdateDefinition;
    function Upsert(AValues: Variant; AUpdateDef: ITNTUpdateDefinition): ITNTTuple;
    procedure Delete(AIndex: Int64; AKeys: Variant);
    function Call(AFunctionName: string; AArguments: Variant): ITNTTuple;
  end;

  ITNTUpdateDefinition = interface
    ['{04B99681-2CF9-43FC-A98B-0102A94C7688}']
    procedure PackToMessage(APacker: IPackerArray);
    function AddOperation(AFieldNo: Integer; AOperation: TTNTUpdateOperationCode; AValue: Variant): ITNTUpdateDefinition;
  end;

  ITNTUpdate = interface(ITNTClientMessageKeys)
    ['{E60FA083-6993-4D6C-860D-18B0A7FFD873}']
    function GetUpdateDefinition: ITNTUpdateDefinition;
    procedure SetUpdateDefinition(const Value: ITNTUpdateDefinition);

    property UpdateDefinition: ITNTUpdateDefinition read GetUpdateDefinition write SetUpdateDefinition;
  end;

  ITNTDelete = interface(ITNTClientMessageKeys)
    ['{05B2D340-F142-49A4-88A5-511003092FCC}']
  end;

implementation

end.
