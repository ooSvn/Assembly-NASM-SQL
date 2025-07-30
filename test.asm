    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
    
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
      

    sys_mkdir       equ 83
    sys_makenewdir  equ 0q777


    sys_mmap     equ     9
    sys_mumap    equ     11
    sys_brk      equ     12
    
     
    sys_exit     equ     60
    
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3

 
	PROT_NONE	  equ   0x0
    PROT_READ     equ   0x1
    PROT_WRITE    equ   0x2
    MAP_PRIVATE   equ   0x2
    MAP_ANONYMOUS equ   0x20
    
    ;access mode
    O_DIRECTORY equ     0q0200000
    O_RDONLY    equ     0q000000
    O_WRONLY    equ     0q000001
    O_RDWR      equ     0q000002
    O_CREAT     equ     0q000100
    O_APPEND    equ     0q002000


    BEG_FILE_POS    equ     0
    CURR_POS        equ     1
    END_FILE_POS    equ     2
    
; create permission mode
    sys_IRUSR     equ     0q400      ; user read permission
    sys_IWUSR     equ     0q200      ; user write permission

    NL            equ   0xA
    Space         equ   0x20



section .data
  A:       dq 0
  here:   db "here",0

section .bss
buf1:    resb 10000000
buf2:    resb 10000000
buf3:    resq 10000000
section .text
	global _start
;----------------------------------------------------
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
onSpace:
   push   rax
   mov    rax, Space
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
putc:	

   push   rcx
   push   rdx
   push   rsi
   push   rdi 
   push   r11 

   push   ax
   mov    rsi, rsp    ; points to our char
   mov    rdx, 1      ; how many characters to print
   mov    rax, sys_write
   mov    rdi, stdout 
   syscall
   pop    ax

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx
   ret
;---------------------------------------------------------
writeNum:
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10 
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain
   push   rax 
   mov    al, '-'
   call   putc
   pop    rax
   neg    rax  

wAgain:
   cmp    rax, 9	
   jle    cEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain

cEnd:
   add    al, 0x30
   call   putc
   dec    rcx
   jl     wEnd
   pop    rax
   jmp    cEnd
wEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret

;---------------------------------------------------------
getc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi 
   push   r11 

 
   sub    rsp, 1
   mov    rsi, rsp
   mov    rdx, 1
   mov    rax, sys_read
   mov    rdi, stdin
   syscall
   mov    al, [rsi]
   add    rsp, 1

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx

   ret
;---------------------------------------------------------

readNum:
   push   rcx
   push   rbx
   push   rdx

   mov    bl,0
   mov    rdx, 0
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl,1  
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' ' ;Space
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx,  rax
   xor    rax, rax
   call   getc
   jmp    sAgain
rEnd:
   mov    rax, rdx 
   cmp    bl, 0
   je     sEnd
   neg    rax 
sEnd:  
   pop    rdx
   pop    rbx
   pop    rcx
   ret

;-------------------------------------------
printString:
   push    rax
   push    rcx
   push    rsi
   push    rdx
   push    rdi

   mov     rdi, rsi
   call    GetStrlen
   mov     rax, sys_write  
   mov     rdi, stdout
   syscall 
   
   pop     rdi
   pop     rdx
   pop     rsi
   pop     rcx
   pop     rax
   ret
;-------------------------------------------
printSpace:
    mov dl, ' '
    mov ah, 2
   ;  int 21h
    ret
;-------------------------------------------

; rdi : zero terminated string start 

GetStrlen:
   push    rbx
   push    rcx
   push    rax  

   xor     rcx, rcx
   not     rcx
   xor     rax, rax
   cld
         repne   scasb
   not     rcx
   lea     rdx, [rcx -1]  ; length in rdx

   pop     rax
   pop     rcx
   pop     rbx
   ret
;-------------------------------------------

%macro printR 1
    push rax
    mov rax, %1
    call writeNum
    pop rax
%endmacro

%macro inputR 1
    push rax
    call readNum
    mov %1,rax
    pop rax
%endmacro

;-------------------------------------------
;---------------------------------------------
; readString: 
;   rdi = pointer to buffer
;   returns: RAX = length of string (number of bytes before NL or space)
;   also writes a trailing 0 at buffer[RAX]
;---------------------------------------------
readString:
    push   rbp
    mov    rbp, rsp
    push   rbx
    push   rcx

    mov    rbx, rdi        ; rbx = buffer pointer
    xor    rcx, rcx        ; rcx = index into buffer
.read_loop:
    ; call getc → AL = next char (it does a 1‐byte sys_read)
    call   getc           
    cmp    al, NL         ; stop on newline
    je     .done
    cmp    al, Space      ; or stop on space 
    je     .done
    mov    [rbx + rcx], al
    inc    rcx
    cmp    rcx, 127       ; avoid overflow (leave 1 byte for null)
    je     .done
    jmp    .read_loop
.done:
    mov    byte [rbx + rcx], 0
    mov    rax, rcx       ; return length
    pop    rcx
    pop    rbx
    pop    rbp
    ret

;-------------------------------------------
; Check if the pattern matches in the string with start index r8
pattern_checker:
  push r14
  xor r9, r9
  mov r14, r8
  xor rcx, rcx
  
in_loop:
  xor rax, rax
  xor rbx, rbx
  mov al, [buf1 + r8]
  mov bl, [buf2 + r9]
  
  ; printR rax
  ; call onSpace
  ; printR rbx
  ; call onSpace
  ; call newLine
  
  cmp rbx, 0
  je yep
  
  cmp rax, 0
  je nope
  
  cmp rax, rbx
  jne nope
  
  inc r8
  inc r9
  jmp in_loop
  
nope:
  mov r8, r14
  pop r14
  ; call newLine
  ret
  
yep:
  mov r8, r14
  mov rcx, 1
  pop r14
  ; call newLine
  ret
;-------------------------------------------

_start:
  lea   rdi, [rel buf1]
  call  readString      ; reads up to NL/Space, store at inputBuf, returns len in RAX
  
  ; mov rsi, buf1
  ; call printString
  ; call newLine
  
  lea   rdi, [rel buf2]
  call readString
  
  mov rdx, rax ; the length of the pattern
  
  ;loop over the string for start index increment
  xor r13, r13 ; the count of the found patterns
  xor r8, r8   ; string iterator
  loop1:
    ; printR r8
    ; call onSpace
    xor rax, rax
    mov al, [buf1 + r8]
    
    cmp rax, 0 ; check if the end of the string has reached
    je next

    call pattern_checker
    cmp rcx, 1
    je pattern_found ; pattern_found ✅

    mov rsi, here
    ; supposed the pattern is not found by starting from current r8
    add r8, 1    ; increment the loop
    jmp loop1
    
  pattern_found:
    ; printR r13
    ; printR r8
    ; call onSpace
    mov [buf3 + r13*8], r8
    add r8, 1
    add r13, 1
    jmp loop1
    
    
next: ;sort and output
  xor r8, r8
  mov rcx, r13
  mov rbx, r13
  while1:
    xor r9, r9
    inc r8
    while2:
      mov r14, [buf3+r9*8]
      cmp r14, [buf3+r9*8+8]
      
      jle no_need_for_swap
      ; printR r14
      ; call onSpace
      xchg [buf3+r9*8+8], r14
      mov [buf3+r9*8], r14
      
      no_need_for_swap:
        inc r9
        cmp r9, rcx
        jne while2
      
    dec rcx
    cmp r8, rbx
    jne while1
    
  inc r13
  mov r8, 1
output_while:
  cmp r8, r13
  je Exit
  mov rax, [buf3+r8*8]
  printR rax
  call onSpace
  inc r8
  jmp output_while
    
    

  Exit:
    mov     rax, sys_exit
    xor     rdi, rdi
    syscall
    
;a => 97

;
