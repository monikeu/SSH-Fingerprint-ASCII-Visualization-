;Zadanie 1 - Prezentacja funckji klucza publicznego w postaci grafiki ASCII
;Modyfikacja - zamiana półbajtów
;autor: Monika Darosz


dane segment

	argumenty  		db 128 dup (?) ; miejsce na argumenty wpisane do programu
	offsetarg   	db 128 dup (?) ; offsety początku kolejnych argumentów
	ilearg 			db  0			
	dlargumentow	db 128 dup (?) ; dugości poszczególnych argumentów
	dlarg 			db 0 			; długość pojedynczego argumentu
	kluczb    		db 16 dup (?)  	; klucz w postaci binarnej
	
	error0 db "Brak argumentow! " , 13, 10, '$'
	error1 db "Niepoprawna liczba argumentow, maja byc 2!", 10, 13, '$'
	error2 db "Niepoprawny pierwszy argument, cyfry 0, 1!", 10, 13, '$'
	error3 db "Niepoprawny drugi argument, ma miec 32 znaki!", 10, 13, '$'
	error4 db "Niepoprawny drugi argument, powinien zawierac litery a-f, cyfry 0-9!" , 10, 13 , '$'
	
	belka_gora db "+---[RSA 1024]----+", 10, 13, '$'
	belka_dol  db "+-----------------+", 10, 13, '$'
	plansza    db 153 dup (0) 
	pozycja_konca db 0
	znaki	db		' ','.', 'o', '+', '=', '*', 'B', 'O', 'X', '@', '%', '&', '#', '/'
	linia_do_wypisania db 19 dup ('|') , 10, 13, '$'
	
dane ends

kod segment

	start:	

		mov sp, offset wstosu       ; inicjalizacja stosu
		mov ax, seg wstosu
		mov ss, ax 
		
		call czy_sa_argumenty
		call funkcja_poprawnosc
		call wersja
		call na_binarny
		call wykonaj_ruch 
		call wstaw_znaki
		call wypisz_plansze
		call koniec
	
;///////////////////////////////////////////////////////////PARSER////////////////////////////////////////////////////////////////////
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
	koniec:  ; koniec programu
		mov ax,4ch 				
		int 21h
	
	print:  ;wypisywanie
		mov ah, 9h 					
		int 21h 					
	ret
		
		
	czy_sa_argumenty: ;sprawdza czy są jakiekolwiek argumenty
		push bx	
			mov bx,0     				
			mov bl, byte ptr es:[080h] ; ile znaków w buforze wejsciowym 	
		
			cmp bx, 1 					
			ja wykryto_arg 				; A>B
		pop bx	
			call nie_ma_argumentow		; jeśli nie ma arg
			koniec_wykryto_arg:
		pop bx
	ret
	
	nie_ma_argumentow: ;wypisuje stosowny komunikat
		push ds
		push dx
			mov ax, seg error0  		 
			mov ds,ax
			mov dx, offset error0
		
			call print
		pop dx
		pop ds
			call koniec
	ret
	
	wykryto_arg: ; uruchomiona tylko wtedy, gdy zostaną wykryte argumenty    
		push ds
		push si
		push di
		push cx
			mov	ax, seg argumenty 			
			mov	ds, ax       
			mov	si, 0 		;   si będzie iterować po kolejnych miejscach ciągu bajtów "argumenty"

			mov cx, 0 				
			
			mov cx, bx 		;w BX - ilość argumentów w buforze , w CX (licznik) - ilosc powtorzen    
			
			dec bx
			mov di, bx
			mov byte ptr es:[082h+di], 20h ; wstawiam spację zamiast entera na koniec bufora
			
			mov di, 0 
			mov bx, 0 		
			mov ax, 0		
			
			call wczytaj_z_przerwami
		pop cx
		pop di
		pop si
		pop ds
	jmp koniec_wykryto_arg
	
	
	wczytaj_z_przerwami: ; wczytuje argumenty do 'argumenty' w  postaci "arg$arg$arg$" itd. 					
		wczyt_znak:	
		
			mov al, es:[082h+di] 					; di iteruje po buforze
		
			jmp czy_bialy 									;sprawdzam czy znak jest biały, jeśli jest powrót nastąpi do etykiety "idz_na_kon"
			koniec_czy_bialy:
			
			cmp bl, 0										; w bl  - informacja o poprzednim znaku, (znak 'zerowy' ustawiony na biały)
			
			je offset_poczatku_i_zliczanie       		 ; skok jeśli poprzedni znak był biały, a obecny jest nie-biały (czyli początek argumentu)
			koniec_offset_poczatku_i_zliczanie:	
			
			mov ds:[argumenty+si], al 				; si iteruje po 'argumenty'	
			inc di 						
			inc si						
			inc ds:[dlarg] 				;zwiększam długość argumentu
			
			mov bl, 1  					; informacja, że znak wpisany do 'argumenty' jest nie-biały
			idz_na_kon:					; koniec procedury 'zjedz_bialy'
		
		
		loop  wczyt_znak                      
	ret
	
	czy_bialy: ; sprawdza czy znak jest biały 
		cmp al, 20h	 ;spacja w hexie	
		je zjedz_bialy  ;==
			
		cmp al , 9h ; tab w hexie
		je zjedz_bialy ;==
	jmp koniec_czy_bialy
	
	zjedz_bialy: ; zjada białe znaki
			inc di  	; zwiekszam di, przeskakuję na następny znak w buforze						
					cmp bl,1 ;znak poprzedni był nie biały, co oznacza koniec argumentu, wstawiam przerwę ($)
					je wstaw_przerwe; ==
					koniec_wstaw_przerwe:
					
					cmp bl, 1   ;jak wyżej tylko zapisuję długość argumentu
					je dl_arg    
					koniec_dl_arg:
			mov bl, 0d
	jmp idz_na_kon
	
	wstaw_przerwe: ; wstawia między argumenty $
		mov al , '$'
		mov ds:[argumenty+si], al
		inc si ;wstawiłam przerwę, więc przeskakuję na następną pozycję w 'argumenty'
	jmp koniec_wstaw_przerwe
	
	dl_arg: ;zapisuje długości kolejnych argumentów w 'dlargumentow', zeruje 'dlarg' 
		push bx
		push ax
		push di
			mov al, ds:[ilearg]	;  do al ilość argumentów
			mov ah, 0 						
			mov di, ax						;  do di ilość argumentów
				
			mov al, ds:[dlarg]					;do al długość argumentu
			mov ds:[dlargumentow+di],al
		
			mov ds:[dlarg], 0 ;zerowanie długości argumentu
		
		pop di
		pop ax
		pop bx
	jmp koniec_dl_arg
	
	offset_poczatku_i_zliczanie: ; zapisuje offset początku argumentu w 'offsetarg' i zlicza argumenty w 'ilearg'
	push bx
	push ax
	push di
		inc ds:[ilearg]					; zwiekszam ilość argumentów
		mov al, ds:[ilearg]	;  do al ilość argumentów
		mov ah, 0 						
		mov bx, si						;  do bx offset początku argumentu
		mov di, ax						;  do di ilość argumentów
		mov byte ptr ds:[offsetarg+di], bl	
		
	pop di
	pop ax
	pop bx
	jmp koniec_offset_poczatku_i_zliczanie
	
;////////////////////////////////////////////POPRAWNOŚĆ ARGUMENTÓW//////////////////////////////////////////////////////////////////
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	funkcja_ile_arg: ;zwraca ilość argumentów w al
		mov al, ds:[ilearg]
	ret
	
	funkcja_offset_arg_o_nr: ;przyjmuje w ax numer argumentu, zwraca w al jego offset
		push di
			mov di, ax
			mov al, byte ptr ds:[offsetarg+di]
		pop di
	ret
	
	funkcja_dl_arg_o_nr: ;przyjmuje w ax numer argumentu, zwraca w al jego długość
		push di
			mov di, ax
			mov al, byte ptr ds:[dlargumentow+di]
		pop di
	ret
	
	funkcja_poprawnosc: ;funkcja sprawdzająca poprawność argumentów
	push di
	push ds
		mov ax, seg argumenty 
		mov ds, ax
		
		call funkcja_ile_arg ; sprawdzam czy są 2 argumenty
		cmp al, 2
		jne printerror1
	
		mov ax, 1 ; sprawdzam czy 1. argument ma długość 1 
		call funkcja_dl_arg_o_nr
		cmp al, 1 
		jne printerror2
	          
	         
		mov ax, 1 ;sprwadzam czy 1. argument to 0 lub 1 
		call funkcja_offset_arg_o_nr; zwróci w al offset argumentu
		mov ah, 0
		mov di, ax
		mov al, byte ptr ds:[argumenty+di]
		
		cmp al, '1'
		je poprawny
		
		cmp al, '0'
		je poprawny
		
		jmp printerror2 ; jeśli 1. argument nie jest ani '0', ani '1'

		poprawny:
	
		mov ax, 2  ;sprawdzam czy 2. argument ma 32 znaki
		call funkcja_dl_arg_o_nr
		cmp al, 32
		jne printerror3
		
		call poprawnosc_drugiego_arg 
	pop ds
	pop di
	ret

poprawnosc_drugiego_arg: ; sprawdza czy 2. arg składa się z cyfr 1-9 i liter a-f
	push di 
	push cx	

		mov di, 2  							; offset 2. arg (po sprawdzeniu poprawności długości, wiadomo, że ma taki offset)
		mov cx, 32
			sprawdz_znak: 							; iteruje po 2. argumencie
				mov al, ds:[argumenty+di]
				cmp al, '0'    		;<'0'  
				jb printerror4 		; A<B
				
				cmp al, '9' 		; <='9'
				jbe jest_ok 		; A<=B
				
				cmp al, 'a' 		;  <'a'
				jb printerror4
				
				cmp al, 'f' 		; >'f'
				ja printerror4 		;A>B
				
				jest_ok: 
				inc di
			loop sprawdz_znak
	
	pop cx
	pop di
	
ret

	printerror1:
	push ds
	push dx
		mov ax, seg error1
		mov ds, ax
		mov dx, offset error1
		call print
	pop dx
	pop ds
		call koniec
		
	printerror2:
	push ds
	push dx
		mov ax, seg error2
		mov ds, ax
		mov dx, offset error2
		call print
	pop dx
	pop ds
		call koniec

	printerror3:
	push ds
	push dx
		mov ax, seg error3
		mov ds, ax
		mov dx, offset error3
		call print
	pop dx
	pop ds
		call koniec

	printerror4:
	push ds
	push dx
		mov ax, seg error4
		mov ds, ax
		mov dx, offset error4
		call print
	pop dx
	pop ds
		call koniec
		
;//////////////////////////////////////////////////ZAMIANIA NA BINARNY///////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	na_binarny:	; zamienia na postać bitową
		push di
		push si
		push cx
		push bx
		push ds
			mov ax, seg argumenty
			mov ds, ax
			
			mov di, 2 ; di - offset 2. argumentu w obrębie 'argumenty'
			mov si, 0	; si - iteruje po  'kluczb'
			mov cx, 16  ; 16 bajtów do zamiany
			
			konwersja: ; zamienia po dwa znaki (po bajcie)
				push cx
					mov al, ds:[argumenty+di]
					call rozpatrz_znak					; zwraca w al przekonwertowany na postać dzisiętna znak
					mov cl, 4							
					shl al, cl	; przesuwam w lewo o 4 bity, to samo co *16						
					mov bl, al
					
					inc di								; następny znak
					
					mov al,  ds:[argumenty+di]
					call rozpatrz_znak
					add al, bl
					
					mov ds:[kluczb+si], al ; zapisuje bajt do 'kluczb'
					
					inc di
					inc si
				pop cx
			loop konwersja 
		pop ds
		pop bx
		pop cx
		pop si
		pop di
	ret     
	
	rozpatrz_znak: ; sprawdza czy znak jest cyfra czy literą
				cmp al, 'a'
				jae znak_a_f ; >=		
				jmp znak_0_9			
				powrot:
	ret
	  
	znak_a_f: ; zwraca w al postać dzisiętną znaku, a-10, b-11 itd.
	    sub al, 87d
		jmp powrot   
		
	znak_0_9: ; zwraca w al postać dzisiętną znaku
		sub al, 48d
		jmp powrot	
		      
;//////////////////////////////////////////Z MODYFIKACJĄ CZY BEZ?////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	wersja: ; sprawdza wersję programu (z modyfikacja czy bez)
	push ds
	push di
		mov ax, seg offsetarg
		mov ds, ax
		
		mov ax, 1 ; pierwszy argument mówi czy modyfikować czy nie
		call funkcja_offset_arg_o_nr
		mov ah, 0
		mov di, ax
		
		mov al,  ds:[di] ; pierwszy arg 
		cmp al, '1'
		je modyfikacja ; ==
		koniec_modyfikacja:
	pop di
	pop ds
	ret

	modyfikacja: ; zamienia miejscami półbajty
		push bx
		push cx
		push di
		push ds
			mov ax, seg argumenty
			mov ds, ax
			
			mov cx, 16
			mov di, 2 ; offset 2 argumentu
			
			zamien_polbajty: ; 
				mov al,  ds:[argumenty+di]
				mov ah, ds:[argumenty+di+1]
				mov ds:[argumenty+di], ah
				mov ds:[argumenty+di+1], al
				inc di
				inc di
			loop zamien_polbajty
			
		pop ds
		pop di
		pop cx
		pop bx
	jmp koniec_modyfikacja

;////////////////////////////////////////////////WYKONYWANIE RUCHÓW NA PLANSZY////////////////////////////////////////////////////////////////
;/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	wykonaj_ruch:  ; wykonuje ruch na planszy
			push di
			push si
			push cx
			push ds
				mov ax, seg argumenty
				mov ds, ax
				
				mov si, 76 ; do si środek planszy - pozycja startowa (pozycje planszy: 0-152)
				mov di, 0 ; di iteruje po 'kluczb'
				mov cx, 16 ; 16 bajtów do rozpatrzenia
				
				iteruj_po_bajtach: ; przetwarza kolejne bajty na ruchy
					push cx
						mov al, ds:[kluczb+di]
						mov cx, 4
						
						analizuj_bajty: ; 4 pętle dla każdego bajtu
							call analizuj_pary_bitow
							inc ds:[plansza+si]
						loop analizuj_bajty
						
						inc di
					pop cx
				loop iteruj_po_bajtach
				
				mov ax, si ; zapisuję końcową pozycję gońca
				mov ds:[pozycja_konca], al 
			pop ds
			pop cx
			pop si
			pop di
	ret

	analizuj_pary_bitow: ; analizuje pary bitów od końca bajtu
		push cx
			mov cl, 1
			shr al, cl 
			jc wprawo ; if  CF==1
			jmp wlewo
			wroc1:
			
			shr al, cl
			jc wdol
			jmp wgore
			wroc2:
		pop cx
	ret

	wprawo:
		push ax
			mov ax, si ; do ax adres obecnej komórki
			call modulo17
			cmp ah, 16 
			je pominwprawo; ==
				inc si ; zwiększam si, ruch w prawo
			pominwprawo:
		pop ax
	jmp wroc1

	wlewo:
		push ax
			mov ax, si
			call modulo17
			cmp ah, 0
			je pominwlewo ; ==
				dec si ; zmniejszam si, ruch w lewo 
			pominwlewo:
		pop ax
	jmp wroc1

	wgore:
			cmp si, 16
			jbe pominwgore ; <=
				sub si, 17
			pominwgore:
	jmp wroc2

	wdol:
		cmp si, 136
		jae pominwdol ; >=
			add si, 17
		pominwdol:
	jmp wroc2

	modulo17: ;przyjmuje dzielną w ax, zwraca resztę z dzielenia przez 17 w ah
		push bx
			mov bx, 0
			mov bl, 17
			div bl
		pop bx
	ret

;////////////////////////////////////WSTAWIANIE ZNAKÓW DO PLANSZY///////////////////////////////////////////////////////////////////////
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	wstaw_znaki: ; wstawia odpowiednie znaki do planszy
		push cx
		push si
		push di
		push ds
			mov ax, seg argumenty
			mov ds, ax
			
			mov si, 0 ; si - iteruje po planszy
			mov cx, 153 ; 153 pozycje w planszy
				wstaw:
					mov al, ds:[plansza+si]
					cmp al, 14
					jae znak14 ; >=
						mov ah, 0
						mov di, ax
						mov ah, ds:[znaki+di]
						mov ds:[plansza+si], ah
					powrot_znak14:
					inc si
				loop wstaw
				
				mov ds:[plansza+76], 'S'	; wstawiam S na pozycje początku
				mov al, ds:[pozycja_konca]			; wstawiam E na koniec
				mov ah, 0
				mov di,ax
				mov ds:[plansza+di], 'E' 
		pop ds 
		pop di
		pop si
		pop cx
	ret

	znak14: 
		mov byte ptr ds:[plansza+si], '^'
	jmp powrot_znak14

;/////////////////////////////////////////////////////WYPISYWANIE PLANSZY////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	wypisz_plansze: ; wypisuje na ekran planszę, linia po linii
		push si
		push cx
		push di
		push ds
		push dx
		
		mov ax, seg argumenty
		mov ds, ax
		
			call print_belka_gora
			
			mov cx,9
			mov si, 0
			
				linia: ; wypisuje kolejne linie planszy
					push cx
						mov di, 1
						mov cx, 17
						
						kolejne_znaki: ; przepisuje kolejne znaki z planszy do linii 
							mov al, ds:[plansza+si]
							mov ds:[linia_do_wypisania+di], al
							inc di
							inc si
						loop kolejne_znaki
						
						call print_linia
					pop cx
				loop linia
				
			call print_belka_dol
			
		pop dx
		pop ds
		pop di
		pop cx	
		pop si
	ret

	print_linia: ; wypisuje jedną linię
		mov ax, seg linia_do_wypisania
		mov ds, ax
		mov dx, offset linia_do_wypisania
		call print
	ret

	print_belka_gora:
		mov ax, seg belka_gora
		mov ds, ax
		mov dx, offset belka_gora
		call print
	ret

	print_belka_dol:
		mov ax, seg belka_dol
		mov ds, ax
		mov dx, offset belka_dol
		call print
	ret
	
kod ends

;////////////////////////////////////////STOS////////////////////////////////////////////////////////////////////////////////////////
;////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

stos1 segment stack 

	dw 200 dup (?)
	wstosu dw ?

stos1 ends

end start