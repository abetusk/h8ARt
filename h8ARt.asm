;    This program is free software: you can redistribute it and/or modify
;    it under the terms of the GNU General Public License as published by
;    the Free Software Foundation, either version 3 of the License, or
;    (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
; to compile and load:
; m4 demo.S > demo.asm
; avr-as -mmcu=attiny13 -o demo.o demo.asm
; avr-ld -o demo.elf demo.o
; avr-objcopy --output-target=ihex demo.elf demo.ihex
; avrdude -c usbtiny -p t13 -U flash:w:demo.ihex
;


.include "h8ARt_equ.S"

define(brz, breq)
define(brnz, brne)
define(bron, brne)


define(ss0l, r2)
define(ss0h, r3)

define(prev_vecl, r4)
define(prev_vech, r5)

define(state,r6)

define(zero, r8)

define(ss1l, r9)
define(ss1h, r10)


define(msg_led_state, r11)

define(aux_counter_l, r12)
define(aux_counter_h, r13)

define(back_bufl, r14)
define(back_bufh, r15)

define(msg_pause, r16)

define(tmp, r17)
define(t, r18)


define(msg_val, r19)
define(msg_prev_val, r20)

define(msg_shift, r21)

define(frame_copied, r22)

define(msg_frame, r23)

define(shift_counter, r24)

define(cur_vecl, r25)
define(cur_vech, r26)

define(bufl, r27)
define(bufh, r28)

define(zl, r30)
define(zh, r31)

.equ SREG, 0x3f
.equ TIMSK0, 0x39
.equ TCCR0B, 0x33
.equ PORTB,0x18
.equ DDRB ,0x17
.equ PINB, 0x16

;.equ MSG_PAUSE, 250
;.equ SHIFT_PAUSE, 250

.equ MSG_PAUSE, 130
.equ SHIFT_PAUSE, 70

.equ MSG_N, 7

.equ STATE_SHIFT, 0
.equ STATE_PROFILE, 1

.org 0x00
reset:
rjmp main        ; reset
rjmp defaultInt  ; ext_int0
rjmp defaultInt  ; pcint0
rjmp tim0_ovf    ; tim0_ovf
rjmp defaultInt  ; ee_rdy
rjmp defaultInt  ; ana_comp
rjmp defaultInt  ; tim0_compa
rjmp defaultInt  ; tim0_compb
rjmp defaultInt  ; watchdog
rjmp defaultInt  ; adc

defaultInt:
reti

;;;;; TIMER0 ON OVERFLOW
tim0_ovf:

  ;;;;;;;;;;;;;;
  ;;; save state
  push  tmp
  in    tmp, SREG
  push  tmp

  ;; msg_led_state = (msg_led_state+1)%9
  inc   msg_led_state
  ldi   tmp,9
  cp    msg_led_state,tmp
  brne  skip_led_state_mod
  ldi   tmp,0
  mov   msg_led_state,tmp
skip_led_state_mod:


  ;; Use a jump table to skip to the
  ;; appropriate section to charlieplex
  ;; the LEDs.
  ;; Each section checks the 'buf' variables
  ;; to see if the LED for that position
  ;; should be on.
  ;;
led_display_start:

  ldi   tmp, 0b00000000
  out   DDRB, tmp

  ldi   zh, pm_hi8(led_disp_jt)
  ldi   zl, pm_lo8(led_disp_jt)
  add   zl, msg_led_state
  adc   zh, zero
  ijmp

led_disp_jt:
  rjmp  disp_r0c0
  rjmp  disp_r0c1
  rjmp  disp_r0c2

  rjmp  disp_r1c0
  rjmp  disp_r1c1
  rjmp  disp_r1c2

  rjmp  disp_r2c0
  rjmp  disp_r2c1
  rjmp  disp_r2c2

disp_r0c0:

  sbrs  bufh,0
  rjmp  led_display_end

  ldi   tmp, 0b00000011
  out   DDRB, tmp
  ldi   tmp, 0b00000010
  out   PORTB, tmp

  rjmp  led_display_end

disp_r0c1:

  sbrs  bufl,7
  rjmp  led_display_end

  ldi   tmp, 0b00001001
  out   DDRB, tmp
  ldi   tmp, 0b00001000
  out   PORTB, tmp

  rjmp  led_display_end

disp_r0c2:

  sbrs  bufl,6
  rjmp  led_display_end

  ldi   tmp, 0b00010001
  out   DDRB, tmp
  ldi   tmp, 0b00010000
  out   PORTB, tmp

  rjmp  led_display_end

disp_r1c0:

  sbrs  bufl,5
  rjmp  led_display_end

  ldi   tmp, 0b00000011
  out   DDRB, tmp
  ldi   tmp, 0b00000001
  out   PORTB, tmp

  rjmp  led_display_end

disp_r1c1:

  sbrs  bufl,4
  rjmp  led_display_end

  ldi   tmp, 0b00001010
  out   DDRB, tmp
  ldi   tmp, 0b00001000
  out   PORTB, tmp

  rjmp  led_display_end

disp_r1c2:

  sbrs  bufl,3
  rjmp  led_display_end

  ldi   tmp, 0b00010010
  out   DDRB, tmp
  ldi   tmp, 0b00010000
  out   PORTB, tmp

  rjmp  led_display_end

disp_r2c0:

  sbrs  bufl,2
  rjmp  led_display_end

  ldi   tmp, 0b00001001
  out   DDRB, tmp
  ldi   tmp, 0b00000001
  out   PORTB, tmp

  rjmp  led_display_end

disp_r2c1:

  sbrs  bufl,1
  rjmp  led_display_end

  ldi   tmp, 0b00001010
  out   DDRB, tmp
  ldi   tmp, 0b00000010
  out   PORTB, tmp

  rjmp  led_display_end

disp_r2c2:

  ldi   frame_copied, 1

  sbrs  bufl,0
  rjmp  led_display_end

  ldi   tmp, 0b00011000
  out   DDRB, tmp
  ldi   tmp, 0b00010000
  out   PORTB, tmp

  rjmp  led_display_end

led_display_end:

tim0_end:

    pop   tmp
    out   SREG, tmp
    pop   tmp

reti



;;;;;;;;;;;;
;;;;
;;;; MAIN 
;;;;
;;;;;;;;;;;;
main:


  ;;;;;;;;;;;;;;;;
  ;;;;;; init

  ; All PB disabled initially
  ldi   tmp, 0x00
  out   DDRB, tmp

  ; no prescaling
  in    tmp, TCCR0B
  andi  tmp, 0xf8
  ori   tmp, 1
  out   TCCR0B, tmp

  ; enable timer interrupte
  in    tmp, TIMSK0
  ori   tmp, 2
  out   TIMSK0, tmp

  ; initialize global variables
  eor   zero, zero

  eor   frame_copied, frame_copied
  eor   bufl, bufl
  eor   bufh, bufh
  eor   msg_led_state,msg_led_state

  eor   back_bufl, back_bufl
  eor   back_bufh, back_bufh

  eor   msg_shift, msg_shift
  eor   msg_frame,msg_frame

  eor   t, t
  eor   tmp, tmp

  ;;DEBUG
  ldi   bufh, 0b00000001
  ldi   bufl, 0b01111010
  mov   back_bufh,bufh
  mov   back_bufl,bufl

  mov   cur_vecl,bufl
  mov   cur_vech,bufh
  mov   prev_vecl,cur_vecl
  mov   prev_vech,cur_vech
  ldi   shift_counter,SHIFT_PAUSE

  ; <3
  ldi   tmp,0b00000001
  mov   prev_vecl,tmp
  ldi   tmp,0b01111010
  mov   prev_vech,tmp

  ; 'k'
  ;ldi   cur_vech, 0b00000001
  ;ldi   cur_vecl, 0b01110101

  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b10101111


  ;;DEBUG


  eor   aux_counter_l, aux_counter_l
  eor   frame_copied,frame_copied
  eor   msg_val,msg_val

  eor   msg_frame,msg_frame
  eor   msg_pause,msg_pause

  sei

;;----------------------------------------------------
;;                  _                  _     _ _
;;  _ __ ___   __ _(_)_ __   __      _| |__ (_) | ___ 
;; | '_ ` _ \ / _` | | '_ \  \ \ /\ / / '_ \| | |/ _ \
;; | | | | | | (_| | | | | |  \ V  V /| | | | | |  __/
;; |_| |_| |_|\__,_|_|_| |_|___\_/\_/ |_| |_|_|_|\___|
;;                        |_____|                     
;;----------------------------------------------------
;;
main_while:

  ;; trigger on frame update
  ;;
  tst   frame_copied
  brz   main_while
  eor   frame_copied, frame_copied

  ;; load screen with back buffer
  ;;
  cli
  mov   bufh,back_bufh
  mov   bufl,back_bufl
  sei

  ;;DEBUG
  ;ldi   t,STATE_PROFILE
  ;ldi   t,STATE_SHIFT
  ;mov   state, t

  ;ldi   tmp,0b10101010
  ;mov   prev_vecl,tmp
  ;ldi   tmp,0b00000000
  ;mov   prev_vech,tmp
  ;ldi   cur_vecl,0b01010101
  ;ldi   cur_vech,0b00000001
  ;ldi   msg_shift,0
  ;ldi   shift_counter,10
  ;ldi   shift_counter,SHIFT_PAUSE
  ;;DEBUG


  ;; state test
  ;;
  mov   t,state
  cpi   t,STATE_SHIFT
  breq  state_shift

  rjmp  state_message_profile

;;---------------------------------------------
;;      _        _             _     _  __ _   
;;  ___| |_ __ _| |_ ___   ___| |__ (_)/ _| |_ 
;; / __| __/ _` | __/ _ \ / __| '_ \| | |_| __|
;; \__ \ || (_| | ||  __/ \__ \ | | | |  _| |_ 
;; |___/\__\__,_|\__\___| |___/_| |_|_|_|  \__|
;;                                             
;;---------------------------------------------

state_shift:

  ;; pause while shift
  ;;
  dec   shift_counter
  tst   shift_counter 
  breq  state_shift_cp1
  rjmp  main_while
state_shift_cp1:


  ldi   shift_counter,SHIFT_PAUSE

  mov   ss0l,prev_vecl
  mov   ss0h,prev_vech
  eor   ss0h,ss0h

  ldi   tmp,0b11011011

  ;; first shift
  ;;
  and   ss0l,tmp
  lsl   ss0l
  rol   ss0h

  ;; first state, shift once, end
  ;;
  cpi   msg_shift,0
  breq  shift_left_end

  eor   ss0h,ss0h
  ldi   tmp,0b11011011
  and   ss0l,tmp
  lsl   ss0l
  rol   ss0h

  ;; second state, shift twice, end
  ;;
  cpi   msg_shift,1
  breq  shift_left_end


;  ldi   tmp,0b11011011
;  and   ss0l,tmp
;  lsl   ss0l
;  rol   ss0h

  eor ss0l,ss0l
  eor ss0h,ss0h

shift_left_end:

  ;; clear high bits of ss0h
  ;;
  ;ldi   tmp, 0x01
  ;and   ss0h,tmp

;;------------------
;; shift right logic
;;------------------

  ;mov   ss1l,prev_vecl
  ;mov   ss1h,prev_vech

  mov   ss1l,cur_vecl
  mov   ss1h,cur_vech

  ldi   tmp,0b10110110
  cpi   msg_shift,0
  breq  right_shift_3
  cpi   msg_shift,1
  breq  right_shift_2
  cpi   msg_shift,2
  breq  right_shift_1
  rjmp  shift_right_end

right_shift_3:

  and   ss1l,tmp
  lsr   ss1h
  ror   ss1l


right_shift_2:

  and   ss1l,tmp
  lsr   ss1h
  ror   ss1l

right_shift_1:

  and   ss1l,tmp
  lsr   ss1h
  ror   ss1l

shift_right_end:

  ldi   tmp,0x01
  and   ss1h,tmp

  mov   back_bufl,ss0l
  or    back_bufl,ss1l

  mov   back_bufh,ss0h
  or    back_bufh,ss1h

  inc   msg_shift
  cpi   msg_shift,4
  brne  shift_state_end

  eor   msg_shift,msg_shift
  eor   msg_pause,msg_pause

  ldi   tmp,STATE_PROFILE
  mov   state, tmp

shift_state_end:

  rjmp  main_while

;;------------------------------------------------------
;;      _        _                          __ _ _      
;;  ___| |_ __ _| |_ ___   _ __  _ __ ___  / _(_) | ___ 
;; / __| __/ _` | __/ _ \ | '_ \| '__/ _ \| |_| | |/ _ \
;; \__ \ || (_| | ||  __/ | |_) | | | (_) |  _| | |  __/
;; |___/\__\__,_|\__\___| | .__/|_|  \___/|_| |_|_|\___|
;;                        |_|                           
;;------------------------------------------------------

state_message_profile:

;; DEBUG
;ldi   tmp,0b01000101
;mov   back_bufl,tmp
;ldi   tmp,0b00000001
;mov   back_bufh,tmp
;rjmp main_while
;; DEBUG


  ;; delay for msg_pause
  ;;
  inc   msg_pause
  cpi   msg_pause, MSG_PAUSE
  breq  continue_msg_point
  rjmp  main_while

continue_msg_point:

  ldi tmp,STATE_SHIFT
  mov state,tmp

  ;; reset msg pause
  ;;
  ldi   msg_pause, 0

  ;; msg_frame = (msg_frame+1)%N_MSG
  ;;
  inc   msg_frame
  cpi   msg_frame, MSG_N
  brne  msg_frame_mod_skip
  eor   msg_frame,msg_frame
msg_frame_mod_skip:

update_msg:

  ;;ldi   msg_pause, MSG_PAUSE

  ;; update msg_val
  ;;
  cli
  ldi   zh, pm_hi8(msg_lookup_jt)
  ldi   zl, pm_lo8(msg_lookup_jt)
  add   zl, msg_frame
  adc   zh, zero
  ijmp

msg_lookup_jt:
  rjmp  msg_0
  rjmp  msg_1
  rjmp  msg_2
  rjmp  msg_3
  rjmp  msg_4
  rjmp  msg_5
  rjmp  msg_6

  rjmp  main_while

msg_0:
  ;ldi   msg_val, 37 ; 'k'
  ;ldi   msg_val, 21 ; 'k'
  ldi   msg_val, 25 ; 'o'
  rjmp  msg__

msg_1:
  ;ldi   msg_val, 36 ; 'i'
  ;ldi   msg_val, 19 ; 'i'
  ldi   msg_val, 18 ; 'h'
  rjmp  msg__

msg_2:
  ;ldi   msg_val, 38 ; 'i'
  ;ldi   msg_val, 22 ; 'i'
  ldi   msg_val, 29 ; 's'
  rjmp  msg__

msg_3:
  ;ldi   msg_val, 36 ; 'i'
  ;ldi   msg_val, 22 ; 'i'
  ldi   msg_val, 3 ; '2'
  rjmp  msg__

msg_4:
  ;ldi   msg_val, 36 ; '*'
  ;ldi   msg_val, 37 ; '*'
  ldi   msg_val, 1 ; '0'
  rjmp  msg__

msg_5:
  ;ldi   msg_val, 36 ; '*'
  ;ldi   msg_val, 38 ; '*'
  ldi   msg_val, 2 ; '1'
  rjmp  msg__

msg_6:
  ;ldi   msg_val, 36 ; '*'
  ;ldi   msg_val, 0 ; '*'
  ldi   msg_val, 6 ; '5'
  rjmp  msg__

msg__:
  sei


  ;; save previous state (for shift logic)
  ;;
  mov   prev_vecl,cur_vecl
  mov   prev_vech,cur_vech

  ;; update cur_vec
  ;;
  cli
  ldi   zh, pm_hi8(alphanum_lookup_jt)
  ldi   zl, pm_lo8(alphanum_lookup_jt)
  add   zl, msg_val
  adc   zh, zero
  ijmp

alphanum_lookup_jt:
  rjmp  alphanum_lookup_space

  rjmp  alphanum_lookup_0
  rjmp  alphanum_lookup_1
  rjmp  alphanum_lookup_2
  rjmp  alphanum_lookup_3
  rjmp  alphanum_lookup_4
  rjmp  alphanum_lookup_5
  rjmp  alphanum_lookup_6
  rjmp  alphanum_lookup_7
  rjmp  alphanum_lookup_8
  rjmp  alphanum_lookup_9

  rjmp  alphanum_lookup_a
  rjmp  alphanum_lookup_b
  rjmp  alphanum_lookup_c
  rjmp  alphanum_lookup_d
  rjmp  alphanum_lookup_e
  rjmp  alphanum_lookup_f
  rjmp  alphanum_lookup_g
  rjmp  alphanum_lookup_h
  rjmp  alphanum_lookup_i
  rjmp  alphanum_lookup_j
  rjmp  alphanum_lookup_k
  rjmp  alphanum_lookup_l
  rjmp  alphanum_lookup_m
  rjmp  alphanum_lookup_n
  rjmp  alphanum_lookup_o
  rjmp  alphanum_lookup_p
  rjmp  alphanum_lookup_q
  rjmp  alphanum_lookup_r
  rjmp  alphanum_lookup_s
  rjmp  alphanum_lookup_t
  rjmp  alphanum_lookup_u
  rjmp  alphanum_lookup_v
  rjmp  alphanum_lookup_w
  rjmp  alphanum_lookup_x
  rjmp  alphanum_lookup_y
  rjmp  alphanum_lookup_z

  rjmp  alphanum_lookup_heart
  rjmp  alphanum_lookup_shearth
  rjmp  alphanum_lookup_sheartl

  rjmp  alphanum_lookup_space

alphanum_lookup_space:
  ldi   cur_vech, 0b00000000
  ldi   cur_vecl, 0b00000000
  rjmp  alphanum_lookup_end 

alphanum_lookup_0:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11101111
  rjmp  alphanum_lookup_end 
alphanum_lookup_1:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b10010111
  rjmp  alphanum_lookup_end 
alphanum_lookup_2:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b10010011
  rjmp  alphanum_lookup_end 
alphanum_lookup_3:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11001011
  rjmp  alphanum_lookup_end 
alphanum_lookup_4:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b00111010
  rjmp  alphanum_lookup_end 
alphanum_lookup_5:
  ;ldi   cur_vech, 0b00000000
  ;ldi   cur_vecl, 0b11010100
  ldi   cur_vech, 0b00000000
  ldi   cur_vecl, 0b11110110
  rjmp  alphanum_lookup_end 
alphanum_lookup_6:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b00110110
  rjmp  alphanum_lookup_end 
alphanum_lookup_7:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11001010
  rjmp  alphanum_lookup_end 
alphanum_lookup_8:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b10111011
  rjmp  alphanum_lookup_end 
alphanum_lookup_9:
  ldi   cur_vech, 0b00000000
  ldi   cur_vecl, 0b11011001
  rjmp  alphanum_lookup_end 

alphanum_lookup_a:
  ldi   cur_vech, 0b00000000
  ldi   cur_vecl, 0b11101111
  rjmp  alphanum_lookup_end 
alphanum_lookup_b:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b00111111
  rjmp  alphanum_lookup_end 
alphanum_lookup_c:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11100111
  rjmp  alphanum_lookup_end 
alphanum_lookup_d:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b10101110
  rjmp  alphanum_lookup_end 
alphanum_lookup_e:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11110111
  rjmp  alphanum_lookup_end 
alphanum_lookup_f:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11110100
  rjmp  alphanum_lookup_end 
alphanum_lookup_g:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11111011
  rjmp  alphanum_lookup_end 
alphanum_lookup_h:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b01111101
  rjmp  alphanum_lookup_end 
alphanum_lookup_i:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11010111
  ;ldi   cur_vecl, 0b00000000
  ;ldi   cur_vech, 0b00010010
  rjmp  alphanum_lookup_end 
alphanum_lookup_j:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11010100
  rjmp  alphanum_lookup_end 
alphanum_lookup_k:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b01110101
  rjmp  alphanum_lookup_end 
alphanum_lookup_l:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b00100111
  ;ldi   cur_vech, 0b00100110
  rjmp  alphanum_lookup_end 
alphanum_lookup_m:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b10111101
  rjmp  alphanum_lookup_end 
alphanum_lookup_n:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b10101101
  rjmp  alphanum_lookup_end 
alphanum_lookup_o:
  ldi   cur_vech, 0b00000001
  ;ldi   cur_vecl, 0b11101111
  ldi   cur_vecl, 0b10101111
  rjmp  alphanum_lookup_end 
alphanum_lookup_p:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11111100
  rjmp  alphanum_lookup_end 
alphanum_lookup_q:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11101001
  rjmp  alphanum_lookup_end 
alphanum_lookup_r:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b10101100
  rjmp  alphanum_lookup_end 
alphanum_lookup_s:
  ldi   cur_vech, 0b00000000
  ldi   cur_vecl, 0b11010110
  rjmp  alphanum_lookup_end 
alphanum_lookup_t:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b11010010
  rjmp  alphanum_lookup_end 

alphanum_lookup_u:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b01101111
  rjmp  alphanum_lookup_end 
alphanum_lookup_v:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b01101010
  rjmp  alphanum_lookup_end 
alphanum_lookup_w:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b01111111
  rjmp  alphanum_lookup_end 
alphanum_lookup_x:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b01010101
  rjmp  alphanum_lookup_end 
alphanum_lookup_y:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b01010010
  rjmp  alphanum_lookup_end 
alphanum_lookup_z:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b10010011
  rjmp  alphanum_lookup_end 

alphanum_lookup_heart:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b01111010
  rjmp  alphanum_lookup_end 

alphanum_lookup_shearth:
  ldi   cur_vech, 0b00000001
  ldi   cur_vecl, 0b01010000
  rjmp  alphanum_lookup_end 

alphanum_lookup_sheartl:
  ldi   cur_vech, 0b00000000
  ldi   cur_vecl, 0b00101010
  rjmp  alphanum_lookup_end 

alphanum_lookup_end:
  sei

  rjmp  main_while

