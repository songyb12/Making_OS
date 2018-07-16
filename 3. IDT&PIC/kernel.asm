#include "init2.inc"

[org 0x10000]
[bits 32]
; http://kcats.tistory.com/169 이쪽이 더 설명 잘 되어 있다.
PM_Start:
	mov bx, SysDataSelector
	mov ds, bx
	mov es, bx
	mov fs, bx
	mov gs, bx
	mov ss, bx
	
	lea esp, [PM_Start]
	
	mov edi, 0
	lea esi, [msgPMode]
	call printf
	
	cld
	mov ax, SysDataSelector
	mov es, ax						; Extra Segment에 SysDataSelector를 복사.
	xor eax, eax					; EAX와 ECX를 0으로 초기화.
	xor ecx, ecx
	mov ax, 256						; IDT에서 디스크립터 갯수가 256이므로 256으로 초기화하고, edi를 0으로 초기화한다.
	mov edi, 0						; EDI : Extended Destination Index.
	
	; 완전한 IDT의 크기는 2KB = 256개 * 8Byte
	; mov : 좌변에 우변(혹은 상수)의 값을 입력하는 것.
	; lea : 좌변(레지스터)에 우변의 주소값을 입력하는 것.
loop_idt:							; 256개의 디스크립터를 초기화하기 위함.
	lea esi, [idt_ignore]			; ESI : Extended Source Index
	mov cx, 8						; Counter Register. 디스크립터 1개는 8 Byte이다.
	rep movsb						; Repeat Move Single Byte.
									; ECX의 값 만큼 ESI가 가리키는 곳에 EDI의 값을 바이트 단위로 복사한다. (cx가 8이므로 8Byte씩)
	dec ax							; 256였던 ax가 0이 되면 다음으로 진행.
	jnz loop_idt
	; 요약하자면, idt_ignore이 가리키는 주소에 8Byte씩 EDI(0)을 붙여넣는다.  256번 반복한다.
	; idt_ignore는 디스크립터이다. idt_ignore 디스크립터를 0으로 초기화를 하면.. ignore가 아니게 되어서 다음 isr_ignore에 접근하는 것이 아닐까 추정.
	
	mov edi, 8*0x20					; 타이머 IDT 디스크립터를 복사한다.
	lea esi, [idt_timer]
	mov cx, 8
	rep movsb
	
	mov edi, 8*0x21					; 키보드 IDT 디스크립터를 복사한다.
	lea esi, [idt_keyboard]
	mov cx, 8
	rep movsb
	
	
	lidt[idtr]						; 지금까지 등록된 IDT를 레지스터에 등록한다.
	
	mov al, 0xFC					; 막아두었던 인터럽트 중에
	out 0x21, al					; 타이머와 키보드만 다시 유효하게 한다.
	sti
	
	jmp $
	
	
;****************************************************
;*********************Subroutines********************
;****************************************************


printf:
	push eax
	push es
	mov ax, VideoSelector
	mov es, ax
	
printf_loop:
	mov al, byte [esi]
	mov byte [es:edi], al
	inc edi
	mov byte [es:edi], 0x06
	inc esi
	inc edi
	or al, al
	jz printf_end
	jmp printf_loop
	
printf_end:
	pop es
	pop eax
	ret
	
;****************************************************
;*********************Data Area**********************
;****************************************************

msgPMode db "We are in Protected Mode", 0
msg_isr_ignore db "This is an ignorable interrupt", 0
msg_isr_32_timer db ".This is he timer interrupt", 0
msg_isr_33_keyboard db ".This is the keyboard interrupt", 0

;****************************************************
;*************interrupt Service Routines*************
;****************************************************

isr_ignore:
	push gs
	push fs
	push es
	push ds
	pushad
	pushfd
	
	mov al, 0x20
	out 0x20, al
	
	mov ax, VideoSelector
	mov es, ax
	mov edi, (80*7*2)
	lea esi, [msg_isr_ignore]
	call printf
	
	popfd
	popad
	pop ds
	pop es
	pop fs
	pop gs
	
	iret
	
isr_32_timer:
	push gs
	push fs
	push es
	push ds
	pushad
	pushfd
	
	mov al, 0x20
	out 0x20, al
	
	mov ax, VideoSelector
	mov es, ax
	mov edi, (80*2*2)
	lea esi, [msg_isr_32_timer]
	call printf
	inc byte [msg_isr_32_timer]
	
	popfd
	popad
	pop ds
	pop es
	pop fs
	pop gs
	
	iret
	
isr_33_keyboard:
	pushad
	push gs
	push fs
	push es
	push ds
	pushfd
	
	in al, 0x60
	
	mov al, 0x20
	out 0x20, al
	
	mov ax, VideoSelector
	mov es, ax
	mov edi, (80*4*2)
	lea esi, [msg_isr_33_keyboard]
	call printf
	inc byte [msg_isr_33_keyboard]
	
	popfd
	pop ds
	pop es
	pop fs
	pop gs
	popad
	iret
	
;****************************************************
;************************IDT*************************
;****************************************************

idtr:
	dw 256*8-1
	dd 0

idt_ignore:					; 32 Bit	= 8 Byte = 디스크립터의 크기.
	dw isr_ignore			; 2Byte : 8 Bit. 실제로 인터럽트가 발생시 실행될 핸들러루틴 이라고들 한다. Integrated Services Router
	dw 0x08					; 2Byte : 8 Bit
	db 0					; 1Byte : 4 Bit
	db 0x8E					; 1Byte : 4 Bit
	dw 0x0001				; 2Byte : 8 Bit
  ; 1. 핸들러의 오프셋 . 즉 인터럽트 핸들러 가 수행될 오프셋 이다. 
  ; 2. 코드 세그먼트 셀렉터 (시작 주소 = 0x00000000 ) 
  ; 5. 상위 0x00010000	
idt_timer
	dw isr_32_timer
	dw 0x08
	db 0
	db 0x0E
	dw 0x0001
	
idt_keyboard
	dw isr_33_keyboard
	dw 0x08
	db 0
	db 0x8E
	dw 0x0001
	
times 512-($-$$) db 0