%include "init2.inc"
[org 0]						

jmp 07C0h:start
; x : Register, s : Segment
start:
	mov ax, cs			; Code Segment(코드의 시작주소) 를 AX(Accumulator Register)
	mov ds, ax			
	mov es, ax			; Data Seg, Extra Seg

reset:					; 플로피 디스크 리셋
	mov ax, 0
	mov dl, 0			; ax와 dl 초기화
	int 13h				; 0x13 힌터럽트 영역을 System Call
	jc reset
	
	mov ax, 0xB800
	mov es, ax
	mov di, 0
	mov ax, word [msgBack]
	mov cx, 0x7FF
	
paint:
	mov word [es:di], ax
	add di, 2
	dec cx
	jnz paint
	
read:
	mov ax, 0x1000					; ax : Accumulator Register.
	mov es, ax						; es : Extra Segment.
	mov bx, 0						; bx : Base Register. 데이터의 주소를 가리키는 포인터로 사용.
	
	mov ah, 2						; 디스크에 있는 데이터를 es:bx의 주소로
	mov al, 1						; 1 섹터를 읽을 것이다.
	mov ch, 0						; 0번재 Cylinder
	mov cl, 2						; 2번째 섹터부터 읽기 시작한다.
	mov dh, 0						; Head=0
	mov dl, 0						; Drive = 0
	int 13h							; Interrupt 0x13 : READ!!!
	
	jc read
	
	mov dx, 0x3F2					; 플로피 디스크 드라이브의 모터를 끈다.
	xor al, al						; 0X3F2 번지에 out I/O 명령을 사용하여 프로그램의 실행 도중에는 모터가 멈추도록 한다.
	out dx, al
	
	cli
	
	; PIC == Programmable Interrupt Controller. 하드웨어 인터럽트를 처리하는 역할을 한다.
	; Master - Slave 구조로 되어있다.  마스터 : 0x20, 0x21 // 슬레이브 0xA0, 0xA1
	;-----------------------------------
	; [마스터 PIC에서 인터럽트 발생]--------------
	; 마스터 PIC는 자신의 INT핀에 신호를 실어 CPU의 INT 핀에 신호를 준다.
	; CPU는 EFLAG 레지스터의 IE 비트가 1로 세트되어 인터럽트를 받을 수 있는 상황이면 /INTA를 통해 마스터 PIC에게 신호를 보내 인터럽트를 잘 받았다고 신호를 보낸다.
	; 마스터 PIC는 /INTA 신호를 받으면 몇 번째 IRQ에 연결된 장치에서 인터럽트가 발생했는지를 숫자로 DATA 버스를 통해 CPU로 보낸다.( 이 경우 숫자는 0~7)
	; CPU는 이 데이터를 참고하여 Protected Mode로 실행 중이라면 IDT에서 그 번호에 맞는 디스크립터를 찾아 인터럽트 핸들러를 실행
	; [슬레이브 PIC에서 인터럽트 발생]----------------
	; 슬레이브 PIC는 자신의 INT 핀에 신호를 실어 마스터 PIC의 IRQ 2번 핀에 인터럽트 신호를 보낸다
	; 마스터 PIC는 자신의 IRQ 핀에서 인터럽트가 발생했으므로 자신의 INT핀에 신호를 실어 CPU에게 보낸다.
	; CPU가 /INTA 신호를 줘서 잘 받았다는 것을 알면 DATA 버스에 숫자를 실어 CPU에게 몇번 째 IRQ에서 인터럽트가 발생 했는지 알림( 이 경우 숫자는 8~15)
	; 마스터 PIC의 경우와 같이 CPU가 데이터를 참고하여 인터럽트 핸들러 실행
	; 출처: http://kcats.tistory.com/169 [kcats's mindstory]
	; ----------------------------------
	
	; 인터럽트 디스크립터 테이블 : https://ko.wikipedia.org/wiki/%EC%9D%B8%ED%84%B0%EB%9F%BD%ED%8A%B8_%EC%84%9C%EC%88%A0%EC%9E%90_%ED%85%8C%EC%9D%B4%EB%B8%94
	; 하드웨어 인터럽트, 소프트웨어 인터럽트, 프로세서 예외에 의해서 IDT가 사용된다.
	; 총 256개의 인터럽트 벡터들로 이루어져있으며 처음 32개(0x0-0x1F)는 프로세서 예외용으로 예악되어있다.
	; 20~31은 Intel에서 예약해두었다.
	
	; ----------------------------------
	; 다이어그램 및 구조 참조 : https://devsdk.github.io/development/2017/07/11/InterruptHandling.html
	; ICW 레지스터 명령어 참조 : http://itguava.tistory.com/17
	
	; ICW == Initialization Command Word.
	; 하드웨어 인터럽트가 발생할 때, IRQ가 적절히 작동하도록 하기 위해서는 PIC가 가진 각 IRQ를 초기화 해 줘야한다.
	; 1부터 4까지 차례대로 루틴 실행
	; ICW1 : PIC 초기화에 사용된다.
	; ICW2 : 사용할 PIC의 IVT 베이스 어드레스를 매핑하기 위해 사용. (Interrupt VecTor).
	;		 IVT는 인터럽트를 처리할 수 있는 서비스 루틴들의 주소를 가지고 있는 공간. 이후의 IDT(Interrupt Descriptor Table)의 형태.
	;		 물리 메모리의 1024바이트에 위채 (0x0~0x3FF) . 메모리맵 참조 http://itguava.tistory.com/9
	;	     PIC에 IVT 베이스 어드레스의 위치를 보내준다.
	; ICW3 : Master와 Slave 통신시에 어떤 IRQ라인을 사용할지 알려줌
	; ICW4 : 추가 명령어
	; OCW == Operation Command Word. 사용할 때.
	
	; ICW는 4가지 초기화 명령어로 구성.
	;------------
	; 처음 마스터 ICW1은 out 0x20, 슬레이브 ICW2는 out 0xA0으로 초기화하고, 나머지 ICW2~ICW4까지는 0x21과 0xA1으로 초기화한다.
	; ㅇPIC가 사용하는 I/O Port 주소.
	; Master PIC Command : 0x20
	; Master PIC Data : 0x21
	; Slave PIC Command : 0xA0
	; Slave PIC Data : 0xA1
	; 출처: http://0x200.tistory.com/entry/4-Interrupt-와-Exception-2 [여긴 어디 난 누구]
	
	
	; out AX(B), CX		: C 레지스터의 내용을 A 레지스터가 지시하는 번지 (혹은 B 번지)로 출력.	
	
	;-----------
	; ICW1 루틴으로 시작.
	; 0x11 == 0001 0001을 al 레지스터에 복사. (AX의 하위 8 bit 레지스터)
	; 0 bit : 1로 Set 되면 PIC는 초기화하는 동안 IC4를 받을 것이다. (IC4는 0bit 값의 이름)
	; 4 BIT : 초기화 비트. 1로 Set 되면 PIC가 초기화된다.
	mov al, 0x11					; PIC 초기화.
	out 0x20, al					; I/O Port 0x20으로 al 값을 출력.
	dw 0x00eb, 0x00eb				; 0x00eb : jmp $+2 nop nop 를 기계어 코드로 번역한 것. 딜레이를 주기 위함.
	;------------
	; 0xA0(슬레이브 PIC)에게 초기화를 알린다.
	out 0xA0, al					; 슬레이브 PIC
	dw 0x00eb, 0x00eb
	;------------
	; ICW2 루틴 시작!					  IRQ의 핀을 사용하기 위해 IVT의 베이스 주소를 알려준다. IRQ의 번호에 얼마를 더해줄지를 정하는 값.
	mov al, 0x20					; 마스터 PIC 인터럽트 시작점(IVT의 베이스주소)인 0x20을 PIC에 전달. Accumulator Low
	out 0x21, al					; 0x20 이하의 인터럽트(0x0-0x1F)는 예외처리를 위해 사용된다.
	dw 0x00eb, 0x00eb
	;------------
	mov al, 0x28					; 슬레이브 PIC 인터럽트 시작점(IVT의 베이스주소)인 0x28 값을 전달. IRQ 8부터 시작이므로 앞선 값에 8을 더함.
	out 0xA1, al
	dw 0x00eb, 0x00eb
	;------------
	; ICW3 루틴 시작!
	mov al, 0x04					; 마스터 PIC의 IRQ 2번에 (0000 0100) 2번 bit
	out 0x21, al					; 슬레이브 pic가 연결되어 있다.
	dw 0x00eb, 0x00eb
	mov al, 0x02					; 슬레이브 PIC가 마스터 PIC의 (0000 0010) 1*2^1+0*2^0
	out 0xA1, al					; IRQ 2번에 연결되어 있다.
	dw 0x00eb, 0x00eb
	;------------
	; ICW4 루틴 시작!	
	mov al, 0x01					; 8086 모드를 사용한다.
	out 0x21, al
	dw 0x00eb, 0x00eb
	out 0xA1, al
	dw 0x00eb, 0x00eb
	;-----------
	; ICW 루틴 종료. 인터럽트 막음.
	mov al, 0xFF					; PIC에서 모든 인터럽트를 막는다.
	out 0xA1, al
	dw 0x00eb, 0x00eb
	mov al, 0xFB					; 마스터 PIC의 IRQ 2번을 제외한 모든 인터럽트를 막는다.
	out 0x21, al
	
	; 초기화 후 1-4 루틴인지, 1-4 루틴 후 인터럽트 막는 단계가 있는 것인지는 의문.
	lgdt[gdtr]
	
	mov eax, cr0
	or eax, 0x00000001
	mov cr0, eax
	
	jmp $+2
	nop
	nop
	
	mov bx, SysDataSelector
	mov ds, bx
	mov es, bx
	mov fs, bx
	mov gs, bx
	mov ss, bx
	
	jmp dword SysCodeSelector:0x10000
	
	msgBack db '.', 0x67
	
gdtr:
	dw gdt_end - gdt - 1	;
	dd gdt+0x7C00
	
gdt:
	dd 0, 0
	dd 0x0000FFFF ,0x00CF9A00
	dd 0x0000FFFF, 0x00CF9200
	dd 0x8000FFFF, 0x0040920B
	
gdt_end:
	times 510-($-$$) db 0
	dw 0AA55h