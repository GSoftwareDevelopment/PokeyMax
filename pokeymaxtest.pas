uses CRT,POKEYMAXconf;

var
  config:TConfig;
  PMVER:String[8];
  keyb:byte absolute 764;

procedure wait4key;
begin
  keyb:=255; repeat until keyb<>255; keyb:=255;
end;

begin
  if not detectPOKEYMax then
  begin
    writeLn('Sorry, POKEYMax not found ;(');
    wait4key;
    halt;
  end;
  PMVER:=GetVersion;
  writeLn('POKEYMax ver: ',PMVER);
  fetchConfiguration(config);
  writeLn('Capability:');
  if config.capability and pmc_FLASH<>0 then
    writeLn('Possible to flash firmware & configuration');

  write('POKEY: ');
  case config.capability and pmc_POKEYS of
    pmc_POKEY_MONO: writeLn('mono (1 POKEY)');
    pmc_POKEY_STEREO: writeLn('stereo (2 POKEYs) L/R');
    pmc_POKEY_QUAD: writeLn('quad (4 POKEYs) L/R/L/R');
  end;

  if config.capability and pmc_SID<>0 then
  begin
    writeLn('2xSID support');
    write('  #1 ');
    case config.SIDMODE and sid_1_CHIPTYPE of
      0: write('8580 (linear filter) ');
    else
      write('6581 ');
    end;
    case config.SIDMODE and sid_1_DIGIFIX of
      0: writeLn('without DIGIFIX');
    else
      writeLn('with DIGIFIX');
    end;
    write('  #2 ');
    case config.SIDMODE and sid_2_CHIPTYPE of
      0: write('8580 (linear filter) ');
    else
      write('6581 ');
    end;
    case config.SIDMODE and sid_2_DIGIFIX of
      0: writeLn('without DIGIFIX');
    else
      writeLn('with DIGIFIX');
    end;
  end;

  if config.capability and pmc_PSG<>0 then
  begin
    write('2xPSG support ');
    case config.PSGMODE and psg_FREQ of
      psg_2MHz: write('@2MHz clock ');
      psg_1MHz: write('@1MHz clock ');
      psg_1_7MHz: write('@1.7MHz clock ');
    end;
    writeLn('with:');
    case config.PSGMODE and psg_VOLP of
      psg_LOGVol: write('log volume; ');
      psg_LINVol: write('linear volume; ');
    end;
    case config.PSGMODE and psg_ENV of
      psg_ENV16: write('16 step envelope; ');
      psg_ENV32: write('32 step envelope; ');
    end;
    case config.PSGMODE and psg_STEREO of
      psg_MONO: writeLn('mono output');
      psg_ABBC: writeLn('A+B B+C output');
      psg_ACBC: writeLn('A+C B+C output');
      psg_CLCR: writeLn('#1 to left, #2 to right');
    end;
  end;
  if config.capability and pmc_COVOX<>0 then
    writeLn('4xCOVOX support');
  if config.capability and pmc_SAMPLE<>0 then
    writeLn('DMA sample support');

  wait4Key;
end.