module display_lcd (
    input ligado, clk, leu,
    input [2:0] opcode,
    input [3:0] register,
    input [15:0] val,
    output reg EN, RW, RS, LCD_ON,
    output reg [7:0] data
);

// Parâmetros de tempo 
parameter MS = 50_000;      // Contagem para 1 ms (para um clock de 50 MHz) 
parameter PULSE = 25;       // Pulso de ENABLE: 25 ciclos de clock (~500 ns a 50MHz)

// Estados para a máquina de tempo 
parameter WRITE = 0, WAIT = 1;

// Estados do sistema
parameter INIT = 0, READY = 1, PROCESS = 2;

// Inicialização dos sinais de controle 
initial begin 
    EN = 0; RW = 0; RS = 0; LCD_ON = 0;
    data = 8'h00;
    instructions = 0;
    counter = 0;
    last_button = 0;
    system_on = 0;
    state = WRITE;
    sys_state = INIT;
end

reg [7:0] instructions = 0;
reg [31:0] counter = 0;
reg last_button = 0, system_on;
reg state = WRITE;
reg [1:0] sys_state = INIT;
reg prev_leu = 0;
reg zerar = 0;

wire [3:0] ones, tens, hundreds, thousands, ten_thousands;
binary_to_bcd A0(val[14:0], ones, tens, hundreds, thousands, ten_thousands);

// Definição dos opcodes 
parameter LOAD = 3'b000, ADD = 3'b001, ADDI = 3'b010, SUB = 3'b011, 
          SUBI = 3'b100, MUL = 3'b101, CLEAR = 3'b110, DISPLAY = 3'b111;

// Detector de mudança no botão ligado
reg prev_ligado = 0;
wire ligado_edge = (ligado != prev_ligado) && ligado;

// Detector de mudança no botão leu
wire leu_edge = (leu != prev_leu) && leu;

// Máquina de estado para o sistema
always @(posedge clk) begin
    prev_ligado <= ligado;
    prev_leu <= leu;
    
    case(sys_state)
        INIT: begin
            if(ligado_edge) begin
                // Ligar o sistema
                LCD_ON <= 1;
                zerar <= 1;
                sys_state <= READY;
            end
            else begin
                LCD_ON <= 0;
            end
        end
        
        READY: begin
            if(!ligado) begin
                // Desligar o sistema
                LCD_ON <= 0;
                sys_state <= INIT;
            end
            else if(leu_edge) begin
                // Processar nova instrução
                zerar <= 1;  // Reinicia o contador de instruções
                sys_state <= PROCESS;
            end
        end
        
        PROCESS: begin
            if(!ligado) begin
                // Desligar o sistema durante processamento
                LCD_ON <= 0;
                sys_state <= INIT;
            end
            else if(instructions >= 38) begin
                // Finalizar o processamento
                sys_state <= READY;
            end
            // O contador de instruções é incrementado na máquina de estados de tempo
        end
    endcase
end

// Máquina de estado para o tempo 
always @(posedge clk) begin
    case(state)
        WRITE: begin
            if(counter == MS - 1) begin
                counter <= 0;
                state <= WAIT;
            end
            else counter <= counter + 1;
        end
        
        WAIT: begin
            if(counter == MS - 1) begin
                counter <= 0;
                state <= WRITE;
                //if(sys_state == PROCESS && instructions < 40)
                    //instructions <= instructions + 1;
            end
            else counter <= counter + 1;
        end
    endcase
end

always @(posedge clk) begin
	if(counter == MS - 1 && sys_state == PROCESS && instructions < 40) instructions <= instructions + 1;
	if(zerar) begin instructions <= 0; end
	
end

// Máquina de estado para o sinal de ENABLE (EN)
always @(posedge clk) begin
    case(state)
        WRITE: EN <= (counter < PULSE) ? 1 : 0;
        WAIT:  EN <= 0;
        default: EN <= 0;
    endcase
    
    // Mantem RW em 0 para todas as operações (escrita)
    RW <= 0;
    
    if(sys_state == INIT) begin
        // Estado de inicialização - display desligado
        data <= 8'h00;
        RS <= 0;
    end
    else if(sys_state == READY) begin
        // Estado pronto - mostra mensagem inicial
        case(instructions)
            1: begin data <= 8'h38; RS <= 0; end // Function set: 2 lines, 5x8 dot matrix
            2: begin data <= 8'h0E; RS <= 0; end // Display on, cursor on
            3: begin data <= 8'h01; RS <= 0; end // Clear display
            4: begin data <= 8'h06; RS <= 0; end // Entry mode: increment, no shift
            5: begin data <= 8'h80; RS <= 0; end // Set DDRAM address to beginning of first line
            6: begin data <= 8'h52; RS <= 1; end // 'R'
            7: begin data <= 8'h45; RS <= 1; end // 'E'
            8: begin data <= 8'h41; RS <= 1; end // 'A'
            9: begin data <= 8'h44; RS <= 1; end // 'D'
            10: begin data <= 8'h59; RS <= 1; end // 'Y'
            default: begin data <= 8'h00; RS <= 0; end
        endcase
    end
    else if(sys_state == PROCESS) begin
        case(opcode)
            // Código para cada instrução - mantém o mesmo, apenas certifica que RS e data são definidos corretamente
            LOAD: begin
                case(instructions)
                    1:  begin data <= 8'h38; RS <= 0; end // seta duas linhas
                    2:  begin data <= 8'h0E; RS <= 0; end // ativa o cursor
                    3:  begin data <= 8'h01; RS <= 0; end // limpa o display
                    4:  begin data <= 8'h06; RS <= 0; end // modo de entrada
                    5:  begin data <= 8'h80; RS <= 0; end // primeira linha, início
                    6:  begin data <= 8'h4C; RS <= 1; end // 'L'
                    7:  begin data <= 8'h4F; RS <= 1; end // 'O'
                    8:  begin data <= 8'h41; RS <= 1; end // 'A'
                    9:  begin data <= 8'h44; RS <= 1; end // 'D'
                    10: begin data <= 8'h20; RS <= 1; end // ' ' (espaço)
                    11: begin data <= 8'h5B; RS <= 1; end // '['
                    12: begin data <= (register[3] == 0) ? 8'h30 : 8'h31; RS <= 1; end
                    13: begin data <= (register[2] == 0) ? 8'h30 : 8'h31; RS <= 1; end
                    14: begin data <= (register[1] == 0) ? 8'h30 : 8'h31; RS <= 1; end
                    15: begin data <= (register[0] == 0) ? 8'h30 : 8'h31; RS <= 1; end
                    16: begin data <= 8'h5D; RS <= 1; end // ']'
                    17: begin data <= 8'hC0; RS <= 0; end // 2ª linha
                    18: begin data <= (val[15] == 0) ? 8'h2B : 8'h2D; RS <= 1; end // '+'/'-'
                    19: begin
                          if (ten_thousands != 0) begin 
                              data <= 8'h30 + ten_thousands; RS <= 1; 
                          end else begin 
                              data <= 8'h20; RS <= 1; // espaço se for zero
                          end
                       end
                    20: begin
                          if (thousands != 0 || ten_thousands != 0) begin 
                              data <= 8'h30 + thousands; RS <= 1; 
                          end else begin 
                              data <= 8'h20; RS <= 1; // espaço se for zero
                          end
                       end
                    21: begin
                          if (hundreds != 0 || thousands != 0 || ten_thousands != 0) begin 
                              data <= 8'h30 + hundreds; RS <= 1; 
                          end else begin 
                              data <= 8'h20; RS <= 1; // espaço se for zero
                          end
                       end
                    22: begin
                          if (tens != 0 || hundreds != 0 || thousands != 0 || ten_thousands != 0) begin 
                              data <= 8'h30 + tens; RS <= 1; 
                          end else begin 
                              data <= 8'h20; RS <= 1; // espaço se for zero
                          end
                       end
                    23: begin data <= 8'h30 + ones; RS <= 1; end // Sempre mostrar unidades
                    default: begin data <= 8'h00; RS <= 0; end
                endcase
            end
            
            // Adicione os outros casos de forma similar, simplificando e corrigindo
            
            // Por exemplo, para ADD
            ADD: begin
                case(instructions)
                    1: begin data <= 8'h38; RS <= 0; end 
                    2: begin data <= 8'h0E; RS <= 0; end 
                    3: begin data <= 8'h01; RS <= 0; end 
                    4: begin data <= 8'h06; RS <= 0; end 
                    5: begin data <= 8'h80; RS <= 0; end 
                    6: begin data <= 8'h41; RS <= 1; end // 'A'
                    7: begin data <= 8'h44; RS <= 1; end // 'D'
                    8: begin data <= 8'h44; RS <= 1; end // 'D'
                    9: begin data <= 8'h20; RS <= 1; end // ' ' (espaço)
                    10: begin data <= 8'h5B; RS <= 1; end // '['
                    11: begin data <= (register[3] == 0) ? 8'h30 : 8'h31; RS <= 1; end
                    12: begin data <= (register[2] == 0) ? 8'h30 : 8'h31; RS <= 1; end
                    13: begin data <= (register[1] == 0) ? 8'h30 : 8'h31; RS <= 1; end
                    14: begin data <= (register[0] == 0) ? 8'h30 : 8'h31; RS <= 1; end
                    15: begin data <= 8'h5D; RS <= 1; end // ']'
                    16: begin data <= 8'hC0; RS <= 0; end // 2ª linha
                    17: begin data <= (val[15] == 0) ? 8'h2B : 8'h2D; RS <= 1; end // '+'/'-'
                    // Números simplificados para evitar código repetitivo
                    18: begin data <= (ten_thousands != 0) ? (8'h30 + ten_thousands) : 8'h20; RS <= 1; end
                    19: begin data <= ((thousands != 0) || (ten_thousands != 0)) ? (8'h30 + thousands) : 8'h20; RS <= 1; end
                    20: begin data <= ((hundreds != 0) || (thousands != 0) || (ten_thousands != 0)) ? (8'h30 + hundreds) : 8'h20; RS <= 1; end
                    21: begin data <= ((tens != 0) || (hundreds != 0) || (thousands != 0) || (ten_thousands != 0)) ? (8'h30 + tens) : 8'h20; RS <= 1; end
                    22: begin data <= 8'h30 + ones; RS <= 1; end // Sempre mostrar unidades
                    default: begin data <= 8'h00; RS <= 0; end
                endcase
            end
            
            // Continue com os outros opcodes...
            // Use a lógica simplificada para mostrar números
            
            default: begin
                // Instrução desconhecida
                case(instructions)
                    1: begin data <= 8'h38; RS <= 0; end
                    2: begin data <= 8'h0E; RS <= 0; end
                    3: begin data <= 8'h01; RS <= 0; end
                    4: begin data <= 8'h06; RS <= 0; end
                    5: begin data <= 8'h80; RS <= 0; end
                    6: begin data <= 8'h45; RS <= 1; end // 'E'
                    7: begin data <= 8'h52; RS <= 1; end // 'R'
                    8: begin data <= 8'h52; RS <= 1; end // 'R'
                    9: begin data <= 8'h4F; RS <= 1; end // 'O'
                    10: begin data <= 8'h52; RS <= 1; end // 'R'
                    default: begin data <= 8'h00; RS <= 0; end
                endcase
            end
        endcase
    end
end

endmodule