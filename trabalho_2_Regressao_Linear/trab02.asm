extern fopen
extern fclose
extern fgets
extern sscanf
extern fprintf
extern printf
extern strncmp

section .data
    formato_scan       db "%f %f", 0
    formato_tela       db "coeficiente a = %.2f", 10, "coeficiente b = %.2f", 10, 0
    formato_arquivo    db "Execucao %d", 10, "===============", 10, "coeficiente a = %lf", 10, "coeficiente b = %lf", 10, "===============", 10, 0
    formato_num        db "%d", 0
    modo_leitura       db "r", 0
    modo_append        db "a", 0
    nome_resultado     db "resultado.txt", 0
    execucao_prefixo   db "Execucao", 0

section .bss
    soma_x   resq 1
    soma_y   resq 1
    soma_xy  resq 1
    soma_x2  resq 1

    x_temp   resd 1
    y_temp   resd 1
    a_temp   resq 1
    b_temp   resq 1
    n_pontos resd 1
    contador_execucao resd 1
    temp_num resd 1

    buffer   resb 128

section .text
    global main
    
main:
    push rbp
    mov rbp, rsp
    sub rsp, 64

    ; Abrir arquivo de entrada
    mov rax, [rsi + 8]
    mov rdi, rax
    lea rsi, [rel modo_leitura]
    call fopen
    mov [rbp-8], rax

    ; Inicializar variáveis
    xorpd xmm0, xmm0
    movsd [soma_x], xmm0
    movsd [soma_y], xmm0
    movsd [soma_xy], xmm0
    movsd [soma_x2], xmm0
    mov dword [n_pontos], 0

leitura_loop:
    ; Ler linha do arquivo
    lea rdi, [rel buffer]
    mov esi, 128
    mov rdx, [rbp-8]
    call fgets
    test rax, rax
    je fim_leitura

    ; Extrair valores x e y
    lea rdi, [rel buffer]
    lea rsi, [rel formato_scan]
    lea rdx, [rel x_temp]
    lea rcx, [rel y_temp]
    xor rax, rax
    call sscanf
    cmp eax, 2
    jne leitura_loop

    ; Converter para double e acumular somas
    movss xmm0, dword [x_temp]
    cvtss2sd xmm0, xmm0
    movss xmm1, dword [y_temp]
    cvtss2sd xmm1, xmm1

    movsd xmm2, [soma_x]
    addsd xmm2, xmm0
    movsd [soma_x], xmm2

    movsd xmm2, [soma_y]
    addsd xmm2, xmm1
    movsd [soma_y], xmm2

    mulsd xmm0, xmm1
    movsd xmm2, [soma_xy]
    addsd xmm2, xmm0
    movsd [soma_xy], xmm2

    movss xmm0, dword [x_temp]
    cvtss2sd xmm0, xmm0
    mulsd xmm0, xmm0
    movsd xmm2, [soma_x2]
    addsd xmm2, xmm0
    movsd [soma_x2], xmm2

    ; Incrementar contador de pontos
    mov eax, [n_pontos]
    inc eax
    mov [n_pontos], eax

    jmp leitura_loop

fim_leitura:
    ; Fechar arquivo de entrada
    mov rdi, [rbp-8]
    call fclose

    ; Calcular médias
    cvtsi2sd xmm0, [n_pontos]
    movsd xmm1, [soma_x]
    divsd xmm1, xmm0        ; x̄
    movsd xmm2, [soma_y]
    divsd xmm2, xmm0        ; ȳ

    ; Calcular coeficiente a
    movsd xmm3, [soma_xy]
    movsd xmm4, xmm0
    mulsd xmm4, xmm1
    mulsd xmm4, xmm2
    subsd xmm3, xmm4

    movsd xmm5, [soma_x2]
    movsd xmm6, xmm1
    mulsd xmm6, xmm1
    mulsd xmm6, xmm0
    subsd xmm5, xmm6

    divsd xmm3, xmm5
    movsd [a_temp], xmm3

    ; Calcular coeficiente b
    movsd xmm8, xmm3
    mulsd xmm8, xmm1
    movsd xmm9, xmm2
    subsd xmm9, xmm8
    movsd [b_temp], xmm9

    ; Mostrar resultados na tela
    lea rdi, [rel formato_tela]
    movsd xmm0, [a_temp]
    movsd xmm1, [b_temp]
    mov al, 2
    call printf

    ; Contar execuções anteriores no resultado.txt
    lea rdi, [rel nome_resultado]
    lea rsi, [rel modo_leitura]
    call fopen
    test rax, rax
    je contador_zero
    mov r13, rax
    mov dword [contador_execucao], 0

contador_loop:
    ; Ler linha do arquivo
    lea rdi, [rel buffer]
    mov esi, 128
    mov rdx, r13
    call fgets
    test rax, rax
    je contador_fim

    ; Verificar se a linha começa com "Execucao"
    lea rdi, [rel buffer]
    lea rsi, [rel execucao_prefixo]
    mov rdx, 8              ; Comprimento de "Execucao"
    call strncmp
    test eax, eax
    jne contador_next_line

    ; Extrair número da execução
    lea rdi, [rel buffer+8] ; Pula "Execucao "
    lea rsi, [rel formato_num]
    lea rdx, [rel temp_num]
    xor eax, eax
    call sscanf

    ; Atualizar contador se necessário
    mov eax, [temp_num]
    cmp eax, [contador_execucao]
    jle contador_next_line
    mov [contador_execucao], eax

contador_next_line:
    jmp contador_loop

contador_fim:
    ; Fechar arquivo
    mov rdi, r13
    call fclose
    jmp contador_ok

contador_zero:
    ; Se arquivo não existir, começar do zero
    mov dword [contador_execucao], 0

contador_ok:
    ; Incrementar contador para esta execução
    mov eax, [contador_execucao]
    inc eax
    mov [contador_execucao], eax

    ; Abrir arquivo de resultados em modo append
    lea rdi, [rel nome_resultado]
    lea rsi, [rel modo_append]
    call fopen
    mov [rbp-16], rax

    ; Escrever resultados no arquivo
    mov rdi, [rbp-16]
    lea rsi, [rel formato_arquivo]
    mov edx, [contador_execucao]
    movsd xmm0, [a_temp]
    movsd xmm1, [b_temp]
    mov al, 2
    call fprintf

    ; Fechar arquivo de resultados
    mov rdi, [rbp-16]
    call fclose

    ; Finalizar programa
    mov rsp, rbp
    pop rbp
    xor eax, eax
    ret