 		.data
		.align 2
naglowek:	.space 124
		
		#Elementy oblicze�
MaxRv:		.space 4
MaxGv:		.space 4
MaxBv:		.space 4
MinRv:		.space 4
MinGv:		.space 4
MinBv:		.space 4
pixels:		.space 124
height:		.space 4
width:		.space 4
size:		.space 4
offset:		.space 4
pixelTable:  	.space 32
buffer: 	.space 400

		#�cie�ki i wiadomo�ci
msgIntro:	.asciiz "--- Histogram Streaching bmp ---\n"
fileNameIn:	.asciiz "/home/kajkacz/Dropbox/Studia/ARKO/ARKO Projekt/Test.bmp"
fileErrorMsg:	.asciiz "Error opening file"

		#Pliki do zapisania histogram�w do sprawdzenia, i innych testowych plik�w
fileOut:	.asciiz "/home/kajkacz/Dropbox/Studia/ARKO/ARKO Projekt/TestResults/FilePixelTable.txt"	
fileNameOutTxtB:.asciiz "/home/kajkacz/Dropbox/Studia/ARKO/ARKO Projekt/TestResults/FileHistogramBlue.txt"
fileNameOutTxtR:.asciiz "/home/kajkacz/Dropbox/Studia/ARKO/ARKO Projekt/TestResults/FileHistogramRed.txt"
fileNameOutTxtG:.asciiz "/home/kajkacz/Dropbox/Studia/ARKO/ARKO Projekt/TestResults/FileHistogramGreen.txt"
fileNameOutTxtDB:.asciiz "TestResults/FileHistogramDistributionBlue.txt"
fileNameOutTxtDR:.asciiz "/home/kajkacz/Dropbox/Studia/ARKO/ARKO Projekt/TestResults/FileHistogramDistributionRed.txt"
fileNameOutTxtDG:.asciiz "/home/kajkacz/Dropbox/Studia/ARKO/ARKO Projekt/TestResults/FileHistogramDistributionGreen.txt"

		#�cie�ka do pliku wyj�ciowego
fileNameOut:	 .asciiz "/home/kajkacz/Dropbox/Studia/ARKO/ARKO Projekt/Output.bmp"

		#Histogramy
	.align 2
histR:		.space 1024 
	.align 2
histG:		.space 1024
	.align 2
histB:		.space 1024
	.align 2
histDystR:	.space 1024
	.align 2
histDystG:	.space 1024
	.align 2
histDystB:	.space 1024
		.text
		.globl main
		
main:
	# wyswietlenie informacji powiatlnej:
	la $a0, msgIntro
	li $v0, 4
	syscall
	
openFile:
	#################################################################
	# Otworzenie i odczytanie plik�w : Zawartosc wa�nych rejestrow:	#	
	#################################################################
	# $t1 --> deskryptor pliku					#
	# $s0 --> rozmiar pliku						#
	# $s1 --> adres zaalokowanej pamieci				#
	# $s2 --> width							#
	# $s3 --> height						#
	#################################################################

	# otworzenie pliku o nazwie ze zmiennej fileNameIn
	la $a0, fileNameIn
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall	
	
	# deskryptor pliku do $t1
	move $t1, $v0 		
	
	#Zakoncz w wypadku bledu otworzenia pliku
	bltz $t1, fileError	
			
	#odczytanie naglowka
	la $a0, ($t1) 
	la $a1, naglowek + 2
	li $a2, 122
	li $v0, 14
	syscall
	
	la $a0, ($t1)
	li $v0, 16
	syscall
	
	#Zapisanie waznych dla nas elementow naglowka
	lw  $t2 , naglowek + 36
	sw  $t2 , size
	
	lb  $t2 , naglowek + 24
	sb  $t2 , height
	
	lb  $t2 , naglowek + 20
	sb  $t2 , width
	
	lb  $t2 , naglowek + 12
	sb  $t2 , offset

	# zaalokowanie pamieci na bitmape
	lw $a0, size
	li $v0, 9
	syscall
	
	# adres pamieci zaalokowanej na bitmape do s1
	move $s1, $v0
	sw $s1, pixelTable
	
	
wczytaj_bajty:

	#Otwieramy plik ponownie
	la $a0, fileNameIn
	li $a1, 0
	li $a2, 0
	li $v0, 13
	syscall	
	
	# deskryptor pliku do $t1
	move $t1, $v0 		
	
	#Zakoncz w wypadku bledu
	bltz $t1, fileError	
	
	#Przsuwamy wskaznik na pozycje offsetu
	la $a0, ($t1) 
	la $a1, buffer
	lw $a2, offset
	li $v0, 14
	syscall		
	
	# wczytanie tablicy pixeli do zaalokowanej pamieci
	li $v0, 14
	la $a0, ($t1)
	la $a1, ($s1)
	lw $a2, size
	syscall
	
	# zamkniecie pliku, s0 niepotrzebne
	li $v0, 16
	la $a0, ($t1)
	syscall
	
histogramCalc:

	#################################################################################
	#	Zawartosc rejestrow:							#
	#################################################################################
	# $s0 --> size									#
	# $s1 --> adres zaalokowanej pamieci (gdzie wczytany zostal caly plik bmp)!	#
	# $s2 --> width!								#
	# $s3 --> height!								#
	# $s4 --> offset!								#
	# $s6 --> licznik pikseli w wierszu!						#
	# $s7 --> adres bajtu danego koloru						#
	# $t0 --> B piksela								#
	# $t1 --> G piksela								#
	# $t2 --> R piksela								#
	# $t3 --> adres histogramu R!							#
	# $t4 --> adres histogramu G!							#
	# $t5 --> adres histogramu B!							#
	# $t6 --> liczba pikseli w calym pliku (koniec petli)!				#
	# $t7 --> licznik przerobionych pikseli!					#
	# $t8 --> reszta z dzielenia width / 4 (padding)				#
	# $t9 --> tymczasowy rejestr do obliczen					#
	#################################################################################
	
	li $t7, 0		# licznik przerobionych pixeli ustawiony na 0
	
	lw $s2, width		# wczytujemy wymiary
	lw $s3, height
	
	li $s6, 1		# ustawienie licznika pikseli w wierszu na 1
		
	lw $s1, pixelTable	# ladujemy adres tablicy pixeli
	
	la $t3,histB		# ladujemy adresy histogramow
	la $t4,histG
	la $t5,histR
	mul $t6, $s2, $s3	# width * height daje nam ilosc pixeli
	sw $t6, pixels		# ktora zapisujemy n

	srl $t8, $s2, 2		# sprawdzamy padding
histogramLoop:	
	beq $t6, $t7, calcHistDyst	# Warunek wyjscia z petli(Przerobienie wszystkich pixeli
	lbu $t0, ($s1)		# wczytanie B piksela
	addi $s1, $s1, 1	# przejscie o kolejny bajt
	
	lbu $t1, ($s1)		# wczytanie G piksela
	addi $s1, $s1, 1	# przejscie o kolejny bajt
	
	lbu $t2, ($s1)		# wczytanie R piksela
	addi $s1, $s1, 1	# Przejd� do nast�pnego pixela
	
	# przerabianie skladowej kazdego koloru dla danego piksela:
			# B 
	sll $t0,$t0,2		# Mnozymy przez 4, aby oc obsluzyc duze obrazki
	addu $s7,$t3,$t0	# Znajduje miejsce do zapisania tego koloru w histogramie
	lbu  $t9,($s7)		# Znajduje bit okreslajacy ilosc wystapien danego koloru
	addi $t9,$t9,1		# inkrementuje
	sb   $t9,($s7)
			# G
	sll $t1,$t1, 2		# Mnozymy przez 4, aby oc obsluzyc duze obrazki
	addu $s7,$t4,$t1	# Znajduje miejsce do zapisania tego koloru w histogramie
	lbu  $t9,($s7)		# Znajduje bit okreslajacy ilosc wystapien danego koloru
	addi $t9,$t9,1		# inkrementuje
	sb   $t9,($s7)
			# R 
	sll $t2,$t2, 2		# Mnozymy przez 4, aby oc obsluzyc duze obrazki
	addu $s7,$t5,$t2	# Znajduje miejsce do zapisania tego koloru w histogramie
	lbu  $t9,($s7)		# Znajduje bit okreslajacy ilosc wystapien danego koloru
	addi $t9,$t9,1		# inkrementuje
	sb   $t9,($s7)

	addi $t7, $t7, 1	# zwiekszenie licznika przerobionych pikseli
	
	# sprawdzamy padding:
	
	beq $s6, $s2, padding	# jesli licznik pikseli w wierszu = width znaczy ze doszlismy do paddingu
	addi $s6, $s6, 1	# zwiekszenie licznika przerobionych pikseli w wierszu
	j histogramLoop
	
padding:
	li $s6, 1
	beq $t8, 0, padding0
	beq $t8, 1, padding1
	beq $t8, 2, padding2
	beq $t8, 3, padding3

padding0:		
	# przechodzimy o jeden bajt dalej - nic nie robimy
	b histogramLoop

padding1:
	# przechodzimy lacznie o 2 bajty dalej (1 paddingowy omijamy)
	addi $s1, $s1, 1
	b histogramLoop
	
padding2:
	# przechodzimy lacznie o 3 bajty dalej (2 paddingowe omijamy)
	addi $s1, $s1, 2
	b histogramLoop
	
padding3: 
	# przechodzimy lacznie o 4 bajty dalej (3 paddingowe omijamy)
	addi $s1, $s1, 3
	b histogramLoop
	
	#########################################
	# $t0 --> Adres histR			#
	# $t1 --> Adres histG			#
	# $t2 --> Adres histB			#
	# $t3 --> Wartosc obecna		#
	# $t4 --> Suma wartosci R		#
	# $t5 --> Suma wartosci G		#
	# $t6 --> Suma wartosci B		#
	# $t7 --> Rozmiar histogramow		#
	# $s0 --> Adres histDystR		#
	# $s1 --> Adres histDystG		#
	# $s2 --> Adres histDystB		#
	# $s3 --> Licznik histogramu R		#
	# $s4 --> Licznik histogramu G		#
	# $s5 --> Licznik histogramu B		#
	#########################################
	
calcHistDyst:
	la $t0,histR		# Zaladuj histogramy
	la $t1,histG
	la $t2,histB
	li $t3,0		# Wyzeruj warotosci
	li $t4,0
	li $t5,0
	li $t6,0
	la $s0,histDystR 	# Zaladuj dystrybuanty hisogramow
	la $s1,histDystG
	la $s2,histDystB
	li $t7,256		# Ladujemy rozmiar histogramow
	li $s3,0		# Ladujemy liczniki histogramow
	li $s4,0
	li $s5,0
	
calcHistDystR:
	lw $t3,($t0)				# Ladujemy wartosc z histogramu
	add $t4, $t3, $t4			# Sumujemy z dotychczasowa calkowita suma
	sw $t4, ($s0)				# Zapsiujemy do dystrubuanty danego histogramu
	addi $t0, $t0, 4			# Zwiekszamy adres odczytu
	addi $s0, $s0, 4			# Zwiekszamy adres zapisu
	addi $s3, $s3, 1			# Zwiekszamy licznik
	bge $s3, $t7, calcHistDystG		# Jesli przerobilismy 256 wartosci przechodzimy do nastepnego histogramu
	j calcHistDystR
	
calcHistDystG:
	lw $t3,($t1)				# Ladujemy wartosc z histogramu
	add $t5, $t3, $t5			# Sumujemy z dotychczasowa calkowita suma
	sw $t5, ($s1)				# Zapsiujemy do dystrubuanty danego histogramu
	addi $t1, $t1, 4			# Zwiekszamy adres odczytu
	addi $s1, $s1, 4			# Zwiekszamy adres zapisu
	addi $s4, $s4, 1			# Zwiekszamy licznik
	bge $s4, $t7, calcHistDystB		# Jesli przerobilismy 256 wartosci przechodzimy do nastepnego histogramu
	j calcHistDystG
	
calcHistDystB:
	lw $t3,($t2)				# Ladujemy wartosc z histogramu
	add $t6, $t3, $t6			# Sumujemy z dotychczasowa calkowita suma
	sw $t6, ($s2)				# Zapsiujemy do dystrubuanty danego histogramu
	addi $t2, $t2, 4			# Zwiekszamy adres odczytu
	addi $s2, $s2, 4			# Zwiekszamy adres zapisu
	addi $s5, $s5, 1			# Zwiekszamy licznik
	bge $s5, $t7, MinMaxCalculations 	#Jesli przerobilismy 256 wartosci przechodzimy do obliczenia wartosci maxymalnych i minimalnych
	j calcHistDystB

MinMaxCalculations:
	#########################################
	# Zawartosc rejestrow:			#
	#########################################
	# $t0 --> MaxR				#
	# $t1 --> MaxG				#
	# $t2 --> MaxB				#
	# $t3 --> MinR				#
	# $t4 --> MinG				#
	# $t5 --> MinB				#
	# $t6 --> Pixels			#
	# $t7 --> Licznik			#
	# $t8 --> PaddingCheck			#
	# $s1 --> adres tablicy pixeli		#
	# $s2 --> width				#
	# $s3 --> height			#
	# $s4 --> B piksela			#
	# $s5 --> G piksela			#
	# $s6 --> R piksela			#
	# $s7 --> licznik pikseli w wierszu	#
	#########################################
				
				# Warto�ci poczatkowe dla :
	li $t0,0		# MaxR
	li $t1,0		# MaxB
	li $t2,0		# MaxG
	li $t3,1024		# MinR
	li $t4,1024		# MinB
	li $t5,1024		# MinG
	lw $t6, pixels		# ladujemy ilosc pixeli
	li $t7, 0		# licznik ustawiony na 0
	srl $t8, $s2, 2		# Padding Check
	lw $s1, pixelTable	
	lw $s2, width
	lw $s3, height
	li $s7, 1		# ustawienie licznika pikseli w wierszu na 1
		
MinMaxLoop:	
	beq $t6, $t7, saveMinMax	# Warunek wyjscia z petli ( po przerobieniu wszystkich pixeli)
	lbu $s4, ($s1)			# wczytanie B piksela
	addi $s1, $s1, 1		# przejscie o kolejny bajt
	
	lbu $s5, ($s1)			# wczytanie G piksela
	addi $s1, $s1, 1		# przejscie o kolejny bajt
	
	lbu $s6, ($s1)			# wczytanie R piksela
	addi $s1, $s1, 1		# Przejd� do nast�pnego pixela	
	
	# przerabianie skladowej kazdego koloru dla danego piksela:
BlueCheck:			# B 
	bgt $s4,$t2,MaxB
	blt $s4,$t5,MinB
	
GreenCheck:			# G
	bgt $s5,$t1,MaxG
	blt $s5,$t4,MinG
	
RedCheck:			# R 
	bgt $s6,$t0,MaxR
	blt $s6,$t3,MinR
	
AfterChecks:	

	addi $t7, $t7, 1		# zwiekszenie licznika przerobionych pikseli	
	# sprawdzamy padding:
	beq $s7, $s2, MinMaxpadding	# jesli licznik pikseli w wierszu = width
	addi $s7, $s7, 1		# zwiekszenie licznika przerobionych pikseli w wierszu
	j MinMaxLoop
	
MinMaxpadding:
	li $s7, 1
	beq $t8, 0, MinMaxpadding0
	beq $t8, 1, MinMaxpadding1
	beq $t8, 2, MinMaxpadding2
	beq $t8, 3, MinMaxpadding3

MinMaxpadding0:		
	# przechodzimy o jeden bajt dalej - nic nie robimy
	b MinMaxLoop

MinMaxpadding1:
	# przechodzimy lacznie o 2 bajty dalej (1 paddingowy omijamy)
	addi $s1, $s1, 1
	b MinMaxLoop
	
MinMaxpadding2:
	# przechodzimy lacznie o 3 bajty dalej (2 paddingowe omijamy)
	addi $s1, $s1, 2
	b MinMaxLoop
	
MinMaxpadding3: 
	# przechodzimy lacznie o 4 bajty dalej (3 paddingowe omijamy)
	addi $s1, $s1, 3
	b MinMaxLoop
	
	#Zapisywanie maximow i minimow do tymczasowych rejestrow

MaxB:
	addi $t2,$s4,0
	j GreenCheck
MinB:
	addi $t5,$s4,0
	j GreenCheck
MaxG:
	addi $t1,$s5,0
	j RedCheck
MinG:
	addi $t4,$s5,0
	j RedCheck
MaxR:
	addi $t0,$s6,0
	j AfterChecks
MinR:
	addi $t3,$s6,0
	j AfterChecks

	#Zapisywanie maximow i minimow do pamieci	
saveMinMax:
	sw $t0,MaxRv
	sw $t1,MaxGv
	sw $t2,MaxBv
	sw $t3,MinRv
	sw $t4,MinGv
	sw $t5,MinBv	


	#########################################
	# $t0 --> Current(Calculations) 	#
	# $t1 --> Licznik pixeli w pliku	#
	# $t2 --> Licznik pixeli w wierszu	#
	# $t3 --> MinR				#
	# $t4 --> MinG				#
	# $t5 --> MinB				#
	# $t6 --> Adress histDystR		#
	# $t7 --> Adress histDystG		#
	# $t8 --> Adress histDystB		#
	# $s1 --> pixels			#
	# $s2 --> width			   	#
	# $s3 --> HistR				#
	# $s4 --> HistG				#
	# $s5 --> HistB				#
	# $s6 --> PaddingCheck			#
	# $s7 --> Tablica pixeli		#
	#########################################

initEqualize:
	li $t1,1		# Poczatkowe wartosci licznikow	
	li $t2,1	
	lw $t3,MinRv		# Zaladuj wartosci minimalne
	lw $t4,MinGv
	lw $t5,MinBv
	la $t6,histDystR	# Zaladuj dystrybuanty
	la $t7,histDystG
	la $t8,histDystB
	lw $s1,pixels
	lw $s2,width
	srl $s6, $s2, 2		#Padding Check
	lw $s7,pixelTable
	
equalizeLoop:
	beq $s1, $t1, saveImage	# Wyjscie z petli, po przerobieniu wszystkich pixeli	
	
	#B
	
	lbu $t0, ($s7)		# wczytanie B piksela
	sll $t0,$t0,2
	add $a0,$t8,$t0		# Znajduje wartosci dystrybuanty dla danej wartosci koloru pixela
	lw $t0, ($a0)		# Po czym j� wczytuje
	sub $t0,$t0,$t5		# Algorytm wyrownania histogramu
	mul $t0,$t0,255
	sub $a0, $s1,$t5	# Pixels - MinB
	div $t0,$a0
	mflo $t0
	sb $t0,($s7)	
	addi $s7, $s7, 1	# przejscie o kolejny bajt
	
	#G
	
	lbu $t0, ($s7)		# wczytanie G piksela
	sll $t0,$t0,2
	add $a0,$t7,$t0 	# Znajduje wartosci dystrybuanty dla danej wartosci koloru pixela
	lw $t0, ($a0)		# Po czym j� wczytuje
	sub $t0,$t0,$t4		# Algorytm wyrownania histogramu
	mul $t0,$t0,255
	sub $a0, $s1,$t4	# Pixels - MinG
	div $t0,$a0
	mflo $t0
	sb $t0,($s7)	
	addi $s7, $s7, 1	# przejscie o kolejny bajt
	
	#R 
	
	lbu $t0, ($s7)		# wczytanie R piksela
	sll $t0,$t0,2
	add $a0,$t6,$t0 	# Znajduje wartosci dystrybuanty dla danej wartosci koloru pixela
	lw $t0, ($a0)		# Po czym j� wczytuje
	sub $t0,$t0,$t3		# Algorytm wyrownania histogramu
	mul $t0,$t0,255
	sub $a0, $s1,$t3	# Pixels - MinR
	div $t0,$a0
	mflo $t0
	sb $t0,($s7)	
	addi $s7, $s7, 1	# Przejdz do nastepnego pixela
		
	# sprawdzamy padding:
	beq $t2, $s2, equalizepadding	# jesli licznik pikseli w wierszu = width
	addi $t2, $t2, 1		# zwiekszenie licznika przerobionych pikseli w wierszu
	addi $t1, $t1, 1		# zwiekszenie licznika przerobionych pikseli
	j equalizeLoop
	
equalizepadding:
	li $t2, 1
	beq $s6, 0, equalizepadding0
	beq $s6, 1, equalizepadding1
	beq $s6, 2, equalizepadding2
	beq $s6, 3, equalizepadding3

equalizepadding0:		
	# przechodzimy o jeden bajt dalej - nic nie robimy
	b equalizeLoop

equalizepadding1:
	# przechodzimy lacznie o 2 bajty dalej (1 paddingowy omijamy)
	addi $s7, $s7, 1
	b equalizeLoop
	
equalizepadding2:
	# przechodzimy lacznie o 3 bajty dalej (2 paddingowe omijamy)
	addi $s7, $s7, 2
	b equalizeLoop
	
equalizepadding3: 
	# przechodzimy lacznie o 4 bajty dalej (3 paddingowe omijamy)
	addi $s7, $s7, 3
	b equalizeLoop	

	#Zapis obrazka do pliku ze sciezki fileNameOut
saveImage:
	la $a0, fileNameOut	# Otworzenie pliku do zapsiu
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $s3,$v0
	
	li $v0,15		# Zapisanie naglowka
	la $a0,($s3)
	la $a1,naglowek + 2
	lw $a2,offset
	syscall	
			
	li $v0,15		# Zapisanie tablicy pixeli
	la $a0,($s3)
	lw $a1,pixelTable
	lw $a2,size
	syscall																			
																							
	b exit																								
	
printTests: # Zapis warto�ci testowych - histogramow, dystrybuant etc
			#B
	la $a0, fileNameOutTxtB
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $s3,$v0
	
	li $v0,15
	la $a0,($s3)
	la $a1,histB
	la $a2,1024
	syscall			
			#G
	la $a0, fileNameOutTxtG
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $s3,$v0
	
	li $v0,15
	la $a0,($s3)
	la $a1,histG
	la $a2,1024
	syscall	
			#R
	la $a0, fileNameOutTxtR
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $s3,$v0
	
	li $v0,15
	la $a0,($s3)
	la $a1,histR
	la $a2,1024
	syscall		

	la $a0, fileNameOutTxtDB
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $s3,$v0
	
	li $v0,15
	la $a0,($s3)
	la $a1,histDystB
	la $a2,1024
	syscall			
			#G
	la $a0, fileNameOutTxtDG
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $s3,$v0
	
	li $v0,15
	la $a0,($s3)
	la $a1,histDystG
	la $a2,1024
	syscall	
			#R
	la $a0, fileNameOutTxtDR
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $s3,$v0
	
	li $v0,15
	la $a0,($s3)
	la $a1,histDystR
	la $a2,1024
	syscall	

	# zapisanie do pliku tablicy pixeli
	
	la $a0, fileOut
	li $a1, 1
	li $a2, 0
	li $v0, 13
	syscall
	
	move $s1,$v0
	
	li $v0,15
	move $a0,$s1
	lw $a1,pixelTable
	lb $a2,size
	syscall	
	
	li $v0, 16
	la $a0, ($t1)
	syscall
	b exit		
	
fileError:
	la $a0, fileErrorMsg
	li $v0, 4
	syscall

exit:	
	# zamkniecie programu:
	li $v0, 10
	syscall

