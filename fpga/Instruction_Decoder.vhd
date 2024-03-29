---------------------------------------------------------------------------------------------------
-- Title          : Instruction Decoder, Single-Issue, RISC-V subset RV32G                       --
-- Project        : Nebula RV32 Core                                                             --
-- Filename       : Instruction_Decoder.vhd                                                      --
-- Description    : Implements a RV32G-compatible single-issue instruction decoder.              --
--                                                                                               --
-- Main Author    : Elijah Creed Fedele                                                          --
-- Creation Date  : July 17, 2023 22:22                                                          --
-- Last Revision  : July 17, 2023 22:24                                                          --
-- Version        : N/A                                                                          --
-- License        : CERN-OHL-S-2.0 (CERN OHL, v2.0, Strongly Reciprocal)                         --
-- Copyright      : (C) 2023 Elijah Creed Fedele & Connor Clarke                                 --
--                                                                                               --
-- Library        : N/A                                                                          --
-- Dependencies   : IEEE (STD_LOGIC_1164, NUMERIC_STD)                                           --
-- Initialization : N/A                                                                          --
-- Notes          : Should be able to be simulated on any standards-compliant VHDL               --
--                  simulator, although written specifically for GHDL/GTKWave.                   --
---------------------------------------------------------------------------------------------------

library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;

---------------------------------------------------------------------------------------------------
-- Module:      Instruction_Decoder                                                              --
-- Description: Implements a synchronous RV32G-compatible instruction decoder. Takes a single    --
--              RV32G instruction and emits a bundle of signals used to indicate the operation   --
--              to be performed. Does not handle RVC (16-bit) instructions; this must be carried --
--              out using a RVC expander which converts compressed RV32 instructions to 32-bit   --
--              form prior to instruction decode.                                                --
--                                                                                               --
--              For detailed descriptions of the opcodes, instruction formats, and functions in  --
--              use, see https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf.       --
--                                                                                               --
-- Inputs:      instruction (32)    The instruction (32-bit) to be decoded                       --
--              clk         ( 1)    The pipeline clock                                           --
--              n_rst       ( 1)    Asynchronous active-LOW reset                                --
--              n_irdy      ( 1)    Instruction fetch (IF) is ready; decoder input is valid      --
--              n_stall     ( 1)    Pipeline stall input - asserted when multicycle executions   --
--                                  (i.e. DIV) have not yet completed. Prevents the stage input  --
--                                  from receiving new data and the stage output registers from  --
--                                  clearing.                                                    --
--                                                                                               --
-- Outputs:     n_bad_inst  ( 1)    Bad (illegal/undefined) instruction signal                   --
--              reg_d       ( 5)    Destination register address                                 --
--              reg_sa      ( 5)    First source operand register address                        --
--              reg_sb      ( 5)    Second source operand register address                       --
--              reg_conf    ( 3)    Bundle indicating register configuration (see notes below)   --
--              immed       (32)    Immediate output, extended to 32-bit                         --
--              alu_in      ( 1)    Indicates an integer arithmetic (ALU) instruction            --
--              fpu_in      ( 1)    Indicates a floating-point (FPU) instruction                 --
--              fpu_sd      ( 1)    Single/double-precision FPU mode switch - 0 single, 1 double --
---------------------------------------------------------------------------------------------------
entity Instruction_Decoder is 
    port(
        instruction            : in  STD_LOGIC_VECTOR(31 downto 0);
        clk, n_rst             : in  STD_LOGIC;
        n_irdy, n_stall        : in  STD_LOGIC;
        n_bad_inst             : out STD_LOGIC;
        reg_d                  : out STD_LOGIC_VECTOR( 4 downto 0);
        reg_sa, reg_sb, reg_sc : out STD_LOGIC_VECTOR( 4 downto 0);
        reg_conf               : out STD_LOGIC_VECTOR( 2 downto 0);
        immed                  : out STD_LOGIC_VECTOR(31 downto 0);
        alu_in, fpu_in, fpu_sd : out STD_LOGIC;
    );
end entity Instruction_Decoder;

architecture RTL of Instruction_Decoder is
    signal opcode : STD_LOGIC_VECTOR(6 downto 0) := instruction( 6 downto  0);
    signal funct3 : STD_LOGIC_VECTOR(2 downto 0) := instruction(14 downto 12);
    signal funct7 : STD_LOGIC_VECTOR(6 downto 0) := instruction(31 downto 25);
begin
    DECODE: process(clk, n_rst)
    begin
        if n_rst = '0' then
            -- Flush all gate/DFF states
        elsif rising_edge(clk) and n_irdy = '0' and n_stall = '1' then
            case opcode is
                -- RISC-V opcode LOAD
                -- Implements instructions LB, LH, LW, LBU, and LHU
                ---------------------------------------------------
                when "0000011" =>
                    case funct3 is
                        when "000"  => -- LB
                        when "001"  => -- LH
                        when "010"  => -- LW
                        when "100"  => -- LBU
                        when "101"  => -- LHU
                        when others => n_bad_inst <= '0';
                    end case;
                
                -- RISC-V opcode STORE
                -- Implements instructions SB, SH, and SW
                -----------------------------------------
                when "0100011" =>
                    case funct3 is
                        when "000"  => -- SB
                        when "001"  => -- SH
                        when "010"  => -- SW
                        when others => n_bad_inst <= '0';
                    end case;
                
                -- RISC-V opcode OP-IMM
                -- Implements instructions ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, and SRAI
                -----------------------------------------------------------------------------------
                when "0010011" =>
                    -- ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI

                    
                when "0110011" =>
                    case funct3 is
                        when "000"  =>
                            case funct7 is
                                when "0000000" => -- ADD
                                when "0100000" => -- SUB
                                when "0000001" => -- MUL
                                when others => n_bad_inst <= '0';
                            end case;
                        when "001"  =>
                            case funct7 is
                                when "0000000" => -- SLL
                                when "0000001" => -- MULH
                                when others => n_bad_inst <= '0';
                            end case;
                        when "010"  => -- SLT, MULHSU
                        when "011"  => -- SLTU, MULHU
                        when "100"  => -- XOR, DIV
                        when "101"  => -- SRL, SRA, DIVU
                        when "110"  => -- OR, REM
                        when "111"  => -- AND, REMU
                        when others => n_bad_inst <= '0';
                    end case;
                when others => n_bad_inst <= '0';
            end case;
        end if;
    end process DECODE;
end architecture RTL;