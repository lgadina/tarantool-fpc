{DEFINE DUMP_MSG_PACK}

{$IFDEF DUMP_MSG_PACK}
  {$MESSAGE WARN 'Включен дамп MessagePack'}
{$ENDIF}

{.DEFINE VARIANT_TO_JSON}

{$IFDEF VARIANT_TO_JSON}
  {$IFDEF FPC}
    {$DEFINE SUPEROBJECT}
  {$ELSE}
    {$DEFINE JSONRTL}
  {$ENDIF}
{$ENDIF}

{$IFDEF FPC}
  {$UNDEF USE_RTTI_CONTEXT}
{$ELSE}
  {$DEFINE USE_RTTI_CONTEXT}
{$ENDIF}

{$IFDEF FPC}
  {$MODESWITCH ADVANCEDRECORDS}
  {$MODESWITCH TYPEHELPERS}
  {$MODE DELPHI}
  {$INLINE ON}
  {$MINENUMSIZE 1}
  {$PACKSET 1}
  {$PACKENUM 1}

  {$define HASINLINE}
  {define USEOBJECTINSTEADOFRECORD}
  {$Q-} // disable overflow checking
  {$R-} // disable range checking

  {$ifdef VER2_7}
    {$define ISFPC27}
  {$endif}
  {$ifdef VER3_0}
    {$define ISFPC27}
  {$endif}
  {$ifdef VER3_1}
    {$define ISFPC27}
  {$endif}
  {$ifdef VER3_3}
     {$define ISFPC27}
  {$endif}


  {$ifdef ISFPC27}
    // defined if the http://mantis.freepascal.org/view.php?id=26773 bug is fixed
    // you should use 2.7.1/trunk branch in revision 28995 from 2014-11-05T22:17:54
    // => this will change the TInvokeableVariantType.SetProperty() signature
    {$define FPC_VARIANTSETVAR}
  {$endif}

{$else}

{$ifdef DWSSCRIPT} // always defined since SMS 1.1.2
  {$define ISDWS}           // e.g. for SmartMobileStudio or Delphi Web Script
  {$define ISSMS}           // for SmartMobileStudio
{$else}
  {$ifdef CONDITIONALEXPRESSIONS}  // Delphi 6 or newer
    {$ifdef NEXTGEN}
      {$ZEROBASEDSTRINGS OFF}      // we expect to share code among platforms
    {$endif NEXTGEN}
    {$ifdef UNICODE}
      {$ifdef CPUX64}
        {$define CPU64}
      {$endif}
    {$else}
      {$define USEOBJECTINSTEADOFRECORD}
    {$endif UNICODE}
    {$ifdef VER140}
      {$define ISDELPHI6}
    {$endif}
    {$if CompilerVersion >= 18}    // Delphi 2006 or newer
      {$define HASINLINE}
    {$ifend}
    {$if CompilerVersion >= 21.0}
      {$define ISDELPHI2010}
    {$ifend}
    {$if CompilerVersion >= 22.0}
      {$define ISDELPHIXE}
    {$ifend}
    {$if CompilerVersion >= 23.0}
      {$define ISDELPHIXE2} // e.g. for Vcl.Graphics
      {$ifndef MSWINDOWS}
        {$define USETMONITOR}
      {$endif}
    {$ifend}
    {$if CompilerVersion >= 25.0}
      {$define ISDELPHIXE4}
      {$ZEROBASEDSTRINGS OFF}      // we expect to share code among platforms
      {$warn DUPLICATE_CTOR_DTOR OFF} // avoid W1029 unneeded hints
    {$ifend}
    {$if CompilerVersion >= 29.0}
      {$define ISDELPHIXE8} // e.g. for System.Net.HttpClient
    {$ifend}
    {$if CompilerVersion >= 32.0}
      {$define ISDELPHI102} // e.g. for System.Net.URLClient.ResponseTimeout
    {$ifend}
  {$else}
    {$define ISDELPHI5OROLDER}
    {$define USEOBJECTINSTEADOFRECORD}
  {$endif CONDITIONALEXPRESSIONS}
  {$Q-} // disable overflow checking
  {$R-} // disable range checking
{$endif DELPHIWEBSCRIPT}

{$endif FPC}


