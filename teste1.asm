; Montagem: nasm -f elf64 Trabalho1.asm
; Ligação : ld Trabalho1.o -o Trabalho1.x

section .data
    nome_entrada    db "dados.txt", 0
    nome_saida      db "dados1.txt", 0
    msg_fim         db 10, "Arquivo copiado com sucesso", 10, 0
    tam_msg_fim     equ $ - msg_fim

section .bss
    buffer          resb 1024   ; Buffer para leitura e escrita
    fd_in           resq 1      ; File descriptor entrada
    fd_out          resq 1      ; File descriptor saída

section .text
    global _start

_start:
    ; Abrir arquivo de entrada (dados.asm) - syscall open
    mov rax, 2              ; syscall: sys_open
    mov rdi, nome_entrada   ; nome do arquivo
    mov rsi, 0              ; O_RDONLY = 0
    mov rdx, 0
    syscall
    mov [fd_in], rax        ; salvar file descriptor

    ; Criar arquivo de saída (dados1.asm) - syscall open com O_WRONLY | O_CREAT | O_TRUNC
    mov rax, 2              ; syscall: sys_open
    mov rdi, nome_saida     ; nome do novo arquivo
    mov rsi, 577            ; O_WRONLY (1) | O_CREAT (64) | O_TRUNC (512) = 577
    mov rdx, 0644           ; Permissões rw-r--r--
    syscall
    mov [fd_out], rax       ; salvar file descriptor

read_loop:
    ; Ler do arquivo de entrada
    mov rax, 0              ; syscall: sys_read
    mov rdi, [fd_in]
    mov rsi, buffer
    mov rdx, 1024
    syscall
    cmp rax, 0              ; EOF?
    jle fim

    ; Escrever no arquivo de saída
    mov rbx, rax            ; número de bytes lidos
    mov rax, 1              ; syscall: sys_write
    mov rdi, [fd_out]
    mov rsi, buffer
    mov rdx, rbx
    syscall

    jmp read_loop

fim:
    ; Escreve mensagem final no terminal
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_fim
    mov rdx, tam_msg_fim
    syscall

    ; Fechar arquivo de entrada
    mov rax, 3
    mov rdi, [fd_in]
    syscall

    ; Fechar arquivo de saída
    mov rax, 3
    mov rdi, [fd_out]
    syscall

    ; Encerrar programa
    mov rax, 60
    xor rdi, rdi
    syscall
