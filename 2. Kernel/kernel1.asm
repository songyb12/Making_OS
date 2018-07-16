%include "init1.inc"

[org 0x10000]
[bits 32]

PM_State:
	mov bx, SysDataSelector		;SysDataSelector 초기화
	mov ds, bx
	mov es, bx
	
	mov ax, VideoSelector		;VideoSelector 초기화
	mov es, ax
	
	mov edi, 80*2*10+2*10		;printf:의 문자 출력할 부분 선택
								;80 : 출력 시 한 줄에 들어갈 글자의 수
								;2	: 컬러 텍스트 모드에서 배경과 글자가 각 1바이트가 필요하므로 이를 곱해준다.
								;10	: 출력할 총 줄의 수
								;2*10	:위의 10줄을 수행 한 후, 문자열을 출력하기 전에 더 추가될 문자의  수
	call printf
	
	jmp $
	
printf:
	mov byte [es:edi], 'P'
	inc edi
	mov byte [es:edi], 0x47
	inc edi
	mov byte [es:edi], 'r'
	inc edi
	mov byte [es:edi], 0x47
	inc edi
	mov byte [es:edi], 'o'
	inc edi
	mov byte [es:edi], 0x47
	inc edi
	mov byte [es:edi], 't'
	inc edi
	mov byte [es:edi], 0x47
	inc edi
	mov byte [es:edi], 'e'
	inc edi
	mov byte [es:edi], 0x47
	inc edi
	mov byte [es:edi], 'c'
	inc edi
	mov byte [es:edi], 0x47
	inc edi
	mov byte [es:edi], 't'
	inc edi
	mov byte [es:edi], 0x47
	inc edi
	mov byte [es:edi], 'M'
	inc edi
	mov byte [es:edi], 0x47
	inc edi
	mov byte [es:edi], 'o'
	inc edi
	mov byte [es:edi], 0x47
	inc edi
	mov byte [es:edi], 'd'
	inc edi
	mov byte [es:edi], 0x47
	inc edi
	mov byte [es:edi], 'e'
	inc edi
	mov byte [es:edi], 0x47
	inc edi
	
	ret							; 32비트 커널영역 종료