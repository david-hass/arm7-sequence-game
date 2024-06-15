.text /* Specify that code goes in text segment */
.code 32 /* Select ARM instruction set */
.global main /* Specify global symbol */
.global swi_handler /* Specify global symbol */

.equ IOPIN0, 0xE0028000 // buttons
.equ IOPIN1, 0xE0028010 // leds
.equ IOSET, 0x04
.equ IODIR, 0x08
.equ IOCLR, 0xC

.equ LED_0_bm, 1
.equ LED_1_bm, 2
.equ LED_2_bm, 4
.equ LED_3_bm, 8
.equ LED_4_bm, 16
.equ LED_5_bm, 32
.equ LED_6_bm, 64
.equ LED_7_bm, 128
.equ LED_ALL_bm, 255

.equ BUTTON_0_bm, 1
.equ BUTTON_1_bm, 2
.equ BUTTON_2_bm, 4
.equ BUTTON_3_bm, 8

.equ ledInit, 0
.equ ledOn, (1<<16)
.equ ledOff, (2<<16)
.equ ledToggle, (3<<16)
.equ keyInit, (4<<16)
.equ isPressed, (5<<16)
.equ delay, (6<<16)

JumpTable:
.word _ledInit
.word _ledOn
.word _ledOff
.word _ledToggle
.word _keyInit
.word _isPressed
.word _delay


Level:
.byte 1, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0
.byte 2, 4, 8, 1, 0, 0, 0, 0, 0, 0, 0, 0
.byte 1, 1, 8, 8, 4, 1, 0, 0, 0, 0, 0, 0
.byte 8, 2, 2, 8, 1, 2, 1, 0, 0, 0, 0, 0
//.byte 1, 2, 1, 1, 1, 8, 4, 2, 0, 0, 0, 0
//.byte 2, 1, 2, 8, 8, 2, 2, 1, 1, 0, 0, 0
//.byte 2, 2, 2, 2, 1, 1, 2, 8, 8, 2, 0, 0
//.byte 8, 4, 4, 2, 8, 8, 1, 1, 2, 1, 2, 0
LevelEnd:
.word 0

main:
  ldr r1, =Level
  ldr r9, =LevelEnd
  swi ledInit|LED_ALL_bm

  game:
  swi delay
  swi delay
  mov r2, #0
  loopComputer:
    ldrb r0, [r1]
    add r1, #1
    cmp r0, #0
    swine ledToggle
    swine delay
    swine ledToggle
    swine delay
    add r2, #1
    cmp r2, #12
    bne loopComputer

  sub r1, r2
  mov r2, #0
  loopPlayer:
    ldrb r3, [r1]
    add r1, #1
    cmp r3, #0
    beq skip

    bl getInput

    cmp r10, r3
    mov r0, r10
    swi ledToggle
    swi delay
    swi ledToggle
    bne loss

    skip:
    add r2, #1
    cmp r2, #12
    mov r10, #0
    bne loopPlayer

    bl levelPassed
    cmp r1, r9
    bne game

  b win


  getInput:
    swi isPressed|BUTTON_0_bm
    cmp r10, #0
    bxne lr
    swi isPressed|BUTTON_1_bm
    cmp r10, #0
    bxne lr
    swi isPressed|BUTTON_2_bm
    cmp r10, #0
    bxne lr
    swi isPressed|BUTTON_3_bm
    cmp r10, #0
    bxne lr
    b getInput

  levelPassed:
    swi ledOff|LED_ALL_bm
    swi ledOn|LED_0_bm|LED_2_bm|LED_4_bm|LED_6_bm
    swi delay
    swi ledToggle|LED_ALL_bm
    swi delay
    swi ledOff|LED_ALL_bm
    bx lr
    
win:
    swi ledOff|LED_ALL_bm
    swi ledToggle|LED_ALL_bm
    swi delay
    swi ledToggle|LED_ALL_bm
    swi delay
    swi ledToggle|LED_ALL_bm
    swi delay
    swi ledToggle|LED_ALL_bm
    swi delay
    bl getInput
    b main

loss:
    swi ledOn|LED_ALL_bm
    bl getInput
    swi ledOff|LED_ALL_bm
    b main



swi_handler:
    stmfd sp!,{r0-r3,lr}

    ldr r3,[lr,#-4] // get swi opcode

    bic r3,r3,#0xff000000 // remove instruction

    and r1,r3, #0x00ff0000 // extract function id

    ands r2,r3,#0xff // extract maybe param
    movne r0,r2 // if param store in r0

    ldr r2,=JumpTable
    ldr r3,[r2,r1,LSR#14] // make call address
    mov lr, pc
    add lr, #4
    bx r3
    ldmfd sp!,{r0-r3,pc}^ // ^ restore spsr

_ledInit:
    push {r1,r2}
    lsl r0, #16
    ldr r1,=(IOPIN1+IODIR)
    ldr r2, [r1]
    orr r0, r2
    str r0,[r1]
    pop {r1,r2}
    bx lr

_ledOn:
    push {r1,r2}
    lsl r0, #16
    ldr r1,=(IOPIN1+IOSET)
    ldr r2, [r1]
    orr r0, r2
    str r0,[r1]
    pop {r1,r2}
    bx lr

_ledOff:
    push {r1,r2}
    lsl r0, #16
    ldr r1,=(IOPIN1+IOCLR)
    ldr r2, [r1]
    orr r0, r2
    str r0,[r1]
    pop {r1,r2}
    bx lr

_ledToggle:
    push {r1,r2}
    ldr r1,=(IOPIN1+IOSET)
    ldr r2, [r1]
    lsr r2, #16
    mvn r1, r2
    and r1, r0
    and r0, r2
    push {lr}
    bl _ledOff
    mov r0, r1
    bl _ledOn
    pop {lr}
    pop {r1,r2}
    bx lr

_keyInit:
    push {r1,r2}
    lsl r0, #10
    ldr r1,=(IOPIN0+IODIR)
    ldr r2, [r1]
    bic r2, r2, r0
    str r2,[r1]
    pop {r1,r2}
    bx lr

_isPressed:
    push {r1,r2}
    lsl r0, #10
    ldr r1,=IOPIN0
    ldr r2, [r1]
    ands r2, r0
    moveq r10, r0, lsr#10
    movne r10, #0
    pop {r1,r2}
    bx lr
     
_delay:
    push {r0}
    ldr r0, =9999999
    innerdelay:
        adds r0,#-1
        bne innerdelay
    pop {r0}
    bx lr

.end
