# media5.4.s:
#	Media y resto de N enteros con signo de 32 bits calculada usando
#	registros de 32 bits
#	comprobar con depurador gdb/ddd y salida printf
# SECCIÓN DE DATOS (.data, variables globales inicializadas)
.section .data
#ifndef TEST
#define TEST 1
#endif
.macro linea	# Media/Resto - Comentario
#if TEST==1		// 1/6
	.int 1, 2, 1, 2
#elif TEST==2	// -1/-6
	.int -1,-2,-1,-2
#elif TEST==3	// 2147483647/0
	.int 0x7FFFFFFF
#elif TEST==4	// -2147483648/0
	.int 0x80000000
#elif TEST==5	// -1/0
	.int 0xFFFFFFFF
#elif TEST==6	// 2000000000/0
	.int 2000000000
#elif TEST==7	// -1294967296/0
	.int 3000000000
#elif TEST==8	// -2000000000/0
	.int -2000000000
#elif TEST==9	// 1294967296/0 Truncado
	.int -3000000000
#elif TEST==10	// 1/0
	.int 0, 2, 1, 1, 1, 1
#elif TEST==11	// 1/3
	.int 1, 2, 1, 1, 1, 1
#elif TEST==12	// 2/6
	.int 8, 2, 1, 1, 1, 1
#elif TEST==13	// 3/9
	.int 15, 2, 1, 1, 1, 1
#elif TEST==14	// 3/12
	.int 16, 2, 1, 1, 1, 1
#elif TEST==15	// -1/0
	.int 0, -2, -1, -1, -1, -1
#elif TEST==16	// -1/-3
	.int -1, -2, -1, -1, -1, -1
#elif TEST==17	// -2/-6
	.int -8, -2, -1, -1, -1, -1
#elif TEST==18	// -3/-9
	.int -15, -2, -1, -1, -1, -1
#elif TEST==19	// -3/-12
	.int -16, -2, -1, -1, -1, -1
#else
	.error "Definir TEST entre 1..19"
#endif
.endm

# formato: 	.asciz	"suma = %lu = 0x%lx hex\n"	# fmt para printf() libC 
# el string “formato” sirve como argumento a la llamada printf opcional
formato:	.ascii "\nRegistros 32 bits: \n"
			.ascii "\n\tMedia: \n"
			.ascii "\t\t = %d (sgn) = 0x%x  hex\n"
			.ascii "\tResto: \n"
			.asciz "\t\t= %d (sgn) = 0x%x hex\n"
lista: .irpc i, 123
		linea
	.endr
#lista:		.int 0xffffffff, 1	# ejs. binario 0b / hex 0x
longlista:	.int   (.-lista)/4	# . = contador posiciones. Aritm.etiq.
media:	.int   0				
resto:	.int   0
# formato: 	.asciz	"suma = %lu = 0x%lx hex\n"	# fmt para printf() libC 
# el string “formato” sirve como argumento a la llamada printf opcional

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
	mov $lista, %rbx	# dirección del array lista
	mov longlista, %ecx	# número de elementos a sumar
	call suma		# == suma(&lista, longlista);
	mov %eax, media	# Guardo cociente de la división
	mov %edx, resto # Guardo resto de la división

	ret

# SUBRUTINA: suma(int* lista, int longlista);
# entrada: 	1) %rbx = dirección inicio array
#			2) %rcx = número de elementos a sumar
# salida:	%eax = resultado de la suma
suma:
	mov $0, %eax		# poner a 0 registro de bits menos significativos
	mov $0, %edx 		# poner a 0 registro de bits más significativos
	mov $0, %esi		# poner a 0 acumulador de bits menos significativos
	mov $0, %edi		# poner a 0 acumulador de bits más significativos
	mov $0, %ebp		# poner a 0 indice de bucle
bucle:
	mov (%ebx,%ebp,4), %eax   # Copio el valor i-ésimo al registro
	cdq                 # Transforma el registro %EAX
                        # en EDX:EAX con extensión de signo
  	add %eax, %esi     	# Acumulo parte menos significativa con add
  	adc %edx, %edi    	# Acumulo la parte más significativa con adc

  	inc %ebp        	# Incremento cnt
  	cmp %ebp, %ecx  	# Comparación del indice y el numero de elementos de la lista
	jne bucle         	# Si son iguales repito bucle

  	mov %edi, %edx      # Cuando acaba copia los acumuladores 
	mov %esi, %eax 		# en los registros que necesitamos --> EDX:EAX

	idiv %ecx			#División con signo de EDX:EAX entre el numero de elementos en la lista
						#El cociente se almacena en %EAX
						#El resto se almacena en %EDX
	ret

imprim_C:			# requiere libC
# si se usa esta subrutina, usar también la línea que define formato
# se puede linkar con ld –lc –dyn ó gcc –nostartfiles, o usar main
	mov	$formato, %rdi	# traduce resultado a decimal/hex
	mov	media, %esi		# versión libC de syscall __NR_write
	mov media,%edx		# ventaja: printf() con fmt "%u" / "%x"
	mov resto,%ecx
	mov resto,%r8d
	call printf			# == printf(formato, res, res);
	mov $0,%rax			# varargin sin xmm
	
	ret

acabar_L:				# void _exit(int status);
	mov $60, %rax		# exit: servicio 60 kernel Linux
	mov $0, %edi		# status: código a retornar (la suma)
	syscall				# == _exit(resultado)
	
	ret

#acabar_C:			# requiere libC
				# void exit(int status);
#	mov  resultado, %edi	# status: código a retornar (la suma)
#	call _exit			# ==  exit(resultado)
#	ret
