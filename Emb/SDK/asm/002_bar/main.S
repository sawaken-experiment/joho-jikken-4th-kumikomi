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
     li    $5, 16384       # 
     li    $6, 0           # 
L1:
     srl   $7, $6, 10      # 
     sw    $7,0($3)        # 
     addi  $3, $3, 1       # 
     addi  $6, $6, 1       # 
     bne   $6, $5, L1      # 
     nop                   #

$L1:
     j     $L1             #
     nop                   #

     .end     main
