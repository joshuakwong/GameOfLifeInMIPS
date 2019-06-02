# prog.s ... Game of Life on a NxN grid
#
# Needs to be combined with board.s
# The value of N and the board data
# structures come from board.s
#
# Written by Kwong Ting Hin Joshua (z5127215), August 2017

    .data
    .align 2
main_ret_save: .space 4
msg1: 
    .asciiz "# Iterations: "
msg2a: 
    .asciiz "=== After iteration "
msg2b:
    .asciiz " ==="
msg2c:
    .asciiz "\n"

    .text
    .globl main

main:
    sw      $ra,main_ret_save

    la      $a0,msg1        #printf("# Iterations: ")
    li      $v0,4
    syscall                
    li      $v0,5           #scanf("%d", &maxiters);
    syscall
    move    $s0,$v0         #$s0 = maxiters

    # first loop
    li      $s3,1           #$s3 = n = 1
    lw      $s4,N           #$t1 = N (hash defined)

    loop1:
        bgt     $s3,$s0,end_main#if (n>maxiters), goto end_main
        li      $s1,0           #$s1 = i = 0
        j       loop2

        loop2:
            bge     $s1,$s4,m_print   #if (i>=N), goto loop1
            li      $s2,0           #$s2 = j = 0
            j       loop3

            loop3:
                bge     $s2,$s4,loop3_end   #if (j>=N), goto loop2
                li      $t2,0           #$t2 = nn 
                move    $a0,$s1         #loading $s1 (i) to $a0 as argument
                move    $a1,$s2         #loading $s2 (j) to $a1 as argument
                jal     neighbours
                move    $t2,$v0         #put the return val $v0 to $t2

                # calculate board offset for board[i][j]
                mul     $t0,$s1,$s4     #row offset to $t0
                move    $t1,$s2         #col offset to $t1
                add     $t0,$t0,$t1     #total board offset
                lb      $t1,board($t0)  #load board[i][j] value to $t1
                j       if1

                if1:
                    li      $t3,1
                    bne     $t1,$t3,if2       #board[i][j] != 1, jump to if2
                    li      $t3,2
                    blt     $t2,$t3,nb0       #(nn<2), goto nb0
                    beq     $t2,$t3,nb1       #(nn==2), goto nb1
                    li      $t3,3
                    beq     $t2,$t3,nb1       #(nn==3), goto nb1
                    j       nb0             #else goto nb0

                if2:
                    li      $t3,3
                    beq     $t2,$t3,nb1       #(nn==3), goto nb1
                    j       nb0             #else goto nb0

                nb1:
                    li      $t3,1
                    sb      $t3,newBoard($t0)
                    add     $s2,$s2,1
                    j       loop3
                nb0:
                    li      $t3,0
                    sb      $t3,newBoard($t0)
                    add     $s2,$s2,1
                    j       loop3

            loop3_end:
                addi    $s1,$s1,1       #i++
                j       loop2

        m_print:
            la      $a0,msg2a
            li      $v0,4
            syscall                 #printf("=== After iteration")
            move    $a0,$s3
            li      $v0,1
            syscall                 #print n using %d
            la      $a0,msg2b
            li      $v0,4
            syscall                 #printf("===")
            la      $a0,msg2c
            li      $v0,4
            syscall                 #printf("\n")
            jal     copyBackAndShow
            addi    $s3,$s3,1       #n++
            j       loop1

    end_main:
        lw      $ra,main_ret_save
        jr      $ra


# The other functions go here
   .data
   .align 2
nei_ret_save:
   .space 4

   .text
neighbours:
    sw      $ra,nei_ret_save
    li      $v0,0           #$v0 = nn in this function
    # load arguments to t registers
    move    $t6,$a0
    move    $t7,$a1
    li      $t8,-1          #$t8 = x
    loop4:
        li      $t3,1
        bgt     $t8,$t3,end_neigh
        li      $t9,-1          #$t9 = y
        j       loop5

        loop5:
            li      $t3,1
            bgt     $t9,$t3,loop4_end
            add     $t3,$s4,-1          #$t3 = N-1
            add     $t4,$t6,$t8         #$t4 = i+x
            blt     $t4,$zero,loop5_end #continue statement
            bgt     $t4,$t3,loop5_end   #continue statement

            add     $t5,$t7,$t9         #$t5 = j+y
            blt     $t5,$zero,loop5_end #continue statement
            bgt     $t5,$t3,loop5_end   #continue statement

            bnez    $t8,nei_else        #(x != 0)check next condt
            bnez    $t9,nei_else        #(y != 0)continue statement
            j       loop5_end

        nei_else:   
            # access board, life.c:46
            mul     $t0,$t4,$s4     #save row offset to $t0
            add     $t0,$t0,$t5     #use $t5 for col offset since each char is 1 byte
            lb      $t0,board($t0)  #$t0 = board[i+x][j+y] value
            li      $t3,1
            bne     $t0,$t3,loop5_end #to loop 5 if board[i+x][j+y] != 1
            add     $v0,$v0,1       #nn++
            j       loop5_end

        loop5_end:
            add     $t9,$t9,1       #y++
            j       loop5


    loop4_end:
        add     $t8,$t8,1       #x++
        j       loop4

end_neigh:
    lw      $ra,nei_ret_save
    jr      $ra



   .data
   .align 2
copy_ret_save:
   .space 4
cpy_msg_dot:
    .asciiz "."
cpy_msg_hash:
    .asciiz "#"
cpy_msg_nl:
    .asciiz "\n"

   .text
copyBackAndShow:
    sw      $ra,copy_ret_save
    li      $t6,0           #$t6 = 0
loop6:
    bge     $t6,$s4,end_cpy
    li      $t7,0           #$t7 = 0
    j       loop7

    loop7:
        bge     $t7,$s4,loop6_end
        mul     $t4,$t6,$s4     #save row offset to $t4
        add     $t4,$t4,$t7     #add col offset to $t4 as TOTAL offset 
                                #since each char is 1 byte
        lb      $t5,newBoard($t4)#$t5 = newBoard[i][j] value
        sb      $t5,board($t4)
        #lb      $t5,board($t4)
        beqz    $t5,cp_print_dot
        j       cp_print_hash
    
        cp_print_dot:
            la      $a0,cpy_msg_dot
            li      $v0,4
            syscall
            j       loop7_end

        cp_print_hash:
            la      $a0,cpy_msg_hash
            li      $v0,4
            syscall
            j       loop7_end
    
    loop7_end:
        add     $t7,$t7,1       #j++
        j       loop7


    loop6_end:
        la      $a0,cpy_msg_nl
        li      $v0,4
        syscall
        add     $t6,$t6,1       #i++
        j       loop6

end_cpy:
    lw      $ra,copy_ret_save
    jr      $ra
