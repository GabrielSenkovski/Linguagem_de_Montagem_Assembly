; Montagem: nasm -f elf64 ordenador_sem_funcao.asm -o ordenador.o
; Ligação:   ld ordenador.o -o ordenador
; Execução:  ./ordenador
;
; Pré-requisito: Crie um arquivo "dados.txt" com números de 0 a 99, um por linha.

section .data
    ; Nomes de arquivos e mensagens
    nome_entrada    db "dados.txt", 0
    nome_saida      db "ordenado.txt", 0
    msg_original    db "Vetor Original:", 0xA, 0
    msg_ordenado    db 0xA, "Vetor Ordenado:", 0xA, 0
    msg_estats      db 0xA, "Estatisticas:", 0xA, 0
    msg_comp        db "  - Comparacoes: ", 0
    msg_trocas      db "  - Trocas: ", 0
    espaco          db " ", 0
    newline         db 0xA, 0

section .bss
    vetor           resd 30         ; Vetor para até 30 inteiros (4 bytes cada)
    contador        resd 1          ; Quantidade de elementos no vetor
    
    comparacoes     resd 1
    trocas          resd 1

    fd_leitura      resq 1
    fd_escrita      resq 1

    buffer_leitura  resb 4          ; Buffer para ler uma linha (ex: "99\n")
    buffer_escrita  resb 4          ; Buffer para converter inteiro para string

section .text
    global _start

_start:
    ; ======================================================
    ; PARTE 1: ABRIR E LER O ARQUIVO dados.txt
    ; ======================================================

    ; Abrir arquivo
    mov rax, 2                  ; syscall: open
    mov rdi, nome_entrada
    mov rsi, 0                  ; O_RDONLY
    syscall
    mov [fd_leitura], rax

    ; Loop de leitura do arquivo
    xor r12, r12                ; r12 = índice do vetor (inicia em 0)
leitura_loop:
    mov rax, 0                  ; syscall: read
    mov rdi, [fd_leitura]
    mov rsi, buffer_leitura
    mov rdx, 4
    syscall

    cmp rax, 0                  ; Se rax=0, fim do arquivo
    jle leitura_fim

    ; Converter ASCII para inteiro (0-99)
    xor r13, r13                ; r13 = Acumulador para o número
    mov r14, buffer_leitura     ; Ponteiro para o buffer
    
    movzx rax, byte [r14]       ; Primeiro dígito
    sub rax, '0'
    mov r13, rax
    inc r14

    movzx rax, byte [r14]       ; Verifica se há um segundo dígito
    cmp rax, 0xA                ; É um newline?
    je leitura_armazena         ; Se for, armazena número de 1 dígito

    imul r13, 10                ; Multiplica o primeiro dígito por 10
    movzx rax, byte [r14]
    sub rax, '0'
    add r13, rax                ; Soma o segundo dígito

leitura_armazena:
    mov [vetor + r12 * 4], r13d ; Armazena o inteiro de 32 bits
    inc r12

    cmp r12, 30
    jge leitura_fim
    jmp leitura_loop

leitura_fim:
    mov [contador], r12d        ; Salva a quantidade de números lidos
    mov rax, 3                  ; syscall: close
    mov rdi, [fd_leitura]
    syscall

    ; ======================================================
    ; PARTE 2: IMPRIMIR VETOR ORIGINAL NA TELA
    ; ======================================================
    
    ; Imprimir mensagem
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_original
    mov rdx, 17
    syscall

    ; Loop para imprimir o vetor
    xor r12, r12
print_original_loop:
    mov r13d, [contador]
    cmp r12d, r13d
    jge print_original_fim

    ; Lógica para converter int para string (para números 0-99)
    mov eax, [vetor + r12 * 4]
    mov r14, 10
    cmp eax, 10
    jge .dois_digitos_orig
    ; Um dígito
    add al, '0'
    mov [buffer_escrita], al
    mov r15, 1 ; tamanho da string
    jmp .escreve_na_tela_orig
.dois_digitos_orig:
    xor rdx, rdx
    div r14      ; rax = quociente, rdx = resto
    add rax, '0'
    add rdx, '0'
    mov [buffer_escrita], al
    mov [buffer_escrita+1], dl
    mov r15, 2 ; tamanho da string

.escreve_na_tela_orig:
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer_escrita
    mov rdx, r15
    syscall
    ; Imprime espaço
    mov rax, 1
    mov rdi, 1
    mov rsi, espaco
    mov rdx, 1
    syscall

    inc r12
    jmp print_original_loop

print_original_fim:
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall

    ; ======================================================
    ; PARTE 3: BUBBLE SORT (baseado no seu código)
    ; ======================================================
    mov ecx, [contador]         ; ecx = n
    dec ecx                     ; Laço externo vai de n-1 até 1
loop_externo:
    cmp ecx, 0
    jle sort_fim

    xor esi, esi                ; esi = i (índice do laço interno)
loop_interno:
    cmp esi, ecx
    jge interno_fim

    ; Comparação para 32 bits
    inc dword [comparacoes]
    mov eax, [vetor + esi * 4]
    mov ebx, [vetor + esi * 4 + 4]
    cmp eax, ebx
    jle sem_troca

    ; Troca para 32 bits
    inc dword [trocas]
    mov [vetor + esi * 4], ebx
    mov [vetor + esi * 4 + 4], eax

sem_troca:
    inc esi
    jmp loop_interno

interno_fim:
    dec ecx
    jmp loop_externo

sort_fim:

    ; ======================================================
    ; PARTE 4: IMPRIMIR VETOR ORDENADO E ESTATÍSTICAS
    ; ======================================================
    
    ; Imprimir mensagem
    mov rax, 1
    mov rdi, 1
    mov rsi, msg_ordenado
    mov rdx, 18
    syscall

    ; Loop para imprimir o vetor ordenado (lógica de conversão repetida)
    xor r12, r12
print_ordenado_loop:
    mov r13d, [contador]
    cmp r12d, r13d
    jge print_ordenado_fim

    ; Lógica para converter int para string
    mov eax, [vetor + r12 * 4]
    mov r14, 10
    cmp eax, 10
    jge .dois_digitos_ord
    add al, '0'
    mov [buffer_escrita], al
    mov r15, 1
    jmp .escreve_na_tela_ord
.dois_digitos_ord:
    xor rdx, rdx
    div r14
    add rax, '0'
    add rdx, '0'
    mov [buffer_escrita], al
    mov [buffer_escrita+1], dl
    mov r15, 2

.escreve_na_tela_ord:
    mov rax, 1
    mov rdi, 1
    mov rsi, buffer_escrita
    mov rdx, r15
    syscall
    mov rax, 1
    mov rdi, 1
    mov rsi, espaco
    mov rdx, 1
    syscall

    inc r12
    jmp print_ordenado_loop

print_ordenado_fim:
    ; (Imprime estatísticas)
    mov rax, 1; mov rdi, 1; mov rsi, msg_estats; mov rdx, 14; syscall
    mov rax, 1; mov rdi, 1; mov rsi, msg_comp; mov rdx, 17; syscall
    ; Imprime o número de comparações
    mov eax, [comparacoes]
    mov r14, 10
    cmp eax, 10
    jge .dois_digitos_comp
    add al, '0'
    mov [buffer_escrita], al
    mov r15, 1
    jmp .escreve_comp
.dois_digitos_comp:
    xor rdx, rdx; div r14; add rax, '0'; add rdx, '0'; mov [buffer_escrita], al; mov [buffer_escrita+1], dl; mov r15, 2
.escreve_comp:
    mov rax, 1; mov rdi, 1; mov rsi, buffer_escrita; mov rdx, r15; syscall
    mov rax, 1; mov rdi, 1; mov rsi, newline; mov rdx, 1; syscall

    mov rax, 1; mov rdi, 1; mov rsi, msg_trocas; mov rdx, 10; syscall
    ; Imprime o número de trocas
    mov eax, [trocas]
    mov r14, 10
    cmp eax, 10
    jge .dois_digitos_troca
    add al, '0'
    mov [buffer_escrita], al
    mov r15, 1
    jmp .escreve_troca
.dois_digitos_troca:
    xor rdx, rdx; div r14; add rax, '0'; add rdx, '0'; mov [buffer_escrita], al; mov [buffer_escrita+1], dl; mov r15, 2
.escreve_troca:
    mov rax, 1; mov rdi, 1; mov rsi, buffer_escrita; mov rdx, r15; syscall
    mov rax, 1; mov rdi, 1; mov rsi, newline; mov rdx, 1; syscall

    ; ======================================================
    ; PARTE 5: GRAVAR ARQUIVO ordenado.txt
    ; ======================================================
    ; Abrir/Criar arquivo para escrita
    mov rax, 2
    mov rdi, nome_saida
    mov rsi, 101o               ; O_WRONLY | O_CREAT
    mov rdx, 0644o              ; Permissões
    syscall
    mov [fd_escrita], rax

    xor r12, r12
gravacao_loop:
    mov r13d, [contador]
    cmp r12d, r13d
    jge gravacao_fim

    ; Lógica para converter int para string
    mov eax, [vetor + r12 * 4]
    mov r14, 10
    cmp eax, 10
    jge .dois_digitos_grav
    add al, '0'
    mov [buffer_escrita], al
    mov r15, 1
    jmp .escreve_no_arquivo
.dois_digitos_grav:
    xor rdx, rdx
    div r14
    add rax, '0'
    add rdx, '0'
    mov [buffer_escrita], al
    mov [buffer_escrita+1], dl
    mov r15, 2

.escreve_no_arquivo:
    mov rax, 1
    mov rdi, [fd_escrita]
    mov rsi, buffer_escrita
    mov rdx, r15
    syscall
    mov rax, 1
    mov rdi, [fd_escrita]
    mov rsi, newline
    mov rdx, 1
    syscall

    inc r12
    jmp gravacao_loop

gravacao_fim:
    mov rax, 3
    mov rdi, [fd_escrita]
    syscall

    ; ======================================================
    ; PARTE 6: FINALIZAR
    ; ======================================================
fim_programa:
    mov rax, 60
    xor rdi, rdi
    syscall
