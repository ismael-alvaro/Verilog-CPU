module binary_to_bcd (
    input [14:0] binary,         // Número binário de 15 bits
    output reg [3:0] ones,       // Unidade (0-9)
    output reg [3:0] tens,       // Dezena (0-9)
    output reg [3:0] hundreds,   // Centena (0-9)
    output reg [3:0] thousands,  // Milhar (0-9)
    output reg [3:0] ten_thousands // Dezena de milhar (0-9)
);

    reg [34:0] shift_reg; // Registrador de 35 bits para o algoritmo Double Dabble
    integer i;
    
    always @(*) begin
        // Inicializa o registrador: 20 bits para os dígitos BCD e 15 bits para o número binário
        shift_reg = {20'd0, binary}; 
        
        // Algoritmo Double Dabble: 15 iterações para processar cada bit do número binário
        for (i = 0; i < 15; i = i + 1) begin
            // Se algum dos dígitos BCD for >= 5, soma 3
            if (shift_reg[34:31] >= 5) shift_reg[34:31] = shift_reg[34:31] + 3;
            if (shift_reg[30:27] >= 5) shift_reg[30:27] = shift_reg[30:27] + 3;
            if (shift_reg[26:23] >= 5) shift_reg[26:23] = shift_reg[26:23] + 3;
            if (shift_reg[22:19] >= 5) shift_reg[22:19] = shift_reg[22:19] + 3;
            if (shift_reg[18:15] >= 5) shift_reg[18:15] = shift_reg[18:15] + 3;
            
            // Desloca o registrador para a esquerda em 1 bit
            shift_reg = shift_reg << 1;
        end
        
        // Atribui os dígitos BCD às saídas
        ten_thousands = shift_reg[34:31];
        thousands     = shift_reg[30:27];
        hundreds      = shift_reg[26:23];
        tens          = shift_reg[22:19];
        ones          = shift_reg[18:15];
    end
endmodule