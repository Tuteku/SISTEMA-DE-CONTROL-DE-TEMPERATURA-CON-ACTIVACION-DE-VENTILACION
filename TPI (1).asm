    LIST P=16F887
    #include "p16f887.inc"
	    
	    __CONFIG _CONFIG1, _XT_OSC & _WDTE_OFF & _MCLRE_ON & _LVP_OFF
	   
	    
	    CBLOCK	    0X20
			    NTECLA	 ;Valor de tecla apretada
			    W_TEMP
			    STATUS_TEMP	 ;Contexto
			    NTECLA1     ; Primer dígito (más reciente)
			    NTECLA2     ; Segundo dígito
			    NTECLA3 	; Tercer dígito (más antiguo)			   
			    DEL1	;Delay display
			    DEL2	;delay display
			    ESTADO      ; 0: inactivo, 1: activo
			    CLAVE_OK    ; Bandera temporal para comparación de clave
			    TEMP_ADC	; Registro donde se guarda la conversion de la temperatura
			    CONT_TMR	; 2 segundos TMR0
			    DECENAS	;Decena del valor de temperatura a transmitir
			    UNIDADES	;Unidad del valor de temperatura a transmitir
	    ENDC
	    
	    ORG		    0X00
	    GOTO	    INICIO
	    ORG		    0X04
	    GOTO	    ISR
	    ORG		    0X05
	
CONF_PORT		    MACRO
	    BANKSEL	    ANSELH	    
	    CLRF	    ANSELH		;Puerto B digital
	    MOVLW	    B'00000001'		;RA0 ANALOGICO pin del sensor LM35
	    MOVWF	    ANSEL
	    BANKSEL	    TRISA		
	    MOVLW	    B'11110001'		;Como entrada para el sensor RA0 y como salida para la multiplexacion RA1-RA3
	    MOVWF	    TRISA
	    MOVLW	    B'11110000'		;Como entrada COLUMNAS RB4-RB6 - Como salidas FILAS RB0 - RB2
	    MOVWF	    TRISB
	    BANKSEL	    WPUB
	    MOVWF	    WPUB    ;Habilitando pullup entrada portb
	    MOVWF	    IOCB    ;Habilitando interrupciones portb
	    CLRF	    TRISD   ;Port d salida segmentos display
	    MOVLW	    B'11011000'
	    MOVWF	    TRISC   ;PORT C SALIDA ESTADOS
	    BANKSEL	    PORTD
	    CLRF	    PORTD
	    MOVLW	    B'00000001'
	    MOVWF	    PORTC    ;Estado Desactivado al inicio
	    ENDM
CONF_TMR0		    MACRO
	    BANKSEL	    OPTION_REG
	    MOVLW	    B'00000111'	  ;PS 256, RBPU 0, INTEDG 0, TOCS 0, TOSE 0, PSA 0 
	    MOVWF	    OPTION_REG 
	    ENDM
	    
CONF_ADC		    MACRO
	    BANKSEL	    ADCON1
	    MOVLW	    B'10000000'    ; ADFM=1 (resultado justificado a la DERECHA), VDD-VSS
	    MOVWF	    ADCON1
	    BANKSEL	    ADCON0
	    MOVLW	    B'01000001'    ; Selecciona canal AN0,FOSC/8, ADC encendido
	    MOVWF	    ADCON0
	    ENDM

CONF_INT		    MACRO
	    BANKSEL	    INTCON
	    MOVLW	    B'11101000'	    ;INT. GLOBALES, POR TMR0 Y POR PORTB BANDERAS EN 0
	    MOVWF	    INTCON
	    BANKSEL	    PIE1
	    BCF		    PIE1, ADIE	   ;NO QUEREMOS INTERRUPCIONES DEL ADC NI DE LA TRANSMIISON.
	    BCF		    PIE1,TXIE    
	    BANKSEL	    PIR1
	    BCF		    PIR1, ADIF	   
	    ENDM
	    
CONF_USART		    MACRO
	    BANKSEL	    BAUDCTL
	    BCF		    BAUDCTL, BRG16  ;Transmitimos 8bits
	    BANKSEL	    SPBRG
	    MOVLW	    .25            ; Para 9600 bps con Fosc = 4 MHz y BRGH=1
	    MOVWF	    SPBRG
	    BANKSEL	    RCSTA
	    BSF		    RCSTA, SPEN	  ; Habilitamos los puertos de transmision en serie

	    BANKSEL	    TXSTA
	    BSF		    TXSTA, TXEN	    ;Habilitamos la transmision
	    BSF		    TXSTA, BRGH	    ;Velocidad rapida
	    BCF		    TXSTA, SYNC	    ;Transmision Asincrono
	    ENDM

INICIO	    
	    CONF_PORT
	    CONF_TMR0	    
	    CONF_ADC
	    CONF_USART	  
	    CONF_INT
	    CLRF	    NTECLA1
	    CLRF	    NTECLA2
	    CLRF   	    NTECLA3
	    CLRF	    TXREG
LOOP	    	    
	    CALL	    MOSTRAR_DIS
	    GOTO	    LOOP
ISR
	    MOVWF	    W_TEMP
	    SWAPF	    STATUS, W
	    MOVWF	    STATUS_TEMP
	    BTFSC	    INTCON, RBIF
	    CALL	    TECLA
	    BTFSC	    INTCON, T0IF
	    CALL	    TMR0_ISR
	    GOTO	    ISR_FIN
ISR_FIN

	    BCF		    INTCON, RBIF
	    BCF		    INTCON, T0IF
	    BANKSEL	    STATUS_TEMP
	    SWAPF	    STATUS_TEMP, W
	    MOVF	    STATUS, F
	    SWAPF	    W_TEMP, F
	    SWAPF	    W_TEMP, W
	    RETFIE
	    
TECLA
	    BCF		    STATUS, RP0
	    BCF		    STATUS, RP1
	    CLRF	    NTECLA
	    MOVLW           B'00001110'	    ;Logica utilizada para hacer el barrido por filas y detectar que columna cambio de estado
	    MOVWF	    PORTB                   
	    NOP  
TEST_COL    
	    INCF	    NTECLA, F
	    BTFSS	    PORTB,4	    ;Testea teclas de la columna 1: (1,4,7)
	    GOTO	    TECL_DELAY	    
	    INCF	    NTECLA,F	    
	    BTFSS	    PORTB,5	    ;Testea teclas de la columna 2: (2,5,8)
	    GOTO	    TECL_DELAY	    
	    INCF	    NTECLA,F        
	    BTFSS	    PORTB,6	    ;Testea teclas de la columna 3: (3,6,9)
	    GOTO	    TECL_DELAY	    
	    
TEST_FIL    
	    BTFSS	    PORTB, 2	    ;Ya se revisaron las 3 filas?
	    GOTO	    TECL_RST        ;Si, no se ha presionado ninguna tecla
	    BCF		    STATUS, C       ;No, se sigue con la siguiente Fila
	    RLF		    PORTB, F	    
	    GOTO	    TEST_COL	    

TECL_RST    
	    CLRF	    NTECLA
	    RETURN
TECL_DELAY			            ;Control Antirrebote y reactivación de tecla
Espera1	    
	    BTFSS	    PORTB,4	    ;Espera a que se suete Tecla de la Columna 1
	    GOTO	    Espera1	    
Espera2	    
	    BTFSS	    PORTB,5	    ;Espera a que se suete Tecla de la Columna 2
	    GOTO	    Espera2
Espera3	    
	    BTFSS	    PORTB,6	    ;Espera a que se suete Tecla de la Columna 3
	    GOTO	    Espera3	    
	    CLRF	    PORTB
	        
	    MOVF	    NTECLA2, W	    ; Corrimiento de dígitos anteriores
	    MOVWF	    NTECLA3
	    MOVF	    NTECLA1, W
	    MOVWF	    NTECLA2
	    MOVF	    NTECLA, W
	    MOVWF	    NTECLA1
	    CALL	    VERIFICAR_CLAVE
	    BTFSS	    CLAVE_OK, 0	    ;Volvemos con 1 si la calve es correcta con 0 si es incorrecta
	    RETURN			    				    
	    MOVF	    ESTADO, W	    ;Activamos los estados correspondientes
	    XORLW	    0x01
	    MOVWF	    ESTADO					    
	    BTFSC	    ESTADO, 0
	    CALL	    LED_VERDE
	    BTFSS	    ESTADO, 0
	    CALL	    LED_ROJO    
	    RETURN
	    
TMR0_ISR    
	    INCF	    CONT_TMR, F		;Logica del TMR0 - Delay de 2 segundos
	    MOVF	    CONT_TMR, W
	    SUBLW	    .31
	    BTFSS	    STATUS, Z
	    RETURN
	    CLRF	    CONT_TMR
	    BSF		    ADCON0, GO		;Largamos conversion del ADC
ESPERA	    BTFSC	    ADCON0, GO	    
	    GOTO	    ESPERA
	    
	    BANKSEL	    ADRESL		
	    MOVF	    ADRESL, W
	    BANKSEL	    TEMP_ADC
	    MOVWF	    TEMP_ADC	    ;Guardamos la conversion en el registro TEMP_ADC
	    NOP
	    CALL	    ENVIAR_DECIMAL  ;Llamamos a la transmision
	    MOVLW	    0x35	    ;Valor para realizar la verificacion del umbral. Si supera 26 grados Enciende el cooler, de lo contrario se apaga
	    SUBWF	    TEMP_ADC, W		
	    BTFSS	    STATUS, C		
	    GOTO	    UMBRALX
	    BTFSS	    ESTADO, 0	    ;Si supero el umbral pero estamos en estado desactivado, no prende el cooler
	    GOTO	    DESACTIVADO
	    BSF		    PORTC,2
	    RETURN
UMBRALX	    BCF		    PORTC,2
	    RETURN
DESACTIVADO BCF		    PORTC,2
	    RETURN
	      	    	  	    
MOSTRAR_DIS 
	    BSF		    PORTA, RA3	    ;Multiplexacion para mostrar los valores tecleados con delay 
	    BCF		    PORTA, RA2
	    BCF		    PORTA, RA1
	    MOVF	    NTECLA1, W
	    CALL	    TABLA
	    MOVWF	    PORTD
	    CALL	    DELAY_6ms	 
	    BCF		    PORTA, RA3
	    BSF		    PORTA, RA2
	    BCF		    PORTA, RA1
	    MOVF	    NTECLA2, W
	    CALL	    TABLA
	    MOVWF	    PORTD
	    CALL	    DELAY_6ms
	    BCF		    PORTA, RA3
	    BCF		    PORTA, RA2
	    BSF		    PORTA, RA1
	    MOVF	    NTECLA3, W
	    CALL	    TABLA
	    MOVWF	    PORTD
	    CALL	    DELAY_6ms
	    RETURN
TABLA
	    ADDWF	    PCL, F	;Tabla valores a mostrar en los display (0 a 9)
	    RETLW	    0x3F 
	    RETLW	    0x06 
	    RETLW	    0x5B 
	    RETLW	    0x4F 
	    RETLW	    0x66 
	    RETLW	    0x6D 
	    RETLW	    0x7D 
	    RETLW	    0x07 
	    RETLW	    0x7F
	    RETLW	    0x6F 

	    
DELAY_6ms	    MOVLW	    D'24'      ;Delay 6ms
	    MOVWF	    DEL1
DELAY1
	    MOVLW	    D'50'      
	    MOVWF	    DEL2
DELAY2
	    NOP
	    NOP
	    DECFSZ	    DEL2, F
	    GOTO	    DELAY2
	    DECFSZ	    DEL1, F
	    GOTO	    DELAY1
	    RETURN	


VERIFICAR_CLAVE
	    CLRF	    CLAVE_OK	    ;Algoritmo para comparar los valores tecleados con los seleccionados para la clave. En este caso 2 2 2
	    MOVF	    NTECLA1, W
	    XORLW	    0x02	   
	    BTFSS	    STATUS, Z
	    RETURN
	    MOVF	    NTECLA2, W
	    XORLW	    0x02
	    BTFSS	    STATUS, Z
	    RETURN
	    MOVF	    NTECLA3, W
	    XORLW	    0x02
	    BTFSS	    STATUS, Z
	    RETURN					  
	    BSF		    CLAVE_OK, 0
	    RETURN
LED_VERDE					    ;Estado activado
	    BCF		    PORTC,0
	    BSF		    PORTC,1
	    RETURN
LED_ROJO					    ;Estado desactivado
	    BSF		    PORTC,0
	    BCF		    PORTC,1
	    RETURN
ENVIAR_DECIMAL
	    
	    BCF		    STATUS, C
	    RRF		    TEMP_ADC, W
	    MOVWF	    UNIDADES        ; Guardar la conversion del ADC para mostrar las unidades correspondientes a los grados medidos por el sensor	    
	    CLRF	    DECENAS	    ; Decenas a mostrar
DIV_LOOP    MOVLW	    .10	    
	    SUBWF	    UNIDADES, W     
	    BTFSS	    STATUS, C
	    GOTO	    FIN_DEC
	    MOVWF	    UNIDADES
	    INCF	    DECENAS, F
	    GOTO	    DIV_LOOP
FIN_DEC	    MOVF	    DECENAS, W
	    ADDLW	    '0'		    ;Conversion en ASCCI para la transmision
	    CALL	    TX_BYTE
	    NOP
	    
	    MOVF	    UNIDADES, W
	    ADDLW	    '0'
	    CALL	    TX_BYTE

	    NOP
	    NOP
	    MOVLW	    0x0A            ;Saltos de linea
	    CALL	    TX_BYTE
	    NOP
	    NOP
	    MOVLW	    0x0D           
	    CALL	    TX_BYTE
	    RETURN
	    

TX_BYTE
ESPERA_TX
	    BTFSS	    PIR1, TXIF   ; Espera que TXREG esté libre
	    GOTO	    ESPERA_TX
	    MOVWF	    TXREG         ; Listo para transmitir contenido de W
	    RETURN
	    END






