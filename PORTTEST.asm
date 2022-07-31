;.define TI83
.define TI83PLUS

.ifdef TI83
 .binarymode ti83
 .tivariabletype $05
 .unsquish
 .define bcall(xxxx) call xxxx
 #include "ti83.inc"
 .org userMem
.elseifdef TI83PLUS
 .binarymode TI8X
 #include "ti83plus.inc"
 .org userMem-2
 .db t2ByteTok,tAsmCmp
.endif

Main:
 bcall(_ClrLCDFull)
Main_InitDisp:
 ld hl,$0802
 ld (curRow),hl
 ld b,8
 Main_ShowData:
  call ReadAPort
  push af
   ld a,3
   ld (curCol),a
   call GetExpCurRow
   ld hl,MyByte
   bcall(_puts)
   xor a
   ld (curCol),a
  pop af
  call DispHex
  ld hl,MyByte
  bcall(_puts)
  djnz Main_ShowData
 WaitForKey:
  ld b,8 ; safety for now
  bcall(_GetCSC)
  cp 0
  jr z,WaitForKey
  cp skUp
  jr z,DecBase
  cp skDown
  jr z,IncBase
  cp skTrace
  jr z,PageUp
  cp skGraph
  jr z,PageDown
  cp skClear
  jr z,Exit
 ;jr Main_InitDisp
  halt
  jr WaitForKey
Exit:
 bcall(_ClrScrnFull)
 ret

IncBase:
 ld a,(FirstPort)
 cp $0ff-7
 jp nc,Main_InitDisp
 inc a
 ld (FirstPort),a
 jp Main_InitDisp

DecBase:
 ld a,(FirstPort)
 cp 0
 jp z,Main_InitDisp
 dec a
 ld (FirstPort),a
 jp Main_InitDisp

PageUp:
 ld a,(FirstPort)
 cp 8
 jp c,PageUp_Partial
 add a,$100-8
 ld (FirstPort),a
 jp Main_InitDisp
PageUp_Partial:
 xor a
 ld (FirstPort),a
 jp Main_InitDisp

PageDown:
 ld a,(FirstPort)
 cp $0ff-7-8
 jp nc,PageDown_Partial
 add a,8
 ld (FirstPort),a
 jp Main_InitDisp
PageDown_Partial:
 ld a,$0ff-7
 ld (FirstPort),a
 jp Main_InitDisp

GetExpCurRow:
 ; Initialize (curRow) to where it should be shown on screen, using b
 push af
  ld a,b
  sub 1
  ld (curRow),a
 pop af
 ret

ReadAPort:
 ; Read a port at (FirstPort)+b
 ; Put the port in a
 ; Put the data in MyByte
 ; destroys af bc
 ld a,(FirstPort)
 add a,b
 sub 1
 push af
  ld c,a
  in a,(c)
  call DispBin
 pop af
 ret
 
DispBin: ; Creates A's binary representation in MyByte
 ; Destroys none
 ; reset the string
 push af
  push bc
   push hl
    push af
     ld a,"0"
     ld b,8
     ld hl,MyByte
     DispBin_Res:
      ld (hl),a
      inc hl
      djnz DispBin_Res
     ld (hl),0
     ; set up binary display
     ld b,8
     ld c,$80
     ld hl,MyByte
    pop af
    DispBin_Loop:
     push af
      and c
      jr z,DispBin_NoIncrement
      inc (hl)
      DispBin_NoIncrement:
      srl c
      inc hl
     pop af
     djnz DispBin_Loop
   pop hl
  pop bc
 pop af
 ret

DispHex: ; Creates A's hex representation in MyByte
 ; Destroys none
 push af
  push bc
   push hl
    push af
     ld a,"0"
     ld b,2
     ld hl,MyByte
     DispHex_Res:
      ld (hl),a
      inc hl
      djnz DispHex_Res
     ld (hl),0
    pop af
    push af
     and %11110000
     rra
     rra
     rra
     rra
     cp 10
     call nc,OffsetToA
     add a,$30
     ld (MyByte),a
    pop af
    and %00001111
    cp 10
    call nc,OffsetToA
    add a,$30
    ld (MyByte+1),a
   pop hl
  pop bc
 pop af
 ret

OffsetToA:
 add a,7
 ret

MyByte:
 .db "00000000",0

FirstPort:
 .db 0

.ifdef TI83
 .squish
 .db $3F,$D4,$3F,$30,$30,$30,$30,$3F,$D4
.endif
.end