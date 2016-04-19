unit tarantool.constant;

{$mode objfpc}{$H+}

interface
const
     IPROTO_REQUEST_TYPE          = $00;
     IPROTO_SYNC                  = $01;
     IPROTO_SERVER_ID             = $02;
     IPROTO_LSN                   = $03;
     IPROTO_TIMESTAMP             = $04;
     IPROTO_SCHEMA_ID             = $05;
     IPROTO_SPACE_ID              = $10;
     IPROTO_INDEX_ID              = $11;
     IPROTO_LIMIT                 = $12;
     IPROTO_OFFSET                = $13;
     IPROTO_ITERATOR              = $14;
     IPROTO_INDEX_BASE            = $15;
     IPROTO_KEY                   = $20;
     IPROTO_TUPLE                 = $21;
     IPROTO_FUNCTION_NAME         = $22;
     IPROTO_USER_NAME             = $23;
     IPROTO_SERVER_UUID           = $24;
     IPROTO_CLUSTER_UUID          = $25;
     IPROTO_VCLOCK                = $26;
     IPROTO_EXPR                  = $27;
     IPROTO_OPS                   = $28;
     IPROTO_DATA                  = $30;
     IPROTO_ERROR                 = $31;

     IPROTO_SELECT                = $01;
     IPROTO_INSERT                = $02;
     IPROTO_REPLACE               = $03;
     IPROTO_UPDATE                = $04;
     IPROTO_DELETE                = $05;
     IPROTO_CALL                  = $06;
     IPROTO_AUTH                  = $07;
     IPROTO_EVAL                  = $08;
     IPROTO_UPSERT                = $09;

     IPROTO_PING                  = $40;
     IPROTO_JOIN                  = $41;
     IPROTO_SUBSCRIBE             = $42;

     IPROTO_OK                    = $0;
     IPROTO_TYPE_ERR              = $8000;

     IPROTO_ERR_UNKNOWN                            = IPROTO_TYPE_ERR; // 0
     IPROTO_ERR_ILLEGAL_PARAMS                     = $8001;           // 1
     IPROTO_ERR_MEMORY_ISSUE                       = $8002;           // 2
     IPROTO_ERR_TUPLE_FOUND                        = $8003;           // 3
     IPROTO_ERR_TUPLE_NOT_FOUND                    = $8004;           // 4
     IPROTO_ERR_UNSUPPORTED                        = $8005;           // 5
     IPROTO_ERR_NONMASTER                          = $8006;           // 6
     IPROTO_ERR_READONLY                           = $8007;           // 7
     IPROTO_ERR_INJECTION                          = $8008;           // 8
     IPROTO_ERR_CREATE_SPACE                       = $8009;           // 9
     IPROTO_ERR_SPACE_EXISTS                       = $800A;           // 10
     IPROTO_ERR_DROP_SPACE                         = $800B;           // 11
     IPROTO_ERR_ALTER_SPACE                        = $800C;           // 12
     IPROTO_ERR_INDEX_TYPE                         = $800D;           // 13
     IPROTO_ERR_MODIFY_INDEX                       = $800E;           // 14
     IPROTO_ERR_LAST_DROP                          = $800F;           // 15
     IPROTO_ERR_TUPLE_FORMAT_LIMIT                 = $8010;           // 16
     IPROTO_ERR_DROP_PRIMARY_KEY                   = $8011;           // 17
     IPROTO_ERR_KEY_PART_TYPE                      = $8012;           // 18
     IPROTO_ERR_EXACT_MATCH                        = $8013;           // 19
     IPROTO_ERR_INVALID_MSGPACK                    = $8014;           // 20
     IPROTO_ERR_PROC_RET                           = $8015;           // 21
     IPROTO_ERR_TUPLE_NOT_ARRAY                    = $8016;           // 22
     IPROTO_ERR_FIELD_TYPE                         = $8017;           // 23
     IPROTO_ERR_FIELD_TYPE_MISMATCH                = $8018;           // 24
     IPROTO_ERR_SPLICE                             = $8019;           // 25
     IPROTO_ERR_ARG_TYPE                           = $801A;           // 26
     IPROTO_ERR_TUPLE_IS_TOO_LONG                  = $801B;           // 27
     IPROTO_ERR_UNKNOWN_UPDATE_OP                  = $801C;           // 28
     IPROTO_ERR_UPDATE_FIELD                       = $801D;           // 29
     IPROTO_ERR_FIBER_STACK                        = $801E;           // 30
     IPROTO_ERR_KEY_PART_COUNT                     = $801F;           // 31
     IPROTO_ERR_PROC_LUA                           = $8020;           // 32
     IPROTO_ERR_NO_SUCH_PROC                       = $8021;           // 33
     IPROTO_ERR_NO_SUCH_TRIGGER                    = $8022;           // 34
     IPROTO_ERR_NO_SUCH_INDEX                      = $8023;           // 35
     IPROTO_ERR_NO_SUCH_SPACE                      = $8024;           // 36
     IPROTO_ERR_NO_SUCH_FIELD                      = $8025;           // 37
     IPROTO_ERR_SPACE_FIELD_COUNT                  = $8026;           // 38
     IPROTO_ERR_INDEX_FIELD_COUNT                  = $8027;           // 39
     IPROTO_ERR_WAL_IO                             = $8028;           // 40
     IPROTO_ERR_MORE_THAN_ONE_TUPLE                = $8029;           // 41
     IPROTO_ERR_ACCESS_DENIED                      = $802A;           // 42
     IPROTO_ERR_CREATE_USER                        = $802B;           // 43
     IPROTO_ERR_DROP_USER                          = $802C;           // 44
     IPROTO_ERR_NO_SUCH_USER                       = $802D;           // 45
     IPROTO_ERR_USER_EXISTS                        = $802E;           // 46
     IPROTO_ERR_PASSWORD_MISMATCH                  = $802F;           // 47
     IPROTO_ERR_UNKNOWN_REQUEST_TYPE               = $8030;           // 48
     IPROTO_ERR_UNKNOWN_SCHEMA_OBJECT              = $8031;           // 49
     IPROTO_ERR_CREATE_FUNCTION                    = $8032;           // 50
     IPROTO_ERR_NO_SUCH_FUNCTION                   = $8033;           // 51
     IPROTO_ERR_FUNCTION_EXISTS                    = $8034;           // 52
     IPROTO_ERR_FUNCTION_ACCESS_DENIED             = $8035;           // 53
     IPROTO_ERR_FUNCTION_MAX                       = $8036;           // 54
     IPROTO_ERR_SPACE_ACCESS_DENIED                = $8037;           // 55
     IPROTO_ERR_USER_MAX                           = $8038;           // 56
     IPROTO_ERR_NO_SUCH_ENGINE                     = $8039;           // 57
     IPROTO_ERR_RELOAD_CFG                         = $803A;           // 58
     IPROTO_ERR_CFG                                = $803B;           // 59
     IPROTO_ERR_SOPHIA                             = $803C;           // 60
     IPROTO_ERR_LOCAL_SERVER_IS_NOT_ACTIVE         = $803D;           // 61
     IPROTO_ERR_UNKNOWN_SERVER                     = $803E;           // 62
     IPROTO_ERR_CLUSTER_ID_MISMATCH                = $803F;           // 63
     IPROTO_ERR_INVALID_UUID                       = $8040;           // 64
     IPROTO_ERR_CLUSTER_ID_IS_RO                   = $8041;           // 65
     IPROTO_ERR_RESERVED66                         = $8042;           // 66
     IPROTO_ERR_SERVER_ID_IS_RESERVED              = $8043;           // 67
     IPROTO_ERR_INVALID_ORDER                      = $8044;           // 68
     IPROTO_ERR_MISSING_REQUEST_FIELD              = $8045;           // 69
     IPROTO_ERR_IDENTIFIER                         = $8046;           // 70
     IPROTO_ERR_DROP_FUNCTION                      = $8047;           // 71
     IPROTO_ERR_ITERATOR_TYPE                      = $8048;           // 72
     IPROTO_ERR_REPLICA_MAX                        = $8049;           // 73
     IPROTO_ERR_INVALID_XLOG                       = $804A;           // 74
     IPROTO_ERR_INVALID_XLOG_NAME                  = $804B;           // 75
     IPROTO_ERR_INVALID_XLOG_ORDER                 = $804C;           // 76
     IPROTO_ERR_NO_CONNECTION                      = $804D;           // 77
     IPROTO_ERR_TIMEOUT                            = $804E;           // 78
     IPROTO_ERR_ACTIVE_TRANSACTION                 = $804F;           // 79
     IPROTO_ERR_NO_ACTIVE_TRANSACTION              = $8050;           // 80
     IPROTO_ERR_CROSS_ENGINE_TRANSACTION           = $8051;           // 81
     IPROTO_ERR_NO_SUCH_ROLE                       = $8052;           // 82
     IPROTO_ERR_ROLE_EXISTS                        = $8053;           // 83
     IPROTO_ERR_CREATE_ROLE                        = $8054;           // 84
     IPROTO_ERR_INDEX_EXISTS                       = $8055;           // 85
     IPROTO_ERR_TUPLE_REF_OVERFLOW                 = $8056;           // 86
     IPROTO_ERR_ROLE_LOOP                          = $8057;           // 87
     IPROTO_ERR_GRANT                              = $8058;           // 88
     IPROTO_ERR_PRIV_GRANTED                       = $8059;           // 89
     IPROTO_ERR_ROLE_GRANTED                       = $805A;           // 90
     IPROTO_ERR_PRIV_NOT_GRANTED                   = $805B;           // 91
     IPROTO_ERR_ROLE_NOT_GRANTED                   = $805C;           // 92
     IPROTO_ERR_MISSING_SNAPSHOT                   = $805D;           // 93
     IPROTO_ERR_CANT_UPDATE_PRIMARY_KEY            = $805E;           // 94
     IPROTO_ERR_UPDATE_INTEGER_OVERFLOW            = $805F;           // 95
     IPROTO_ERR_GUEST_USER_PASSWORD                = $8060;           // 96
     IPROTO_ERR_TRANSACTION_CONFLICT               = $8061;           // 97
     IPROTO_ERR_UNSUPPORTED_ROLE_PRIV              = $8062;           // 98
     IPROTO_ERR_LOAD_FUNCTION                      = $8063;           // 99
     IPROTO_ERR_FUNCTION_LANGUAGE                  = $8064;           // 100
     IPROTO_ERR_RTREE_RECT                         = $8065;           // 101
     IPROTO_ERR_PROC_C                             = $8066;           // 102
     IPROTO_ERR_UNKNOWN_RTREE_INDEX_DISTANCE_TYPE  = $8067;           // 103
     IPROTO_ERR_PROTOCOL                           = $8068;           // 104
     IPROTO_ERR_UPSERT_UNIQUE_SECONDARY_KEY        = $8069;           // 105
     IPROTO_ERR_WRONG_INDEX_RECORD                 = $806A;           // 106
     IPROTO_ERR_WRONG_INDEX_PARTS                  = $806B;           // 107
     IPROTO_ERR_WRONG_INDEX_OPTIONS                = $806C;           // 108
     IPROTO_ERR_WRONG_SCHEMA_VERSION               = $806D;           // 109
     IPROTO_ERR_SLAB_ALLOC_MAX                     = $806E;           // 110
     IPROTO_ERR_WRONG_SPACE_OPTIONS                = $806F;           // 111
     IPROTO_ERR_UNSUPPORTED_INDEX_FEATURE          = $8070;           // 112
     IPROTO_ERR_VIEW_IS_RO                         = $8071;           // 113


     IterEq            = $0;
     IterReq           = $1;
     IterAll           = $2;
     IterLt            = $3;
     IterLe            = $4;
     IterGe            = $5;
     IterGt            = $6;
     IterBitsAllSet    = $7;
     IterBitsAnySet    = $8;
     IterBitsAllNotSet = $9;


implementation

end.

