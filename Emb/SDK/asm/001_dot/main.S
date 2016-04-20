###########################################################################
# Sample Program for MieruEMB System v1.0
###########################################################################
     .text
     .align   2
     .globl   main
     .ent     main

main:
     .set     noreorder

     li    $3,0x900000     # $3 = vram address
     li    $2,7            # $2 = 7 (white)
     sw    $2,4288($3)     # vram[4288] = 7;
                           # (33 * 128 + 64) = 4288
$L1:
     j     $L1             # while(1);
     nop                   #

     .end     main
