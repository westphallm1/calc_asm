.MODEL SMALL
.STACK 200H
.DATA
;local variables used in subroutines
errType db 0
str2Num_isNeg db 0 
main_getOpp_result db ?
main_MulDivNegBool db ?
main_SumDiffNegBool db ?
sourceOffset dw 0
destOffset dw 0
places dw 0
numStr_addr dw ?
str2num_accum dw ?
num2str_accum dw ?
;For reading input
inputStr_maxlen db 254
inputStr_actlen db 0
eqnStr db 255 dup ("$")
;Input parsed into these 3
numStr1 db 255 dup ("$")
numStr2 db 255 dup ("$")
oppStr db 16 dup ("$")
;parsed into numbers stored here
val1 dw ?
val2 dw ?
valf dw ?
valr dw ?
;final value stored as string here
numStr db 16 dup ("$")
;remainder of divisions
remainderStr db 16 dup ("$")
;constants
inputMsg db "> $"
titleMsg db "ASSEMBLY CALCULATOR (VER 0.01)$"
ansMsg db " = $"
remainderMsg db " (R = $"
remianderMsg_end db ")$"
zeroDivErrStr db "ERR: ZERO DIV$"
overflowErrStr db "ERR: OVERFLOW$"
invalidErrStr db "ERR: INVALID$"
maxIntStr db "32766$"
.CODE
START:
;SET DS TO CURRENT SEGMENT
mov ax, seg numStr
mov ds, ax

;BODY OF CODE

;Display the title
mov dx, offset titleMsg
call printCurrStr
call newLine

mainLoop:
  ;print the prompt ("> ")
  mov dx, offset inputMsg
  call printCurrStr
  
  ;read in the first value
  mov dx, offset eqnStr
  call readInput
  mov dx, offset eqnStr
  ;exit if "Q" was input
  call checkQuit 
  ;parse the input text
  call parseEqnStr 
  ;make sure the strings were input correctly
  mov dx, offset numStr1
  call isValidNumStr 
  cmp al, 0
  jne jmp2MainErrs

  mov dx, offset numStr2
  call isValidNumStr 
  cmp al, 0
  jne jmp2MainErrs

  ;Get the two values to be math'd
  mov dx, offset numStr1
  call str2Num
  mov val1, ax
  mov dx, offset numStr2
  call str2Num
  mov val2, ax
  
  ;read in opperation to perform
  ;(+,-,*,/)
  mov bx, offset oppStr
  mov al, ds:[bx]
  mov main_getOpp_result, al

  ;clear input strings for next cycle
  mov dx, offset eqnStr
  call clearStr
  mov dx, offset numStr1
  call clearStr
  mov dx, offset numStr2
  call clearStr
  mov dx, offset oppStr
  call clearStr
  

  ;set the remainder to "negative" 
  ;and check it later in the print
  ;subroutine
  mov valr, 0FFFFh
  mov al, main_getOpp_result
  cmp al, "+"
  je jmp2MainSumOpt
  cmp al, "-"
  je jmp2MainDiffOpt
  cmp al, "*"
  je jmp2MainProdOpt
  cmp al, "/"
  je jmp2MainQuotOpt


  ;Conditional jumps can't
  ;conditionally jump very far
  ;so have them jump to non -
  ;conditional jumps
  jmp2MainSumOpt:
    jmp mainSumOpt
  jmp2MainDiffOpt:
    jmp mainDiffOpt
  jmp2MainProdOpt:
    jmp mainProdOpt
  jmp2MainQuotOpt:
    jmp mainQuotOpt
  jmp2MainErrs:
    ;clear out strings for next round
    mov errType, al
    mov dx, offset eqnStr
    call clearStr
    mov dx, offset numStr1
    call clearStr
    mov dx, offset numStr2
    call clearStr
    mov dx, offset oppStr
    call clearStr
    ;print appropriate error message
    cmp errType, 1
    je jmp2MainInvalidErr
    cmp errType, 2
    je jmp2MainOverflowErr
    jmp2MainInvalidErr:
      jmp mainLoop_invalidErr
    jmp2MainOverflowErr:
      jmp mainLoop_overFlowErr
;;;;;;;;;
;PROCESS ADDITION
;;;;;;;;;
  mainSumOpt:
    mov main_SumDiffNegBool, 0 
    mov ax, val1
    add ax, val2

    ;Check for overflow
    cmp val1, 7FFFh
    jb main_sumVal1Pos
      ;do this if val1 is negative
      inc main_SumDiffNegBool
    main_sumVal1Pos:
    cmp val2, 7FFFh
    jb main_sumVal2Pos
      ;do this if val2 is negative
      inc main_SumDiffNegBool
    main_sumVal2Pos:
      ;both pos -> pos output
      cmp main_SumDiffNegBool,0
      je main_sumCheckNeg
      ;both neg -> neg output
      cmp main_SumDiffNegBool,2
      je main_sumCheckPos

      ;no risk of overflow if
      ;adding opposite signs
      jmp main_sumIsGood

      ;ensure input is below 
      ;overflow point (gt 0)
      main_sumCheckNeg:
        cmp ax, 7FFFh
        ja main_sumIsBad
      jmp main_sumIsGood
      ;ensure input is above
      ;over flow point (lt 0)
      main_sumCheckPos:
        cmp ax, 7FFFh
        jb main_sumIsBad
      jmp main_sumIsGood
  main_sumIsGood:
    jmp mainLoopEnd
  main_sumIsBad:
    jmp mainLoop_overFlowErr
;;;;;;;;;;
;PROCESS SUBTRACTION
;;;;;;;;;;
  mainDiffOpt:
    mov main_SumDiffNegBool,0
    mov ax, val1
    sub ax, val2
    cmp val1, 7FFFh
    jb main_diffVal1Pos
      ;do if val1 is negative
      inc main_SumDiffNegBool
    main_diffVal1Pos:
    cmp val2, 7FFFh
    jb main_diffVal2Pos
      ;do if val2 is negative
      add main_SumDiffNegBool,2
    main_diffVal2Pos:
    ;val1 lt 0, val2 gt 0 -> out lt 0
    cmp main_SumDiffNegBool,1
    je main_diffCheckPos
    ;val1 gt 0, val2 lt 0 -> out gt 0
    cmp main_SumDiffNegBool,2
    je main_diffCheckNeg

    ;no risk of overflow if subtracting
    ;same sign
    jmp main_diffIsGood
    
    main_diffCheckPos:
      cmp ax, 7FFFh
      jb main_diffIsBad
    jmp main_diffIsGood

    main_diffCheckNeg:
      cmp ax, 7FFFh
      ja main_diffIsBad
    jmp main_diffIsGood
    
  jmp mainLoopEnd

  main_diffIsGood:
    jmp mainLoopEnd
  main_diffIsBad:
    jmp mainLoop_overFlowErr
;;;;;;;;;
;PROCESS MULTIPLICATION
;;;;;;;;;
  mainProdOpt:
    mov dx, 0
    ;get the absolute product of 
    ;the two numbers
    ;this method circumvents the 
    ;overflow checking that would
    ;otherwise be required
    mov main_MulDivNegBool,0
    mov ax, val1
    cmp ax, 7FFFh
    jb main_mul_val1Pos
      neg ax
      inc main_MulDivNegBool
    
    main_mul_val1Pos:
    mov cx, val2
    cmp cx, 7FFFh
    jb main_mul_val2Pos
      neg cx
      dec main_MulDivNegBool

    main_mul_val2Pos:
    mul cx
    ;no overflow should have
    ;occurred
    cmp dx, 0
    jne main_mulIsBad
    cmp ax, 7FFFh 
    ja main_mulIsBad
    mov ax, val1
    mov cx, val2
    mul cx
    jmp main_mulIsGood
main_mulIsGood:
  jmp mainLoopEnd
main_mulIsBad:
  jmp mainLoop_overFlowErr
;;;;;;;
;PROCESS DIVISION
;;;;;;;
  mainQuotOpt:
    mov dx, 0
    ;catch 0 division errors
    cmp val2, 0
    jne main_noZeroDivErr
      call newLine
      mov dx, offset zeroDivErrStr
      call printCurrStr
      call newLine
      call newLine
      jmp mainLoop
    main_noZeroDivErr:
    ;make both values positive
    ;and store whether signs 
    ;are equal
    mov ax, val1
    cmp ax, 7FFFh
    mov main_MulDivNegBool, 0
    jb main_div_numPos
      neg ax
      inc main_MulDivNegBool
    
    main_div_numPos:
    mov cx, val2
    cmp cx, 7FFFh
    jb main_div_denPos
      neg cx
      dec main_MulDivNegBool

    main_div_denPos:
    div cx
    mov valr, dx
    ;make the quotient negative
    ;if the signs of num and denom
    ;are opposite
    cmp main_MulDivNegBool, 0
    je mainLoopEnd
    neg ax
  jmp mainLoopEnd

  mainLoopEnd:
    ;print the output
    call newLine
    mov dx, offset numStr
    call num2Str
    mov dx, offset numStr
    call printCurrStr
    mov dx, offset numStr
    call clearStr

    ;append "(R = X)" in case of 
    ;division
    cmp valr, 0FFFFh
    je mainLoop_oppWasntDiv
      mov dx, offset remainderMsg
      call printCurrStr
      mov ax, valr
      mov dx, offset numStr
      call num2Str
      mov dx, offset numStr
      call printCurrStr
      mov dx, offset numStr
      call clearStr
      mov dx, offset remianderMsg_end
      call printCurrStr
    
    mainLoop_oppWasntDiv:
    call newLine
    call newLine
jmp mainLoop

;print overflow message and loop back
mainLoop_overFlowErr:
  call newLine
  mov dx, offset overflowErrStr
  call printCurrStr
  call newLine
  call newLine
jmp mainLoop

;print invalid message and loop back
mainLoop_invalidErr:
  call newLine
  mov dx, offset invalidErrStr
  call printCurrStr
  call newLine
  call newLine
jmp mainLoop

;;;;;;;;
;Fills the string at dx with '$'
;;;;;;;;
clearStr:
mov bx, dx
  clearStr_not_null:
    mov ah, ds:[bx] 
    mov al, '$'
    mov ds:[bx], al
    inc bx
    cmp ah, '$'
  jne clearStr_not_null
ret

;;;;;;;;;;;;;;;;;;;
;Moves "A + B$" into "A$" "+$" "B$"
;;;;;;;;;;;;;;;;;;;
parseEqnStr:
  mov destOffset, 0 
  mov sourceOffset, 0
  ;read the first term into numStr1
  ;jump over spaces until a non space is found
  mov bx, offset eqnStr
  parseEqnStr_clearStartSpace:
    mov al, ds:[bx]
    cmp al,20h
    jne parseEqnStr_start_Str1
    inc bx
    inc sourceOffset
    jmp parseEqnStr_clearStartSpace
  parseEqnStr_start_Str1:
    ;Special case: first char is '-' sign
    mov bx, offset eqnStr
    add bx, sourceOffset
    mov al, ds:[bx]
    cmp al,'-'
    jne parseEqnStr_isNum1
    mov bx, offset numStr1
    mov ds:[bx], al
    inc sourceOffset
    inc destOffset
  parseEqnStr_isNum1:
    ;add numeric characters to numStr1,
    ;ignoring spaces
    mov bx, offset eqnStr
    add bx, sourceOffset
    mov al, ds:[bx]
    cmp al, 20h
    je parseEqnStr_isNum1_isSpace
    cmp al, 30h
    jb parseEqnStr_isNum1_end
    mov bx, offset numStr1
    add bx, destOffset
    mov ds:[bx], al
    inc destOffset
    parseEqnStr_isNum1_isSpace:
      inc sourceOffset
      jmp parseEqnStr_isNum1
  parseEqnStr_isNum1_end:
  ;read the second term into oppStr
  mov destOffset, 0
  parseEqnStr_isOpp:
    mov bx, offset eqnStr
    add bx, sourceOffset
    mov al, ds:[bx]
    cmp al, 20h
    je parseEqnStr_isOpp_isSpace
    cmp al, 24h
    je parseEqnStr_isOpp_end
    mov bx, offset oppStr
    add bx, destOffset
    mov ds:[bx], al
    jmp parseEqnStr_isOpp_end
    parseEqnStr_isOpp_isSpace:
      inc sourceOffset
      jmp parseEqnStr_isOpp
  parseEqnStr_isOpp_end:
  ;read the last term into numStr2
  inc sourceOffset
  mov destOffset, 0
  parseEqnStr_isNum2:
    mov bx, offset eqnStr
    add bx, sourceOffset
    mov al, ds:[bx]
    cmp al, 20h
    je parseEqnStr_isNum2_isSpace
    cmp al, 24h
    je parseEqnStr_isNum2_end
    cmp al, 20h
    jb parseEqnStr_isOpp_end
    mov bx, offset numStr2
    add bx, destOffset
    mov ds:[bx], al
    inc destOffset
    parseEqnStr_isNum2_isSpace:
    inc sourceOffset
    jmp parseEqnStr_isNum2
  parseEqnStr_isNum2_end:
  parseEqnStr_end:
ret
;;;;;;;;;
;Puts the decimal representation of
;the value at ax into the string at dx
;;;;;;;;
num2Str:
  mov num2str_accum, ax
  ;store the string's address before
  ;it gets overwritten
  mov bx, dx

  ;treat numbers gt 7FFFh as "negative"
  cmp ax, 7FFFh
  jb num2Str_numIsPos

  neg ax;x -> FFFFh - x + 1
  mov num2str_accum,ax
  ;add a '-' sign to the front of the string
  mov al, '-'
  mov ds:[bx], al
  inc bx

  num2Str_numIsPos:
  ;set places to the greatest power of 10
  ;less than num
  mov places, 1
  mov ax, places
  mov cx, 10
  num2Str_places_lt_num:
    mul cx
  ;check for overflow
  cmp ax, 86A0h 
  je num2Str_place_overFlow
  cmp ax,num2str_accum
  jb num2Str_places_lt_num
  ;bring places back 1 power of 10
  mov dx, 0
  div cx

  jmp num2Str_place_noOverflow
  num2Str_place_overFlow:
  mov ax, 10000
  num2Str_place_noOverflow:
  mov places, ax
  ;get the digit at each place in num and
  ;put its ASCII code in numStr
  mov ax, num2str_accum
  num2Str_places_ne_1:
    ;get the ASCII digit at the current power of 10
    ;using modulo
    mov ax, num2str_accum
    mov cx, places
    mov dx, 0
    div cx
    add ax,30h
    ;and write it to the string
    ;catch the '10 is :' glitch
    cmp al, ':'
    jne num2Str_no10err
    mov al, '1'
    mov ds:[bx], al
    inc bx
    mov al, '0'

    num2Str_no10err:
    mov ds:[bx], al
    inc bx
    ;set num to the remainder
    mov num2str_accum, dx
    mov dx, 0
    ;reduce places to next power of 10
    mov ax, places
    mov cx, 10
    div cx
    mov places,ax

  cmp places,0
  jne num2Str_places_ne_1
ret

;;;;;;;;;;;;
;Checks if the string at dx
;can be converted into a number
;without overflowing
;al = 1 -> valid
;al = 0 -> invalid
;;;;;;;;;;;;
isValidNumStr:
  mov places, 0
  mov bx, dx
  ;pos or neg?
  mov al, ds:[bx]
  cmp al, '$'
  je isValidNumStr_isInvalid
  cmp al, '-'
  jne isValidNumStr_checkPlaces
    inc bx
  isValidNumStr_checkPlaces:
    mov al, ds:[bx]      
    cmp al, '$'
    je isValidNumStr_checkExtremes
    ;detect non-digit characters
    cmp al,39h
      ja isValidNumStr_isInvalid
    cmp al,30h
      jb isValidNumStr_isInvalid
    ;detect whether string is too long
    cmp places, 4
      ja isValidNumStr_isOverflow
    inc places 
    inc bx
  jmp isValidNumStr_checkPlaces
  
  ;Check whether 5 digit numbers
  ;are less than maximum int
  isValidNumStr_checkExtremes:
    cmp places, 5
    jb isValidNumStr_isValid

    mov sourceOffset, offset maxIntStr
    mov destOffset, dx
    mov bx, dx 
    mov al, ds:[bx]
    ;ignore leading '-'
    cmp al, '-'
    jne isValidNumStr_extremesLoop
      inc destOffset
  isValidNumStr_extremesLoop:
    mov bx, sourceOffset
    mov al, ds:[bx]
    mov bx, destOffset
    cmp al, '$'
    je isValidNumStr_isValid
    ;digit lt max -> good
    cmp al, ds:[bx]
    ja isValidNumStr_isValid
    ;digit gt max -> bad
    cmp al, ds:[bx]
    jb isValidNumStr_isOverflow
    ;digit eq max -> check next
    inc destOffset
    inc sourceOffset

  jmp isValidNumStr_extremesLoop

  isValidNumStr_isInvalid:
    mov al, 1
  ret
  isValidNumStr_isOverflow:
    mov al, 2
  ret
  isValidNumStr_isValid:
    mov al, 0
  ret

ret
;;;;;;;;
;Puts the decimal representation in 
;the string at dx into a value in ax
;;;;;;;;
str2Num:
  mov str2num_accum, 0
  mov bx, dx
  mov places,1
  mov str2Num_isNeg, 0
  mov numStr_addr, dx
  ;check for negative number
  mov al, '-' 
  cmp ds:[bx], al
  jne str2Num_isPos_Start
  inc bx
  mov numStr_addr, bx
  mov str2Num_isNeg, 1
  ;find the ending point of the string
  str2Num_isPos_Start:
  al_ne_nullterm:
    ;stores the character at ds:dx to al 
    mov al, ds:[bx] 
    inc bx
  ;exit on a $ terminator or a newline
  cmp al, 29h
  ja al_ne_nullterm
  dec bx
  ;go backwards through the string, adding
  ;[val @ loc] * 10^[end - loc] to val
  mov cx, 10
  bx_ne_dx:
    dec bx
    ;move the value at ds:[bx] to ax
    mov ax, 0
    mov al, ds:[bx]
    sub al, 30h
    ;multiply by the current power of 10
    mov cx, places
    mul cx
    ;add it to the accumulator variable
    add str2num_accum, ax 
    ;increment the current power of 10
    mov ax, places
    mov cx, 10
    mul cx
    mov places, ax
  cmp bx, numStr_addr
  jne bx_ne_dx

  mov ax, str2num_accum

  cmp str2Num_isNeg, 0
  je str2Num_isPos_End
  neg ax
  str2Num_isPos_End:

ret
;;;;;;;;
;Put string at ds:dx to stdout
;;;;;;;;
printCurrStr:
  push ax
  mov ah,9
  int 21h
  pop ax
ret

;;;;;;;;
;Read a string from stdin into
;inputStr
;;;;;;;;
readInput:
  push ax
  push dx
  mov dx, offset inputStr_maxlen
  mov ah,0Ah
  int 21h
  pop dx
  pop ax
ret

;;;;;;;;
;Exits the program if "Q" exists
;at ds:[dx]
;;;;;;;;
checkQuit:
  mov bx, dx
  mov al, ds:[bx]
  cmp al, "Q"
  je endProg
ret
;;;;;;;;
;Pushes a new line to stdout
;;;;;;;;
newLine:
  push ax
  push dx
  mov ah, 2
  mov dl, 10
  int 21h
  mov dl,13
  int 21h
  pop dx
  pop ax
ret

;;;;;;;;
;Terminates the program
;;;;;;;;
endProg:
  mov ax, 4c00h
  int 21h

END START
