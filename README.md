EN | [PT-BR](#PT-BR)

# Verilog CPU (Quartus)

Educational Verilog CPU project with basic arithmetic instructions, internal memory (16 registers x 16 bits), 7-segment output, and LCD interface.

## Overview

This project implements a finite-state machine (FSM) that:

- receives an 18-bit instruction through `data[17:0]`;
- decodes opcode and instruction fields;
- accesses registers in a single-port RAM;
- executes ALU operations;
- writes results back to destination register;
- shows status/results on LCD and 7-segment displays.

Target tool: Intel Quartus Prime Lite 21.1.1  
Target FPGA: Cyclone IV E (`EP4CE115F29C7`)  
Top-level: `cpu`

## Main Modules

- `cpu.v`: top controller (FSM), instruction decoding, RAM read/write control, and peripheral integration.
- `ula.v`: 16-bit ALU (add, subtract, multiply) with sign bit in `saida[15]`.
- `single_port_ram.v`: 16-word x 16-bit memory (4-bit address space).
- `decodificador7seg.v`: converts result to digits for 4 seven-segment displays and sign output.
- `display_lcd.v`: LCD driver (init, messages, result display).
- `binary_to_bcd.v`: binary-to-BCD conversion (Double Dabble), used by LCD logic.

## Instruction Format (18 bits)

From MSB to LSB:

- `data[17:15]`: opcode
- `data[14:11]`: destination register (or target register for `DISPLAY`/`CLEAR`)

Per-instruction fields:

- `LOAD`: `data[10]` = sign, `data[9:3]` = immediate (magnitude)
- `ADD` and `SUB`: `data[10:7]` = register A, `data[6:3]` = register B
- `ADDI`, `SUBI`, `MUL`: `data[10:7]` = register A, `data[6]` = immediate sign, `data[5:0]` = immediate (magnitude)
- `DISPLAY` and `CLEAR`: mainly use `data[14:11]`

### Opcode Table

- `000`: LOAD
- `001`: ADD
- `010`: ADDI
- `011`: SUB
- `100`: SUBI
- `101`: MUL
- `110`: CLEAR
- `111`: DISPLAY

## Inputs and Outputs

Inputs:

- `clk`
- `botao_ligar`
- `botao_ler`
- `data[17:0]`

Outputs:

- `resultado[15:0]`
- `ligado`, `leu`, `sinal`
- `unidade[6:0]`, `dezena[6:0]`, `centena[6:0]`, `milhar[6:0]`
- LCD: `EN`, `RW`, `RS`, `LCD_ON`, `data_lcd[7:0]`

Note: pin mapping is defined in `cpu.qsf`.

## Build Steps (Quartus)

1. Open Quartus Prime Lite.
2. Open project `cpu.qpf`.
3. In the Project Navigator, confirm the selected revision is `cpu` (Project Navigator > Revisions).
4. Run `Processing > Start Compilation`.
5. Program FPGA with output files from `output_files/`.

## Basic Usage Flow

1. Power on the system (`botao_ligar`).
2. Set instruction on `data[17:0]`.
3. Trigger `botao_ler` to latch/execute instruction.
4. Check:
- `resultado[15:0]` for raw value.
- 7-segment displays for decimal value.
- LCD for opcode/register/value.
5. Repeat for next instructions.

## Project Structure

- Verilog sources: project root (`*.v`)
- Quartus project: `cpu.qpf`, `cpu.qsf`, `cpu.qws`
- Vector simulation files: `Waveform.vwf`, `Waveform1.vwf`, `Waveform2.vwf`, `Waveform3.vwf`, `Waveform4.vwf`, `Waveform5.vwf`
- Build artifacts: `db/`, `incremental_db/`, `output_files/`, `simulation/`

## Notes

- The design uses extra wait states to synchronize RAM reads before ALU operations.
- In multiple blocks, the MSB of 16-bit values is treated as sign.
- `.bak` files are backup versions of some modules.

---

# PT-BR

[EN](#Verilog-CPU-Quartus) | PT-BR

# CPU em Verilog (Quartus)

Projeto de uma CPU didática em Verilog com suporte a instrucoes aritmeticas basicas, memoria interna (16 registradores de 16 bits), exibicao em 7 segmentos e interface LCD.

## Visao Geral

Este projeto implementa uma maquina de estados finitos (FSM) que:

- recebe uma instrucao de 18 bits via barramento `data[17:0]`;
- decodifica opcode e campos da instrucao;
- acessa registradores em uma RAM single-port;
- executa operacoes na ULA;
- grava resultado no registrador de destino;
- exibe estado/resultado em LCD e display de 7 segmentos.

Ferramenta alvo: Intel Quartus Prime Lite 21.1.1  
FPGA alvo: Cyclone IV E (`EP4CE115F29C7`)  
Top-level: `cpu`

## Modulos Principais

- `cpu.v`: controle principal (FSM), decodificacao de instrucao, controle de leitura/escrita da RAM e integracao com perifericos.
- `ula.v`: ULA de 16 bits (soma, subtracao, multiplicacao) com bit de sinal em `saida[15]`.
- `single_port_ram.v`: memoria de 16 palavras x 16 bits (enderecos de 4 bits).
- `decodificador7seg.v`: converte resultado em digitos para 4 displays de 7 segmentos e sinal de negativo.
- `display_lcd.v`: driver para LCD (inicializacao, mensagens e exibicao de resultado).
- `binary_to_bcd.v`: conversao binario para BCD (Double Dabble), usada no LCD.

## Formato da Instrucao (18 bits)

Bits mais significativos para menos significativos:

- `data[17:15]`: opcode
- `data[14:11]`: registrador destino (ou registrador alvo em `DISPLAY`/`CLEAR`)

Campos por instrucao:

- `LOAD`: `data[10]` = sinal, `data[9:3]` = imediato (magnitude)
- `ADD` e `SUB`: `data[10:7]` = registrador A, `data[6:3]` = registrador B
- `ADDI`, `SUBI`, `MUL`: `data[10:7]` = registrador A, `data[6]` = sinal imediato, `data[5:0]` = imediato (magnitude)
- `DISPLAY` e `CLEAR`: usam principalmente `data[14:11]`

### Tabela de Opcodes

- `000`: LOAD
- `001`: ADD
- `010`: ADDI
- `011`: SUB
- `100`: SUBI
- `101`: MUL
- `110`: CLEAR
- `111`: DISPLAY

## Entradas e Saidas

Entradas:

- `clk`
- `botao_ligar`
- `botao_ler`
- `data[17:0]`

Saidas:

- `resultado[15:0]`
- `ligado`, `leu`, `sinal`
- `unidade[6:0]`, `dezena[6:0]`, `centena[6:0]`, `milhar[6:0]`
- LCD: `EN`, `RW`, `RS`, `LCD_ON`, `data_lcd[7:0]`

Obs.: o mapeamento de pinos esta em `cpu.qsf`.

## Como Compilar (Quartus)

1. Abra o Quartus Prime Lite.
2. Abra o projeto `cpu.qpf`.
3. No painel de projeto, confirme que a revisao selecionada e `cpu` (Project Navigator > Revisions).
4. Execute `Processing > Start Compilation`.
5. Programe a FPGA com o arquivo gerado em `output_files/`.

## Fluxo Basico de Uso

1. Ligue o sistema (`botao_ligar`).
2. Defina a instrucao em `data[17:0]`.
3. Acione `botao_ler` para capturar/executar a instrucao.
4. Consulte:
- `resultado[15:0]` para valor bruto.
- 7 segmentos para valor decimal.
- LCD para opcode/registrador/valor.
5. Repita para novas instrucoes.

## Estrutura do Projeto

- Fontes Verilog: raiz do projeto (`*.v`)
- Projeto Quartus: `cpu.qpf`, `cpu.qsf`, `cpu.qws`
- Simulacao vetorial: `Waveform.vwf`, `Waveform1.vwf`, `Waveform2.vwf`, `Waveform3.vwf`, `Waveform4.vwf`
- Artefatos de compilacao: `db/`, `incremental_db/`, `output_files/`, `simulation/`

## Observacoes

- O projeto usa estados de espera extras para sincronizar leituras da RAM antes de operar na ULA.
- O bit mais significativo de valores de 16 bits e tratado como sinal em varios blocos.
- Existem arquivos `.bak` com versoes de seguranca de alguns modulos.
