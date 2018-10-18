# media5.3.s:
#	Sumar N enteros con signo de 32 bits sobre dos registros de 32 bits
#	mediante extensión de signo
#	comprobar con depurador gdb/ddd y salida printf
# SECCIÓN DE DATOS (.data, variables globales inicializadas)
.section .data
#ifndef TEST
#define TEST 1
#endif
.macro linea	# Resultado - Comentario
#if TEST==1		
	.int -1, -1, -1, -1
#elif TEST==2	//positivo pequeño (suma cabría en sgn32b)
	.int 0x04000000, 0x04000000, 0x04000000, 0x04000000
#elif TEST==3	// positivo intermedio (sm. cabría en uns32b)
	.int 0x08000000,0x08000000,0x08000000,0x08000000
#elif TEST==4	// positivo intermedio (sm. no cabría uns32b)
	.int 0x10000000, 0x10000000, 0x10000000, 0x10000000
#elif TEST==5	// positivo grande (máximo elem. en sgn32b)
	.int 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF, 0x7FFFFFFF
#elif TEST==6	// negativo grande (mínimo elem. en sgn32b)
	.int 0x80000000, 0x80000000, 0x80000000, 0x80000000
#elif TEST==7	// negativo intermedio (no cabría en sgn32b)
	.int 0xF0000000, 0xF0000000, 0xF0000000, 0xF0000000
#elif TEST==8	// negativo pequeño (suma cabría en sgn32b)
	.int 0xF8000000, 0xF8000000, 0xF8000000, 0xF8000000
#elif TEST==9	// anterior-1 es interm. (no cabría en sgn32b)
	.int 0xF7FFFFFF, 0xF7FFFFFF, 0xF7FFFFFF, 0xF7FFFFFF
#elif TEST==10	// fácil calcular q. suma cabe sgn32b (<=2Gi-1)
	.int 100000000, 100000000, 100000000, 100000000
#elif TEST==11	// pos+gran A·10^b suma cabe uns32b (<=4Gi-1)
	.int 200000000, 200000000, 200000000, 200000000
#elif TEST==12	// pos+peq A·10^b suma no cabe uns32b(>=4Gi)
	.int 300000000, 300000000, 300000000, 300000000
#elif TEST==13	// pos+gran A·10^b reprsntble sgn32b (<=2Gi-1)
	.int 2000000000, 2000000000, 2000000000, 2000000000
#elif TEST==14	// pos+peq A·10^b no reprsntble sgn32b(>=2Gi)
	.int 3000000000, 3000000000, 3000000000, 3000000000
#elif TEST==15	// fácil calcular q. suma cabe sgn32b (>=-2Gi)
	.int -100000000, -100000000, -100000000, -100000000
#elif TEST==16	// neg+peq -A·10^b suma no cabe sgn32b(<-2Gi)
	.int -200000000, -200000000, -200000000, -200000000
#elif TEST==17	// aún menos hubiera cabido
	.int -300000000, -300000000, -300000000, -300000000
#elif TEST==18	// neg+gran A·10^b reprsntble sgn32b (>=-2Gi)
	.int -2000000000, -2000000000, -2000000000, -2000000000
#elif TEST==19	// neg+peq A·10^b no reprsntble sgn32b(<-2Gi)
	.int -3000000000, -3000000000, -3000000000, -3000000000
#else
	.error "Definir TEST entre 1..19"
#endif
.endm
# formato: 	.asciz	"suma = %lu = 0x%lx hex\n"	# fmt para printf() libC 
# el string “formato” sirve como argumento a la llamada printf opcional
formato:	.ascii "resultado \t = %18ld (sgn)\n"
			.ascii "\t\t = 0x%18lx (hex)\n"
			.asciz "\t\t = 0x %08x %08x\n"
lista: .irpc i, 1234
		linea
	.endr
longlista:	.int   (.-lista)/4	# . = contador posiciones. Aritm.etiq.
resultado:	.quad   0			#necesitamos un tipo mayor que int para 
								#almacenar un numero superior a 32 bits

# opción: 1) no usar printf, 2)3) usar printf/fmt/exit, 4) usar tb main
# 1) as  suma.s -o suma.o
#    ld  suma.o -o suma					1232 B
# 2) as  suma.s -o suma.o				6520 B
#    ld  suma.o -o suma -lc -dynamic-linker /lib64/ld-linux-x86-64.so.2
# 3) gcc suma.s -o suma -no-pie –nostartfiles		6544 B
# 4) gcc suma.s -o suma	-no-pie				8664 B

# SECCIÓN DE CÓDIGO (.text, instrucciones máquina)
.section .text		# PROGRAMA PRINCIPAL
#_start: .global _start	# se puede abreviar de esta forma
main: .global  main	# Programa principal si se usa C runtime

	call trabajar	# subrutina de usuario
	call imprim_C	# printf()  de libC
	call acabar_L	# exit()   del kernel Linux
#	call acabar_C	# exit()    de libC
	ret

trabajar:
	mov $lista, %rbx		# dirección del array lista
	mov longlista, %ecx		# número de elementos a sumar
	call suma				# == suma(&lista, longlista);
	mov %eax, resultado		# Guardo resultado
	mov %edx, resultado+4 	# Guardo acarreo en la otra mitad de resultado
	
	ret

# SUBRUTINA: suma(int* lista, int longlista);
# entrada: 	1) %rbx = dirección inicio array
#			2) %rcx = número de elementos a sumar
# salida:	%eax = resultado de la suma
suma:
	mov $0, %eax	# poner a 0 registro de bits menos significativos
	mov $0, %edx 	# poner a 0 registro de bits más significativos
	mov $0, %esi	# poner a 0 acumulador de bits menos significativos
	mov $0, %edi	# poner a 0 acumulador de bits más significativos
	mov $0, %ebp	# poner a 0 indice de bucle
bucle:
	mov (%ebx,%ebp,4), %eax   # Copio el valor i-ésimo al registro
	cdq                 # Transforma el registro %EAX
                        # en EDX:EAX con extensión de signo
  	add %eax, %esi      # Acumulo parte menos significativa con add
  	adc %edx, %edi 	    # Acumulo la parte más significativa con adc

  	inc %ebp            # Incremento cnt
  	cmp %ebp, %ecx      # Comparación del indice y el numero de elementos de la lista
	jne bucle           # Si son iguales repito bucle

  	mov %edi, %edx      # Cuando acaba copia los acumuladores 
	mov %esi, %eax 		# en los registros que necesitamos --> EDX:EAX

	ret

imprim_C:			# requiere libC
# si se usa esta subrutina, usar también la línea que define formato
# se puede linkar con ld –lc –dyn ó gcc –nostartfiles, o usar main
	mov	$formato, %rdi	# traduce resultado a decimal/hex
	mov	resultado, %rsi	# versión libC de syscall __NR_write
	mov resultado,%rdx	# ventaja: printf() con fmt "%u" / "%x"
	mov resultado+4,%ecx
	mov resultado,%r8d
	call printf			# == printf(formato, res, res);
	mov $0,%rax			# varargin sin xmm
	
	ret

acabar_L:				# void _exit(int status);
	mov $60, %rax		# exit: servicio 60 kernel Linux
	mov resultado, %edi	# status: código a retornar (la suma)
	syscall				# == _exit(resultado)
	
	ret

#acabar_C:			# requiere libC
				# void exit(int status);
#	mov  resultado, %edi	# status: código a retornar (la suma)
#	call _exit		# ==  exit(resultado)
#	ret
