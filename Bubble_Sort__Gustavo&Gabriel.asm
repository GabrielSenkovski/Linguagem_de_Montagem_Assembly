; MONTAGEM E LIGACAO ->

; nasm -f elf64 [LM pratica 01]GustavoChiossi_GabrielSenkovski.asm

; ld [LM pratica 01]GustavoChiossi_GabrielSenkovski.o -o [LM pratica 01]GustavoChiossi_GabrielSenkovski.x

; ./[LM pratica 01]GustavoChiossi_GabrielSenkovski.x


section .data
    msg_org db "vetor original: ", 0xA
    msg_orgL equ $ - msg_org
    msg_ord db "vetor ordenado: ", 0xA
    msg_ordL equ $ - msg_ord

    arquivo_original db "dados.txt", 0
    arquivo_ordenado db "ordenado.txt", 0

    arrayL equ 30

    ; flags
    O_RDONLY equ 0
    O_WRONLY equ 1
    O_CREAT equ 64
    O_TRUNC equ 512
    PERM equ 0o644

    msg_stats    db 10, "Estatísticas:", 10, 0
    msg_statsL   equ $ - msg_stats

    msg_comp     db "Comparações: ", 0
    msg_compL    equ $ - msg_comp

    msg_trocas   db "Trocas: ", 0
    msg_trocasL  equ $ - msg_trocas

section .bss
    array resd arrayL
    buffer_leitura resb 200
    buffer_resultado resb 200
    digitos resb 10
    comparacoes resd 1
    trocas resd 1
    tam_lido resb 1

section .text
    global _start

_start:
    ; abrir arquivo
    mov rax, 2
    mov rdi, arquivo_original
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    mov r12, rax

    ; ler conteúdo
    mov rax, 0
    mov rdi, r12
    mov rsi, buffer_leitura
    mov rdx, 200
    syscall

    ; fechar
    mov rax, 3
    mov rdi, r12
    syscall

    ; converter ASCII -> decimal
    mov rsi, buffer_leitura
    mov rdi, array
    xor rcx, rcx

converte:
    movzx eax, byte [rsi]
    cmp al, 0
    je converte_fim
    cmp al, 0xA
    je proximo

    ; primeiro dígito
    sub al, '0'

    movzx ebx, byte [rsi + 1]
    cmp bl, 0xA
    je .um_digito

    ; dois dígitos
    sub bl, '0'
    imul eax, 10
    add eax, ebx
    add rsi, 1
    jmp .grava

    .um_digito:
    ; eax já contém o valor do único dígito

    .grava:
    mov [rdi], al
    inc rdi
    inc rcx
    

proximo:
    inc rsi
    jmp converte

converte_fim:
    mov [tam_lido], cl

    ; printar vetor original
    mov eax, 1
    mov edi, 1
    mov rsi, msg_org
    mov edx, msg_orgL
    syscall

    mov rsi, array
    xor r8, r8
    mov rdi, buffer_resultado
    mov rbx, rdi

print_loop_org:
    movzx r9, byte [tam_lido]
    cmp r8, r9
    jge fim_print_org

    movzx eax, byte [rsi + r8]
    xor rcx, rcx
    mov r10, 10

div10_org:
    xor rdx, rdx
    div r10
    add dl, '0'
    mov [digitos + rcx], dl
    inc rcx
    cmp eax, 0
    jne div10_org

escreve_org:
    dec rcx
    mov al, [digitos + rcx]
    mov [rdi], al
    inc rdi
    cmp rcx, 0
    jne escreve_org

    mov byte [rdi], 0xA
    inc rdi
    inc r8
    jmp print_loop_org

fim_print_org:
    dec rdi
    mov byte [rdi], 0xA
    mov r14, rdi
    mov rdx, rdi
    sub rdx, rbx
    inc rdx

    mov eax, 1
    mov edi, 1
    mov rsi, rbx
    syscall

    ; zera contadores
    mov dword [comparacoes], 0
    mov dword [trocas], 0

    ; Bubble Sort com tam_lido
    movzx ecx, byte [tam_lido]
    dec ecx

externo:
    xor esi, esi
    mov edx, ecx

interno:
    movzx eax, byte [array + esi]
    movzx ebx, byte [array + esi + 1]

    ; contador comparações
    mov edi, [comparacoes]
    inc edi
    mov [comparacoes], edi

    cmp eax, ebx
    jle no_swap

    ; troca
    mov [array + esi], bl
    mov [array + esi + 1], al

    ; contador trocas
    mov edi, [trocas]
    inc edi
    mov [trocas], edi

no_swap:
    inc esi
    dec edx
    jne interno
    dec ecx
    jne externo

    ; printar vetor ordenado
    mov eax, 1
    mov edi, 1
    mov rsi, msg_ord
    mov edx, msg_ordL
    syscall

    mov rsi, array
    xor r8, r8
    mov rdi, buffer_resultado
    mov rbx, rdi

print_loop_ord:
    movzx r9, byte [tam_lido]
    cmp r8, r9
    jge fim_print_ord

    movzx eax, byte [rsi + r8]
    xor rcx, rcx
    mov r10, 10

div10_ord:
    xor rdx, rdx
    div r10
    add dl, '0'
    mov [digitos + rcx], dl
    inc rcx
    cmp eax, 0
    jne div10_ord

escreve_ord:
    dec rcx
    mov al, [digitos + rcx]
    mov [rdi], al
    inc rdi
    cmp rcx, 0
    jne escreve_ord

    mov byte [rdi], 0xA
    inc rdi
    inc r8
    jmp print_loop_ord

fim_print_ord:
    dec rdi
    mov byte [rdi], 0xA
    mov r15, rdi
    mov rdx, rdi
    sub rdx, rbx
    inc rdx

    mov eax, 1
    mov edi, 1
    mov rsi, rbx
    syscall

    ; salvar ordenado.txt
    mov rax, 2
    mov rdi, arquivo_ordenado
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, PERM
    syscall
    mov r12, rax

    mov eax, 1
    mov rdi, r12
    mov rsi, rbx
    mov rdx, r15
    sub rdx, rbx
    inc rdx
    syscall

    mov eax, 3
    mov rdi, r12
    syscall

    ; imprimir estatísticas
    mov eax, 1
    mov edi, 1
    mov rsi, msg_stats
    mov edx, msg_statsL
    syscall

    ; comparações
    mov eax, 1
    mov edi, 1
    mov rsi, msg_comp
    mov edx, msg_compL
    syscall

    mov eax, [comparacoes]
    jmp imprime_decimal_comp

continua_trocas:
    mov eax, 1
    mov edi, 1
    mov rsi, msg_trocas
    mov edx, msg_trocasL
    syscall

    mov eax, [trocas]
    jmp imprime_decimal_trocas

imprime_decimal_comp:
    mov rdi, buffer_resultado
    xor rcx, rcx
    mov rbx, 10

.loop_comp:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [digitos + rcx], dl
    inc rcx
    cmp eax, 0
    jne .loop_comp

.print_comp:
    dec rcx
    mov al, [digitos + rcx]
    mov [rdi], al
    inc rdi
    cmp rcx, 0
    jne .print_comp

    mov byte [rdi], 0xA
    mov rdx, rdi
    sub rdx, buffer_resultado
    inc edx

    mov eax, 1
    mov edi, 1
    mov rsi, buffer_resultado
    syscall

    jmp continua_trocas

imprime_decimal_trocas:
    mov rdi, buffer_resultado
    xor rcx, rcx
    mov rbx, 10

.loop_trocas:
    xor rdx, rdx
    div rbx
    add dl, '0'
    mov [digitos + rcx], dl
    inc rcx
    cmp eax, 0
    jne .loop_trocas

.print_trocas:
    dec rcx
    mov al, [digitos + rcx]
    mov [rdi], al
    inc rdi
    cmp rcx, 0
    jne .print_trocas

    mov byte [rdi], 0xA
    mov rdx, rdi
    sub rdx, buffer_resultado
    inc edx

    mov eax, 1
    mov edi, 1
    mov rsi, buffer_resultado
    syscall

    jmp fim

fim:
    mov eax, 60
    xor edi, edi
    syscall
