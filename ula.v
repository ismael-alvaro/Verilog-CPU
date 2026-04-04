module ula(
    input [15:0] entrada_A, entrada_B,
    input [1:0] seletor,
    output reg [15:0] saida
);

    reg [14:0] saida_temp;
	 
	 parameter SOMA = 0, SUBTRAIR = 1, MULTIPLICAR = 2;
	 
    always @(*) begin
        case (seletor)
            SOMA: begin
                if (entrada_A[15] == 0 && entrada_B[15] == 0) saida = entrada_A + entrada_B;
                else if (entrada_A[15] == 1 && entrada_B[15] == 1) begin
                    saida_temp = entrada_A[14:0] + entrada_B[14:0];
                    saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b1, saida_temp[14:0]};
                end
                else if (entrada_A[15] == 0 && entrada_B[15] == 1) begin
                    if (entrada_A[14:0] > entrada_B[14:0]) begin
                        saida_temp = entrada_A[14:0] - entrada_B[14:0];
                        saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b0, saida_temp[14:0]};
                    end
                    else if (entrada_A[14:0] < entrada_B[14:0])begin
                        saida_temp = entrada_B[14:0] - entrada_A[14:0];
                        saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b1, saida_temp[14:0]};
                    end
                    else if (entrada_A[14:0] == entrada_B[14:0]) saida = 0;
                end
                else if (entrada_A[15] == 1 && entrada_B[15] == 0) begin
                    if (entrada_A[14:0] > entrada_B[14:0]) begin
                        saida_temp = entrada_A[14:0] - entrada_B[14:0];
                        saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b1, saida_temp[14:0]};
                    end
                    else if (entrada_A[14:0] < entrada_B[14:0]) begin
                        saida_temp = entrada_B[14:0] - entrada_A[14:0];
                        saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b0, saida_temp[14:0]};
                    end
                    else if (entrada_A[14:0] == entrada_B[14:0]) saida = 0;
                end
            end

            SUBTRAIR: begin
                if (entrada_A[15] == 0 && entrada_B[15] == 0) begin
                    if (entrada_A[14:0] > entrada_B[14:0]) begin
                        saida_temp = entrada_A[14:0] - entrada_B[14:0];
                        saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b0, saida_temp[14:0]};
                    end
                    else if (entrada_A[14:0] < entrada_B[14:0])begin
                        saida_temp = entrada_B[14:0] - entrada_A[14:0];
                        saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b1, saida_temp[14:0]};
                    end
                    else if (entrada_A[14:0] == entrada_B[14:0]) saida = 0;
                end
                else if (entrada_A[15] == 0 && entrada_B[15] == 1) begin
                    saida_temp = entrada_A[14:0] + entrada_B[14:0];
                    saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b0, saida_temp[14:0]};
                end
                else if (entrada_A[15] == 1 && entrada_B[15] == 0) begin
                    saida_temp = entrada_A[14:0] + entrada_B[14:0];
                    saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b1, saida_temp[14:0]};
                end
                else if (entrada_A[15] == 1 && entrada_B[15] == 1) begin
                    if (entrada_A[14:0] > entrada_B[14:0]) begin
                        saida_temp = entrada_A[14:0] - entrada_B[14:0];
                        saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b1, saida_temp[14:0]};
                    end
                    else if (entrada_A[14:0] < entrada_B[14:0]) begin
                        saida_temp = entrada_B[14:0] - entrada_A[14:0];
                        saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b0, saida_temp[14:0]};
                    end
                    else if (entrada_A[14:0] == entrada_B[14:0]) saida = 0;
                end
            end

            MULTIPLICAR: begin
                if (entrada_A[15] == 0 && entrada_B[15] == 0) saida = entrada_A * entrada_B;
                else if (entrada_A[15] == 1 && entrada_B[15] == 0) begin
                    saida_temp = entrada_A[14:0] * entrada_B[14:0];
                    saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b1, saida_temp[14:0]};
                end
                else if (entrada_A[15] == 0 && entrada_B[15] == 1) begin
                    saida_temp = entrada_A[14:0] * entrada_B[14:0];
                    saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b1, saida_temp[14:0]};
                end
                else if (entrada_A[15] == 1 && entrada_B[15] == 1) begin
                    saida_temp = entrada_A[14:0] * entrada_B[14:0];
                    saida = (saida_temp == 0) ? {1'b0, saida_temp[14:0]} : {1'b0, saida_temp[14:0]};
                end
            end
        endcase                 
    end

endmodule