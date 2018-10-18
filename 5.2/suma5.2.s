# media5.2.s:
#	Sumar N enteros sin signo de 32 bits sobre dos registros de 32 bits
#	mediante extensión con ceros
#	comprobar con depurador gdb/ddd y salida printf
# SECCIÓN DE DATOS (.data, variables globales inicializadas)
.section .data
#ifndef TEST
#define TEST 1
#endif
.macro linea	# Resultado - Comentario
#if TEST==1		//16 – ejemplo muy sencillo
	.int 1,1,1,1
#elif TEST==2	//0xffff fff0, casi acarreo
	.int 0x0fffffff, 0x0fffffff, 0x0fffffff, 0x0fffffff
#elif TEST==3	// 16x5G= 80G >> 11 280 523 264
	.int 0x10000000,0x10000000,0x10000000,0x10000000
#elif TEST==4	// 16x5G= 80G >> 11 280 523 264
	.int 0xffffffff, 0xffffffff, 0xffffffff, 0xffffffff
#elif TEST==5	// 16x5G= 80G >> 11 280 523 264
	.int -1, -1, -1, -1
#elif TEST==6	// 16x5G= 80G >> 11 280 523 264
	.int 200000000, 200000000, 200000000, 200000000
#elif TEST==7	// 16x5G= 80G >> 11 280 523 264
	.int 300000000, 300000000, 300000000, 300000000
#elif TEST==8	// 16x5G= 80G >> 11 280 523 264
	.int 5000000000, 5000000000, 5000000000, 5000000000
#else
	.error "Definir TEST entre 1..8"
#endif
.endm
# formato: 	.asciz	"suma = %lu = 0x%lx hex\n"	# fmt para printf() libC 
# el string “formato” sirve como argumento a la llamada printf opcional
formato:	.ascii "resultado \t = %18lu (usg)\n"
									.ascii "\t\t = 0x%18lx (hex)\n"
									.asciz "\t\t = 0x %08x %08x\n"
lista: .irpc i, 1234
		linea
	.endr
longlista:	.int   (.-lista)/4	# . = contador posiciones. Aritm.etiq.
resultado:	.quad   0										#necesitamos un tipo mayor que int para
																														# almacenar un numero superior a 32 bits

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

	call trabajar					# subrutina de usuario
	call imprim_C					# printf()  de libC
	call acabar_L					# exit()   del kernel Linux
#	call acabar_C				# exit()    de libC
	ret

trabajar:
	mov $lista, %rbx						# dirección del array lista
	mov longlista, %ecx			# número de elementos a sumar
	call suma													# == suma(&lista, longlista);
	mov %eax, resultado			# Guardo resultado
	mov	%edx, resultado+4 # Guardo acarreo en la otra mitad de resultado
	ret

# SUBRUTINA: suma(int* lista, int longlista);
# entrada: 	1) %rbx = dirección inicio array
#			2) %rcx = número de elementos a sumar
# salida:	%eax = resultado de la suma
suma:
	mov $0, %eax						# poner a 0 acumulador de bits menos significativos
	mov $0, %edx 					# poner a 0 acumulador de bits más significativos
	mov $0, %esi						# poner a 0 índice
bucle:
	add (%ebx,%esi,4), %eax	# acumular i-ésimo elemento
	adc $0, %edx
	inc %esi										# Incremento el indice
	cmp %esi, %ecx	  	# Comparación del indice y el numero de elementos de la lista
	jne bucle	       	# Si son iguales repito bucle

 ret

imprim_C:			# requiere libC
# si se usa esta subrutina, usar también la línea que define formato
# se puede linkar con ld –lc –dyn ó gcc –nostartfiles, o usar main
	mov	$formato, %rdi	# traduce resultado a decimal/hex
	mov	resultado, %rsi	# versión libC de syscall __NR_write
	mov resultado,%rdx	# ventaja: printf() con fmt "%u" / "%x"
	mov resultado+4,%ecx
	mov resultado,%r8d
	call printf		# == printf(formato, res, res);
	mov 	$0,%rax	# varargin sin xmm

	ret

acabar_L:			# void _exit(int status);
	mov $60, %rax	# exit: servicio 60 kernel Linux
	mov resultado, %edi	# status: código a retornar (la suma)
	syscall			# == _exit(resultado)
	
	ret

#acabar_C:			# requiere libC
				# void exit(int status);
#	mov  resultado, %edi	# status: código a retornar (la suma)
#	call _exit		# ==  exit(resultado)
#	ret
