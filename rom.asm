fibonacci: $1000

main:   
    ; Initialize
    lda #1          ; load A with the value 1
    ldy #0          ; load Y with the value 0
    ldx #10         ; load X with the value 10
loop:
    adc fibonacci   ; get the new fibonacci number
    sta fibonacci   ; store it
    phy             ; swap Y and A
    tay
    pla
    dex             ; decrement X
    biz inf         ; branch if zero to inf
    jmp loop        ; jump to loop

inf:
    jmp inf         ; infinite loop