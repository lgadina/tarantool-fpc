unit Tarantool.CommanCode;
{$I Tarantool.Options.inc}
interface

const
  tncSelect  = $01;
  tncInsert  = $02;
  tncReplace = $03;
  tncUpdate  = $04;
  tncDelete  = $05;
  tncCall_16 = $06;
  tncAuth    = $07;
  tncEval    = $08;
  tncUpsert  = $09;
  tncCall    = $0a;
  // Admin command codes
  tncPing    = $40;

  // -- Value for tnccode key in response can be:
  tncOK      = $00;
  tncERROR   = $8000;

implementation

end.
