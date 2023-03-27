unit POKEYMAXConf;

interface

{$I pokeymax_type.inc}
{$I pokeymax_const.inc}

var
  [volatile] pmcID:byte absolute $d20c;                 // R
  [volatile] pmcCONFIG:byte absolute $d20c;             // W
  [volatile] pmcVERSION:byte absolute $d214;            // R
  [volatile] pmcVERSIONLOC:byte absolute $d214;         // W
  [volatile] pmcFLASHOP:byte absolute $d21b;            // W
  [volatile] pmcFLASHADL:byte absolute $d21d;           // W
  [volatile] pmcFLASHADH:byte absolute $d21e;           // W
  [volatile] pmcFLASHDAT:byte absolute $d21f;           // R/W
  [volatile] lifeConfig:TPokeyMaxConfig absolute $d210; // R/W

function detectPokeyMax:Boolean;
procedure ConfigMode(state:boolean);
function GetVersion:PString;
procedure FetchConfiguration(var _config:TPokeyMaxConfig);
function FlashPokeyMax(var _data; startAdr:word; size:byte; mode:byte):boolean;
procedure FlashConfiguration(var _config:TPokeyMaxConfig);

implementation

function detectPokeyMAX:boolean;
begin
  result:=(pmcID=1);
end;

{
  setup PokeyMax bank
  true - set configuration bank (at $d210)
  false - set device access (Pokey #2 if enabled)
}
procedure configMode(state:boolean);
begin
  case state of
    true: pmcConfig:=pmc_CFGEN; // enable PokeyMax config bank
    false: pmcCONFIG:=0; // just disable PokeyMax config bank
  end;
end;

function GetVersion:PString;
var
  i:byte;

begin
  configMode(true);
  result[0]:=#8;
  for i:=1 to 8 do
  begin
    pmcVERSIONLOC:=i-1;
    result[i]:=char(pmcVERSION);
  end;
  configMode(false);
end;

procedure FetchConfiguration(var _config:TPokeyMaxConfig);
begin
  configMode(true);
  move(LifeConfig,_config,sizeOf(TPokeyMaxConfig));
  configMode(false);
end;

{
  function for flash PokeyMax chip
  _data - source of data
  startAdr - begining address of flash
  size - size of data (max 256 bytes at once) and MUST be divisible by 4
  mode - FLASH_CFG for flash configuration
         FLASH_FIRMWARE for flash firmware
         FLASH_VALID for validate data
  return:
  true  - if flush is correct
  false - if not
}
function FlashPokeyMax(var _data; startAdr:word; size:byte; mode:byte):boolean;
var
  adr:Word absolute $d8;
  adrL:Byte absolute $d8;
  adrH:Byte absolute $d9;
  _fOP:byte absolute $da;
  _fAH:byte absolute $db;
  _FAL:byte absolute $dc;
  data:array[0..0] of byte;

  i:byte absolute $dd;
  win:byte absolute $de;
  phase:byte; // 0 - erase; 1 - write; 2 - check
  validate:boolean;
  _RW:byte;

  procedure setupFlash(RW:Byte);
  begin
    adr:=startAdr;
    _RW:=RW and flash_RW;

    // prepare adress
    _fOP:=(adrH and %11100000) shr 2;
    _fAH:=(adrH shl 3) or (adrL shr 2);
    _fAL:=adrL shl 2;

    // apply
    pmcFLASHOP:=_fOP or mode or _RW;
    pmcFLASHADH:=_fAH;
  end;

  {
    Make request to PokeyMax and wait until done or timeout
    return:
      false - if request is done
       true - if request is timeout
  }
  function makeRequest:boolean;
  var
    otm:byte;
    tm:byte absolute 20;

  begin
    pmcFLASHOP:=_fOP or mode or flash_REQ or _RW;
    otm:=tm;
    // wait until request is made (flasg_REQ=0) or
    // will not exceed the time
    repeat
      result:=(tm-otm)>0;
    until (pmcFLASHOP and flash_REQ<>0) or result;
  end;

begin
  validate:=(mode and FLASH_VALID)<>0;    // check validation
  mode:=mode and FLASH_CFG;               // prevent, from bad values

  data:=_data;

  for phase:=0 to 2 do                    // phase loop
  begin
    if phase<2 then                       // write/erase
      setupFlash(flash_Write)
    else
      if validate then                    // only if validate is set
        setupFlash(flash_Read)            // read
      else
        break;                            // leave loop if validate is not set

    for i:=0 to size-1 do                 // data loop
    begin
      win:=i and 3;
      if (phase=2) and (win=0) then   // phase 2 (read) - get request before read 32-bits data
        if makeRequest then exit(false);

      pmcFLASHADL:=_fAL or win;
      if phase=0 then                     // erase flash
        pmcFLASHDAT:=$FF
      else if phase=1 then                // write flash
        pmcFLASHDAT:=data[i]
      else if pmcFLASHDAT<>data[i] then   // validate (read)
        exit(false);

      if (phase<>2) and (win=3) then  // phase 0 & 1 - after each 4 bytes (32-bits) push request to PokeyMax
        if makeRequest then exit(false);

      inc(_fAL);                          // increment LSB address register (next 32-bits of data)

    end;                                  // end data loop

  end;                                    // end phase loop

  result:=true;
end;

procedure FlashConfiguration(var _config:TPokeyMaxConfig);
begin
  configMode(true);
  flashPokeyMax(_config,$0000,$10,FLASH_CFG);
  configMode(false);
end;

end.