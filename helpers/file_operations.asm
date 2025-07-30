
section .data
    src_file    db "srcfile.txt", 0
    dst_file    db "dstfile.txt", 0
    append_file db "dstfile.txt", 0
    dir_name    db "testdir", 0
    FDsrc       dq 0    ; file descriptor for source file
    FDdst       dq 0    ; file descriptor for destination file
    FDappend    dq 0    ; file descriptor for append file
    write_data  db "Hello, Assembly!"
    write_data_len dq 16
    append_data db "Appended text!"
    append_data_len dq 14

    error_create        db "error in creating file             ", NL, 0
    error_close         db "error in closing file              ", NL, 0
    error_write         db "error in writing file              ", NL, 0
    error_open          db "error in opening file              ", NL, 0
    error_open_dir      db "error in opening dir               ", NL, 0
    error_append        db "error in appending file            ", NL, 0
    error_delete        db "error in deleting file             ", NL, 0
    error_read          db "error in reading file              ", NL, 0
    error_print         db "error in printing file             ", NL, 0
    error_seek          db "error in seeking file              ", NL, 0
    error_create_dir    db "error in creating directory        ", NL, 0

    suces_create        db "file created and opened for R/W    ", NL, 0
    suces_create_dir    db "dir created and opened for R/W     ", NL, 0
    suces_close         db "file closed                        ", NL, 0
    suces_write         db "written to file                    ", NL, 0
    suces_open          db "file opened for R/W                ", NL, 0
    suces_open_dir      db "dir opened for R/W                 ", NL, 0
    suces_append        db "file opened for appending          ", NL, 0
    suces_delete        db "file deleted                       ", NL, 0
    suces_read          db "reading file                       ", NL, 0
    suces_seek          db "seeking file                       ", NL, 0

section .bss
    buffer      resb    bufferlen
    command     resb    64          ;to store a line of command to be parsed

section .text
    global _start

append_to_appendfile:
    mov     rdi, append_file                   ; Load address of append filename into rdi
    call    appendFile                         ; Call appendFile to open appendfile.txt in append mode
    mov     [FDappend], rax                    ; Store file descriptor in FDappend
    mov     rdi, [FDappend]                    ; Load file descriptor for writing
    mov     rsi, append_data                   ; Load address of data to append ("Appended text!")
    mov     rdx, [append_data_len]             ; Load length of data to append
    call    writeFile                          ; Call writeFile to append data
    mov     rdi, [FDappend]                    ; Load file descriptor for closing
    call    closeFile
    ret


_start:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; ; Create file
    ; mov     rdi, dst_file                      ; Load address of destination filename into rdi
    ; call    createFile                         ; Call createFile to create/open dstfile.txt
    ; mov     [FDdst], rax                       ; Store file descriptor returned in rax to FDdst

    ; mov     rdi, [FDdst]                       ; Load file descriptor from FDdst for closing
    ; call    closeFile                          ; Call closeFile to close dstfile.txt
    ; jmp Exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Open source file in read-only mode and read
    mov rdi, dst_file
    call openFile
    mov [FDdst], rax

    mov     rdi, [FDdst]                       ; Load file descriptor into rdi for reading
    mov     rsi, buffer                        ; Load address of buffer to store read data
    mov     rdx, bufferlen                     ; Load maximum bytes to read (buffer size)
    ; [h, e, ..., !,...,0]
    call    readFile                           ; Call readFile to read from srcfile.txt
    call    writeNum
    call    newLine

    mov     rdi, rsi                           ; Move buffer address to rdi for printing
    call    printString                        ; Print the read contents to stdout

    mov     rdi, [FDdst]                       ; Load file descriptor for closing
    call    closeFile                          ; Call closeFile to close srcfile.txt
    jmp Exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create and write to destination file
    mov     rdi, dst_file                      ; Load address of destination filename into rdi
    call    createFile                         ; Call createFile to create/open dstfile.txt
    mov     [FDdst], rax                       ; Store file descriptor returned in rax to FDdst

    mov     rdi, [FDdst]                       ; Load file descriptor into rdi for writeFile
    mov     rsi, write_data                    ; Load address of data to write ("Hello, Assembly!")
    mov     rdx, [write_data_len]              ; Load length of data to write
    call    writeFile                          ; Call writeFile to write data to dstfile.txt
    mov     rdi, [FDdst]                       ; Load file descriptor for closing
    call    closeFile                          ; Call closeFile to close srcfile.txt
    jmp Exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Seek and read from source file, write to destination
    mov     rdi, src_file
    call    openFile
    mov     [FDsrc], rax

    mov     rdi, dst_file
    call    createFile
    mov     [FDdst], rax

    ; seek source file at offset
    mov     rdi, [FDsrc]
    mov     rsi, 2; skip the characters
    mov     rdx, 0 ; from beginning
    call    seekFile

    ; read from source file
    mov     rdi, [FDsrc]
    mov     rsi, buffer
    mov     rdx, 7 ; read length
    call    readFile
    mov     rdi, rsi ; start of buffer
    call    printString
    call    newLine

    ; write to destination file
    mov     rdi, [FDdst]
    mov     rsi, buffer
    mov     rdx, 7 ; write length
    call    writeFile

    ; close files
    mov     rdi, [FDsrc]
    call    closeFile
    mov     rdi, [FDdst]
    call    closeFile
    jmp Exit
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Append to append_file
    mov     rdi, append_file                   ; Load address of append filename into rdi
    call    appendFile                         ; Call appendFile to open appendfile.txt in append mode
    mov     [FDappend], rax                    ; Store file descriptor in FDappend
    mov     rdi, [FDappend]                    ; Load file descriptor for writing
    mov     rsi, append_data                   ; Load address of data to append ("Appended text!")
    mov     rdx, [append_data_len]             ; Load length of data to append
    call    writeFile                          ; Call writeFile to append data
    mov     rdi, [FDappend]                    ; Load file descriptor for closing
    call    closeFile                          ; Call closeFile to close appendfile.txt
    jmp Exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; ; Create directory
    ; mov     rax, sys_mkdir                     ; Load syscall number for mkdir (83) into rax
    ; mov     rdi, dir_name                      ; Load address of directory name into rdi
    ; mov     rsi, sys_makenewdir                ; Load directory permissions (0777) into rsi
    ; syscall                                    ; Invoke sys_mkdir to create testdir
    ; cmp     rax, -1                            ; Check if directory creation failed
    ; jle     dir_error                          ; If failed, jump to dir_error
    ; mov     rsi, suces_create_dir              ; Load success message for directory creation
    ; call    printString                        ; Print "dir created and opened for R/W"
    ; jmp Exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Delete append_file
    mov     rdi, append_file                   ; Load address of append filename into rdi
    call    deleteFile                         ; Call deleteFile to delete appendfile.txt


Exit:
    mov     rax, sys_exit
    xor     rdi, rdi
    syscall

open_error:
    mov     rsi, error_open
    call    printString
    jmp     Exit

dir_error:
    mov     rsi, error_create_dir
    call    printString
    jmp     Exit

;----------------------------------------------------
; Helper functions and macros (same as provided files)
;----------------------------------------------------
%ifndef SYS_EQUAL
%define SYS_EQUAL
    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
    sys_mkdir    equ     83
    sys_makenewdir equ 0q777
    sys_exit     equ     60
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3
    PROT_NONE    equ     0x0
    PROT_READ    equ     0x1
    PROT_WRITE   equ     0x2
    MAP_PRIVATE  equ     0x2
    MAP_ANONYMOUS equ 0x20
    O_DIRECTORY  equ     0q0200000
    O_RDONLY     equ     0q000000
    O_WRONLY     equ     0q000001
    O_RDWR       equ     0q000002
    O_CREAT      equ     0q000100
    O_APPEND     equ     0q002000
    BEG_FILE_POS equ     0
    CURR_POS     equ     1
    END_FILE_POS equ     2
    sys_IRUSR    equ     0q400
    sys_IWUSR    equ     0q200
    sys_IRGRP    equ     0q040
    sys_IROTH    equ     0q004
    NL           equ     0xA
    Space        equ     0x20
    bufferlen    equ     99999
%endif

%ifndef NOWZARI_IN_OUT
%define NOWZARI_IN_OUT
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
putc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11
   push   ax
   mov    rsi, rsp
   mov    rdx, 1
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
readNum:
   push   rcx
   push   rbx
   push   rdx
   mov    bl, 0
   mov    rdx, 0
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl, 1
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' '
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx, rax
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
printString:
   push   rax
   push   rcx
   push   rsi
   push   rdx
   push   rdi
   mov    rdi, rsi
   call   GetStrlen
   mov    rax, sys_write
   mov    rdi, stdout
   syscall
   pop    rdi
   pop    rdx
   pop    rsi
   pop    rcx
   pop    rax
   ret
GetStrlen:
   push   rbx
   push   rcx
   push   rax
   xor    rcx, rcx
   not    rcx
   xor    rax, rax
   cld
   repne  scasb
   not    rcx
   lea    rdx, [rcx - 1]
   pop    rax
   pop    rcx
   pop    rbx
   ret
%endif

createFile:
    mov     rax, sys_create
    mov     rsi, sys_IRUSR | sys_IWUSR | sys_IRGRP | sys_IROTH ; 0644
    syscall
    cmp     rax, -1
    jle     createerror
    mov     rsi, suces_create
    call    printString
    ret
createerror:
    mov     rsi, error_create
    call    printString
    ret
openFile:
    mov     rax, sys_open
    mov     rsi, O_RDWR
    syscall
    cmp     rax, -1
    jle     openerror
    mov     rsi, suces_open
    call    printString
    ret
openerror:
    mov     rsi, error_open
    call    printString
    ret
appendFile:
    mov     rax, sys_open
    mov     rsi, O_RDWR | O_APPEND
    syscall
    cmp     rax, -1
    jle     appenderror
    mov     rsi, suces_append
    call    printString
    ret
appenderror:
    mov     rsi, error_append
    call    printString
    ret
writeFile:
    mov     rax, sys_write
    syscall
    cmp     rax, -1
    jle     writeerror
    mov     rsi, suces_write
    call    printString
    ret
writeerror:
    mov     rsi, error_write
    call    printString
    ret
readFile:
    mov     rax, sys_read
    syscall
    cmp     rax, -1
    jle     readerror
    mov     byte [rsi+rax], 0
    push    rsi
    mov     rsi, suces_read
    call    printString
    pop     rsi
    ret
readerror:
    mov     rsi, error_read
    call    printString
    ret
closeFile:
    mov     rax, sys_close
    syscall
    cmp     rax, -1
    jle     closeerror
    mov     rsi, suces_close
    call    printString
    ret
closeerror:
    mov     rsi, error_close
    call    printString
    ret
deleteFile:
    mov     rax, sys_unlink
    syscall
    cmp     rax, -1
    jle     deleterror
    mov     rsi, suces_delete
    call    printString
    ret
deleterror:
    mov     rsi, error_delete
    call    printString
    ret
seekFile:
    mov     rax, sys_lseek
    syscall
    cmp     rax, -1
    jle     seekerror
    mov     rsi, suces_seek
    call    printString
    ret
seekerror:
    mov     rsi, error_seek
    call    printString
    ret



; To RUN the code:
; nasm -f elf64 file_operations.asm -o file_operations.o
; ld file_operations.o -o file_operations
; ./file_operations