; ls.asm – minimal directory listing in NASM for x86_64 Linux

section .bss
    buf:    resb 4096           ; buffer for getdents (should be large enough)

section .text
    global _start

_start:
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
    ; write syscall
    mov     rax, 1              ; sys_write
    mov     rdi, 1              ; stdout
    ; rsi already points to name
    mov     rdx, rcx            ; length of name
    syscall

    ; write newline
    mov     rax, 1
    mov     rdi, 1
    lea     rsi, [rel nl]
    mov     rdx, 1
    syscall

    ; advance to next entry
    add     rbx, r14
    sub     r13, r14
    jmp     .next_entry

.done:
    ; close directory
    mov     rax, 3              ; sys_close
    mov     rdi, r12
    syscall

    ; exit
    mov     rax, 60             ; sys_exit
    xor     rdi, rdi
    syscall

section .data
dot:    db '.',0
nl:     db 10                  ; newline
