###########################################################################
# Sample Program for MieruEMB System v1.0            Arch Lab. TOKYO TECH #
###########################################################################
     .text
     .globl  _start
     .ent    _start
_start:
     .set    noreorder
     .set    noat

     nop
     move    $1, $0
     move    $2, $0
     move    $3, $0
     move    $4, $0
     move    $5, $0
     move    $6, $0
     move    $7, $0
     move    $8, $0
     move    $9, $0
     move    $10, $0
     move    $11, $0
     move    $12, $0
     move    $13, $0
     move    $14, $0
     move    $15, $0
     move    $16, $0
     move    $17, $0
     move    $18, $0
     move    $19, $0
     move    $20, $0
     move    $21, $0
     move    $22, $0
     move    $23, $0
     move    $24, $0
     move    $25, $0
     move    $26, $0
     move    $27, $0
     move    $28, $0
     move    $29, $0
     move    $30, $0
     move    $31, $0
     li $sp, 0x7ff00   # stack pointer 512KB
     j      main       # jump to the main
     nop

     .end _start
