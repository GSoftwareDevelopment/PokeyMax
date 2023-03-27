type
  TPokeyMaxConfig = record
    MODE,                             // $d210 RW
    CAPABILITY,                       // $d211 RW
    POSTDIVIDE,                       // $d212 RW
    GTIAEN,                           // $d213 RW
    VERSION,                          // $d214 R/read char W/set location
    PSGMODE,                          // $d215 RW
    SIDMODE,                          // $d216 RW
    RESTRICT:byte;                    // $d217 RW
    _RESERVED:array[0..2] of byte;    // $d218-$d21a
    _FLASH:array[0..4] of byte;       // $d21b-$d21f
  end;
