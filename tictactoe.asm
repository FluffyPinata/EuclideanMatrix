TITLE tictactoe.asm
; Header comment block
; Created by Gabriel Jones
; Created on 12/1/18
; Program Description: 
; Allows the user to play tic tac toe against either another player, a computer, or have two computers play eachother.
; Moves are entered with keys 0-8
; Program will keep track of amount of games played as well as the number of tie games.


INCLUDE Irvine32.inc

.data
; variables are defined here

.code
main PROC
.data
;The gameboard we pass to all subsequent functions
Board BYTE 9 DUP(0)
WhoTurn BYTE 0

menuPrompt BYTE "Welcome to tic tac toe! Select any of the 3 games below using the number keys:",0Ah,0Dh,0
opt1 BYTE "1. Player versus player",0Ah,0Dh,0
opt2 BYTE "2. Player versus computer",0Ah,0Dh,0
opt3 BYTE "3. Computer versus computer",0Ah,0Dh,0
opt4 BYTE "4. Print statistics",0Ah,0Dh,0
opt5 BYTE "5. Exit program",0Ah,0Dh,0
errorPromptMenu BYTE "Please ensure the number you entered is between 1 and 5",0Ah,0Dh,0

PVPCounter BYTE 0
PVCCounter BYTE 0
CVCCounter BYTE 0
TieCounter BYTE 0

.code
; exe code goes here

;Prototypes
makeBoard PROTO, boardPtr: PTR BYTE
printBoard PROTO, boardPtr: PTR BYTE
printWinningBoard PROTO, boardPtr: PTR BYTE, first: DWORD, second: DWORD, third: DWORD
makePlayerMove PROTO, boardPtr: PTR BYTE, turnFlag: BYTE
makeComputerMove PROTO, boardPtr: PTR BYTE, turnFlag: BYTE
checkWinner PROTO, boardPtr: PTR BYTE, turnFlag: BYTE
setXOColor PROTO
setXOColorWinner PROTO, first: DWORD, second: DWORD, third: DWORD
playerVsPlayer PROTO, boardPtr: PTR BYTE
computerVsComputer PROTO, boardPtr: PTR BYTE
playerVsComputer PROTO, boardPtr: PTR BYTE
printStats PROTO, PVPGames: BYTE, PVCGames: BYTE, CVCGames: BYTE, TieCount: BYTE
printRules PROTO

call Randomize

startAgain:

;Will print the menu and all options
mov edx,offset menuPrompt
call writeString
mov edx,offset opt1
call writeString
mov edx,offset opt2
call writeString
mov edx,offset opt3
call writeString
mov edx,offset opt4
call writeString
mov edx,offset opt5
call writeString

;Reads user input and makes an appropriate jump
mov eax,0
call readDec

;Error checking jump
cmp eax,0
jb invalidInput
cmp eax,5
ja invalidInput
jmp continueMenu
invalidInput:

;Jumps back to start if input was invalid
mov edx,offset errorPromptMenu
call writeString
call waitMsg
call clrscr

jmp startAgain
continueMenu:

cmp eax,1
jne PVC

;First play the PVP game, then check if it was a tie (tie result is stored in eax)
invoke playerVsPlayer, addr Board
inc PVPCounter
cmp eax,1
jne restartMenu

;If eax was 1, increment the tie counter
inc tieCounter

jmp restartMenu
PVC:
cmp eax,2
jne CVC

invoke playerVsComputer, addr Board
inc PVCCounter
cmp eax,1
jne restartMenu

inc tieCounter

jmp restartMenu
CVC:
cmp eax,3
jne STATS

invoke computerVsComputer, addr Board
inc CVCCounter
cmp eax,1
jne restartMenu

inc tieCounter

jmp restartMenu
STATS:
cmp eax,4
jne QUIT

invoke printStats, PVPCounter, PVCCounter, CVCCounter, TieCounter

restartMenu:

call waitMsg
call clrscr

jmp startAgain
QUIT:

exit
main ENDP ; end of main procedure

playerVsComputer PROC, boardPtr: PTR BYTE
; Description: Runs a game of tic tac toe against the computer. Player (X) or computer (O) is chosen randomly to go first.
; Receives: Pointer to the game board
; Returns: If game was a tie in eax (1 for yes).
.data

PlayerVC1Prompt BYTE "Player, please enter your move.",0Ah,0Dh,0
PlayerVC1Win BYTE "Player has won the game!",0Ah,0Dh,0
ComputerVP1Win BYTE "Computer has won the game!",0Ah,0Dh,0

CurrentTurnPVC BYTE 0

.code
mov ebx,boardPtr

;Create the blank board
invoke makeBoard, ebx

;Pick who goes first (0 for player, 1 for comp)
mov eax,2
call RandomRange
cmp eax,0
jne pickComp

mov CurrentTurnPVC,0

jmp continuePVC
pickComp:

mov CurrentTurnPVC,1

continuePVC:

;Loop 9 times for all 9 spaces in the board
mov ecx,9
pvcLoop:
push ecx

cmp CurrentTurnPVC,0
jne computerTurn

;Make a player move and flip the current player
mov ebx,boardPtr
invoke makePlayerMove, ebx, CurrentTurnPVC
mov CurrentTurnPVC,al

;Delay for a second and clear the screen
call crlf
mov eax,1000
call Delay
call clrscr

;Check if the player won after making that won (1 will be in eax)
mov ebx,boardPtr
invoke checkWinner, ebx, CurrentTurnPVC
cmp eax,1
jne notWonPVC


jmp wonPVC
computerTurn:

;Make a computer move if it's their turn and nobody has won yet
mov ebx,boardPtr
invoke makeComputerMove, ebx, CurrentTurnPVC
mov CurrentTurnPVC,al

;Delay a second
call crlf
mov eax,1000
call Delay
call clrscr

;Check if the computer won after making that move
mov ebx,boardPtr
invoke checkWinner, ebx, CurrentTurnPVC
cmp eax,1
jne notWonPVC
wonPVC:

;Player or comp won
;First check if it was player or comp who just won and print the appropriate message
cmp CurrentTurnPVC,1
jne playerWinCon
mov edx,offset playerVC1Win
call writeString
jmp winnerEscapePVC
playerWinCon:
mov edx,offset computerVP1Win
call writeString
winnerEscapePVC:
pop ecx
;Changet the flag so it's not a tie
mov eax,0

jmp someoneWonPVC
notWonPVC:

;If the game wasn't won, print the normally updaed board
mov ebx,boardPtr
invoke printBoard, ebx

;Set the flag for a tie if this was the last move
mov eax,1

endPVC:

pop ecx
dec ecx
cmp ecx,0
jne pvcLoop

someoneWonPVC:

ret
playerVsComputer ENDP

computerVsComputer PROC, boardPtr: PTR BYTE
; Description: Runs a game of tic tac toe between two computers. First computer will always pick the center.
; Receives: Pointer to the game board
; Returns: If game was a tie in eax (1 for yes).
.data

Computer1Win BYTE "Computer X has won the game!",0Ah,0Dh,0
Computer2Win BYTE "Computer O has won the game!",0Ah,0Dh,0

CurrentTurnC BYTE 0

.code
;Set the flag for the turn so that X always goes first
mov CurrentTurnC,0
mov ebx,boardPtr

;Creates a new blank board
invoke makeBoard, ebx
mov ecx,9
cvcLoop:
push ecx

;Make a compute move and invert the flag
mov ebx,boardPtr
invoke makeComputerMove, ebx, CurrentTurnC
mov CurrentTurnC,al

;Delay for a second and clear the screen
call crlf
mov eax,1000
call Delay
call clrscr

;Check if the computer on that turn won
mov ebx,boardPtr
invoke checkWinner, ebx, CurrentTurnC
cmp eax,1
jne notWinnerC

;If they did win, print which computer won and set the tie flag to be false
cmp CurrentTurnC,1
jne computer2WinCon
mov edx,offset Computer1Win
call writeString
jmp winnerEscapeC
computer2WinCon:
mov edx,offset Computer2Win
call writeString
winnerEscapeC:
pop ecx
mov eax,0

jmp someoneWonC
notWinnerC:

;If not a winner, just print the updated game board and set the tie flag
mov ebx,boardPtr
invoke printBoard, ebx
mov eax,1

endPVP:

pop ecx
dec ecx
cmp ecx,0
jne cvcLoop

someoneWonC:

ret
computerVsComputer ENDP

playerVsPlayer PROC, boardPtr: PTR BYTE
; Description: Runs a game of tic tac toe against another player. 
; Receives: Pointer to the game board
; Returns: If game was a tie in eax (1 for yes).
.data

Player1Prompt BYTE "Player X, please enter your move.",0Ah,0Dh,0
Player2Prompt BYTE "Player O, please enter your move.",0Ah,0Dh,0
Player1Win BYTE "Player X has won the game!",0Ah,0Dh,0
Player2Win BYTE "Player O has won the game!",0Ah,0Dh,0

CurrentTurn BYTE 0

.code
mov ebx,boardPtr

;Creates the empty board
invoke makeBoard, ebx
mov ecx,9
pvpLoop:
push ecx

;Will pick the current player's turn based on the flag and print an appropriate message
cmp CurrentTurn,0
jne player2Turn
mov edx,offset Player1Prompt
call writeString
jmp pvpPlayGame
player2Turn:
mov edx,offset Player2Prompt
call writeString


pvpPlayGame:

;Makes that player's move and inverts the turn flag
mov ebx,boardPtr
invoke makePlayerMove, ebx, CurrentTurn
mov CurrentTurn,al

;Delays a second
call crlf
mov eax,1000
call Delay
call clrscr

;Checks if that player won on the turn
mov ebx,boardPtr
invoke checkWinner, ebx, CurrentTurn
cmp eax,1
jne notWinner

;If they did win, print the win message and exit the function. Also set the tie flag to 0.
cmp CurrentTurn,1
jne player2WinCon
mov edx,offset Player1Win
call writeString
jmp winnerEscape
player2WinCon:
mov edx,offset Player2Win
call writeString
winnerEscape:
pop ecx
mov eax,0

jmp someoneWon
notWinner:

;If they didn't win, print the updated board.
mov ebx,boardPtr
invoke printBoard, ebx
mov eax,1

endPVP:

pop ecx
dec ecx
cmp ecx,0
jne pvpLoop

someoneWon:

ret
playerVsPlayer ENDP

makeBoard PROC, boardPtr: PTR BYTE
; Description: Fills the board with blanks ('-')
; Receives: Pointer to the game board
; Returns: boardPtr with blank spaces
.data


.code

;Loops through each of the 9 indexes of our matrix (purely a 9 length array), and sets each one to be a '-' character.
mov ebx,boardPtr
mov ecx,9
mov esi,0
mov al,'-'
fillLoop:
	mov [ebx+esi],al
	inc esi
loop fillLoop

ret
makeBoard ENDP

printBoard PROC, boardPtr: PTR BYTE
; Description: Prints the current state of the board provided neither player has won on that turn. X's are printed with yellow background and O's have cyan background.
; Receives: Pointer to the game board
; Returns: Updated game board.
.data

.code

mov ebx,boardPtr
mov ecx,3
mov esi,0
mov eax,0
printLoop:
	;Since the board spans 3 lines we will loop 3 times.
	;This will move the current index of the matrix into al and set the color if was an x or o.
	mov al,[ebx+esi]
	invoke setXOColor
	inc esi

	;Inbetween each index we put a '|'
	mov al,'|'
	call writeChar

	mov al,[ebx+esi]
	invoke setXOColor
	inc esi

	mov al,'|'
	call writeChar
	
	mov al,[ebx+esi]
	invoke setXOColor
	inc esi

	call crlf
loop printLoop

ret
printBoard ENDP

setXOColor PROC
; Description: Sets the color of an X or O on the gameboard. 
; Receives: Current contents of the current index of the matrix.
; Returns: Updated color if the content was an X or O.
.data

.code

;If the content was originally an '-', we do nothing.
cmp eax,'-'
je endSetXO
cmp eax,'X'
je isX
;isO
;If it's an O, we set the text color to be black with cyan background.
mov eax,black + (cyan * 16)
call setTextColor
mov eax,0
mov al,'O'

jmp endSetXO
isX:
;If it's an X, we set the text color to be black with a yellow backround.
mov eax,black + (yellow * 16)
call setTextColor
mov eax,0
mov al,'X'

endSetXO:

;At the end we revert the color to be light gray with black background while printing the character.
call writeChar
mov eax,lightGray + (black*16)
call setTextColor
mov eax,0

ret
setXOColor ENDP

makePlayerMove PROC, boardPtr: PTR BYTE, turnFlag: BYTE
; Description: Gets the move of a player user and updates the gameboard
; Receives: Pointer to the game board
; Returns: Updated gameboard
.data
pickMovePrompt BYTE "Where would you like to make a move? Enter a number 0-8.",0Ah,0Dh,0
errorPrompt BYTE "Please ensure you enter a number between 0 and 8.",0Ah,0Dh,0
errorNoRoomPrompt BYTE "The position you tried to enter already has been filled, please enter another one.",0Ah,0Dh,0
playerMove BYTE 0

.code

enterAgain:
mov eax,0

;Firstly prints how to make a move.
;Asks the user for a move and checks if it's valid
invoke printRules
mov edx,offset pickMovePrompt
call writeString
call readDec
cmp eax,0
jb invalidInput
cmp eax,8
ja invalidInput
jmp continueMove
invalidInput:

;If it wasn't valid, jump back to the start of the function.
mov edx,offset errorPrompt
call writeString
call waitMsg
call clrscr


jmp enterAgain
continueMove:

;Stores the move
mov playerMove,al

;Will check if it's X or O turn and move into al.
mov eax,0
mov al,turnFlag
cmp turnFlag,0
je xTurn
;oTurn
mov eax,0
mov al,'O'
jmp adjustBoard
xTurn:
mov eax,0
mov al,'X'

adjustBoard:

;Moves the X or O into the player's chosen index on the board. If the index is occupied it will jump back to the start.
mov ebx,boardPtr
mov ecx,0
mov cl,playerMove
mov edx,0
mov edx,[ebx+ecx]
cmp dl,'-'
jne errorMove
mov [ebx+ecx],al

jmp endMove
errorMove:

;Display quick error message and try again.
mov edx,offset errorNoRoomPrompt
call writeString
jmp enterAgain
endMove:

;Inverts the current turn.
mov eax,0
mov al,turnFlag
cmp al,0
je invertTurn
mov turnFlag,0
jmp endFunction
invertTurn:
mov turnFlag,1

endFunction:

;Stores inverted flag in al.
mov eax,0
mov al,turnFlag


ret
makePlayerMove ENDP

makeComputerMove PROC, boardPtr: PTR BYTE, turnFlag: BYTE

.data

computerMove BYTE 0
; Description: Randomly generates a move for the computer and updates the gameboard
; Receives: Pointer to the game board
; Returns: Updated gameboard
.code

;First checks if center has already been played. If it hasn't, set the computer's move to that.
mov eax,0
mov ebx,boardPtr
mov al,[ebx+4]
cmp al,'-'
jne nonEmptyCenter

mov computerMove,4

jmp computerContinueMove
nonEmptyCenter:

;Otherwise randomly generate a move from 0-8.
mov eax,9
call RandomRange 

mov computerMove,al

computerContinueMove:

;First check the turn flag and move either X or O into al.
mov eax,0
mov al,turnFlag
cmp turnFlag,0
je xTurnC
;oTurnC
mov eax,0
mov al,'O'
jmp adjustBoardC
xTurnC:
mov eax,0
mov al,'X'

adjustBoardC:

;Move the X or O into the computer chosen index. If it's already occupied jump back the start of the function.
mov ebx,boardPtr
mov ecx,0
mov cl,computerMove
mov edx,0
mov edx,[ebx+ecx]
cmp dl,'-'
jne nonEmptyCenter ;If move was already occupied
mov [ebx+ecx],al

;Invert the turn flag.
mov eax,0
mov al,turnFlag
cmp al,0
je invertTurn
mov turnFlag,0
jmp endFunctionC
invertTurn:
mov turnFlag,1

endFunctionC:

;Move the turn flag into eax
mov eax,0
mov al,turnFlag

ret
makeComputerMove ENDP

checkWinner PROC, boardPtr: PTR BYTE, turnFlag: BYTE
; Description: Checks if the board currently has a winning row, column or diagonal.
; Receives: Pointer to the game board, current player turn.
; Returns: Whether the game is won in eax.
.data

FirstIndex DWORD ?
SecondIndex DWORD ?
ThirdIndex DWORD ?

WinnerFlag BYTE 0
WinFirstIndex DWORD ?
WinSecondIndex DWORD ?
WinThirdIndex DWORD ?

XOCounter BYTE 0

CheckingXO BYTE ?

.code

mov winnerFlag,0
mov XOCounter,0

;First determines if needs to count X or O
mov eax,0
mov al,turnFlag
cmp turnFlag,1
je checkingX
mov eax,0
mov al,'O'
mov CheckingXO,al
jmp checkingBoard
checkingX:
mov eax,0
mov al,'X'
mov CheckingXO,al
checkingBoard:

;Check rows
mov ecx,3
mov esi,0
mov ebx, boardPtr
;Will check all 3 indexes of each row to see if they match X or O. If the count of the X or O is 3, then that is determined to a win.
rowsLoop:
	mov XOCounter,0
	mov eax,0
	mov al,CheckingXO
	mov dl,[ebx+esi]
	mov firstIndex,esi
	cmp al,dl
	jne firstNotCorrectRow

	inc XOCounter

	firstNotCorrectRow:
	inc esi
	mov dl,[ebx+esi]
	mov secondIndex,esi
	cmp al,dl
	jne secondNotCorrectRow

	inc XOCounter

	secondNotCorrectRow:
	inc esi
	mov dl,[ebx+esi]
	mov thirdIndex,esi
	cmp al,dl
	jne thirdNotCorrectRow

	inc XOCounter

	thirdNotCorrectRow:
	inc esi

	mov eax,0
	mov al,XOCounter
	cmp al,3
	jne checkNextRow
	mov winnerFlag,1
	mov eax,firstIndex
	mov winFirstIndex,eax
	mov eax,secondIndex
	mov winSecondIndex,eax
	mov eax,thirdIndex
	mov winThirdIndex,eax

	checkNextRow:

	dec ecx
	cmp ecx,0
jne rowsLoop ;Loop jump was too far so I just did this instead, functionally the same

mov XOCounter,0

;Check cols
mov ecx,3
mov esi,0
mov ebx, boardPtr
;Will check all 3 indexes of each column to see if they match X or O. If the count of the X or O is 3, then that is determined to a win.
colsLoop:
	mov esi,ecx
	dec esi
	mov XOCounter,0
	mov eax,0
	mov al,CheckingXO
	mov dl,[ebx+esi]
	mov firstIndex,esi
	cmp al,dl
	jne firstNotCorrectCol

	inc XOCounter

	firstNotCorrectCol:
	add esi,3
	mov dl,[ebx+esi]
	mov secondIndex,esi
	cmp al,dl
	jne secondNotCorrectCol

	inc XOCounter

	secondNotCorrectCol:
	add esi,3
	mov dl,[ebx+esi]
	mov thirdIndex,esi
	cmp al,dl
	jne thirdNotCorrectCol

	inc XOCounter

	thirdNotCorrectCol:
	add esi,3

	mov eax,0
	mov al,XOCounter
	cmp al,3
	jne checkNextCol
	mov winnerFlag,1
	mov eax,firstIndex
	mov winFirstIndex,eax
	mov eax,secondIndex
	mov winSecondIndex,eax
	mov eax,thirdIndex
	mov winThirdIndex,eax

	checkNextCol:

	dec ecx
	cmp ecx,0
jne colsLoop

;Will check all 3 indexes of the first diagonal to see if they match X or O. If the count of the X or O is 3, then that is determined to a win.
mov XOCounter,0
mov esi,0
mov ebx, boardPtr
	mov eax,0
	mov al,CheckingXO
	mov dl,[ebx+esi]
	mov firstIndex,esi
	cmp al,dl
	jne firstNotCorrectDiag

	inc XOCounter

	firstNotCorrectDiag:
	add esi,4
	mov dl,[ebx+esi]
	mov secondIndex,esi
	cmp al,dl
	jne secondNotCorrectDiag

	inc XOCounter

	secondNotCorrectDiag:
	add esi,4
	mov dl,[ebx+esi]
	mov thirdIndex,esi
	cmp al,dl
	jne thirdNotCorrectDiag

	inc XOCounter

	thirdNotCorrectDiag:
	add esi,4

	mov eax,0
	mov al,XOCounter
	cmp al,3
	jne checkNextDiag
	mov winnerFlag,1
	mov eax,firstIndex
	mov winFirstIndex,eax
	mov eax,secondIndex
	mov winSecondIndex,eax
	mov eax,thirdIndex
	mov winThirdIndex,eax

	checkNextDiag:

	mov XOCounter,0
mov esi,2

;Will check all 3 indexes of the second diagonal to see if they match X or O. If the count of the X or O is 3, then that is determined to a win.
mov ebx, boardPtr
	mov eax,0
	mov al,CheckingXO
	mov dl,[ebx+esi]
	mov firstIndex,esi
	cmp al,dl
	jne firstNotCorrectDiag2

	inc XOCounter

	firstNotCorrectDiag2:
	add esi,2
	mov dl,[ebx+esi]
	mov secondIndex,esi
	cmp al,dl
	jne secondNotCorrectDiag2

	inc XOCounter

	secondNotCorrectDiag2:
	add esi,2
	mov dl,[ebx+esi]
	mov thirdIndex,esi
	cmp al,dl
	jne thirdNotCorrectDiag2

	inc XOCounter

	thirdNotCorrectDiag2:
	add esi,2

	mov eax,0
	mov al,XOCounter
	cmp al,3
	jne checkNextDiag2
	mov winnerFlag,1
	mov eax,firstIndex
	mov winFirstIndex,eax
	mov eax,secondIndex
	mov winSecondIndex,eax
	mov eax,thirdIndex
	mov winThirdIndex,eax

	checkNextDiag2:

;Check if player won
mov eax,0
mov al,winnerFlag
cmp al,0
je notWinner

;If we found one winning condition, we pass those saved indexes into our print funciton.

invoke printWinningBoard, addr Board, winFirstIndex, winSecondIndex, winThirdIndex

notWinner:

mov eax,0
mov al,winnerFlag



ret
checkWinner ENDP

printWinningBoard PROC, boardPtr: PTR BYTE, first: DWORD, second: DWORD, third: DWORD
;Description: Prints the board with all 3 winning indexes highlighted.
;Receives: Board pointer and all 3 winning indexes
;Returns: Board with winning indexes highligted in blue and white.
.data

.code

mov ebx,boardPtr
mov ecx,3
mov esi,0
mov eax,0
mov edx,0
printWinLoop:
	mov al,[ebx+esi]
	mov edx,esi
	invoke setXOColorWinner, first, second, third
	inc esi

	mov al,'|'
	call writeChar

	mov al,[ebx+esi]
	mov edx,esi
	invoke setXOColorWinner, first, second, third
	inc esi

	mov al,'|'
	call writeChar
	
	mov al,[ebx+esi]
	mov edx,esi
	invoke setXOColorWinner, first, second, third
	inc esi

	call crlf
loop printWinLoop

ret
printWinningBoard ENDP

setXOColorWinner PROC, first: DWORD, second: DWORD, third: DWORD
;Description: Checks the passed index to see if it was a winning index. If it was, highlight it in blue text with white background.
;Receives: All 3 winning indexes
;Returns: Board with winning indexes highligted in blue and white.
.data

.code

;If contents was a dash, do nothing.
cmp eax,'-'
je endSetXO
cmp eax,'X'
je isX
;isO
;If the contents was an O, check if it matched any of the stored indexes. If it did, print it in blue with white background.
cmp edx,first
je setWinnerO
cmp edx,second
je setWinnerO
cmp edx,third
je setWinnerO
;Not a winner

mov eax,black + (cyan * 16)
call setTextColor
mov eax,0
mov al,'O'

jmp endSetXO
setWinnerO:

mov eax,blue + (white * 16)
call setTextColor
mov eax,0
mov al,'O'

jmp endSetXO
isX:
;If the contents was an X, check if it matched any of the stored indexes. If it did, print it in blue with white background.
cmp edx,first
je setWinnerX
cmp edx,second
je setWinnerX
cmp edx,third
je setWinnerX

mov eax,black + (yellow * 16)
call setTextColor
mov eax,0
mov al,'X'

jmp endSetXO
setWinnerX:

mov eax,blue + (white * 16)
call setTextColor
mov eax,0
mov al,'X'

endSetXO:

;Reset text color to lightgray with black background at the end.
call writeChar
mov eax,lightGray + (black*16)
call setTextColor
mov eax,0

ret
setXOColorWinner ENDP

printStats PROC, PVPGames: BYTE, PVCGames: BYTE, CVCGames: BYTE, TieCount: BYTE
;Description: Prints the games played of each type as well as the number of tie games.
;Receives: All 4 counts of games and ties.
;Returns: All 4 stats printed.
.data

PVPGamesPrompt1 BYTE "You have played ",0
PVPGamesPrompt2 BYTE " PVP games.",0Ah,0Dh,0
PVCGamesPrompt1 BYTE "You have played ",0
PVCGamesPrompt2 BYTE " PVC games.",0Ah,0Dh,0
CVCGamesPrompt1 BYTE "You have played ",0
CVCGamesPrompt2 BYTE " CVC games.",0Ah,0Dh,0
TieGamesPrompt1 BYTE "There have been ",0
TieGamesPrompt2 BYTE " tie games.",0Ah,0Dh,0

.code

mov eax,0

mov edx,offset PVPGamesPrompt1 
call writeString
mov al,PVPGames
call writeDec
mov edx,offset PVPGamesPrompt2
call writeString

mov edx,offset PVCGamesPrompt1 
call writeString
mov al,PVCGames
call writeDec
mov edx,offset PVCGamesPrompt2
call writeString

mov edx,offset CVCGamesPrompt1 
call writeString
mov al,CVCGames
call writeDec
mov edx,offset CVCGamesPrompt2
call writeString

mov edx,offset TieGamesPrompt1
call writeString
mov al,TieCount
call writeDec
mov edx,offset TieGamesPrompt2
call writeString

ret
printStats ENDP

printRules PROC
;Description: Prints a blank board with each of the indexes in the slots.
;Receives: Nothing
;Returns: Blank board with indexes in place of dashes.
.data

.code

mov ecx,3
mov esi,0
mov eax,0
printLoop:
	mov eax,esi
	call writeDec
	inc esi

	mov al,'|'
	call writeChar

	mov eax,esi
	call writeDec
	inc esi

	mov al,'|'
	call writeChar
	
	mov eax,esi
	call writeDec
	inc esi

	call crlf
loop printLoop

ret
printRules ENDP

END main ; end of source code
