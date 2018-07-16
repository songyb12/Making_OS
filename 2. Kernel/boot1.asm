%include "init1.inc"


[org 0]						; 메모리의 몇 번지에서 실행해야하는지 알려주는 선언문
[bits 16]					; 이 프로그램은 16bit 단위로 데이터를 처리하는 프로그램이다.
	jmp 0x07C0:start		; 물리주소(세그먼트):상대주소(오프셋) /// 물리주소로부터 상대주소만큼 이동
							; 0x7C0인 이유 : 메모리 맵을 확인해보면, 개발자가 사용가능한 사용자 OS 부트섹터는 0x7C00부터이다. 왜 0이 한개 더 있는가?
							
							; 인텔이 8086 CPU를 개발하는 과정에서 20bit 어드레스 버스와 호환이 어려워서 16 bit 레지스터를 2개 이용하는 방식을 채택
							; 20bit 어드레스 버스의 물리주소 : 0x00000~0xfffff
							; 16bit 레지스터의 주소 : 0x0000~0xffff
							; 따라서 세그먼트 레지스터를 좌측으로 4bit 쉬프트 연산을 해 주고 0x07C0<<1 -> 0x07C00
							; 오프셋을 더해주면 0x07C05라는 20bit 물리주소를 구할 수 있다.

							; MOVE destination, source : src를 des로 복사
							; 이전까지 사용된 명령어를 기계어로 바꾸면 EA(00000000), 05(00000001), 00(00000002),
start:							; C0(00000003), 07(00000004)으로 5Byte를 이용한다. [org 0]이므로 0번지에서 5Byte 지난 0x5가 된다.
	mov ax, cs				; EAX(Extended Accumulator Register) 범용 레지스터의 반(16bit). 산술, 논리 연산시 주로 사용
							; CS(Code Segment Register). 현재 사용중인 프로그램의 코드가 저장된 세그먼트의 주소를 가리킨다. 즉 0x0000.
	mov ds, ax				; DS(Data Segment Register). 현재 프로그램이 사용중인 데이터가 저장된 세그먼트의 주소를 가리킨다.
							; AX를 통해 CS를 DS로 복사한다. 
	mov ax, 0xB800			; 메모리맵을 보면, 0xA0000부터 0xFFFFF까지가 Video Memory 영역.
							; 그 중 0xB8000영역이 컬러 텍스트 모드 비디오 메모리 영역이다.
	mov es, ax				; ES(Extra Segment). 프로그래머에 의해 마음대로 사용.
	mov di, 0				; DI(Destination Index Register). 주로 오프셋으로 사용되는 듯 하다.
	mov ax, word [msgBack]	; ax에 [msgBack] 값이 2Byte 만큼 들어있다. msgBack은 하단부에 정의한다.
	mov cx, 0x7FF			; ECX(Extended Counter Register) 범용 레지스터의 반(16bit). 반복 명령어 사용시 카운터로 사용.
	
	
paint:
	mov word [es:di], ax	; ax 값 [msgBack]을 word 단위로 논리 주소 [0xB800:0x0000]에 저장한다.
	add di, 2				; di에 1word(2Byte)씩 증가 시킨다.
	dec cx					; 0x7FF였던 CX가 0이 되면 자동으로 Zero Flag가 0이 된다.

	jnz paint				; Zero Flag가 0이 아닐 때 점프.
	
	
	mov edi, 0				; EDI(Extended Destination Index)(32bit). 메모리 복사 명령에서 목적지 주소 포인터로 주로 사용된다.
	mov byte [es:edi], 'R'	; 어셈블리 데이터타입 	:	byte(1), word(2), dword(4)
							; 어셈블리에서 [A]	:	주소 A에 저장된 메모리 내용물. 즉 C언어에서 *A와 유사.
							; 그냥 mov를 하면 어차피 1 byte씩 옮겨지는 듯하다.
	inc edi					; include A : A의 값을 1 증가 시킨다.
	mov byte [es:edi], 0x05
	inc edi
	mov byte [es:edi], 'e'
	inc edi
	mov byte [es:edi], 0x16
	inc edi
	mov byte [es:edi], 'a'
	inc edi
	mov byte [es:edi], 0x27
	inc edi
	mov byte [es:edi], 'l'
	inc edi
	mov byte [es:edi], 0x30
	inc edi
	mov byte [es:edi], 'M'
	inc edi
	mov byte [es:edi], 0x41
	inc edi
	mov byte [es:edi], 'D'
	inc edi
	mov byte [es:edi], 0x53
	inc edi
	mov byte [es:edi], '1'
	inc edi
	mov byte [es:edi], 0x57
	inc edi
	
	;jmp $
	
	
;msgBack db '.', 0x17		; db : Byte 크기로 [문자 '.'과 색상]을 저장.
;times 510-($-$$) db 0
;dw 0xAA55

disk_read:				; 메모리맵 상에서 High Memory는 0x00100000 부터이다.
	mov ax, 0x1000		; 복사 목적지 주소 값 지정 ES:BX = 0x1000:0000(물리주소 : 0x10000)
	mov es, ax
	mov bx, 0
	
	mov ah, 2			; 디스크에 있는 데이터를 es:bx의 주소로
	mov dl, 0			; 0번 드라이브
	mov ch, 0			; 0번째 실린더
	mov dh, 0			; 0번째 헤드
	mov cl, 2			; (몇 번째부터 읽을 것인가?) 2번째 섹터부터 읽을 것이다.
	mov al, 1			; (처리할 연속적 섹터 번호 : 몇 번 섹터를 읽을 것인가?) 1번 섹터를 읽는다.
	
	int 13h				; Read!
	
	jc disk_read		; 에러가 나면 다시함
	
	
;------------------------- Real Mode to Protected Mode	
	cli
	
	lgdt[gdtr]
	
	; 보호모드에 진입하겠다는 것을 0번 컨트롤 레지스터(CR0)을 통해 CPU에 알려줘야한다.
	; or연산을 통해 다른 값들을 보호하며 첫번째 bit값만 변화를 준다.
	mov eax, cr0			; CR0의 값을 eax에 넣어준다.
	or eax, 0x00000001		; eax의 값을 0x00000001과 or 연산
	mov cr0, eax			; CR0에 or연산 된 값을 넣어준다.
	
	
	; 보호모드로 사용됨을 CR0을 통해 알렸지만, 아직 일부 명령어가 16bit 형태로 들어가 있을 수 있다. 이를 건너 뛰기 위해 아래와 같은 코드를 사용한다.
	jmp	$+2					; 2개의 명령을 점프한다.
	nop
	nop
	
	mov bx, SysDataSelector
	mov ds, bx
	mov es, bx
	mov ss, bx
	
	; Address Prefix라는 개념이 사용.
	jmp dword SysCodeSelector:0x10000
	
	msgBack db '.', 0x17
	
	;리얼 모드와 보호모드
	;리얼 모드 : 부트 로더 프로그램이 처리되는 방식. 16bit 단위로 데이터가 처리. 80286 이후의 x86 호환 CPU 운영방식.
	;		  1. 8088 CPU에서는 어드레스 주소로 20bit를 사용하였으므로 램의 물리주소 2^20 = 1MB 를 0x00000~0xfffff까지 밖에 사용 불가.
	;		  2. 해당 세그먼트 내의 어떠한 메모리 주소로도 이동이 가능하므로, 민감한 데이터를 건드릴 수 있다.
	;		  3. 자동으로 세그먼트가 지정되므로, 프로그래머가 세그먼트의 시작 주소를 지정하기 어렵다.
	;		  4. EAX 같은 확장 레지스터 사용 불가. (위쪽 코드를 보면 전부 AX 와 같은 16bit 레지스터를 사용한다)
	;			커널 프로그램을 구돌할 때에는 운영 모드를 바꿔주어야한다.
	;보호 모드 : 32bit 운영 모드에서는 메모리를 1MB 초과하여 사용가능. GDT를 사용하여 32bit 보호 모드로 운영 모드를 변환.
	;		  1. 잘못된 기계어 명령어를 입력해도 오동작을 방지하는 보호 기능 사용 가능.
	;		  2. BIOS를 이용할 수 없다.
	;		  3. 16bit와 32bit의 기계어 해석 방법이 달라서, 서로 언어가 호환되지 않는다.
	
	;GDT란 ?? (Global Descriptor Table)
	;세그먼트 영억에 대한 데이터를 일정한 디스크립터 형식으로 기술하고 이를 하나의 테이블에 모아두고자 하는 것.
	; http://itguava.tistory.com/14?category=630867
	
	

	; 총 4개의 디스크립터를 생성.
	; dw : 워드 단위로 데이터를 읽을 것 // db : 바이트 단위로 데이터를 읽을 것.
	; < 디스크립터 필드 테이블 참조하면 해석 가능 >
	; < 코드 세그먼트 디스크립터 해석 >
	; DPL = 00 : 커널 영역이다.
	; S = 1: 코드 세그먼트이다.
	; Type = 1010: 1(Code), 0(Excute/Read), 1(non_conforming), 0(non-accessed)
	; G = 1: 세그먼트 단위를 4KB로
	; D = 1: 세그먼트를 32bit로 설정
	
gdtr:
	dw gdt_end - gdt - 1	; GDT의 limit
	dd gdt+0x7C00			; GDT의 베이스 어드레스	
		
gdt:
	dd 0x00000000, 0x00000000	; NULL 세그먼트
	dd 0x0000FFFF, 0x00CF9A00	; 코드 세그먼트
	dd 0x0000FFFF, 0x00CF9200	; 데이터 세그먼트
	dd 0x8000FFFF, 0x0040920B	; 비디오 세그먼트 
	
	; ----- " init1.inc" ------
	; SysCodeSelector	equ 0x08
	; SysDataSelector 	equ 0x10
	; VideoSelctor		equ 0x18
	;	아래를 요약하면 위와 같음.

		
; gdt:						; NULL 세그먼트 디스크립터
	; dw 0					; 모든 비트가 0. (해석 방식은 아래와 동일하게)
	; dw 0
	; db 0
	; db 0
	; db 0
	; db 0

; SysCodeSelector equ 0x08	; 코드 세그먼트 디스크립터
	; dw 0xFFFF				; 세그먼트 리미트 0~15bit : 					(2진수 : 1111 1111 1111 1111)
	; dw 0x0000				; 베이스 어드레스 하위 0~15bit:					(2진수 : 0000 0000 0000 0000)
	; db 0x01					; 베이스 어드레스 상위 16~23bit:						  (2진수:  0000 0001)
	; db 0x9A					; 속성 비트(P[1], DPL[2],		S[1], Type[4]):		  (2진수:  1001 1010)
	; db 0xCF					; 속성 비트(G, D, 예약비트, AVL, 세그먼트 리미트 16~19비트[4])	  (2진수:  1001 1010)
	; db 0x00					; 베이스 어드레스 상위 24~32bit:						  (2진수:  0000 0000)
	
; SysDataSelector equ 0x1000	; 데이터 세그먼트 디스크립터
	; dw 0xFFFF				; 해석하는 방식은 위와 동일하게
	; dw 0x0000
	; db 0x01
	; db 0x92
	; db 0xCF
	; db 0x00
	
; VideoSelctor equ 0x18		; 데이터 세그먼트 디스크립터
	; dw 0xFFFF				; 해석하는 방식은 위와 동일하게
	; dw 0x0000
	; db 0x0B
	; db 0x92
	; db 0xCF
	; db 0x00
	
	; 이것을 사용하겠다고 시스템에 알려주면 된다.
	; GDTR이라는 레지스터를 통해 GDT의 주소를 LGDT에 저장.
	
	; ldgt[gdtr]
	
gdt_end:
	times 510-($-$$) db 0
	dw 0xAA55
	