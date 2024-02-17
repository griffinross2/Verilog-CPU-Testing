fibonacci: $1000

main:   
    ; Initialize
    lda #1          ; load A with the value 1
    ldy #0          ; load Y with the value 0
    ldx #10         ; load X with the value 10
loop:
    adc fibonacci   ; add to A
    sta fibonacci   ; store the value of A
    phy             ; push the value of A onto the stack
    tay             ; transfer the value of A to Y
    pla             ; pull the value of A from the stack
    dex             ; decrement X
    biz inf         ; branch if zero to inf
    jmp loop        ; jump to loop

inf:
    jmp inf         ; infinite loop