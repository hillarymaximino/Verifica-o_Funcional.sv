localparam logic [3:0] TECLA_CONFIRMA = 4'hA; 
localparam logic [3:0] TECLA_CLEAR    = 4'hB;
localparam logic [3:0] POS_VAZIA      = 4'hF;
localparam logic [3:0] COD_TIMEOUT    = 4'hE;

localparam logic [19:0][3:0] VETOR_VAZIO = {20{4'hF}};

localparam int CICLOS_APERTO   = 150;
localparam int CICLOS_SOLTO    = 100;
localparam int CICLOS_MANTIDA  = 2500;
localparam int LIMITE_VALID    = 300;
localparam int LIMITE_TIMEOUT  = 5500;

int mon_n_pulsos = 0;
int mon_largura_atual = 0;
int mon_ultima_largura = 0;
logic [19:0][3:0] mon_ultimo_valor = {20{4'hF}};

int n_checagens = 0;
int n_erros     = 0;

task aplicar_reset(input int ciclos = 3); // 3 é o parâmetro 
  @(negedge clk); // Observe a borda de descida do clk
  rst = 1'b1; // Nessa borda o reset será 1 (ou seja, ativado)
  repeat (ciclos) // Isso se repete por 3 ciclos (3 pulsos de clk)
        
  @(negedge clk); // Após esses 3 ciclos de clk, observe novamente a próxima descida do clk
  rst = 1'b0; // Nessa descida desative o reset
  @(negedge clk); // Leve mais um pulso de descida do clk para finalizar a task
endtask

task esperar_ciclos(input int n); // Recebe um inteiro n como parâmetro
  repeat (n) // repete n vezes (Varia de acordo com qual valor for esse "n" 
  @(negedge clk); // Na descida do clk acaba a task
endtask

task digitar_tecla(input logic [3:0] tecla); // Recebe um logic de 4 bits
  pressionar_tecla(tecla); // LUMA QUE IMPLEMENTOU DE OUTRA FORMA (CORRIGIR !!!!!)
  esperar_ciclos(CICLOS_APERTO); // Chama a função e utiliza 150 ciclos como parâmetro de segurança de pressionamento
  soltar_tecla(); // LUMA QUE IMPLEMENTOU DE OUTRA FORMA (CORRIGIR !!!!!)
  esperar_ciclos(CICLOS_SOLTO); // Espera 100 ciclos para finalizar a task
  // Logo a tecla precisa de 150 ciclos pressionada e mais 100 ciclos para soltar
endtask

task aguardar_valid(input int pulsos_antes, input int limite, output bit ok); // Recebe um valor inteiro que representa a qnt de pulsos antes, um inteiro para ser o limite de tempo e um sinal de bit 1 ou 0
  int n; // Declara um inteiro n
  n  = 0; // Esse n inicia em 0
  ok = 1'b0; // O sinal/bit inicia em 0
    while (n < limite && mon_n_pulsos == pulsos_antes) begin // Enquanto (repetição) esse valor de n for menor que o limite (parâmetro) e mon_n_pulsos (EXPLICAR ESSA VARIAVEL) for igual a quantidade de pulsos antes (parâmetro)
      @(negedge clk); // Na borda de descida do clk
      n++; // Esse valor "n" vai sendo incrementado
    end // Isso acontece enquanto n for menor que o limite e o mon_n_pulsos for igual a qnt de pulsos antes, se uma delas for falsa, sai o while
  ok = (mon_n_pulsos != pulsos_antes); // Quando sair do while ele vai verificar se o mon_n_pulsos é um valor diferente de pulsos antes, se isso for verdade esse ok vai emitir um sinal 1
  esperar_ciclos(4); // Espera 4 ciclos de descida do clk para finalizar a task
endtask

task checar(input bit condicao, input string msg); // Recebe um bit que indica 1 ou 0 para uma condição, e uma mensagem
  n_checagens++; // Incrementa o contador responsável por calcular a quantidade de checagens de condições
    if (condicao) begin // Se a condição for verdadeira (Se o bit que eu recebi foi 1)
      $display("[%0t] OK   : %s", $time, msg); // Eu vou transmitir um OK seguido da mensagem 
    end
    else begin  // Se a condição foi falsa (Se o bit que eu recebi foi o)
      n_erros++; // Incrementa o contador responsável por calcular a quantidade de erros
      $display("[%0t] ERRO : %s", $time, msg); // Eu vou transmitir um ERRO seguido da mensagem
    end
endtask

task checar_vetor(input logic [19:0][3:0] esperado, input string msg); // Recebo um vetor (que é o esperado) e uma mensagem
  n_checagens++; // Incrementa o contador responsável por calcular a quantidade de checagens de condições
    if (mon_ultimo_valor === esperado) begin // Se o meu mon_ultimo_valor for igual a esse vetor que eu espero 
      $display("[%0t] OK   : %s (vetor = %h)", $time, msg, mon_ultimo_valor);  // Eu vou transmitir um OK seguido da mensagem e do mon_ultimo_valor 
    end
     else begin // Se meu mon_ultimo_valor não for igual ao vetor esperado
      n_erros++; // Incremento o contador de erro
      $display("[%0t] ERRO : %s", $time, msg); // Imprimo a mensagem de erro e a mensagem
      $display("           esperado = %h", esperado); // O valor que era esperado
      display("           obtido   = %h", mon_ultimo_valor); // E o ultimo valor
    end
endtask

task confirmar_e_checar(input logic [19:0][3:0] esperado, input string msg); // Recebe como parâmetro o vetor esperado e uma mensagem
        int antes; // Cria um inteiro 
        bit ok; // O bit de controle OK
        antes = mon_n_pulsos; // O valor antes = mon_n_pulsos
  pressionar_tecla(TECLA_CONFIRMA); // LUMA QUE IMPLEMENTOU DE OUTRA FORMA (CORRIGIR !!!!!)
  aguardar_valid(antes, LIMITE_VALID, ok); // Chama a função e coloca como parametro o valor de antes (=mon_n_pulsos), 300 ciclos e o bit OK
  soltar_tecla();// LUMA QUE IMPLEMENTOU DE OUTRA FORMA (CORRIGIR !!!!!)
  esperar_ciclos(CICLOS_SOLTO); //Chama a função e coloca 100 com parâmetro
  checar(ok, {msg, " - digitos_valid subiu apos CONFIRMA"}); //Chama a função, coloca o valor do bit OK, uma mensagem
  if (ok) checar_vetor(esperado, msg); // Se OK for 1, chama checar vetor, coloca o vetor esperado e a mensagem
    endtask
