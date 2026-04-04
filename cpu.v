module cpu (
    input [17:0] data,
    input botao_ler, botao_ligar, clk,
    output reg [15:0] resultado, 
    output reg ligado, leu, sinal,
    output reg EN, RW, RS, LCD_ON,
    output reg [7:0] data_lcd, 
    output reg[6:0] unidade, centena, dezena, milhar
);

// Registrador para travar a instrução atual
reg [17:0] instruction_latch;

reg [15:0] data_prov;
reg [3:0] add_reg, reg_atual;
reg we, reset;
wire [15:0] out, saida;
reg [5:0] estado_atual; // Increased to 6 bits to accommodate more states
reg[15:0] reg_prov1, reg_prov2;
reg [15:0] entrada_A, entrada_B;
reg [1:0] seletor;
reg[2:0] funcao_atual;
wire [7:0] data_lcd_fio;
wire EN_prov, RW_prov, RS_prov, LCD_ON_prov;

initial begin 
    ligado = 0;
    leu = 0;
    estado_atual = 0;                               
    reg_prov1 = 0;
    reg_prov2 = 0;
    entrada_A = 0;
    entrada_B = 0;
    seletor = 0;
    funcao_atual = 0;
    reg_atual = 0;
    instruction_latch = 0;
end

wire [6:0] unidade1, centena1, dezena1, milhar1;
wire sinal1;
decodificador7seg A3(resultado, unidade1, centena1, dezena1, milhar1, sinal1);
single_port_ram A0(data_prov, add_reg, we, clk, reset, out);
ula A1(entrada_A, entrada_B, seletor, saida);
display_lcd A2(ligado, clk, leu, funcao_atual, reg_atual, resultado, EN_prov, RW_prov, RS_prov, LCD_ON_prov, data_lcd_fio);

parameter DESLIGADO = 0, 
          ESPERAR_LIGAR = 1, 
          ESPERAR_WRITE = 2, 
          LER = 3, 
          LER_INSTRUCAO = 4, 
          LOAD = 5, 
          ADD1 = 6, ADD1_WAIT = 26, ADD1_WAIT2 = 33, ADD2 = 7, ADD2_WAIT = 27, ADD2_WAIT2 = 34, ADD3 = 8, ADD3_WAIT = 24,
          ADDI1 = 9, ADDI1_WAIT = 28, ADDI1_WAIT2 = 35, ADDI2 = 10, ADDI3 = 11, 
          SUB1 = 12, SUB1_WAIT = 29, SUB1_WAIT2 = 36, SUB2 = 13, SUB2_WAIT = 30, SUB2_WAIT2 = 37, SUB3 = 14, SUB3_WAIT = 25,
          SUBI1 = 15, SUBI1_WAIT = 31, SUBI1_WAIT2 = 38, SUBI2 = 16, SUBI3 = 17, 
          MUL1 = 18, MUL1_WAIT = 32, MUL1_WAIT2 = 39, MUL2 = 19, MUL3 = 20, 
          CLEAR = 21, 
          DISPLAY = 22, 
          ESPERAR_DESLIGAR = 23;

always@(posedge clk) begin
    case(estado_atual) 
        DESLIGADO: begin
            ligado <= 0;
            leu <= 0;
            resultado <= 0;
            instruction_latch <= 0; // Limpa o latch de instrução
            if(botao_ligar) estado_atual <= DESLIGADO;
            else if(!botao_ligar) estado_atual <= ESPERAR_LIGAR; 
        end
        
        ESPERAR_LIGAR: begin
            if(!botao_ligar) estado_atual <= ESPERAR_LIGAR;
            else if(botao_ligar) estado_atual <= ESPERAR_WRITE;
        end
        
        ESPERAR_WRITE: begin
            ligado <= 1;
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) estado_atual <= ESPERAR_WRITE;
            else if(!botao_ler) estado_atual <= LER;
        end
        
        LER: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(!botao_ler) estado_atual <= LER;
            else if(botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        LER_INSTRUCAO: begin
            leu <= 0;
            resultado <= 0;
            reg_prov1 <= 0;
            reg_prov2 <= 0;
            entrada_A <= 0;
            entrada_B <= 0;
            instruction_latch <= data; // Armazena a instrução atual
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
            else if(botao_ler) begin
                case(data[17:15]) // Usa data aqui porque é o momento da captura
                    3'b000: estado_atual <= LOAD;
                    3'b001: estado_atual <= ADD1;
                    3'b010: estado_atual <= ADDI1;
                    3'b011: estado_atual <= SUB1;
                    3'b100: estado_atual <= SUBI1;
                    3'b101: estado_atual <= MUL1;
                    3'b110: estado_atual <= CLEAR;
                    3'b111: estado_atual <= DISPLAY;
                endcase
            end
        end
        
        LOAD: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                resultado <= {instruction_latch[10], 8'b00000000, instruction_latch[9:3]};
                estado_atual <= LOAD;
                leu <= 1;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end
        
        CLEAR: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= CLEAR;
                leu <= 1;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end
        
        DISPLAY: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= DISPLAY;
                resultado <= out;
                leu <= 1;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end

        // Estados ADD com estados de espera adicionados e corrigidos
        ADD1: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= ADD1_WAIT;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        ADD1_WAIT: begin  // Primeiro estado de espera
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= ADD1_WAIT2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end
        
        ADD1_WAIT2: begin  // Segundo estado de espera para garantir que out tenha o valor correto
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                reg_prov1 <= out;  // Agora captura o valor após dois ciclos de espera
                estado_atual <= ADD2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end

        ADD2: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= ADD2_WAIT;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        ADD2_WAIT: begin  // Primeiro estado de espera
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= ADD2_WAIT2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end
        
        ADD2_WAIT2: begin  // Segundo estado de espera para garantir que out tenha o valor correto
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                reg_prov2 <= out;  // Agora captura o valor após dois ciclos de espera
                estado_atual <= ADD3;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end

        ADD3: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                // Configura operandos para ALU
                entrada_A <= reg_prov1;
                entrada_B <= reg_prov2;
                seletor <= 0; // SOMA
                estado_atual <= ADD3_WAIT;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        ADD3_WAIT: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                leu <= 1;
                // Captura o resultado da ALU
                resultado <= saida;
                estado_atual <= ADD3_WAIT;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        // Estados ADDI com estados de espera adicionados e corrigidos
        ADDI1: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= ADDI1_WAIT;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        ADDI1_WAIT: begin  // Primeiro estado de espera
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= ADDI1_WAIT2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end
        
        ADDI1_WAIT2: begin  // Segundo estado de espera para garantir que out tenha o valor correto
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                reg_prov1 <= out;  // Agora captura o valor após dois ciclos de espera
                estado_atual <= ADDI2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end

        ADDI2: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                // Configura operandos para ALU
                entrada_A <= reg_prov1;
                entrada_B <= {instruction_latch[6], 9'b000000000, instruction_latch[5:0]}; // Usa valor travado
                seletor <= 0; // SOMA
                estado_atual <= ADDI3;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end

        ADDI3: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                leu <= 1;
                resultado <= saida;
                estado_atual <= ADDI3;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        // Estados SUB com estados de espera adicionados e corrigidos
        SUB1: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= SUB1_WAIT;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        SUB1_WAIT: begin  // Primeiro estado de espera
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= SUB1_WAIT2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end
        
        SUB1_WAIT2: begin  // Segundo estado de espera para garantir que out tenha o valor correto
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                reg_prov1 <= out;  // Agora captura o valor após dois ciclos de espera
                estado_atual <= SUB2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end

        SUB2: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= SUB2_WAIT;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        SUB2_WAIT: begin  // Primeiro estado de espera
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= SUB2_WAIT2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end
        
        SUB2_WAIT2: begin  // Segundo estado de espera para garantir que out tenha o valor correto
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                reg_prov2 <= out;  // Agora captura o valor após dois ciclos de espera
                estado_atual <= SUB3;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end

        SUB3: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                // Configura operandos para ALU
                entrada_A <= reg_prov1;
                entrada_B <= reg_prov2;
                seletor <= 1; // SUBTRAIR
                estado_atual <= SUB3_WAIT;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        SUB3_WAIT: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                leu <= 1;
                // Captura o resultado da ALU
                resultado <= saida;
                estado_atual <= SUB3_WAIT;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        // Estados SUBI com estados de espera adicionados e corrigidos
        SUBI1: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= SUBI1_WAIT;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        SUBI1_WAIT: begin  // Primeiro estado de espera
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= SUBI1_WAIT2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end
        
        SUBI1_WAIT2: begin  // Segundo estado de espera para garantir que out tenha o valor correto
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                reg_prov1 <= out;  // Agora captura o valor após dois ciclos de espera
                estado_atual <= SUBI2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end

        SUBI2: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                // Configura operandos para ALU
                entrada_A <= reg_prov1;
                entrada_B <= {instruction_latch[6], 9'b000000000, instruction_latch[5:0]};  // Usa valor travado
                seletor <= 1; // SUBTRAIR
                estado_atual <= SUBI3;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end

        SUBI3: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                leu <= 1;
                resultado <= saida;
                estado_atual <= SUBI3;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        // Estados MUL com estados de espera adicionados e corrigidos
        MUL1: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= MUL1_WAIT;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
        
        MUL1_WAIT: begin  // Primeiro estado de espera
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                estado_atual <= MUL1_WAIT2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end
        
        MUL1_WAIT2: begin  // Segundo estado de espera para garantir que out tenha o valor correto
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                reg_prov1 <= out;  // Agora captura o valor após dois ciclos de espera
                estado_atual <= MUL2;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO;
        end

        MUL2: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                // Configura operandos para ALU
                entrada_A <= reg_prov1;
                entrada_B <= {instruction_latch[6], 9'b000000000, instruction_latch[5:0]};  // Usa valor travado
                seletor <= 2; // MULTIPLICAR
                estado_atual <= MUL3;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end

        MUL3: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ler) begin
                leu <= 1;
                resultado <= saida;
                estado_atual <= MUL3;
            end
            else if(!botao_ler) estado_atual <= LER_INSTRUCAO; 
        end
  
        ESPERAR_DESLIGAR: begin
            if(!botao_ligar) estado_atual <= ESPERAR_DESLIGAR;
            else if(botao_ligar) estado_atual <= DESLIGADO;
        end
    endcase
    reg_atual <= instruction_latch[14:11]; // Usa valores travados
    funcao_atual <= instruction_latch[17:15]; // Usa valores travados
    unidade <= unidade1; centena <= centena1; dezena <= dezena1; milhar <= milhar1; sinal <= sinal1;
end


always@(*) begin
    EN = EN_prov;
    RW = RW_prov; 
    RS = RS_prov; 
    LCD_ON = LCD_ON_prov;
    data_lcd = data_lcd_fio;
    case(estado_atual)
        DESLIGADO: begin data_prov = 0; add_reg = instruction_latch[14:11]; we = 0; reset = 1; end 
        ESPERAR_LIGAR: begin data_prov = 0; add_reg = 0; we = 0; reset = 0; end
        ESPERAR_WRITE: begin data_prov = 0; add_reg = 0; we = 0; reset = 0; end
        LER: begin data_prov = 0; add_reg = 0; we = 0; reset = 0; end
        LER_INSTRUCAO: begin data_prov = 0; add_reg = 0; we = 0; reset = 0; end
        LOAD: begin data_prov = {instruction_latch[10], 8'b00000000, instruction_latch[9:3]}; add_reg = instruction_latch[14:11]; we = 1; reset = 0; end
        CLEAR: begin data_prov = 0; add_reg = instruction_latch[14:11]; we = 0; reset = 1; end 
        DISPLAY: begin data_prov = 0; add_reg = instruction_latch[14:11]; we = 0; reset = 0; end 

        // Estados para ADD com estados de espera adicionais
        ADD1: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        ADD1_WAIT: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        ADD1_WAIT2: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        ADD2: begin data_prov = 0; add_reg = instruction_latch[6:3]; we = 0; reset = 0; end
        ADD2_WAIT: begin data_prov = 0; add_reg = instruction_latch[6:3]; we = 0; reset = 0; end
        ADD2_WAIT2: begin data_prov = 0; add_reg = instruction_latch[6:3]; we = 0; reset = 0; end
        ADD3: begin data_prov = 0; add_reg = 0; we = 0; reset = 0; end
        ADD3_WAIT: begin data_prov = saida; add_reg = instruction_latch[14:11]; we = 1; reset = 0; end
        
        // Estados para ADDI com estados de espera adicionais
        ADDI1: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end 
        ADDI1_WAIT: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        ADDI1_WAIT2: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        ADDI2: begin data_prov = 0; add_reg = 0; we = 0; reset = 0; end
        ADDI3: begin data_prov = saida; add_reg = instruction_latch[14:11]; we = 1; reset = 0; end

        // Estados para SUB com estados de espera adicionais
        SUB1: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        SUB1_WAIT: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        SUB1_WAIT2: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        SUB2: begin data_prov = 0; add_reg = instruction_latch[6:3]; we = 0; reset = 0; end
        SUB2_WAIT: begin data_prov = 0; add_reg = instruction_latch[6:3]; we = 0; reset = 0; end
        SUB2_WAIT2: begin data_prov = 0; add_reg = instruction_latch[6:3]; we = 0; reset = 0; end
        SUB3: begin data_prov = 0; add_reg = 0; we = 0; reset = 0; end
        SUB3_WAIT: begin data_prov = saida; add_reg = instruction_latch[14:11]; we = 1; reset = 0; end
        
        // Estados para SUBI com estados de espera adicionais
        SUBI1: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        SUBI1_WAIT: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        SUBI1_WAIT2: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        SUBI2: begin data_prov = 0; add_reg = 0; we = 0; reset = 0; end
        SUBI3: begin data_prov = saida; add_reg = instruction_latch[14:11]; we = 1; reset = 0; end 
        
        // Estados para MUL com estados de espera adicionais
        MUL1: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        MUL1_WAIT: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        MUL1_WAIT2: begin data_prov = 0; add_reg = instruction_latch[10:7]; we = 0; reset = 0; end
        MUL2: begin data_prov = 0; add_reg = 0; we = 0; reset = 0; end
        MUL3: begin data_prov = saida; add_reg = instruction_latch[14:11]; we = 1; reset = 0; end
        
        default: begin data_prov = 0; add_reg = 0; we = 0; reset = 0; end
    endcase
end

endmodule