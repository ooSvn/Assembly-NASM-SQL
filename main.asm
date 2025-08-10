section .data

    error_create        db "error in creating file             ", NL, 0
    error_close         db "error in closing file              ", NL, 0
    error_write         db "error in writing file              ", NL, 0
    error_read          db "error in reading file              ", NL, 0
    error_print         db "error in printing file             ", NL, 0

    suces_read          db "reading file                       ", NL, 0
    ; -----------------------------------------------------------------
    SEPARATOR           db "==================================================",NL,0
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
    fileNotExistsMsg    db "Error: no such table.", 10
    fileNotExistsMsgLen equ $ - fileNotExistsMsg
    fileNotFoundMsg     db "Error: file not found!",10
    fileNotFoundMsgLen  equ $ - fileNotFoundMsg
    noSuchColumnMsg     db "Error: no such column",10
    noSuchColumnMsgLen  equ $ - noSuchColumnMsg
    invalidColName      db "Error: invalid columns",10,0
    numOfColsError      db "Error: invalid number of columns",10,0
    ; -----------------------------------------------------------------
    dot                 db  ".", 0
    pipe_char           db  '|'
    comma               db  ",",0
    newline             db  10,0
    src_file            db  "srcfile.txt", 0
    FDdst               dq  0    ; file descriptor for destination file
    dash                db  '-',0
    s11                 dq  15
    s12                 db  0


section .bss
    FILE_NAME   resb    100         ; To store the name of the file
    CONTENT     resb    1000        ; To store the content of a command
    CONTENT_LEN resq    1
    LINE        resb    1000        ; To store a line of the content read from file
    LINE_LEN    resq    1
    HEADER      resb    4096        ; To store the header of the file.
    HEADER_LEN  resq    1
    COLUMNS     resb    1000        ; To store the columns of a table
    CONDITION   resb    1000        ; To store the condition been inputted from command
    command     resb    100         ; To store the whole inputted command 
    buf         resb    4096        ; a buffer to store the whole content of file
    buf_pointer resq    1
    ; -----------------------------------------------------------------
    ; Some helper storages
    s1          resb    1000
    s2          resb    1000
    s3          resb    1
    s4          resb    1
    s5          resb    1000
    s6          resb    1000
    s7          resb    1000
    s8          resb    1000  
    s9          resb    1000
    s10         resb    1


%macro printR 1:
    push        rax
    mov         rax, %1
    call        writeNum
    pop         rax
%endmacro


section .text
    global _start

; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; To read one line of command (stops reading when reached into a newline)
readOneLineCommand:
    push        rax
    push        r8
    xor         r8, r8

readOneLineCommand_loop:
    call        getc
    cmp         al, NL
    je          readOneLineCommand_done
    mov         [command + r8], al
    inc         r8
    jmp         readOneLineCommand_loop

readOneLineCommand_done:
    mov         byte [command + r8], 0
    pop         r8
    pop         rax
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; Parsing and doing commands like: CREATE TABLE <table_name> (col1:str,col2:int)
createTable:
    push        rax
    push        rsi
    push        rdi
    push        rdx
    push        rcx

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
    mov     rdx, 0
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
    cmp     al, ':'
    jne     .go_on
    mov     rdx, 1
.go_on:
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .copy_content

.done_content:
    mov     byte [rdi], 10
    mov     byte [rdi + 1], 0      ; NUL‑terminate
    cmp     rdx, 1
    jne     createTable_raiseError
    jmp     createTable_ContentLenExtraction


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
    jmp         createTable_done

createTable_raiseError:
    mov         rsi, invalidColName
    call        printString

createTable_done:
    pop         rcx
    pop         rdx
    pop         rdi
    pop         rsi
    pop         rax
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; Parsing and doing commands like: DROP TABLE <table_name>
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
; Parsing and doing command: SHOW TABLES
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
; Parsing and doing commands like: DESCRIBE <table_name>
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
    cmp     byte [buf + rbx], 44
    jne     .okay
    call    newLine
    inc     rbx
    jmp     .find_nl
.okay:
    cmp     byte [buf + rbx], NL
    je      .got_nl
    mov     al, [buf + rbx]
    call    putc
    inc     rbx
    jmp     .find_nl

.got_nl:
    mov     byte [buf + rbx], 0  ; NUL-terminate


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
    call    newLine
    pop     rdx
    pop     rcx
    pop     rax
    pop     rdi
    pop     rsi
    pop     rbx
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; Parsing and doing commands like: INSERT INTO <table_name> VALUES (val_1,val_2,...)
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
; header of the file (col1:type1,col2:type2,...) to (col1,col2,...) and save into COLUMNS
extract_header_columns:
    ; save registers (one per line as you requested)
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rsi
    push    rdi

    lea     rdi, [rel COLUMNS]  ; dest base
    xor     rbx, rbx            ; source index
    xor     rcx, rcx            ; dest index

.copy_into_COLUMN:
    mov     al, [rsi + rbx]
    cmp     al, ':'
    je      .got_colon
    cmp     al, NL
    je      .done_columns
    cmp     al, 0
    je      .done_columns
    mov     [rdi + rcx], al
    inc     rcx
    inc     rbx
    jmp     .copy_into_COLUMN

.got_colon: 
    inc     rbx
    mov     al, [rsi + rbx]
    cmp     al, NL
    je      .done_columns
    cmp     al, 0
    je      .done_columns
    cmp     al, ','
    jne     .got_colon
    mov     [rdi + rcx], al
    inc     rbx
    inc     rcx
    jmp     .copy_into_COLUMN

.done_columns:
    mov     byte [rdi + rcx], 0

    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; Parsing and handling commands like: 
; SELECT * FROM <table_name>
; SELECT * FROM <table_name> WHERE <condition>
; SELECT col1,col2,... FROM <table_name> WHERE <condition>
; (noting that <condition> could limit the records over just one column like: age>10)
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
    mov         byte [s12], 0

selectCommandHandler_extractColumns:
    mov         r12, 6
    cmp         byte [command + r12], ' '
    jne         selectCommandHandler_raiseError

    inc         r12
    xor         r13,r13
.looop:
    mov         al,[command + r12]
    cmp         al, ' '
    je          .found_cols
    cmp         al, 0
    je          selectCommandHandler_raiseError
    mov         byte [COLUMNS + r13], al
    inc         r13
.next:
    inc         r12
    jmp         .looop
.found_cols:
    mov         byte [COLUMNS + r13], 0

    cmp         byte [COLUMNS], '*'
    jne         selectCommandHandler_skipFROM
    cmp         byte [COLUMNS + 1], 0
    jne         selectCommandHandler_skipFROM

; here is assumed that * is inputted as columns
    mov         byte [s12], 1
    

selectCommandHandler_skipFROM:
    mov         rsi, FROM
    mov         rdi, s2
    mov         rcx, 5
    rep         movsb

    xor         rdx, r12
.looop:
    lea         rsi, [command + rdx]
    cmp         byte [rsi], 0
    je          selectCommandHandler_raiseError
    mov         rcx, 4
    mov         rdi, s1
    rep         movsb
    mov         byte [s1 + 4], 0
    
    call        stringComparator
    cmp         byte [s3], 1
    je          selectCommandHandler_extractFileName
.next:
    inc         rdx
    jmp         .looop


selectCommandHandler_extractFileName:
    add         rdx, 4
    cmp         byte [command + rdx], ' '
    jne         selectCommandHandler_raiseError

    inc     rdx
    lea     rsi, [command + rdx]
    mov     rdi, FILE_NAME

.copy_fname:
    mov     al, [rsi]
    cmp     al, ' '
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
    mov     byte [rdi + 4], 0
    call    check_file_existance
    cmp     byte [s3], 1
    jne     selectCommandHandler_fileNotFound


selectCommandHandler_skipWHERE:
    mov         rcx, 6
    mov         rsi, WHERE
    mov         rdi, s2
    rep         movsb

    xor         rdx, rdx
.looop:
    lea         rsi, [command + rdx]
    cmp         byte [rsi], 0
    je          noCondition
    mov         rdi, s1
    mov         rcx, 5
    rep         movsb
    mov         byte [s1 + 5], 0
    
    call        stringComparator
    cmp         byte [s3], 1
    je          selectCommandHandler_extractCondition
.next:
    inc         rdx
    jmp         .looop

selectCommandHandler_extractCondition:
    xchg        r12, rdx
    add         r12, 5
    cmp         byte [command + r12], ' '
    jne         selectCommandHandler_raiseError
    
    inc         r12
    xor         r13,r13
.looop:
    mov         al,[command + r12]
    cmp         al, ' '
    je          selectCommandHandler_raiseError
    cmp         al, 0
    je          .done
    mov         byte [CONDITION + r13], al
    inc         r13
.next:
    inc         r12
    jmp         .looop

.done:
    mov         byte[CONDITION + r13], 0

condition_exists:
    mov         byte [s9], 1
    jmp         selectCommandHandler_display
noCondition:
    mov         byte [s9], 0

; to display all info or with the mentioned condition.
selectCommandHandler_display:
.read_file:
    mov     rax, sys_open
    lea     rdi, [rel FILE_NAME]
    xor     rsi, rsi                ; O_RDONLY
    syscall
    cmp     rax, 0
    js      selectCommandHandler_raiseError    ; check for error
    mov     [FDdst], rax            ; save file descriptor

; reading the file into buf
    mov     rdi, [FDdst]
    mov     rsi, buf
    mov     rdx, 1024
    mov     rax, 0      ; sys_read
    syscall 

    mov     rdi, [FDdst]
    call    closeFile



.read_header:
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
    
; checking if the columns were inputted as *
    cmp     byte [s12], 1
    jne     selectCommandHandler_display_header
    call    extract_header_columns

selectCommandHandler_display_header:
    lea     rsi, [COLUMNS]
.begin:
    lea     rdi, [s7]
.looop:
    mov     al, [rsi]
    cmp     al, 0
    je      .found_the_col
    cmp     al, ','
    je      .found_the_col
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .looop
.found_the_col:
    mov     byte [rdi], 0
    call    print_s7
    cmp     byte [rsi], 0
    je      .done
    inc     rsi
    jmp     .begin
.done:
    call    newLine

selectCommandHandler_display_checkLine:
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

    cmp     byte [s9], 1
    jne     .no_check_cond

    call    check_condition
    cmp     byte [s3], 1
    jne     .nextLine

.no_check_cond:
    call    conditional_display

.nextLine:
    add     r13, r14
    xor     r14, r14
    jmp     .copy_line
.done:
    jmp     selectCommandHandler_done



selectCommandHandler_raiseError:
    call        raiseError_badCommand

selectCommandHandler_fileNotFound:
    call        raiseError_fileNotFound

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

;------------------------------------------------------------------------------
; conditional_display
;
; For each name in COLUMNS:
;   1) find its field index by walking HEADER (split on “,” and “:”)
;   2) extract that field out of LINE
;   3) print it
;   4) print a tab (or some spaces) to separate columns
;------------------------------------------------------------------------------
conditional_display:
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rsi
    push    rdi
    push    r8
    push    r9
    push    r11
    push    r12
    push    r14
    push    r13

    call    print_separator
    ; rsi = address of COLUMNS
    lea     r14, [rel COLUMNS]
    mov     r12, 1
.next_col:
    ; if *rsi == 0, we’re done
    cmp     r12, 1
    jne     .done_display
    mov     rsi, r14
    mov     al, [rsi]
    cmp     al, 0
    je      .done_display

    ; --- 1) extract next col name into s2 ---
    lea     rdi, [rel s2]
    xor     rcx, rcx
.extract_name:
    mov     al, [rsi]
    cmp     al, ','    
    je      .name_done
    cmp     al, 0
    je      .name_done
    mov     [rdi+rcx], al
    inc     rcx
    inc     rsi
    jmp     .extract_name
.name_done:
    mov     byte [rdi+rcx], 0  ; NUL terminate s2
    cmp     byte [rsi], 0
    jne     .boom
    mov     r12, 0
.boom:
    ; if we stopped on ',', skip it
    cmp     byte [rsi], ','
    jne     .find_index_start
    inc     rsi


.find_index_start:
    lea     r14, [rsi]
    ; --- 1b) find this name in HEADER, save index in r10 ---
    lea     rdi, [rel s1]    ; for comparator
    ; lea     rbx, [rel s2]    ; sought name
    lea     rsi, [rel HEADER]
    xor     rdx, rdx         ; field index counter
.find_header_loop:
    xor     rcx, rcx
.copy_hdr_name:
    mov     al, [rsi+rcx]
    cmp     al, ':'   ; stop at type-separator
    je      .hdr_term
    cmp     al, 0   ; or at next field
    je      .raiseError_noSuchColumn
    cmp     al, ','
    je      .skip_to_next
    mov     [rdi+rcx], al
    inc     rcx
    jmp     .copy_hdr_name
.hdr_term:
    mov     byte [rdi+rcx], 0
    ; note: adjust your strcpy_zero to allow dest!=src
    call    stringComparator
    cmp     byte [s3], 1
    je      .got_index
    
    inc     rdx           ; next field index
.skip_to_next:
    add     rsi, rcx
    inc     rsi
    jmp     .find_header_loop

.got_index:
    mov     r11, rdx      ; save desired field index

    ; --- 2) extract that field from LINE into s7 ---
    lea     rsi, [rel LINE]
    lea     rdi, [rel s7]
    xor     r8, r8        ; current field idx
    xor     r9, r9        ; offset in LINE

.find_field:
    cmp     r8, r11
    je      .start_copy_field
    ; skip until next comma or NL
.skipfld:
    mov     al, [rsi+r9]
    cmp     al, ','
    je      .field_sep
    cmp     al, NL
    je      .start_copy_field
    inc     r9
    jmp     .skipfld
.field_sep:
    inc     r9
    inc     r8
    jmp     .find_field

.start_copy_field:
    ; now r9 points at first char of desired field
    xor     rcx, rcx
.copy_field:
    mov     al, [rsi+r9]
    cmp     al, ','
    je      .field_done
    cmp     al, NL
    je      .field_done
    mov     [rdi+rcx], al
    inc     rcx
    inc     r9
    jmp     .copy_field
.field_done:
    mov     byte [s7+rcx], 0

    ; --- 3) print s7, then some spacing ---
    lea     rsi, [rel s7]
    call    print_s7

    ; loop back for next column
    jmp     .next_col

.raiseError_noSuchColumn:
    call    raiseError_noSuchColumn
    jmp     .restore

.done_display:
    ; print newline at end of record
    call    newLine
.restore:
    pop     r14
    pop     r13
    pop     r12
    pop     r11
    pop     r9
    pop     r8
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret


; Helper function for printing what's in s7 in an organised and clean box (the size of box is stored in s11)
print_s7:
    push    rax
    push    r14
    push    r13
    push    rdi
    push    rsi

    mov     rax, sys_write        ; syscall: write
    mov     rdi, stdout           ; file descriptor 1
    lea     rsi, [rel pipe_char]  ; pointer to '|'
    mov     rdx, 1                 ; length = 1 byte
    syscall

    xor     r14, r14
    jmp     .printer
    mov     al, 124     ; '|'
    call    putc
.newliner:
    call    newLine
    mov     al, ' '
    call    putc
.printer:
    mov     r13, [s11]
.looop:
    dec     r13
    cmp     r13, 0
    je      .newliner
    
    mov     al, [s7 + r14]
    cmp     al, 0
    je      .s7_ended
    call    putc
    inc     r14
    jmp     .looop
.s7_ended:
    cmp     r13, 0
    jle     .done 
    dec     r13
    mov     al, ' '
    call    putc
    jmp     .s7_ended
.done:
    pop     rsi
    pop     rdi
    pop     r13
    pop     r14
    pop     rax
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; Parsing and handling commands like: DELETE FROM <table_name> WHERE <condition>
; <condition> could be same as it was in SELECT command.
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
    call        check_file_existance
    cmp         byte [s3], 1
    jne         deleteFromTable_fileNotFound

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
    mov         byte [CONDITION + r13], 0

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
; Checking if the the CONDITION holds for the record available in LINE
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
    ; copy s5 into s1 for comparator
    push    rsi
    lea     rdi, [rel s1]
    mov     rsi, s5
    call    strcpy_zero
    pop     rsi
    
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
    ; call    putc
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

    ; --- 4. Determine type from HEADER (char after colon) ---
    lea     rsi, [rel HEADER]
    mov     rbx, rdx        ; target field idx
.find_type:
    mov     al, [rsi]
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

    mov     rdi, s7
    call    str2int
    mov     r9, rax

    mov     rdi, s6
    call    str2int
    mov     r10, rax

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
    mov     byte [s3], 0
    jmp     .done

.done:
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; Copying content starting from rsi into rdi until reaching zero-temination
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
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; Helper: convert decimal string at RDI to integer in RAX
str2int:
    push    rbx
    push    rcx
    xor     rax, rax                ; accumulator = 0
    xor     rbx, rbx                ; index = 0
.conv_loop:
    movzx   rcx, byte [rdi + rbx]   ; load next character
    cmp     rcx, 0                  ; end of string?
    je      .conv_done
    sub     rcx, '0'                ; convert ASCII to numeric value
    imul    rax, rax, 10            ; acc *= 10
    add     rax, rcx                ; acc += digit
    inc     rbx                     ; index++
    jmp     .conv_loop
.conv_done:
    pop     rcx
    pop     rbx
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; Helper
print_separator:
    push    rsi
    mov     rsi, SEPARATOR
    call    printString
    pop     rsi
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
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; The director function of the program which passes the command based on their first word
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
; helper
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
; helper
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
; to check whether the inputted VALUES match the types set in the file. (and 
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
    je      .check_if_end_of_CONTENT
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
    mov     rax, 1          ; sys_write
    mov     rdi, 1          ; stdout
    mov     rsi, typeMismatchMsg
    mov     rdx, typeMismatchMsgLen
    syscall
    jmp     .done

.check_if_end_of_CONTENT:
    mov     al, [rdi]
    cmp     al, 0
    je      .done
    cmp     al, NL
    je      .done
    jmp     .num_of_cols_error

.success:
    mov     byte [s3], 1
    jmp     .done

.num_of_cols_error:
    mov     byte [s3], 0
    mov     rsi, numOfColsError
    call    printString


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

    mov     rax, 1
    mov     rdi, 1
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

    mov     rax, 1          
    mov     rdi, 1
    mov     rsi, fileNotExistsMsg
    mov     rdx, fileNotExistsMsgLen
    syscall

    pop     rdx
    pop     rsi
    pop     rdi
    pop     rax
    ret


raiseError_noSuchColumn:
    push    rax
    push    rdi
    push    rsi
    push    rdx

    mov     rax, 1
    mov     rdi, 1
    mov     rsi, noSuchColumnMsg
    mov     rdx, noSuchColumnMsgLen
    syscall

    pop     rdx
    pop     rsi
    pop     rdi
    pop     rax
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; helper
check_file_existance:
    push    rax
    push    rdi
    push    rsi

    mov     rax, sys_open
    lea     rdi, [rel FILE_NAME]
    xor     rsi, rsi                ; O_RDONLY
    syscall
    cmp     rax, 0
    js      .not_exists
    mov     byte [s3], 1
    mov     rdi, rax
    call    closeFile
    jmp     .done

.not_exists:
    mov     byte [s3], 0
.done:
    pop     rsi
    pop     rdi
    pop     rax
    ret
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
; <><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
reset_storage:
    lea         rdi, [rel buf]       ; buffer start
    mov         rcx, 4096            ; size in bytes
    xor         rax, rax
    rep         stosb
    mov         byte [buf_pointer], 0
    mov         byte [HEADER], 0
    mov         byte [HEADER_LEN], 0
    mov         byte [COLUMNS], 0  
    mov         byte [CONDITION], 0
    mov         byte [command], 0
    mov         byte [s1], 0
    mov         byte [s2], 0
    mov         byte [s3], 0
    mov         byte [s4], 0
    mov         byte [s5], 0
    mov         byte [s6], 0
    mov         byte [s7], 0
    mov         byte [s8], 0
    mov         byte [s9], 0
    ; -----------------------------------------------------------------
    mov         byte [FILE_NAME], 0
    mov         byte [CONTENT], 0
    mov         byte [CONTENT_LEN], 0
    mov         byte [LINE], 0
    mov         byte [LINE_LEN], 0
    ret




_start:
    mov         byte [s10], 1
.app_loop:
    call        reset_storage
    cmp         byte [s10], 1
    jne         Exit
    
    mov         rsi, dash
    call        printString

    call        readOneLineCommand
    call        director
    call        newLine

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
    ret
createerror:
    mov     rsi, error_create
    call    printString
    ret
writeFile:
    mov     rax, sys_write
    syscall
    cmp     rax, -1
    jle     writeerror
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
    ret
closeerror:
    mov     rsi, error_close
    call    printString
    ret


; To RUN the code:
; nasm -f elf64 main.asm -o main.o
; ld main.o -o main
; ./main