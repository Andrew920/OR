# 2. Domača naloga OR
[GitHub README](https://github.com/Andrew920/OR/blob/main/README.md) | [Celotna koda na GitHub](https://github.com/Andrew920/OR/blob/main/start.s)
## Razlaga kode:

### Spremenljivke: 
``` 
poslji_t: Koda, ki bo poslana preko debug   
prejmi_t: Koda prejeta preko debug enote
kode: Morsejeva koda za posamezno črko
```

### Začetek
```
__start:  
          bl DEBUG_INIT -> Pripravimo debug enoto za uporabo
          bl INIT_IO -> Pripravimo LED za uporabo
          bl MAIN -> skočimo v glavno metodo
```

### Glavna metoda
Podatki se v zanki POSLJI pošiljajo dokler se ne zapišejo vsi podatki iz spremenljivke pošlji_t. Podatki se en za drugim zapisujejo v spremenljivko prejmi_t. To se dogaja preko debug enote, ki pošlje en podatek in ga nato prejme in zapiše. Ko so vsi podatki poslani in prejeti se pokliče ODDAJ_SIGNAL, ki nato pokliče metodo XWORD, ki poskrbi za izpis teh črk.
```
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
```

### Metoda XWORD

Prejme besedo iz prejšnje metode in jo črko po črko pošilja v metodo GETMCODE, ki nato izpisuje te črke.
```
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
```

### Metoda GETMCODE
V registru r0 prejme črko, nato najde Morse Code za to črko in naslov do te kode zapiše v register r0 in pokliče metodo XMCODE 

```
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
```

### Metoda XMCODE
V registru r0 dobi naslov do signala črke, ki jo je potrebno izpisati in v zanki kliče metodo XMCHAR, ki nato poskrbi, da se vsak znak izpiše. To ponavlja dokler se ne izpišejo vsi znaki in se nato vrne na metodo GETMCODE.

```
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
```

### Metoda XMCHAR
V registru r0 prejme znak '-' ali '.', ki ga je izpisati in ga nato izpiše v obliki dolgega prižiga LED (300 ms) ali kratkega prižiga LED (150 ms). Nato naredi še pavzo za 150 ms.

```
XMCHAR:   
          stmfd r13!, {r0, r1, r5, r14}
          
          ldrb r1, [r0]
          # Delay za piko: 150ms
          ldr r5, =0x96
          
          # Delay za crto: 300ms
          cmp r1, #46
          ldreq r5, =0x12C
          
          # Prizgi in ugasni LED
          bl LED_ON
          bl DELAY
          bl LED_OFF
          
          # Pocakaj dodatnih 150ms
          ldr r5,=0x96
          bl DELAY
          
          ldmfd r13!, {r0, r1, r5, pc}
```

### Metode LED
INIT_IO: Pripravi LED lučko na FRI SMS za uporabo.   
LED_ON: Prižge LED lučko   
LED_OFF: Ugasne LED lučko   

```
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
```

### Metoda delay
Počaka določen čas. Čas je vnesen v register r5. Notranja zanka se izvede 48000-krat kar traja 1 ms zunanja zanka se pa izvede tolikokrat kolikor smo nastavili v registru r5.
```
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
```
### Metode debug
DEBUG_INIT: Inicializira debug enoto  
RCV_DEBUG: Pošlje znak v debug enoto, ki ga prejme v register r0  
SNDD_DEBUG: Prebere znak iz debug enote in ga zapiše v r0  

```
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
```
