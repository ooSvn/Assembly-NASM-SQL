section .data
    comma       db ",",0
    newline     db 10,0
    src_file    db "srcfile.txt", 0
    dst_file    db "dstfile.txt", 0
    append_file db "dstfile.txt", 0
    dir_name    db "testdir", 0
    FDsrc       dq 0    ; file descriptor for source file
    FDdst       dq 0    ; file descriptor for destination file
    FDappend    dq 0    ; file descriptor for append file
    write_data  db "Hello, Assembly!",0
    write_data_len dq 16
    append_data db "Appended text!"
    append_data_len dq 14
    dash        db '-',0

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
    ; -----------------------------------------------------------------
    CREATE              db "CREATE",0
    DROP                db "DROP",0
    TABLE               db "TABLE",0
    INSERT              db "INSERT",0
    IN_TO               db "INTO",0
    VALUES              db "VALUES",0
    QUIT                db "QUIT",0
    SHOW                db "SHOW",0
    DESCRIBE            db "DESCRIBE",0
    SELECT              db "SELECT",0
    FROM                db "FROM",0
    WHERE               db "WHERE",0
    DELETE              db "DELETE",0
    ; -----------------------------------------------------------------
    smthWrongMsg        db "Error: there is something wrong with your command!",10
    smthWrongMsgLen     equ $ - smthWrongMsg
    typeMismatchMsg     db "Error: columns type are mismatched!",10
    typeMismatchMsgLen  equ $ - typeMismatchMsg
    fileExistsMsg       db "Error: file already exists.", 10
    fileExistsMsgLen    equ $ - fileExistsMsg
    fileNotExistsMsg    db "Error: no such table to drop.", 10
    fileNotExistsMsgLen equ $ - fileNotExistsMsg
    fileNotFoundMsg     db "Error: file not found!",10
    fileNotFoundMsgLen  equ $ - fileNotFoundMsg
    dot                 db  ".", 0


section .bss
    where_index resq    1           ; or resb 1 for 1-byte
    buf         resb    4096        ; read entire file into here
    buf_pointer resq    1
    HEADER      resb    4096
    HEADER_LEN  resq    1
    COLUMNS     resb    1000  
    CONDITION   resb    1000  
    buffer      resb    4096
    command     resb    100          ;to store a line of command
    s1          resb    100
    s2          resb    100
    s3          resb    1
    s4          resb    1
    s5          resb    1000
    s6          resb    100
    s7          resb    100
    s8          resb    100   
    s9          resb    100
    s10         resb    1
    ; -----------------------------------------------------------------
    FILE_NAME   resb    100
    CONTENT     resb    1000
    CONTENT_LEN resq    1
    LINE        resb    1000
    LINE_LEN    resq    1


section .text
    global _start

; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; To read one line of command (stops reading when reached into a newline)
readOneLineCommand:
    push        rax
    push        r8
    xor         r8, r8

readOneLineCommand_while1:
    call        getc
    cmp         al, NL
    je          readOneLineCommand_done
    mov         [command + r8], al
    inc         r8
    jmp         readOneLineCommand_while1

readOneLineCommand_done:
    mov         byte [command + r8], 0
    pop         r8
    pop         rax
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; CREATE TABLE <table_name> (col1:str,col2:int)
createTable:
    push        rax
    push        rsi
    push        rdi
    push        rdx
    push        rcx
    
; here FILE_NAME and CONTENT and CONTENT_LEN should be extracted!

; === Skip until after "TABLE" ===
createTable_skipToTable:
    xor         rdx, rdx ;counter

    ; moving "TABLE" into s2
    mov         rsi, TABLE
    mov         rdi, s2
    mov         rcx, 6
    rep         movsb

createTable_skipToTable_loop:
    ; storing 5 characters of 'command' with offset rdx to check == "TABLE"?
    lea         rsi, [command + rdx]
    cmp         byte [rsi], 0
    je          createTable_FileNameExtraction
    mov         rdi, s1
    mov         rcx, 5
    rep         movsb
    mov         byte [s1 + 5], 0
    
    call        stringComparator
    cmp         byte [s3], 1
    jne         createTable_skipToTable_next
    je          createTable_FileNameExtraction

createTable_skipToTable_next:
    inc         rdx
    jmp         createTable_skipToTable_loop


; === Copy word after TABLE to FILE_NAME ===
createTable_FileNameExtraction:
    ; RDX = offset of 'T' in "TABLE"
    ; +6 skips "TABLE" + space
    lea     rsi, [command + rdx + 6]
    mov     rdi, FILE_NAME

.copy_fname:
    mov     al, [rsi]
    cmp     al, ' '
    je      .done_fname
    cmp     al, '('
    je      .done_fname
    cmp     al, 0
    je      .done_fname
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .copy_fname

.done_fname:
    mov     byte [rdi], '.'
    mov     byte [rdi + 1], 't'
    mov     byte [rdi + 2], 'b'
    mov     byte [rdi + 3], 'l'
    mov     byte [rdi + 4], 0      ; NUL‑terminate
    jmp     createTable_ContentExtraction


; === Extract content in parentheses to CONTENT ===
createTable_ContentExtraction:
    lea     rsi, [command]

.find_paren:
    mov     al, [rsi]
    cmp     al, '('
    jne     .inc_paren
    jmp     .start_copy
.inc_paren:
    inc     rsi
    jmp     .find_paren

.start_copy:
    inc     rsi                 ; skip '('
    mov     rdi, CONTENT

.copy_content:
    mov     al, [rsi]
    cmp     al, ')'
    je      .done_content
    cmp     al, 0
    je      .done_content
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .copy_content

.done_content:
    mov     byte [rdi], 10
    mov     byte [rdi + 1], 0      ; NUL‑terminate
    jmp     createTable_ContentLenExtraction
    ; mov     rsi, rdi
    ; call    printString

; === Compute string length of CONTENT and save in CONTENT_LEN ===
createTable_ContentLenExtraction:
    mov     rsi, CONTENT
    xor     rcx, rcx           ; counter = 0

.len_loop:
    mov     al, [rsi + rcx]
    cmp     al, 0
    je      .store_len
    inc     rcx
    jmp     .len_loop

.store_len:
    mov     [CONTENT_LEN], rcx
    jmp     createTable_checkExists

createTable_checkExists:
    ; Try to open FILE_NAME (RDI = pointer to filename)
    mov     rax, 2          ; sys_open
    mov     rdi, FILE_NAME
    mov     rsi, 0          ; O_RDONLY
    syscall

    cmp     rax, 0          ; rax >= 0 means file exists
    jl      .not_exists     ; rax < 0 means does NOT exist (ok to create)

.file_exists:
    ; Close opened fd (if needed)
    mov     rdi, rax
    mov     rax, 3          ; sys_close
    syscall

    ; Print error message
    mov     rax, 1          ; sys_write
    mov     rdi, 1          ; stdout
    mov     rsi, fileExistsMsg
    mov     rdx, fileExistsMsgLen
    syscall

    jmp     createTable_done    ; skip creating the file

.not_exists:
    jmp     createTable_createfile


; Create and write to destination file
createTable_createfile:
    mov         rdi, FILE_NAME                     ; Load address of destination filename into rdi
    call        createFile                         ; Call createFile to create/open dstfile.txt
    mov         [FDdst], rax                       ; Store file descriptor returned in rax to FDdst

    mov         rdi, [FDdst]                       ; Load file descriptor into rdi for writeFile
    mov         rsi, CONTENT                       ; Load address of data to write ("Hello, Assembly!")
    mov         rdx, [CONTENT_LEN]                 ; Load length of data to write
    call        writeFile                          ; Call writeFile to write data to dstfile.txt
    mov         rdi, [FDdst]                       ; Load file descriptor for closing
    call        closeFile  

createTable_done:
    pop         rcx
    pop         rdx
    pop         rdi
    pop         rsi
    pop         rax
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
dropTable:
    push        rax
    push        rsi
    push        rdi
    push        rdx
    push        rcx


dropTable_skipToTable:
    xor         rdx, rdx ;counter

    ; moving "TABLE" into s2
    mov         rsi, TABLE
    mov         rdi, s2
    mov         rcx, 6
    rep         movsb

dropTable_skipToTable_loop:
    ; storing 5 characters of 'command' with offset rdx to check == "TABLE"?
    lea         rsi, [command + rdx]
    cmp         byte [rsi], 0
    je          dropTable_extractFileName
    mov         rdi, s1
    mov         rcx, 5
    rep         movsb
    mov         byte [s1 + 5], 0
    
    call        stringComparator
    cmp         byte [s3], 1
    jne         dropTable_skipToTable_next
    je          dropTable_extractFileName

dropTable_skipToTable_next:
    inc         rdx
    jmp         dropTable_skipToTable_loop



dropTable_extractFileName:
    ; RDX = offset of 'T' in "TABLE"
    ; +6 skips "TABLE" + space
    lea         rsi, [command + rdx + 6]
    mov         rdi, FILE_NAME

.copy_fname:
    mov         al, [rsi]
    cmp         al, 0
    je          .done_fname
    mov         [rdi], al
    inc         rsi
    inc         rdi
    jmp         .copy_fname

.done_fname:
    mov         byte [rdi], '.'
    mov         byte [rdi + 1], 't'
    mov         byte [rdi + 2], 'b'
    mov         byte [rdi + 3], 'l'
    mov         byte [rdi + 4], 0      ; NUL‑terminate
    jmp         dropTable_checkAndDeleteFile

dropTable_checkAndDeleteFile:
    mov         rax, 2          ; sys_open
    mov         rdi, FILE_NAME
    mov         rsi, 0          ; O_RDONLY
    syscall

    cmp         rax, 0
    jl          .file_not_found

.delete_file:
    mov         rax, 87         ; sys_unlink
    mov         rdi, FILE_NAME
    syscall
    jmp         dropTable_done


.file_not_found:
    mov         rsi, fileNotExistsMsg
    call        printString


dropTable_done:
    pop         rcx
    pop         rdx
    pop         rdi
    pop         rsi
    pop         rax
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
hasTblExtension:
    push rdi
    push rcx
    push rdx

    mov rdi, rsi       ; RDI = string ptr
    call GetStrlen     ; RDX = strlen
    cmp rdx, 4
    jb .no

    ; point to last 4 chars
    lea rsi, [rsi + rdx - 4]
    mov eax, dword [rsi]
    cmp eax, 0x6C62742E ; ".tbl" = 0x6C ('l'), 0x62 ('b'), 0x74 ('t'), 0x2E ('.') little-endian
    jne .no
    mov rax, 1
    jmp .done

.no:
    xor rax, rax

.done:
    pop rdx
    pop rcx
    pop rdi
    ret



showTables:
    push rbx
    push rsi
    push rdi
    push rax
    push rcx
    push rdx
    push r14
    push r13
    push r12
    ; --- Open current directory (".") ---
    
    ; syscall: getdents
    mov     rax, 78             ; sys_getdents
    mov     rdi, 0              ; fd = 0 (stdin), but for directory use fd from open.
                                ; Instead, we first open "."
    ; open(".")
    mov     rax, 2              ; sys_open
    lea     rdi, [rel dot]      ; pathname "."
    xor     rsi, rsi            ; flags = O_RDONLY
    xor     rdx, rdx            ; mode = 0
    syscall
    mov     r12, rax            ; save directory fd in r12

.read_dir:
    mov     rax, 78             ; sys_getdents
    mov     rdi, r12            ; fd
    lea     rsi, [rel buf]      ; buffer
    mov     rdx, 4096           ; buffer size
    syscall
    cmp     rax, 0
    je      .done               ; no more entries
    mov     r13, rax            ; bytes read

    mov     rbx, buf            ; current pointer in buffer

.next_entry:
    cmp     r13, 0
    je      .read_dir           ; consumed buffer → read again

    mov     dx, [rbx + 16]      ; d_reclen (offset 16 on x86-64)
    movzx   r14, dx             ; record length

    ; write d_name
    lea     rsi, [rbx + 18]     ; d_name starts at offset 18
    ; find length of name (up to null)
    xor     rcx, rcx
    mov     rdi, rsi

.find_nul:
    cmp     byte [rdi + rcx], 0
    je      .got_len
    inc     rcx
    jmp     .find_nul

.got_len:
    ; rsi → d_name
    ; rcx = length of the name

    ; only proceed if rcx >= 4
    cmp     rcx, 4
    jb      .skip_print

    ; rdx → pointer to last-4 bytes
    lea     rdx, [rsi + rcx - 4]
    cmp     byte [rdx],     '.'     ; '.'
    jne     .skip_print
    cmp     byte [rdx + 1], 't'     ; 't'
    jne     .skip_print
    cmp     byte [rdx + 2], 'b'     ; 'b'
    jne     .skip_print
    cmp     byte [rdx + 3], 'l'     ; 'l'
    jne     .skip_print

    ; -- matches ".tbl", so print it --
    mov     rax, 1               ; sys_write
    mov     rdi, 1               ; stdout
    mov     rdx, rcx             ; length
    syscall

    call    newLine

.skip_print:
    ; advance to next entry
    add     rbx, r14
    sub     r13, r14
    jmp     .next_entry

.done:
    ; close directory
    mov     rax, 3              ; sys_close
    mov     rdi, r12
    syscall

    pop r12
    pop r13
    pop r14
    pop rdx
    pop rcx
    pop rax
    pop rdi
    pop rsi
    pop rbx
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
describeTable:
    push    rbx
    push    rsi
    push    rdi
    push    rax
    push    rcx
    push    rdx

    ;— 1. Extract table name from "DESCRIBE <name>" into FILE_NAME ——
    mov     rdi, FILE_NAME
    xor     rbx, rbx
.extract_loop:
    mov     al, [command + rbx + 9]   ; start at char 9
    cmp     al, ' '
    je      .append_ext
    cmp     al, 0
    je      .append_ext
    mov     [rdi + rbx], al
    inc     rbx
    jmp     .extract_loop

.append_ext:
    ; append ".tbl\0"
    lea     rdi, [FILE_NAME + rbx]
    mov     byte [rdi    ], '.'
    mov     byte [rdi + 1], 't'
    mov     byte [rdi + 2], 'b'
    mov     byte [rdi + 3], 'l'
    mov     byte [rdi + 4], 0

    ; (optional) echo filename for debug
    ; lea   rsi, [FILE_NAME]
    ; call  printString
    ; call  newLine

    ;— 2. Open the file read-only ——
    mov     rax, sys_open
    lea     rdi, [rel FILE_NAME]
    xor     rsi, rsi          ; O_RDONLY
    syscall
    cmp     rax, 0
    js      .err_no_file
    mov     r12, rax          ; save fd

    ;— 3. Read up to 255 bytes ——
    mov     rax, sys_read
    mov     rdi, r12
    lea     rsi, [rel buf]
    mov     rdx, 255
    syscall
    cmp     rax, 1
    jl      .err_read
    mov     rcx, rax          ; bytes read
    xor     rbx, rbx

    ;— 4. Find first newline ——
.find_nl:
    cmp     rbx, rcx
    jge     .err_no_nl
    cmp     byte [buf + rbx], NL
    je      .got_nl
    inc     rbx
    jmp     .find_nl

.got_nl:
    mov     byte [buf + rbx], 0  ; NUL-terminate

    ;— 5. Print it ——
    lea     rsi, [rel buf]
    call    printString
    call    newLine

    ;— 6. Cleanup & return ——
    mov     rax, sys_close
    mov     rdi, r12
    syscall
    jmp     .done

;— Error handlers ——
.err_no_file:
    mov     rsi, error_read
    call    printString
    call    newLine
    jmp     .cleanup

.err_read:
    mov     rsi, error_read
    call    printString
    call    newLine
    jmp     .cleanup

.err_no_nl:
    mov     rsi, error_print
    call    printString
    call    newLine

.cleanup:
    cmp     r12, 0
    jl      .done
    mov     rax, sys_close
    mov     rdi, r12
    syscall

.done:
    pop     rdx
    pop     rcx
    pop     rax
    pop     rdi
    pop     rsi
    pop     rbx
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
insertIntoTable:
    push        rbx
    push        rsi
    push        rdi
    push        rax
    push        rcx
    push        rdx
    push        r14
    push        r13
    push        r12

    mov         rsi, IN_TO
    mov         rdi, s2
    mov         rcx, 5
    rep         movsb
    xor         rdx, rdx

insertIntoTable_skipINTO:
    lea         rsi, [command + rdx]
    cmp         byte [rsi], 0
    je          insertIntoTable_raiseError
    mov         rdi, s1
    mov         rcx, 4
    rep         movsb
    mov         byte [s1 + 4], 0
    
    call        stringComparator
    cmp         byte [s3], 1
    je          insertIntoTable_getFileName

.next:
    inc         rdx
    jmp         insertIntoTable_skipINTO





insertIntoTable_getFileName:
    lea     rsi, [command + rdx + 5]
    mov     rdi, FILE_NAME

.copy_fname:
    mov     al, [rsi]
    cmp     al, ' '
    je      .done_fname
    cmp     al, '('
    je      .done_fname
    cmp     al, 0
    je      .done_fname
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .copy_fname

.done_fname:
    mov     byte [rdi], '.'
    mov     byte [rdi + 1], 't'
    mov     byte [rdi + 2], 'b'
    mov     byte [rdi + 3], 'l'
    mov     byte [rdi + 4], 0      ; NUL‑terminate





insertIntoTable_checkFileExists:
    mov     rax, sys_open
    lea     rdi, [rel FILE_NAME]
    xor     rsi, rsi                ; O_RDONLY
    syscall
    cmp     rax, 0
    js      insertIntoTable_done    ; check for error
    mov     [FDdst], rax            ; save file descriptor




insertIntoTable_skipVALUES:
    mov         rsi, VALUES
    mov         rdi, s2
    mov         rcx, 7
    rep         movsb
    xor         rdx, rdx

.looop:
    lea         rsi, [command + rdx]
    cmp         byte [rsi], 0
    je          insertIntoTable_raiseError
    mov         rdi, s1
    mov         rcx, 6
    rep         movsb
    mov         byte [s1 + 6], 0
    
    call        stringComparator
    cmp         byte [s3], 1
    je          insertIntoTable_extractValues

.next:
    inc         rdx
    jmp         .looop




insertIntoTable_extractValues:
    lea     rsi, [command]

.find_paren:
    mov     al, [rsi]
    cmp     al, '('
    jne     .inc_paren
    jmp     .start_copy
.inc_paren:
    inc     rsi
    jmp     .find_paren

.start_copy:
    inc     rsi                 ; skip '('
    mov     rdi, CONTENT

.copy_content:
    mov     al, [rsi]
    cmp     al, ')'
    je      .done_content
    cmp     al, 0
    je      .done_content
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .copy_content

.done_content:
    mov     byte [rdi], 10
    mov     byte [rdi + 1], 0      ; NUL‑terminate





insertIntoTable_ContentLenExtraction:
    mov     rsi, CONTENT
    xor     rcx, rcx           ; counter = 0

.len_loop:
    mov     al, [rsi + rcx]
    cmp     al, 0
    je      .store_len
    inc     rcx
    jmp     .len_loop

.store_len:
    mov     [CONTENT_LEN], rcx



insertIntoTable_evaluateValues:
    ; reading the file into buf
    mov     rdi, [FDdst]
    mov     rsi, buf
    mov     rdx, 1024
    mov     rax, 0      ; sys_read
    syscall 

    lea     rsi, [buf]
    xor     rcx, rcx

.find_nl:
    mov     al, [rsi + rcx]
    cmp     al, 0xA
    je      .newline_found
    cmp     al, 0
    je      .newline_found            ; reached end without newline
    inc     rcx
    jmp     .find_nl

.newline_found:
    mov     byte [rsi + rcx], 0   ; null-terminate the first line
    call    check_compatibilty
    cmp     byte [s3], 1
    jne     insertIntoTable_closeFile


insertIntoTable_appendToFile:
    mov     rax, 2              ; sys_open
    mov     rdi, FILE_NAME      ; pointer to file name
    mov     rsi, 1025           ; O_WRONLY | O_APPEND (1 + 1024)
    mov     rdx, 0o644          ; mode if O_CREAT is used (rw-r--r--)
    syscall
    cmp     rax, 0
    js      insertIntoTable_done          ; check for error
    mov     [FDdst], rax        ; save file descriptor
    
    mov     rdi, [FDdst]        ; file descriptor
    lea     rsi, [CONTENT]      ; data buffer
    mov     rdx, [CONTENT_LEN]  ; length of data
    call    writeFile           ; your own writeFile subroutine


insertIntoTable_closeFile:
    ; close file
    mov     rdi, [FDdst]
    call    closeFile
    jmp     insertIntoTable_done

insertIntoTable_raiseError:
    call        raiseError_badCommand

insertIntoTable_done:
    pop         r12
    pop         r13
    pop         r14
    pop         rdx
    pop         rcx
    pop         rax
    pop         rdi
    pop         rsi
    pop         rbx
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
selectCommandHandler:
    push        rbx
    push        rsi
    push        rdi
    push        rax
    push        rcx
    push        rdx
    push        r14
    push        r13
    push        r12

selectCommandHandler_extractColumns:
    ; checking whether there is ' ' after SELECT
    mov         r12, 6
    cmp         byte [command + r12], ' '
    jne         selectCommandHandler_raiseError
    inc         r12
    xor         r13, r13
.looop:
    mov         al, [command + r12]
    cmp         al, 0
    je          selectCommandHandler_raiseError
    cmp         al, ' '
    je          .columns_end_found
    mov         byte [COLUMNS + r13], al
    inc         r13
.next:
    inc         r12
    jmp         .looop
.columns_end_found:
    mov         byte [COLUMNS + r13], 0
; OKAY TILL HERE

selectCommandHandler_checkIf_FROM_isThere:
    inc         r12
    lea         rsi, [command + r12]
    lea         rdi, [s1]
    mov         rcx, 4
    rep         movsb
    mov         byte [s1 + 5], 0

    lea         rsi, [FROM]
    lea         rdi, [s2]
    mov         rcx, 5
    rep         movsb

    call        stringComparator
    cmp         byte [s3], 1
    jne         selectCommandHandler_raiseError


selectCommandHandler_extractFileName:
    ; checking whether there is ' ' after FROM
    add         r12, 4
    cmp         byte [command + r12], ' '
    jne         selectCommandHandler_raiseError
    inc         r12
    xor         r13,r13

.looop:
    mov         al,[command + r12]
    cmp         al, ' '
    je          .found_name
    cmp         al, 0
    je          .found_name
    mov         byte [FILE_NAME + r13], al
    inc         r13
.next:
    inc         r12
    jmp         .looop

.found_name:
    mov         byte [FILE_NAME + r13], '.'
    mov         byte [FILE_NAME + r13 + 1], 't'
    mov         byte [FILE_NAME + r13 + 2], 'b'
    mov         byte [FILE_NAME + r13 + 3], 'l'
    mov         byte [FILE_NAME + r13 + 4], 0


; selectCommandHandler_checkIf_WHERE_isThere:
;     cmp         al, 0
;     ; je          .no_where



; selectCommandHandler_loopOverRecords:



selectCommandHandler_raiseError:
    call        raiseError_badCommand

selectCommandHandler_done:
    pop         r12
    pop         r13
    pop         r14
    pop         rdx
    pop         rcx
    pop         rax
    pop         rdi
    pop         rsi
    pop         rbx
    ret


condition_checker:
    
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
deleteFromTable:
    push        rbx
    push        rsi
    push        rdi
    push        rax
    push        rcx
    push        rdx
    push        r14
    push        r13
    push        r12

deleteFromTable_skipFROM:
    mov         r12, 6
    cmp         byte [command + r12], ' '
    jne         deleteFromTable_raiseError
    
    mov         rcx, 5
    mov         rsi, FROM
    mov         rdi, s2
    rep         movsb

    xor         rdx, rdx
.looop:
    lea         rsi, [command + rdx]
    cmp         byte [rsi], 0
    je          deleteFromTable_raiseError
    mov         rdi, s1
    mov         rcx, 4
    rep         movsb
    mov         byte [s1 + 4], 0
    
    call        stringComparator
    cmp         byte [s3], 1
    je          deleteFromTable_extractFileName
.next:
    inc         rdx
    jmp         .looop


deleteFromTable_extractFileName:
    mov         r12, rdx
    add         r12, 4
    cmp         byte [command + r12], ' '
    jne         selectCommandHandler_raiseError
    inc         r12
    xor         r13,r13
.looop:
    mov         al,[command + r12]
    cmp         al, ' '
    je          .found_name
    cmp         al, 0
    je          .found_name
    mov         byte [FILE_NAME + r13], al
    inc         r13
.next:
    inc         r12
    jmp         .looop
.found_name:
    mov         byte [FILE_NAME + r13], '.'
    mov         byte [FILE_NAME + r13 + 1], 't'
    mov         byte [FILE_NAME + r13 + 2], 'b'
    mov         byte [FILE_NAME + r13 + 3], 'l'
    mov         byte [FILE_NAME + r13 + 4], 0


deleteFromTable_skipWHERE:
    cmp         byte [command + r12], ' '
    jne         deleteFromTable_raiseError
    
    mov         rcx, 6
    mov         rsi, WHERE
    mov         rdi, s2
    rep         movsb

    xor         rdx, rdx
.looop:
    lea         rsi, [command + rdx]
    cmp         byte [rsi], 0
    je          deleteFromTable_raiseError
    mov         rdi, s1
    mov         rcx, 5
    rep         movsb
    mov         byte [s1 + 5], 0
    
    call        stringComparator
    cmp         byte [s3], 1
    je          deleteFromTable_extractConditions
.next:
    inc         rdx
    jmp         .looop


deleteFromTable_extractConditions:
    xchg        r12, rdx
    add         r12, 5
    cmp         byte [command + r12], ' '
    jne         deleteFromTable_raiseError
    
    inc         r12
    xor         r13,r13
.looop:
    mov         al,[command + r12]
    cmp         al, ' '
    je          deleteFromTable_raiseError
    cmp         al, 0
    je          .found_conditions
    mov         byte [CONDITION + r13], al
    inc         r13
.next:
    inc         r12
    jmp         .looop
.found_conditions:



deleteFromTable_readFile:
    mov     rax, sys_open
    lea     rdi, [rel FILE_NAME]
    xor     rsi, rsi                ; O_RDONLY
    syscall
    cmp     rax, 0
    js      deleteFromTable_raiseError    ; check for error
    mov     [FDdst], rax            ; save file descriptor

; reading the file into buf
    mov     rdi, [FDdst]
    mov     rsi, buf
    mov     rdx, 1024
    mov     rax, 0      ; sys_read
    syscall 

    mov     rdi, [FDdst]
    call    closeFile


deleteFromTable_FirstLineOfFile:
    ; READ FIRST LINE OF FILE
    xor         r14,r14
.looop:
    mov         al, [buf + r14]
    cmp         al, NL
    je          .done
    mov         byte [HEADER + r14], al
.next:
    inc         r14
    jmp         .looop
.done:
    mov         byte [HEADER + r14], NL
    inc         r14
    mov         byte [HEADER + r14], 0
    mov         [HEADER_LEN], r14
    lea         r13, [buf + r14]
    mov         [buf_pointer], r13


    ; OPEN FILE
.open_file_and_write_header:
    mov     rax, 2                                  ; syscall: sys_open
    lea     rdi, [rel FILE_NAME]                    ; pointer to filename
    mov     rsi, 577                                ; O_WRONLY | O_TRUNC | O_CREAT (1 + 512 + 64)
    mov     rdx, 0o644                              ; file permissions (rw-r--r--)
    syscall
    cmp     rax, 0
    js      deleteFromTable_fileNotFound             ; handle error
    mov     [FDdst], rax  ; save FD


    ; WRITE HEADER
.write_header_on_file:

    mov     rax, 1                  ; syscall: sys_write
    mov     rdi, [FDdst]            ; file descriptor
    lea     rsi, [rel HEADER]       ; pointer to data
    mov     rdx, [HEADER_LEN]       ; length of data
    syscall


deleteFromTable_checkRecords:
    ; LOOP <<
    ; COPY A RECORD ON <LINE>
    xor     r14, r14
    mov     r13, [buf_pointer]
.copy_line:
    mov     al, [r13 + r14]
    cmp     al, NL
    je      .lineEnd
    cmp     al, 0
    je      .done
    mov     byte [LINE + r14], al
    inc     r14
    jmp     .copy_line
.lineEnd:
    mov     byte [LINE + r14], NL
    inc     r14
    mov     [LINE_LEN], r14
    ; CALL ROUTINE FOR CHECKING THE RECORD
    call    check_condition
    cmp     byte [s3], 0
    jne     .nextLine

    mov     rax, 1                  ; syscall: sys_write
    mov     rdi, [FDdst]            ; file descriptor
    lea     rsi, [rel LINE]         ; pointer to data
    mov     rdx, [LINE_LEN]         ; length of data
    syscall

.nextLine:
    add     r13, r14
    xor     r14, r14
    jmp     .copy_line
.done:


    ; CLOSE FILE
.close_file:
    mov     rax, 3            ; syscall: sys_close
    mov     rdi, [FDdst]      ; same FD
    syscall
    ; 
    jmp deleteFromTable_done




deleteFromTable_raiseError:
    call        raiseError_badCommand
    jmp         deleteFromTable_done

deleteFromTable_fileNotFound:
    call        raiseError_fileNotFound
    jmp         deleteFromTable_done


deleteFromTable_done:
    pop         r12
    pop         r13
    pop         r14
    pop         rdx
    pop         rcx
    pop         rax
    pop         rdi
    pop         rsi
    pop         rbx
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; Dastoor
; INSERT INTO students VALUES ("amir",32)
; INSERT INTO students VALUES ("ali",24)
; INSERT INTO students VALUES ("babi",38)
; DELETE FROM students WHERE age<30


; Subroutine: check_condition
; Inputs:
;   CONDITION (buffer) contains NUL-terminated string: <col><op><value>
;   HEADER   (buffer) contains NUL-terminated "name:type,..."
;   LINE     (buffer) contains NUL-terminated data record "val1,val2,..."
; Output:
;   byte [s3] = 1 if condition holds, 0 otherwise
;
; Uses scratch buffers:
;   s5 for column name
;   s6 for condition value string
;   s7 for field value string
;
check_condition:
    ; Save registers
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rsi
    push    rdi

    ; --- 1. Parse CONDITION into s5 (col), s4 (op), s6 (value) ---
    xor     rbx, rbx        ; offset in CONDITION
    lea     rsi, [rel CONDITION]
    lea     rdi, [rel s5]
.parse_cond:
    mov     al, [rsi+rbx]
    cmp     al, '='
    je      .got_op
    cmp     al, '>'
    je      .got_op
    cmp     al, '<'
    je      .got_op
    mov     [rdi+rbx], al
    inc     rbx
    jmp     .parse_cond
.got_op:
    mov     byte [s4], al   ; store operator
    mov     byte [s5+rbx], 0 ; terminate column name
    ; copy remainder to s6
    lea     rdi, [rel s6]
    xor     rcx, rcx        ; count
    inc     rbx
.copy_val:
    mov     al, [rsi+rbx]
    cmp     al, NL
    je      .val_done
    cmp     al, 0
    je      .val_done
    mov     [rdi+rcx], al
    inc     rcx
    inc     rbx
    jmp     .copy_val
.val_done:
    mov     byte [s6+rcx], 0 ; terminate condition value

        ; --- 2. Find column index by comparing s5 to HEADER names ---
    xor     rcx, rcx         
    xor     rdx, rdx        ; field index
    lea     rsi, [rel HEADER]
.find_field:
    ; extract next header name into s2 for compare
    xor     rbx, rbx
    lea     rdi, [rel s2]
.copy_hdr:
    mov     al, [rsi+rcx]
    cmp     al, ':'
    je      .hdr_type_sep
    mov     [rdi+rbx], al
    inc     rcx
    inc     rbx
    jmp     .copy_hdr
.hdr_type_sep:
    mov     byte [rdi+rbx], 0 ; terminate at ':'
.compare_hdr:
    ; push    rsi
    ; lea     rsi, [s2]
    ; call    printString
    ; pop     rsi
    ; copy s5 into s1 for comparator
    push    rsi
    lea     rdi, [rel s1]
    mov     rsi, s5
    call    strcpy_zero
    pop     rsi
    ; copy s2 into s2-buffer (already zero-terminated)
    ; compare
    ; push    rsi
    ; lea     rsi, [s1]
    ; call    printString
    ; lea     rsi, [s2]
    ; call    printString
    ; pop     rsi
    call    stringComparator
    cmp     byte [s3], 1
    je      .got_index
    ; skip to next header

.skip_to_next_header:
    inc     rbx
    mov     al, [rsi+rcx]
    cmp     al, ','
    je      .loooop_done
    cmp     al, 0
    je      .hdr_done
    inc     rcx
    jmp     .skip_to_next_header
.loooop_done:
    inc     rcx
    inc     rdx
    jmp     .find_field

.hdr_done:
    ; no more headers
    jmp .done
.got_index:
    ; ; mov     [where_index], rcx  ; save matched index

    ; mov     rsi, LINE
    ; call    printString
    ; call    newLine
    ; mov     rax, rdx
    ; call    writeNum
    ; call    newLine


    ; --- 3. Extract corresponding field from LINE into s7 --- from LINE into s7 ---
    xor     rbx, rbx        ; row field index
    lea     rdi, [s7]
    lea     rsi, [LINE]
    xor     r9, r9
.extract_val:
    cmp     rbx, rdx        ; reached desired field?
    je      .copy_field
    mov     al, [rsi + r9]
    cmp     al, ','
    je      .next_row_field
    cmp     al, NL
    je      .copy_field
    inc     r9
    jmp     .extract_val
.next_row_field:
    inc     r9
    inc     rbx
    jmp     .extract_val
.copy_field:
    xor     r8, r8          ; offset counter
.copy_loop:
    mov     al, [rsi + r9]
    cmp     al, ','
    je      .field_done
    cmp     al, NL
    je      .field_done
    mov     [rdi + r8], al
    inc     r8
    inc     r9
    jmp     .copy_loop
.field_done:
    mov     byte [s7+r8], 0 ; terminate field string
    ; mov     rsi, s7
    ; call    printString


;     ; mov     rsi, s7
;     ; call    printString


    ; --- 4. Determine type from HEADER (char after colon) ---
    lea     rsi, [rel HEADER]
    mov     rbx, rdx        ; target field idx
.find_type:
    mov     al, [rsi]
    ; call    putc
    cmp     al, ':'
    jne     .inc_type
    cmp     rbx, 0
    jne     .inc_type
    mov     al, [rsi+1]
    mov     [s8], al        ; store type char
    jmp     .eval_cond
.inc_type:
    inc     rsi
    cmp     byte [rsi], ','
    jne     .find_type
    inc     rsi
    dec     rbx
    jnz     .find_type
    jmp     .find_type

; heree
;     ; --- 5. Evaluate condition ---
.eval_cond:
    cmp     byte [s8], 'i'
    je      .eval_int
    ; string compare for '=' only (string types)
    ; copy field value s7 -> s1
    lea     rsi, [rel s7]
    lea     rdi, [rel s1]
    call    strcpy_zero
    ; copy condition value s6 -> s2
    lea     rsi, [rel s6]
    lea     rdi, [rel s2]
    call    strcpy_zero
    ; compare s1 and s2
    call    stringComparator
    ; result in s3 already
    jmp     .done

.eval_int:
    ; mov     rsi, s7
    ; call    printString
    ; call    newLine

    mov     rdi, s7
    call    str2int
    mov     r9, rax
    ; call    writeNum

    mov     rdi, s6
    call    str2int
    mov     r10, rax
    ; call    writeNum

    mov     al, [s4]
    cmp     al, '='
    je      .cmp_eq
    cmp     al, '>'
    je      .cmp_gt
    cmp     al, '<'
    je      .cmp_lt
    jmp     .done
.cmp_eq:
    cmp     r9, r10
    sete    al
    mov     [s3], al
    jmp     .done
.cmp_gt:
    cmp     r9, r10
    setg    al
    mov     [s3], al
    jmp     .done
.cmp_lt:
    cmp     r9, r10
    setl    al
    mov     [s3], al
    jmp     .done

.no_such_column:
    mov     byte [s3], 0
    jmp     .done
.no_such_field:
    ; mov     rax, 1
    ; call    writeNum
    mov     byte [s3], 0
    jmp     .done

.done:
    ; Restore registers
    ; call    newLine
    ; mov     al, [s3]
    ; call    writeNum
    ; mov     byte [s3], 1
    ; call    newLine
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret

strcpy_zero:
    push    rax
    push    rcx
    xor     rcx,rcx
.copy_loop:
    mov     al, [rsi+rcx]
    mov     [rdi+rcx], al
    inc     rcx
    cmp     al, 0
    jne     .copy_loop
    pop     rcx
    pop     rax
    ret



; Helper: convert decimal string at RDI to integer in RAX
str2int:
    push    rbx
    push    rcx
    xor     rax, rax      ; accumulator = 0
    xor     rbx, rbx      ; index = 0
.conv_loop:
    movzx   rcx, byte [rdi + rbx]  ; load next character
    cmp     rcx, 0                 ; end of string?
    je      .conv_done
    sub     rcx, '0'               ; convert ASCII to numeric value
    imul    rax, rax, 10           ; acc *= 10
    add     rax, rcx               ; acc += digit
    inc     rbx                     ; index++
    jmp     .conv_loop
.conv_done:
    pop     rcx
    pop     rbx
    ret




; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; Subroutine for comparing two strings in 's1' and 's2' reserved bytes.
stringComparator:
    push        rax
    push        rbx
    push        r9
    xor         r9, r9

stringComparator_checker:
    mov         al, [s1+r9]
    mov         bl, [s2+r9]
    cmp         al, bl
    jne         stringComparator_not_equal
    cmp         al, 0
    je          stringComparator_equal
    inc         r9
    jmp         stringComparator_checker

stringComparator_not_equal:
    mov         byte [s3], 0
    jmp         stringComparator_done

stringComparator_equal:
    mov         byte [s3], 1
    jmp         stringComparator_done

stringComparator_done:
    pop         r9
    pop         rbx
    pop         rax
    ret
; CHECKED ✅
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
director:
    push        r8
    push        rbx
    push        rcx
    push        rsi
    push        rdi
    xor         r8, r8

; loop for separating the first word to direct the program.
director_while1:
    mov         bl, [command+r8]
    cmp         bl, ' '
    je          director_first_word_separated1
    cmp         bl, 0
    je          director_first_word_separated1
    mov         [s1+r8], bl
    inc         r8
    jmp         director_while1

; checking which command did the user enter?
; CREATE?
director_first_word_separated1:
    mov         byte [s1+r8], 0
    mov         rcx, 7
    mov         rsi, CREATE
    mov         rdi, s2
    rep         movsb
    call        stringComparator
    cmp         byte [s3], 1
    jne         director_first_word_separated2
    call        createTable
    jmp         director_done
; CHECKED ✅

; QUIT?
director_first_word_separated2:
    mov         rcx, 5
    mov         rsi, QUIT
    mov         rdi, s2
    rep         movsb
    call        stringComparator
    cmp         byte [s3], 1
    jne         director_first_word_separated3
    mov         byte [s10], 0
    jmp         director_done
; CHECKED ✅

; DROP?
director_first_word_separated3:
    mov         rcx, 5
    mov         rsi, DROP
    mov         rdi, s2
    rep         movsb
    call        stringComparator
    cmp         byte [s3], 1
    jne         director_first_word_separated4
    call        dropTable
    jmp         director_done
; CHECKED ✅

; SHOW TABLES?
director_first_word_separated4:
    mov         rcx, 5
    mov         rsi, SHOW
    mov         rdi, s2
    rep         movsb
    call        stringComparator
    cmp         byte [s3], 1
    jne         director_first_word_separated5
    call        showTables
    jmp         director_done
; CHECKED ✅

; DESCRIBE?
director_first_word_separated5:
    mov         rcx, 9
    mov         rsi, DESCRIBE
    mov         rdi, s2
    rep         movsb
    call        stringComparator
    cmp         byte [s3], 1
    jne         director_first_word_separated6
    call        describeTable
    jmp         director_done
; CHECKED ✅

; INSERT?
director_first_word_separated6:
    mov         rcx, 7
    mov         rsi, INSERT
    mov         rdi, s2
    rep         movsb
    call        stringComparator
    cmp         byte [s3], 1
    jne         director_first_word_separated7
    call        insertIntoTable
    jmp         director_done

; SELECT?
director_first_word_separated7:
    mov         rcx, 7
    mov         rsi, SELECT
    mov         rdi, s2
    rep         movsb
    call        stringComparator
    cmp         byte [s3], 1
    jne         director_first_word_separated8
    call        selectCommandHandler
    jmp         director_done

; DELETE?
director_first_word_separated8:
    mov         rcx, 7
    mov         rsi, DELETE
    mov         rdi, s2
    rep         movsb
    call        stringComparator
    cmp         byte [s3], 1
    jne         director_first_word_raiseError
    call        deleteFromTable
    jmp         director_done

; NONE
director_first_word_raiseError:
    call        raiseError_badCommand

director_done:
    pop         rdi
    pop         rsi
    pop         rcx
    pop         rbx
    pop         r8
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
checkIf_s5_isInt:
    push        r8

    xor         r8, r8
.looop:
    mov         al, [s5 + r8]
    cmp         al, 0
    je          .is_int
    cmp         al, 48
    jl          .not_int
    cmp         al, 57
    jge         .not_int

.next:
    inc         r8
    jmp         .looop

.not_int:
    mov         byte [s3], 0
    jmp         .done

.is_int:
    mov         byte [s3], 1
    jmp         .done

.done:
    pop         r8
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
checkIf_s5_isStr:
    push        r8

    cmp         byte [s5], 0x22
    jne         .not_str

    xor         r8, r8
.looop:
    mov         al, [s5 + r8]
    cmp         al, 0
    je          .found_end

.next:
    inc         r8
    jmp         .looop

.found_end:
    dec         r8
    cmp         byte [s5 + r8], 0x22
    jne         .not_str

.is_str:
    mov         byte [s3], 1
    jmp         .done

.not_str:
    mov         byte [s3], 0
    jmp         .done

.done:
    pop         r8
    ret

; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
check_compatibilty:
    push    rsi
    push    rdi
    push    rbx
    push    rcx
    push    rdx
    push    r8
    push    r9

    lea     rsi, [buf]           ; schema ptr
    lea     rdi, [CONTENT]       ; values ptr

.next_column:
    ; End of schema?
    mov     al, [rsi]
    cmp     al, 0
    je      .success

    ; skip column name up to ':'
.skip_colname:
    mov     al, [rsi]
    cmp     al, 0
    je      .success
    cmp     al, ':'
    je      .got_type
    inc     rsi
    jmp     .skip_colname

.got_type:
    inc     rsi                 ; now rsi points to first char of type
    mov     bl, [rsi]           ; save type char
    inc     rsi                 ; move past type char

    ; skip ',' after type
.skip_typecomma:
    mov     al, [rsi]
    cmp     al, ','
    jne     .skip_typecomma_check_end
    inc     rsi

.skip_typecomma_check_end:
    ; rsi now ready for next column

.get_next_value:
    ; skip leading commas or spaces
.skip_val_space:
    mov     al, [rdi]
    cmp     al, ' '
    je      .skip_val_advance
    cmp     al, ','
    je      .skip_val_advance
    jmp     .copy_value

.skip_val_advance:
    inc     rdi
    jmp     .skip_val_space

.copy_value:
    xor     rcx, rcx
.copy_loop:
    mov     al, [rdi + rcx]
    cmp     al, ','
    je      .value_done
    cmp     al, 10
    je      .value_done
    cmp     al, 0
    je      .value_done
    mov     [s5 + rcx], al
    inc     rcx
    jmp     .copy_loop

.value_done:
    mov     byte [s5 + rcx], 0
    add     rdi, rcx
    cmp     byte [rdi], ','
    je      .skip_comma
    jmp     .check_type

.skip_comma:
    inc     rdi

.check_type:
    cmp     bl, 'i'
    je      .check_int
    cmp     bl, 's'
    je      .check_str
    jmp     .fail

.check_int:
    call    checkIf_s5_isInt
    cmp     byte [s3], 1
    jne     .fail
    jmp     .next_column

.check_str:
    call    checkIf_s5_isStr
    cmp     byte [s3], 1
    jne     .fail
    jmp     .next_column

.fail:
    mov     byte [s3], 0
    ; Print error message
    mov     rax, 1          ; sys_write
    mov     rdi, 1          ; stdout
    mov     rsi, typeMismatchMsg
    mov     rdx, typeMismatchMsgLen
    syscall
    jmp     .done

.success:
    mov     byte [s3], 1

.done:
    pop     r9
    pop     r8
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rdi
    pop     rsi
    ret


; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
raiseError_badCommand:
    push    rax
    push    rdi
    push    rsi
    push    rdx

    mov     rax, 1          ; sys_write
    mov     rdi, 1          ; stdout
    mov     rsi, smthWrongMsg
    mov     rdx, smthWrongMsgLen
    syscall

    pop     rdx
    pop     rsi
    pop     rdi
    pop     rax
    ret


raiseError_fileNotFound:
    push    rax
    push    rdi
    push    rsi
    push    rdx

    mov     rax, 1          ; sys_write
    mov     rdi, 1          ; stdout
    mov     rsi, fileNotExistsMsg
    mov     rdx, fileNotExistsMsgLen
    syscall

    pop     rdx
    pop     rsi
    pop     rdi
    pop     rax
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>



_start:
    mov         byte [s10], 1
.app_loop:
    cmp         byte [s10], 1
    jne         Exit

    mov         rsi, dash
    call        printString

    ; <<TO GET ONE LINE OF COMMAND<<
    call        readOneLineCommand
    ; >>TO GET ONE LINE OF COMMAND>>

    ; <<TO PROCESS THE INPUTTED LINE OF COMMAND<<
    call        director
    ; >>TO PROCESS THE INPUTTED LINE OF COMMAND>>
    jmp         .app_loop

    

Exit:
    mov     rax, sys_exit
    xor     rdi, rdi
    syscall


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
    O_TRUNC      equ     0q01000
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
    ; mov     rsi, suces_create
    ; call    printString
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
    ; mov     rsi, suces_open
    ; call    printString
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
    ; mov     rsi, suces_write
    ; call    printString
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
    ; mov     rsi, suces_close
    ; call    printString
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
; nasm -f elf64 main.asm -o main.o
; ld main.o -o main
; ./main