fibonacci: $1000

main:   
    ; Initialize
    lda #1          ; load A with the value 1
    ldy #0          ; load Y with the value 0
    ldx #10         ; load X with the value 10
loop:
    adc fibonacci   ; get the new fibonacci number  4
    sta fibonacci   ; store it                      3
    phy             ; swap Y and A                  3
    tay             ;                               2
    pla             ;                               3
    dex             ; decrement X                   3
    biz inf         ; branch if zero to inf         2 (if no branch)
    jmp loop        ; jump to loop                  2 

inf:
    jmp inf         ; infinite loop