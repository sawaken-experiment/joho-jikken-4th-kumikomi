###########################################################################
# Sample Program for MieruEMB System v1.0
###########################################################################
     .text
     .align   2
     .globl   main
     .ent     main

main:
     .set     noreorder

     li    $3, 0x900000    # $3 = vram address
     li    $4, 0x80010c    # $4 = timer adress
     li    $6, 0           # black color code
     li    $7, 7           # white color code
     li    $11, 6400       # starting point
     li    $12, 6527       # ending point
     li    $13, 6400       # now point x (initialized $11, range is $11~$12)
     li    $15, 0          # tmp for draw point

to_right_remove_prev:
     addi  $15, $13, -1 
     blt   $15, $11, to_right_draw_point  # don't remove if x - 1 < $11
     add   $15, $15, $3                   # remove point = point[x-1]
     sb    $6, 0($15)                     # remove

to_right_draw_point:     
     add   $15, $13, $3    # draw point = point[x]
     sb    $7, 0($15)      # draw
     addi  $15, $15, 1     # draw point = point[x + 1]
     sb    $7, 0($15)      # draw
     jal   sleep
     nop     	
     addi  $13, $13, 1                    # x++
     blt   $13, $12, to_right_remove_prev # continue to right if x < $12
     nop

to_left_remove_prev:
     addi  $15, $13, 1 
     bgt   $15, $12, to_left_draw_point   # don't remove if x + 1 > $12
     add   $15, $15, $3                   # remove point = point[x+1]
     sb    $6, 0($15)                     # remove

to_left_draw_point:     
     add   $15, $13, $3    # draw point = point[x]
     sb    $7, 0($15)      # draw
     addi  $15, $15, -1    # draw point = point[x - 1]
     sb    $7, 0($15)      # draw
     jal   sleep
     nop     	
     addi  $13, $13, -1                   # x--
     bgt   $13, $11, to_left_remove_prev  # continue to right if x > $11
     nop
     j     to_right_remove_prev
     nop

	
#---- SUB LOUTINE ----#

# sleep
sleep:
     lw    $8, 0($4)           # $8 = start_time
     addi  $8, $8, 10          # $8 = end_time (start_time + 10)
sleep_loop:
     lw    $9, 0($4)           # $9  = now_time
     sub   $10, $9, $8         # $10 = now_time - end_time
     blt   $10, $0, sleep_loop # jump sleep_loop if now_time < end_time
     nop
     jr    $31
     nop

     .end     main
