TITLE euclidmatrix.asm
; Header comment block
; Created by Gabriel Jones
; Created on 11/26/18
; Program Description: 
; First function will find the greatest common divisor of two numbers and say if it was prime.
; Second function will randomly generate a matrix of letters and find words in it.

INCLUDE Irvine32.inc

.data
; variables are defined here


.code
main PROC

.data
MenuPrompt BYTE "Would you like to find a GCD or view a letter matrix? Press 1 or 2 to choose.",0Ah,0Dh,0
GCDPrompt BYTE "1. Find a GCD",0Ah,0Dh,0
MatrixPrompt BYTE "2. View a letter matrix",0Ah,0Dh,0
ExitPrompt BYTE "3. Exit",0Ah,0Dh,0
ErrorPrompt BYTE "Please only enter 1-3.",0Ah,0Dh,0
LetterMatrix BYTE 25 DUP(0)

.code
;Prototypes
findGCD PROTO
euclidRecursive PROTO, firstNum:DWORD, secondNum:DWORD
MarkPrimes PROTO, PrimeArrayPtr: PTR WORD
makeMatrix PROTO, LetterMatrixPtr: PTR BYTE
printMatrix PROTO, LetterMatrixPtr: PTR BYTE
checkRows PROTO, LetterMatrixPtr: PTR BYTE
checkColumns PROTO, LetterMatrixPtr: PTR BYTE
checkDiagonals PROTO, LetterMatrixPtr: PTR BYTE

;Set random seed
call Randomize

goAgain:
;Prints main menu
mov eax,0
mov edx,offset MenuPrompt
call writeString
mov edx,offset GCDPrompt
call writeString
mov edx,offset MatrixPrompt
call writeString
mov edx,offset ExitPrompt
call writeString
call readDec

;Checks input to see if it's valid, then jumps to appropriate function
cmp eax,1
je runGCD
cmp eax,2
je runMatrix
cmp eax,3
je quitMenu
;Input was not 1-3
mov edx,offset ErrorPrompt
call writeString

jmp goAgain
runGCD:

call clrscr
invoke findGCD
call clrscr

jmp goAgain
runMatrix:

call clrscr
invoke makeMatrix, addr LetterMatrix
invoke printMatrix, addr LetterMatrix
invoke checkRows, addr LetterMatrix
invoke checkColumns, addr LetterMatrix
invoke checkDiagonals, addr LetterMatrix
call waitMsg
call clrscr

jmp goAgain
quitMenu:

exit
main ENDP ; end of main procedure

findGCD PROC
; Description: Takes in two numbers and prints the GCD, makes use of the recursive function.
; Receives: Two numbers to compute the GCD from the user
; Returns: The GCD of the two entered numbers.
.data

GCDMenu BYTE "Number #1 Number #2 GCD       GCD Prime?",0Ah,0Dh,0
GCDMenu2 BYTE "---------------------------------------------------------",0Ah,0Dh,0
GCDMenuSpace BYTE "         ",0
GCDAgain BYTE "Do you wish to enter another pair? (Y/N)",0Ah,0Dh,0
NumPrompt BYTE "What is the first number? ",0Ah,0Dh,0
NumPrompt2 BYTE "What is the second number? ",0Ah,0Dh,0

FirstValue DWORD ?
SecondValue DWORD ?
GCD DWORD ?
IsPrime DWORD 0

YesPrime BYTE "Yes",0Ah,0Dh,0
NoPrime BYTE "No",0Ah,0Dh,0

PrimeBooleans WORD 1000d DUP(0)

.code

invoke MarkPrimes, addr PrimeBooleans

findAnother:

;Get the two values from the user
mov eax,0
mov edx,0
mov ecx,0
mov ebx,0

mov edx,offset NumPrompt
call writeString
call readDec
mov FirstValue,eax

mov edx,offset NumPrompt2
call writeString
call readDec
mov SecondValue,eax

;Print the inital menu
mov edx,offset GCDMenu
call writeString
mov edx,offset GCDMenu2
call writeString

;Find the GCD and store it
invoke euclidRecursive, FirstValue, SecondValue
mov GCD,eax

;Since the prime is also an index we can multiply it to get it into WORD indexing
mov ecx,2
mul ecx

;If the value at the index is a 0, we can say it's prime, if not, it isn't prime.
mov ebx,offset PrimeBooleans
mov cx,[PrimeBooleans+eax]
cmp ecx,0
jne notPrime

mov isPrime,1

jmp printResults
notPrime:

mov isPrime,0

printResults:

;Obnoxious amount of lines to print the final results

mov eax,FirstValue
call writeDec
mov edx,offset GCDMenuSpace
call writeString
mov eax,SecondValue
call writeDec
call writeString
mov eax,GCD
call writeDec
call writeString

mov eax,IsPrime
cmp eax,0
je notAPrime

mov edx,offset YesPrime
call writeString

jmp endPrime
notAPrime:

mov edx,offset NoPrime
call writeString


endPrime:

;Asks if the user wants to run another pair of numbers. If input is anything but a Y or y it will exit.
mov eax,0
mov edx,offset GCDAgain
call writeString
call readChar
cmp al,'Y'
je findAnother
cmp al,'y'
je findAnother


ret
findGCD ENDP

euclidRecursive PROC, firstNum:DWORD, secondNum:DWORD
; Description: Takes in two numbers and computes the GCD recursively. Will subtract the smaller number from the larger until both are equal.
; Receives: Two numbers to compute the GCD from the user
; Returns: The GCD of the two entered numbers in EAX.
.data


.code

;When we reach the case they are equal, we jump to the end
mov eax,secondNum
cmp eax,firstNum
je foundGCD
jg secondIsGreater
;Second is less

;If the second number was smaller, subtract it from the first and call the function again
mov eax,firstNum
sub eax,secondNum
mov firstNum,eax

invoke euclidRecursive, firstNum, secondNum
ret




secondIsGreater:

;If the first number was smaller, subtract it from the second and call the function again
sub eax,firstNum
mov secondNum,eax

invoke euclidRecursive, firstNum, secondNum
ret



foundGCD:
;GCD is 'returned' in EAX
mov eax,firstNum


ret
euclidRecursive ENDP

MarkPrimes PROC PrimeArrayPtr: PTR WORD
; Description: Divides each index from 2-1000 with the numbers 2-32 to determine if that specific index is a prime. If it is, it stays 0, if not, it becomes a 1.
; Receives: Offset of "boolean" array in PrimeArrayPtr
; Returns: Boolean array of primes in PrimeArrayPtr
.data
CurrentValue DWORD 0
.code


;Move offset of array in ebx
mov ebx,PrimeArrayPtr 
mov edi,2 ;We use a counter with 2 based indexing since our prime array is full of words
;Mark both 0 and 1 as not being primes
mov [ebx],word ptr 1
mov [ebx+2], word ptr 1

;We loop back here if the counter hasn't reached 1 thousand
NotThousand:

mov ecx,31d ;Loop counter
mov esi,32d ;Loop divisor (this will skip 1 since literally every number is divisible by 1)
DivisionLoop: ;Divides current index of the array by every number between 2 and 32 (32 is the sqrt of 1000 and is all that's necessary for us to divide by)
	push ebx
	cmp edi,esi ;Compare the current position by the divisor
	je Prime ;Jumps if we are dividing the number by itself (Ie 2 by 2)

	;Convert the edi array indexer back into 1 format by dividing by 2
	mov edx,0
	mov eax,edi
	mov ebx,2
	div ebx
	;We store this value so we can compare if it's equal to the divisor later
	mov CurrentValue,eax

	;Divide the current array position by the divisor to see if has a remainder
	mov edx,0
	mov ebx,esi
	div ebx
	pop ebx
	;Division with a remainder means it's not a prime, so we jump if there ever is a remainder
	cmp edx,0
	jne Prime
	;Then we check if the value is being divided by itself, in which case we can assume it's prime
	cmp CurrentValue,esi
	je Prime
	
	;If it was found to not be a prime, mark it with a 1
	mov [ebx+edi],word ptr 1

	Prime:
	dec esi
loop DivisionLoop


inc edi
inc edi
cmp edi,2000 ;Make sure we haven't reached the end of the list (at 2000 since we use word indexing as opposed to 1000)
jl NotThousand ;If it's less we repeat what we just did on the next element in the array

ret
MarkPrimes ENDP

makeMatrix PROC, LetterMatrixPtr: PTR BYTE
; Description: Fills a 5 by 5 matrix of letters. There's a 50/50 chance to select a consonant or vowel at each index.
; Receives: Offset of empty matrix
; Returns: Filled matrix of letters
.data
Vowels BYTE 'A','E','I','O','U'
Consonants BYTE 'B','C','D','F','G','H','J','K','L','M','N','P','Q','R','S','T','V','W','X','Y','Z'
.code


mov edx,LetterMatrixPtr
mov ecx,25
fillMatrixLoop:

;Generates a 0 or 1 to determine if vowel or consonant will be added
mov ebx,0
mov eax,2
call RandomRange
cmp eax,0
je pickedVowel

;If it picked consonant, randomly pick one of the 21 consonants and add it to the matrix
mov eax,21
call RandomRange
mov bl,[Consonants+eax]
dec ecx
mov [edx+ecx],bl
inc ecx

jmp MatrixLoopEnd
pickedVowel:

;If it picked vowel, randomly pick one of the 5 vowels and add it to the matrix
mov eax,5
call RandomRange
mov bl,[Vowels+eax]
dec ecx
mov [edx+ecx],bl
inc ecx

MatrixLoopEnd:


loop fillMatrixLoop

ret
makeMatrix ENDP

printMatrix PROC, LetterMatrixPtr: PTR BYTE
; Description: Prints the randomly generated matrix. Prints five letters per line, for five lines.
; Receives: Matrix of letters.
; Returns: Printed version of matrix to console.
.data
foundWordsPrompt BYTE "We found these words in the matrix:",0Ah,0D,0h
.code

mov ebx,LetterMatrixPtr
mov ecx,5
mov eax,0
mov esi,0
;Loop will cause the cursor to skip the next line.
printMatrixLoop:

;Prints the next 5 characters in the matrix followed by a space.
mov al,[ebx+esi]
call writeChar
mov al,20h
call writeChar
inc esi

mov al,[ebx+esi]
call writeChar
mov al,20h
call writeChar
inc esi

mov al,[ebx+esi]
call writeChar
mov al,20h
call writeChar
inc esi

mov al,[ebx+esi]
call writeChar
mov al,20h
call writeChar
inc esi

mov al,[ebx+esi]
call writeChar
mov al,20h
call writeChar
inc esi

call crlf

loop printMatrixLoop

call crlf
mov edx,offset foundWordsPrompt
call writeString

ret
printMatrix ENDP

checkRows PROC, LetterMatrixPtr: PTR BYTE
; Description: Checks all 5 rows of the matrix to see if there are any words (a word in this case is anything that has two vowels and three consonants)
; Receives: Offset of letter matrix
; Returns: Found words printed to console
.data
RowVowelCount BYTE 0
RowConsCount BYTE 0
CurrentIndex DWORD 0

.code

mov ebx,LetterMatrixPtr
mov ecx,5
mov eax,0
mov esi,0
;Outer loop will check all 5 rows
countRows:
	mov RowVowelCount,0
	mov RowConsCount,0
	push ecx
	mov ecx,5
	mov CurrentIndex,esi

	;Inner loop will count vowels and consonants in the particular row
	checkRow:
		;Check if current index is a vowel, and make the appropirate jump
		mov al,[ebx+esi]
		cmp eax,'A'
		je countTheVowel
		cmp eax,'E'
		je countTheVowel
		cmp eax,'I'
		je countTheVowel
		cmp eax,'O'
		je countTheVowel
		cmp eax,'U'
		je countTheVowel
		;Count consonant

		inc RowConsCount

		jmp endRow
		countTheVowel:
		inc RowVowelCount

		endRow:

		inc esi ;Will increment the indexer by 1 since we use row-major format
	loop checkRow

	mov eax,0
	;Checks if the number of vowels was 2, if it wasn't, then it doesn't classify as a word
	mov al,RowVowelCount
	cmp al,2
	jne doNotPrintRow

	push ecx
	push esi
	;Loops through the previously checked row and prints all 5 characters
	mov ecx,5
	mov esi,CurrentIndex
	printRow:
		mov al,[ebx+esi]
		call writeChar
		
		inc esi
	loop printRow
	call crlf
	pop esi
	pop ecx

	doNotPrintRow:

	pop ecx
loop countRows

ret
checkRows ENDP

checkColumns PROC, LetterMatrixPtr: PTR BYTE
; Description: Checks all 5 columns of the matrix to see if there are any words (a word in this case is anything that has two vowels and three consonants)
; Receives: Offset of letter matrix
; Returns: Found words printed to console
.data
ColVowelCount BYTE 0
ColConsCount BYTE 0
CurrentIndexCol DWORD 0


.code

mov ebx,LetterMatrixPtr
mov ecx,5
mov eax,0
mov esi,0
;Loop through all 5 columns
countCol:
	mov ColVowelCount,0
	mov ColConsCount,0
	mov CurrentIndexCol,ecx
	mov esi,ecx

	push ecx
	mov ecx,5

	;Check all 5 values of the column 
	checkCol:
		;Check if current index is a vowel and make the appropriate jump
		mov al,[ebx+esi]
		cmp eax,'A'
		je countTheVowelCol
		cmp eax,'E'
		je countTheVowelCol
		cmp eax,'I'
		je countTheVowelCol
		cmp eax,'O'
		je countTheVowelCol
		cmp eax,'U'
		je countTheVowelCol
		;Count consonant

		inc ColConsCount

		jmp endCol
		countTheVowelCol:
		inc ColVowelCount

		endCol:

		;Incrementing by 5 will skip to next column since we have 5 items in each row (using row-major format)
		add esi,5
	loop checkCol

	mov eax,0
	;If vowel count wasn't 2 then the column wasn't a word
	mov al,ColVowelCount
	cmp al,2
	jne doNotPrintCol

	push ecx
	push esi
	mov ecx,5
	;Print the previously read column, again using 5 counter to skip rows.
	mov esi,CurrentIndexCol
	printCol:
		mov al,[ebx+esi]
		call writeChar
		
		add esi,5
	loop printCol
	call crlf
	pop esi
	pop ecx

	doNotPrintCol:

	pop ecx
loop countCol


ret
checkColumns ENDP

checkDiagonals PROC, LetterMatrixPtr: PTR BYTE
; Description: Checks both rows of the matrix to see if there are any words (a word in this case is anything that has two vowels and three consonants)
; Receives: Offset of letter matrix
; Returns: Found words printed to console
.data
DiaVowelCount BYTE 0
DiaConsCount BYTE 0
.code
mov ebx,LetterMatrixPtr
mov ecx,5
mov eax,0
mov esi,0
mov DiaVowelCount,0
mov DiaConsCount,0

;First loop will check the diagonal that goes top left to bottom right
firstDiagonal:
	mov al,[ebx+esi]
		cmp eax,'A'
		je countTheVowelDia
		cmp eax,'E'
		je countTheVowelDia
		cmp eax,'I'
		je countTheVowelDia
		cmp eax,'O'
		je countTheVowelDia
		cmp eax,'U'
		je countTheVowelDia
		;Count consonant

		inc DiaConsCount

		jmp endDia
		countTheVowelDia:
		inc DiaVowelCount

		endDia:

		add esi,6 ;Will move down a row and also skip a column
loop firstDiagonal

mov eax,0
mov esi,0
	mov al,DiaVowelCount
	cmp al,2
	jne doNotPrintDia

	
	mov ecx,5
	;Will print diagonal if was a valid word
	printDia:
		mov al,[ebx+esi]
		call writeChar
		
		add esi,6
	loop printDia
	call crlf

	doNotPrintDia:

mov DiaVowelCount,0
mov DiaConsCount,0

mov ecx,5
mov esi,4

;Checks diagonal that goes top right to bottom left
secondDiagonal:
	mov al,[ebx+esi]
		cmp eax,'A'
		je countTheVowelDia2
		cmp eax,'E'
		je countTheVowelDia2
		cmp eax,'I'
		je countTheVowelDia2
		cmp eax,'O'
		je countTheVowelDia2
		cmp eax,'U'
		je countTheVowelDia2
		;Count consonant

		inc DiaConsCount

		jmp endDia2
		countTheVowelDia2:
		inc DiaVowelCount

		endDia2:

		add esi,4 ;Will move down a row but back one column
loop secondDiagonal

mov eax,0
mov esi,4
	mov al,DiaVowelCount
	cmp al,2
	jne doNotPrintDia2

	
	mov ecx,5
	printDia2:
		mov al,[ebx+esi]
		call writeChar
		
		add esi,4
	loop printDia2
	call crlf

	doNotPrintDia2:


ret
checkDiagonals ENDP

END main ; end of source code
