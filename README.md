# Making_OS
Practice making OS.

간단한 (Intel) OS 만들기 실습 자료입니다.
온라인에서 얻은 코드를 직접 따라가며 작성하고, 주석을 달아가며 원리를 파악해나가는 프로젝트입니다.
1-1. 세그먼트, 레지스터, Global Descriptor Table(GDT).
1-2. 세그먼트-오프셋 주소표기법과 20bit 어드레스 버스.
2-1. 기초 OS 작동 순서.
2-2. Real Mode와 Protected Mode로의 전환과 특징
3-1. Interrupt Descriptor Table과 Programmable Interrupt Controller..
3-2. ICW 루틴.(Initialization Command Word)

개발환경(Develop Environment)
1. Windows 10, 64bit.
2. Notepad++
- 코드 작성용. asm 언어도 문법에 맞게 하이라이팅 해주어서 편리.
3. nasm (Netwide Assembler)
- asm로 작성한 문서를 binary(image) 파일로 변환하는 용도.
4. VMware Workstation.
- 가상 플로피 디스크 형태로 OS 부팅.

중점으로 참고한 사이트(Reference)
http://itguava.tistory.com/9?category=630867
