O objetivo é encontrar os coeficientes a e b para a equação da reta y = ax + b. As fórmulas implementadas no código são:

Coeficiente a (inclinação):

a= 
∑x 
2
 −n⋅( 
x
ˉ
 ) 
2
 
∑xy−n⋅ 
x
ˉ
 ⋅ 
y
ˉ
​
 
​
 
Coeficiente b (intercepto):

b= 
y
ˉ
​
 −a⋅ 
x
ˉ
 
Legenda:
n: Número total de pontos (x, y).

Σxy: Soma dos produtos de cada par (x, y) (soma_xy).

Σx²: Soma do quadrado de cada valor x (soma_x2).

x̄: Média dos valores de x (soma_x / n).

ȳ: Média dos valores de y (soma_y / n).

Implementação em Assembly
A implementação no código Assembly segue a ordem das fórmulas, dividindo o cálculo em etapas lógicas.

1. Cálculo das Médias (x̄ e ȳ)
Antes de calcular os coeficientes, o programa primeiro calcula as médias de x e y, que são usadas em ambas as fórmulas.

Snippet de código

; Carrega 'n' (número de pontos) e converte para double em xmm0.
cvtsi2sd xmm0, [n_pontos]
; Carrega Σx em xmm1.
movsd xmm1, [soma_x]
; Calcula a média de x (x̄ = Σx / n). Resultado fica em xmm1.
divsd xmm1, xmm0
; Carrega Σy em xmm2.
movsd xmm2, [soma_y]
; Calcula a média de y (ȳ = Σy / n). Resultado fica em xmm2.
divsd xmm2, xmm0
2. Cálculo do Coeficiente 'a'
O cálculo é dividido em três partes: numerador, denominador e a divisão final.

2a. Numerador: (Σxy - n * x̄ * ȳ)
Snippet de código

; Carrega Σxy para o registrador do numerador (xmm3).
movsd xmm3, [soma_xy]
; Inicia o cálculo de (n * x̄ * ȳ) carregando n (de xmm0).
movsd xmm4, xmm0
; Multiplica por x̄ (de xmm1), resultado em xmm4: n * x̄.
mulsd xmm4, xmm1
; Multiplica por ȳ (de xmm2), resultado em xmm4: n * x̄ * ȳ.
mulsd xmm4, xmm2
; Finaliza o numerador: Σxy - (n * x̄ * ȳ). O resultado fica em xmm3.
subsd xmm3, xmm4
2b. Denominador: (Σx² - n * (x̄)²)
Snippet de código

; Carrega Σx² para o registrador do denominador (xmm5).
movsd xmm5, [soma_x2]
; Inicia o cálculo de (n * (x̄)²) carregando x̄ (de xmm1).
movsd xmm6, xmm1
; Eleva ao quadrado: x̄ * x̄ = (x̄)².
mulsd xmm6, xmm1
; Multiplica por n (de xmm0), resultado em xmm6: n * (x̄)².
mulsd xmm6, xmm0
; Finaliza o denominador: Σx² - (n * (x̄)²). O resultado fica em xmm5.
subsd xmm5, xmm6
2c. Divisão Final
Snippet de código

; a = Numerador (xmm3) / Denominador (xmm5). O resultado fica em xmm3.
divsd xmm3, xmm5
; Salva o resultado de 'a' na memória.
movsd [a_temp], xmm3
3. Cálculo do Coeficiente 'b'
Com o valor de a já calculado, o coeficiente b é encontrado com a fórmula b = ȳ - a * x̄.

Snippet de código

; Carrega o valor de 'a' (de xmm3) para iniciar o cálculo em xmm8.
movsd xmm8, xmm3
; Calcula a * x̄ (usando x̄ de xmm1).
mulsd xmm8, xmm1
; Carrega ȳ (de xmm2) para xmm9.
movsd xmm9, xmm2
; Finaliza o cálculo: ȳ - (a * x̄). O resultado fica em xmm9.
subsd xmm9, xmm8
; Salva o resultado de 'b' na memória.
movsd [b_temp], xmm9
