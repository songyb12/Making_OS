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
	
	jmp $
	
	
msgBack db '.', 0x17		; db : Byte 크기로 [문자 '.'과 색상]을 저장.
times 510-($-$$) db 0
dw 0xAA55

	