section .text ; program 64-bitowy

	global transformation

transformation:
	push rbp
	mov rbp, rsp

reversal:
	cvttsd2si r10, xmm0
 	;mov	r10, 12695;inicjalizujemy indexy zerem -> R10 to iterator, zwiększa się o jeden co obrót pętli, R11 to index na którym wykonuję obliczenia

	mov r8,rdx; szerokość do R8
	mov rax, rcx		; ax - wysokosc obrazka
	mov r11 , rdx	; r11 - szerokosc obrazka
	mul r11	; mnozywmy szerokosc i wysokosc i dostajemy rozmiar obrazka (ilosc pixeli) w RAX

 	mov r11, 3	; mnozymy ilosc pixeli razy 3 ( bo RGB ) żeby otrzymać ilość komórek do których można zapisywać
	mul r11
	mov r11,rax ; W R11 mamy przeniesioną ilość pixeli razy 3, czyli ilość komórek

	mov r9,r11 ; LIMIT w r9 - koniec pętli, jak wyżej, maks liczba komórek

	mov r15,rsi
	mov r11, rdi

	mov rax ,3
	mul r8
	mov r8, rax ; mnożymy wartość szerokości przez 3(RGB) żeby otrzmać ilość komórek w wierszu
reversalLoop:

	mov rax,r10 ; get the value of index%width - index modulo szerokość to nasza wartość x , współrzędna
	div r8
	mov r12, rdx ; R12 - wartość x ( 0 , 3*width )

	mov r13, r8
	sar r13,1 ; R13 - 3*width/2 W R 13 mamy wartość szerokości podzieloną na 2,

 	cmp r12,r13 ; Sprawdzamy czy nasz punkt leży na lewo czy prawo od połowy

 	jge positive
negative:		; Jeśli nasz punkt jest na lewo od połowy to liczymy odległość od połowy do naszego pixala, mnożymy razy 2,
	sub r13,r12	;i w ten sposób otrzymujemy odległość między źródłowym a docelowym pixelem
	sal r13,1; Zapisujemy ją w R13

	add r13, r10	;Dodajemy do R13 index
	add r13,r11	;oraz adres początku tablicy źródłowej, czyli otrzymujemy adres pamięci skąd mamy wczytać pixel

	mov r14, r15
	add r14,r10	; dodajemy do adresu początku tablicy docelowej obecną wartść indexu, w ten sposób otrzymujemy adres do którego mamy zapisać

	mov al,[r13]	; Zapisujemy po kolei RGB
	mov [r14],al
	inc r14				;Inkrementujemy oba adresy i iterator w R10
	inc r13
 	inc r10

 	mov al, [r13]
 	mov  [r14],al
 	inc r14
 	inc r13
 	inc r10

 	mov al, 255
 	mov [r14],al
  inc r10

 	jmp compare	;Skaczemy do sprawdzenia zcy już koniec

positive: ; Jeśli nasz punkt jest na prawo od połowy to liczymy odległość od połowy do naszego pixala, mnożymy razy 2,
	sub r12,r13;i w ten sposób otrzymujemy odległość między źródłowym a docelowym pixelem
	sal r12,1; Zapisujemy ją w r12

	mov r13, r11	;	W R13 zapisujemy adres tablicy źrdłowej
	add r13, r10	;Dodajem do niego iterator
	sub r13, r12	;Po czym odejmujemy policzone w R12 przesuniecie aby otrzymać adres źródłowego pixela

	mov r14,r10		; do iteratora dodajemy adres początku tablicy docelowej aby otrzymać adres docelowy do zapisu pixela
	add r14, r15


 	mov al, [r13]	;Zapisujemy RGB
 	mov  [r14],al
 	inc r14	;Inkrementujemy
 	inc r13
 	inc r10

 	mov al, [r13]
 	mov  [r14],al
 	inc r14
 	inc r13
 	inc r10

 	mov al, [r13]
 	mov  [r14],al
 	inc r10

compare:
	cmp r10, r9	;sprawzamy czy to koniec

	jle reversalLoop;jeśli nie to powtarzamy
initIdentity:
	sal r9,1
	inc r10
	mov r8, 0
identity:
	mov r13, r8
	mov r14, r10

	add r14 ,r15
	add r13, r11

	mov al, [r13]
	mov [r14],al
	inc r14
	inc r13
	inc r10
	inc r8

	mov al, [r13]
	mov [r14],al
	inc r14
	inc r13
	inc r10
	inc r8

	mov al, [r13]
	mov [r14],al
	inc r14
	inc r13
	inc r10
	inc r8

	cmp r10, r9	;sprawzamy czy to koniec

	jle identity;jeśli nie to powtarzamy
	mov rax, r15
end:
	mov rsp, rbp
	pop rbp
	ret


		; 			r11: -r11 - adres oryginalnego obrazka,
		; 			r15;	-r15 - adres tablicy docelowej
		; 			RDX;	-RDX - szerokość obrazka
		; 			RCX; -RCX - wysokość obrazka
		; 			XMM0;-XMM0- Parrametr 11- Sinus Fi
		; 			XMM1;-XMM1- Parrametr 12	-	Cosinus Fi
		; 			R10; -R10 - licznik
		; 			R11; -R11 - index (i)
		; 			R12; -R12 - index modulo szerokość (i%w)
