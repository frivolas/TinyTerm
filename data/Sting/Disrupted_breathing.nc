;Constant breathing script
;By Oscar Frias (@_frix)
;(www.oscarfrias.com)
;
;Simulate an infant's disrupted breathing:
; -run at a rate for some time,
; -pause for n seconds, then continue
; -vary the rate to something slightly different
; -come back to normal for
;
;Set the breathing rate per the following:
;
; age       |     Breaths per minute
; 0-6mo     |         30-60
; 6-12mo    |         24-30
; 1-5yr     |         20-30
;
; The init file (N_Init.json) sets the X axis to RPM,
; where 1Rrev = 1 breath


g28.3x0

(SET BREATHING RATE)
F30

(RUN FOR 30 sec - distance = rate/2)
g91 g1 x15

(pause in seconds)
g4 p3.0

(Change breathing rate)
F25

(run for 1 min - 2*rate)
g91 g1 x54

(go back to normal rate)
F30

(run for a minute - =rate)
g91 g1 x30
