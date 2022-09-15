.equ PMC_BASE,  0xFFFFFC00  /* (PMC) Base Address */
.equ CKGR_MOR,	0x20        /* (CKGR) Main Oscillator Register */
.equ CKGR_PLLAR,0x28        /* (CKGR) PLL A Register */
.equ PMC_MCKR,  0x30        /* (PMC) Master Clock Register */
.equ PMC_SR,	  0x68        /* (PMC) Status Register */

.text
.code 32

.global _error
_error:
  b _error

.global	_start
_start:

/* select system mode 
  CPSR[4:0]	Mode
  --------------
   10000	  User
   10001	  FIQ
   10010	  IRQ
   10011	  SVC
   10111	  Abort
   11011	  Undef
   11111	  System   
*/

  mrs r0, cpsr
  bic r0, r0, #0x1F   /* clear mode flags */  
  orr r0, r0, #0xDF   /* set supervisor mode + DISABLE IRQ, FIQ*/
  msr cpsr, r0     
  
  /* init stack */
  ldr sp,_Lstack_end
                                   
  /* setup system clocks */
  ldr r1, =PMC_BASE

  ldr r0, = 0x0F01
  str r0, [r1,#CKGR_MOR]

osc_lp:
  ldr r0, [r1,#PMC_SR]
  tst r0, #0x01
  beq osc_lp
  
  mov r0, #0x01
  str r0, [r1,#PMC_MCKR]

  ldr r0, =0x2000bf00 | ( 124 << 16) | 12  /* 18,432 MHz * 125 / 12 */
  str r0, [r1,#CKGR_PLLAR]

pll_lp:
  ldr r0, [r1,#PMC_SR]
  tst r0, #0x02
  beq pll_lp

  /* MCK = PCK/4 */
  ldr r0, =0x0202
  str r0, [r1,#PMC_MCKR]

mck_lp:
  ldr r0, [r1,#PMC_SR]
  tst r0, #0x08
  beq mck_lp

  /* Enable caches */
  mrc p15, 0, r0, c1, c0, 0 
  orr r0, r0, #(0x1 <<12) 
  orr r0, r0, #(0x1 <<2)
  mcr p15, 0, r0, c1, c0, 0 

.global _main
/* main program */
_main:
        .equ DBGU_BASE, 0xFFFFF200 /* Debug Unit Base Address */
        .equ DBGU_CR, 0x00  /* DBGU Control Register */
        .equ DBGU_MR, 0x04   /* DBGU Mode Register*/
        .equ DBGU_IER, 0x08 /* DBGU Interrupt Enable Register*/
        .equ DBGU_IDR, 0x0C /* DBGU Interrupt Disable Register */                          
        .equ DBGU_IMR, 0x10 /* DBGU Interrupt Mask Register */
        .equ DBGU_SR,  0x14 /* DBGU Status Register */
        .equ DBGU_RHR, 0x18 /* DBGU Receive Holding Register */
        .equ DBGU_THR, 0x1C /* DBGU Transmit Holding Register */
        .equ DBGU_BRGR, 0x20 /* DBGU Baud Rate Generator Register */

/* user code here */
          .text
          
test:     .ascii "SOS"
          .byte 0,0,0,0
          .align

poslji_t:  .ascii "SOS"
          .byte 0xc
          .align
                  
prejmi_t: .space 100
          .align

kode:     .ascii ".-"     @ A
          .byte 0,0,0,0
          .ascii "-..."     @ B
          .byte 0,0
          .ascii "–·–·"     @ C
          .byte 0,0
          .ascii "-.."     @ D
          .byte 0,0,0
          .ascii "."     @ E
          .byte 0,0,0,0,0
          .ascii "..-."     @ F
          .byte 0,0
          .ascii "--."     @ G
          .byte 0,0,0
          .ascii "...."     @ H
          .byte 0,0
          .ascii ".."     @ I
          .byte 0,0,0,0
          .ascii ".---"     @ J
          .byte 0,0
          .ascii "-.-"     @ K
          .byte 0,0,0
          .ascii ".-.."     @ L
          .byte 0,0
          .ascii "--"     @ M
          .byte 0,0,0,0
          .ascii "-."     @ N
          .byte 0,0,0,0
          .ascii "---"     @ O
          .byte 0,0,0
          .ascii ".--."     @ P
          .byte 0,0
          .ascii "--.-"     @ Q
          .byte 0,0
          .ascii ".-."     @ R
          .byte 0,0,0
          .ascii "..."     @ S
          .byte 0,0,0
          .ascii "-"     @ T
          .byte 0,0,0,0,0
          .ascii "..-"     @ U
          .byte 0,0,0
          .ascii "...-"     @ V
          .byte 0,0
          .ascii ".--"     @ W
          .byte 0,0,0
          .ascii "-..-"     @ X
          .byte 0,0
          .ascii "-.--"     @ Y
          .byte 0,0
          .ascii "--.."     @ Z
          .byte 0,0

.equ PIOC_BASE, 0xFFFFF800
.equ PIO_PER, 0x00
.equ PIO_OER, 0x10
.equ PIO_SODR, 0x30
.equ PIO_CODR, 0x34

          .align
          .global __start
__start:  
          bl DEBUG_INIT      
          bl INIT_IO
          bl MAIN          
          
          b __end

MAIN:
          adr r1, poslji_t
          adr r2, prejmi_t
POSLJI:
          ldrb r0, [r1]
          
          cmp r0, #12
          beq ODDAJ_SIGNAL
           
          bl SNDD_DEBUG
          add r1, r1, #1

          bl RCV_DEBUG
          strb r0, [r2]
          add r2, r2, #1

          b POSLJI

ODDAJ_SIGNAL:          
          bl XWORD         
         
          
XWORD:    
          adr r0, prejmi_t
XWORD_CONTINUE:          
          ldrb r1, [r0]
          cmp r1, #0
          blne GETMCODE
          add r0, r0, #1
          cmp r1, #0
          blne XWORD_CONTINUE

__end:    b __end

GETMCODE:
          stmfd r13!, {r0, r1, r2, r3, r4, r14}
          ldrb r1, [r0]
          sub r1, r1, #65
          mov r4, #6
          mul r3, r1, r4
          adr r2, kode
          add r0, r2, r3
          
          bl XMCODE
          
          ldmfd r13!, {r0, r1, r2, r3, r4, pc}   

XMCODE:   
          stmfd r13!, {r0, r1, r14}
          
XMCODE_CONTINUE:

          ldrb r1, [r0]
        
          # V primeru 0 skok nazaj v zanko
          cmp r1, #0x0

          # Klic XMCHAR
          blne XMCHAR

          add r0,r0,#1
          cmp r1, #0x0
          blne XMCODE_CONTINUE

          ldmfd r13!, {r0, r1, pc}

XMCHAR:   
          stmfd r13!, {r0, r1, r5, r14}
          
          ldrb r1, [r0]
          # Delay za piko: 150ms
          ldr r5, =0x96
          
          # Delay za crto: 300ms
          cmp r1, #45
          ldreq r5, =0x12C
          
          # Prizgi in ugasni LED
          bl LED_ON
          bl DELAY
          bl LED_OFF
          
          # Pocakaj dodatnih 150ms
          ldr r5,=0x96
          bl DELAY
          
          ldmfd r13!, {r0, r1, r5, pc}

INIT_IO:
          stmfd r13!, {r0, r2, r14}
          ldr r2, =PIOC_BASE
          mov r0, #1 << 1
          str r0, [r2, #PIO_PER]
          str r0, [r2, #PIO_OER]
          bl LED_OFF
          ldmfd r13!, {r0, r2, pc}
           
LED_ON:
          # prizgi led
          stmfd r13!, {r0, r2, r14}
          ldr r2, =PIOC_BASE
          mov r0, #1 << 1
          str r0, [r2, #PIO_CODR]
          ldmfd r13!, {r0, r2, pc} 
          
          
LED_OFF:
          # led off
          stmfd r13!, {r0, r2, r14}
          ldr r2, =PIOC_BASE
          mov r0, #1 << 1
          str r0, [r2, #PIO_SODR]
          ldmfd r13!, {r0, r2, pc}

DELAY:
          stmfd r13!, {r1, r5, r14}

DELAY_LOOP:
          ldr r1, =48000
                    
DELAY_1MS:
          sub r1, r1, #1
          cmp r1, #0
          bgt DELAY_1MS
          
          sub r5, r5, #1
          cmp r5, #0
          bgt DELAY_LOOP                    
          
          
          ldmfd r13!, {r1, r5, pc}
          
DEBUG_INIT:
      stmfd r13!, {r0, r1, r14}
      ldr r0, =DBGU_BASE
      mov r1, #26
      str r1, [r0, #DBGU_BRGR]
      mov r1, #(1 << 11)
      add r1, r1, #(0b10 << 14)
      str r1, [r0, #DBGU_MR]
      mov r1, #0b1010000
      str r1, [r0, #DBGU_CR]
      ldmfd r13!, {r0, r1, pc}
 
      
RCV_DEBUG:
      stmfd r13!, {r1, r14}
      ldr r5, =0x12C
      bl DELAY
      ldr r1, =DBGU_BASE
      ldr r0, [r1, #DBGU_RHR]
      ldmfd r13!, {r1, pc}

SNDD_DEBUG:
      stmfd r13!, {r1, r2, r14}
      ldr r5, =0x12C
      bl DELAY                                                      
      ldr r1, =DBGU_BASE
      str r0, [r1, #DBGU_THR]
      ldmfd r13!, {r1, r2, pc} 



/* end user code */

_wait_for_ever:
  b _wait_for_ever

/* constants */

_Lstack_end:
  .long __STACK_END__

.end

