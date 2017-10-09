;Constant breathing script
;By Oscar Frias (@_frix)
;(www.oscarfrias.com)
;
;Simulate an infant's breathing.
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

(RUN FOR 2 MIN - distance = 2*rate)
g91 g1 x60
