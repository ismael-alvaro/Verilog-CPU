module decodificador7seg(
    input [15:0] numero,
    output reg [6:0] unidade,
    output reg [6:0] dezena,
    output reg [6:0] centena,
    output reg [6:0] milhar,
    output reg sinal
);
    reg [3:0] digito_unidade, digito_dezena, digito_centena, digito_milhar;
    reg [14:0] valor_absoluto;
    
    // Calcula o valor absoluto para tratar números negativos corretamente
    always @(*) begin
             valor_absoluto = numero[14:0];
        // Separa os dígitos em BCD (Divisão por 10)
        digito_unidade = valor_absoluto % 10;
        digito_dezena = (valor_absoluto / 10) % 10;
        digito_centena = (valor_absoluto / 100) % 10;
        digito_milhar = (valor_absoluto / 1000) % 10;
        
        // Define o sinal (1 para negativo, 0 para positivo)
        sinal = numero[15];
    end
    
    // Função para converter BCD para 7 segmentos (lógica ativa baixa)
    function [6:0] bcd_to_7seg;
        input [3:0] bcd;
        case (bcd)
            4'd0: bcd_to_7seg = 7'b1000000; // 0
            4'd1: bcd_to_7seg = 7'b1111001; // 1
            4'd2: bcd_to_7seg = 7'b0100100; // 2
            4'd3: bcd_to_7seg = 7'b0110000; // 3
            4'd4: bcd_to_7seg = 7'b0011001; // 4
            4'd5: bcd_to_7seg = 7'b0010010; // 5
            4'd6: bcd_to_7seg = 7'b0000010; // 6
            4'd7: bcd_to_7seg = 7'b1111000; // 7
            4'd8: bcd_to_7seg = 7'b0000000; // 8
            4'd9: bcd_to_7seg = 7'b0010000; // 9
            default: bcd_to_7seg = 7'b1111111; // Todos os segmentos desligados
        endcase
    endfunction
    
    // Converte cada dígito para saída de 7 segmentos
    always @(*) begin
        unidade = bcd_to_7seg(digito_unidade);
        dezena = bcd_to_7seg(digito_centena);
        centena = bcd_to_7seg(digito_dezena);
        milhar = bcd_to_7seg(digito_milhar);
    end
    
endmodule