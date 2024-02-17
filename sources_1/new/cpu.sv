//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/14/2024 03:03:10 PM
// Design Name: 
// Module Name: cpu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adder (
    input wire a,
    input wire b,
    input wire cin,
    output wire cout,
    output wire sum
);

    wire axb;
    assign axb = a ^ b;
    assign sum = axb ^ cin;
    assign cout = (a & b) | (axb & cin);
endmodule 

module add8 (
    input wire [7:0] a,
    input wire [7:0] b,
    input wire cin,
    output wire cout,
    output wire [7:0] sum
);
    wire [6:0] cnext;

    adder a0 (a[0], b[0], cin, cnext[0], sum[0]);
    adder a1 (a[1], b[1], cnext[0], cnext[1], sum[1]);
    adder a2 (a[2], b[2], cnext[1], cnext[2], sum[2]);
    adder a3 (a[3], b[3], cnext[2], cnext[3], sum[3]);
    adder a4 (a[4], b[4], cnext[3], cnext[4], sum[4]);
    adder a5 (a[5], b[5], cnext[4], cnext[5], sum[5]);
    adder a6 (a[6], b[6], cnext[5], cnext[6], sum[6]);
    adder a7 (a[7], b[7], cnext[6], cout, sum[7]);
endmodule

module add16 (
    input wire [15:0] a,
    input wire [15:0] b,
    input wire cin,
    output wire cout,
    output wire [15:0] sum
);
    wire cnext;

    add8 a0 (a[7:0], b[7:0], cin, cnext, sum[7:0]);
    add8 a1 (a[15:8], b[15:8], cnext, cout, sum[15:8]);
endmodule

module add32 (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire cin,
    output wire cout,
    output wire [31:0] sum
);
    wire cnext;

    add16 a0 (a[15:0], b[15:0], cin, cnext, sum[15:0]);
    add16 a1 (a[31:16], b[31:16], cnext, cout, sum[31:16]);
endmodule

module alu (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [1:0] op,    // 0 for add, 1 for sub
    output wire [31:0] result,
    output wire zero,
    output wire cout
);
    wire [31:0] sum;
    wire [31:0] prod;
    (* use_dsp = "yes" *) assign prod = a * b;

    wire [31:0] b_new = op[0] ? ~b : b;
    add32 add (a, b_new, op[0], cout, sum);

    assign result = op[1] ? prod : sum;
    assign zero = (result == 0);

endmodule

module program_counter (
    input wire [15:0] in,
    input wire clk,
    input wire reset,
    output wire [15:0] out
);
    reg [15:0] pc;

    always @(posedge clk or posedge reset)
    begin
        if (reset)
            pc <= 0;
        else
            pc <= in;
    end

    assign out = pc;

endmodule

module cpu (
    input wire clk,
    input wire reset,
    input wire [31:0] din,
    output wire [31:0] dout,
    output wire [15:0] addr,
    output wire rw  // 0 - write, 1 - read
);
    reg pc_en;
    reg addr_sel;
    reg oe;
    reg [15:0] next_addr;
    wire [15:0] addr_inc;
    wire [15:0] addrout;
    reg [7:0] ir;   // Instruction register
    reg [15:0] ab;  // Address buffer
    reg [31:0] db;  // Data buffer
    reg [31:0] ar;  // A register
    reg [31:0] br;  // B register
    reg [7:0] sr;   // 0 - zero, 1 - carry
    reg [31:0] stack[0:255];   // Stack
    reg [7:0] sp;   // Stack pointer
    reg [7:0] sp_inc;
    reg [7:0] sp_dec;

    wire clk2;
    assign clk2 = ~clk;
    assign rw = ~oe;
    assign dout = oe ? db : 32'hzzzzzzzz;

    program_counter pc (next_addr, clk, reset, addrout);
    add16 addr_add (addrout, 1, 0, , addr_inc);
    add8 sp_add (sp, 8'd1, 0, , sp_inc);
    add8 sp_sub (sp, ~8'd1, 1, , sp_dec);
    
    reg [31:0] alu_a;
    reg [31:0] alu_b;
    reg [31:0] alu_r;
    wire alu_zero;
    wire alu_cout;
    alu alu0 (alu_a, alu_b, ir[1:0], alu_r, alu_zero, alu_cout);

    assign addr = addr_sel ? ab : addrout;

    // CPU state machine
    always @(posedge clk2 or posedge reset) begin
        if (reset) begin
            ir <= 0;
            ar <= 0;
            sr <= 0;
            pc_en <= 1;
            addr_sel <= 0;
            oe <= 0;
            sp <= 0;
        end else begin
            casez (ir)
                8'h00: begin    // NOP/load instruction
                    ir <= din;
                    addr_sel <= 0;
                    oe <= 0;
                    next_addr <= addr_inc;
                end
                8'b?000_0001: begin    // Load A (p1)
                    ar <= ir[7] ? ar : din;     // Load value if direct
                    sr[0] <= ir[7] ? 0 : ~|din; // Set zero flag if direct
                    ir <= ir[7] ? 8'hC1: 8'h00; // Go to second part if indirect
                    ab <= ir[7] ? din : ab;     // Load address if indirect
                    addr_sel <= ir[7];          // Enable address output if indirect
                    oe <= 0;
                    next_addr <= addr_inc;
                end
                8'b1100_0001: begin    // Load A (p2 if indirect)
                    ar <= din;          // Load value
                    sr[0] <= ~|din;     // Set zero flag
                    ir <= 8'h00;
                    addr_sel <= 0;      // Disable address output
                    oe <= 0;            // Disable address output
                    next_addr <= next_addr;
                end
                8'h03: begin    // Store A (p1)
                    ab <= din[15:0];
                    db <= ar;
                    ir <= 8'h02;
                    addr_sel <= 1;
                    oe <= 1;
                    next_addr <= addr_inc;
                end
                8'h02: begin    // Store A (p2)
                    ir <= 0;
                    addr_sel <= 0;
                    oe <= 0;
                    next_addr <= addrout;
                end
                8'b?00010??: begin  // ALU operation (p1)
                    ir <= ir[7] ? {6'b110010, ir[1:0]} : {6'h01, ir[1:0]};  // Set next instruction
                    alu_a <= ar;    
                    alu_b <= din;           // Will get changed next if indirect
                    ab <= ir[7] ? din : ab; // Load address if indirect
                    addr_sel <= ir[7];      // Enable address output if indirect
                    oe <= 0;
                    next_addr <= addr_inc;
                end
                8'b110010??: begin  // ALU operation (p2 if indirect)
                    ir <= {6'h01, ir[1:0]};
                    alu_b <= din;           // Load actual value
                    addr_sel <= 0;          // Disable address output
                    oe <= 0;                // Disable address output
                    next_addr <= addr_inc;  
                end
                8'b000001??: begin  // ALU operation (end)
                    ir <= 0;
                    sr <= {6'h00, alu_cout, alu_zero} | sr; // Set flags
                    ar <= alu_r;    // Load result
                    addr_sel <= 0;  
                    oe <= 0;
                    next_addr <= addrout;
                end
                8'h10: begin    // Jump
                    ir <= 0;
                    next_addr <= din[15:0];
                    addr_sel <= 0;
                    oe <= 0;
                end
                8'h13: begin    // Jump to subroutine (p1)
                    ir <= 8'h12;
                    next_addr <= din[15:0];
                    addr_sel <= 0;
                    oe <= 0;
                    stack[sp] <= addr_inc;
                end
                8'h12: begin    // Jump to subroutine (p2)
                    ir <= 0;
                    next_addr <= addrout;
                    addr_sel <= 0;
                    oe <= 0;
                    sp <= sp_inc;
                end
                8'h15: begin    // Return from subroutine (p1)
                    ir <= 8'h14;
                    addr_sel <= 0;
                    oe <= 0;
                    sp <= sp_dec;
                end
                8'h14: begin    // Return from subroutine (p2)
                    ir <= 0;
                    next_addr <= stack[sp];
                    addr_sel <= 0;
                    oe <= 0;
                end
                8'h16: begin    // Branch if zero
                    ir <= 0;
                    next_addr <= sr[0] ? din[15:0] : addr_inc;
                    addr_sel <= 0;
                    oe <= 0;
                end
                8'h17: begin    // Branch if not zero
                    ir <= 0;
                    next_addr <= sr[0] ? addr_inc : din[15:0];
                    addr_sel <= 0;
                    oe <= 0;
                end
                8'h19: begin    // Push A to stack (p1)
                    ir <= 8'h18;
                    addr_sel <= 0;
                    oe <= 0;
                    stack[sp] <= ar;
                end
                8'h18: begin    // Push A to stack (p2)
                    ir <= 0;
                    addr_sel <= 0;
                    oe <= 0;
                    sp <= sp_inc;
                end
                8'h1B: begin    // Pull A from stack (p1)
                    ir <= 8'h1A;
                    addr_sel <= 0;
                    oe <= 0;
                    sp <= sp_dec;
                end
                8'h1A: begin    // Pull A from stack (p2)
                    ir <= 0;
                    addr_sel <= 0;
                    oe <= 0;
                    ar <= stack[sp];
                end
                8'h1C: begin    // Branch if carry set
                    ir <= 0;
                    next_addr <= sr[1] ? din[15:0] : addr_inc;
                    addr_sel <= 0;
                    oe <= 0;
                end
                8'h1D: begin    // Branch if carry clear
                    ir <= 0;
                    next_addr <= sr[1] ? addr_inc : din[15:0];
                    addr_sel <= 0;
                    oe <= 0;
                end
                8'b?010_00??: begin // Logical operation (p1)
                    ir <= (ir[7] & ~(ir[1:0] == 2'b11)) ? {6'b111000, ir[1:0]} : 0;
                    ab <= ir[7] ? din : ab; // Load address if indirect
                    addr_sel <= ir[7];      // Enable address output if indirect
                    oe <= 0;
                    if(~ir[7]) begin        // Direct operation
                        case (ir[1:0])
                            2'b00:
                                ar <= din | ar;
                            2'b01:
                                ar <= din & ar;
                            2'b10:
                                ar <= din ^ ar;
                            2'b11:
                                ar <= ~ar; 
                            default: 
                                ar <= ar;
                        endcase
                    end
                    next_addr <= (ir[1:0] == 2'b11) ? next_addr : addr_inc; // NOT takes no data
                end
                8'b1110_00??: begin // Logical operation (p2 if indirect)
                    ir <= 0;
                    addr_sel <= 0;          // Disable address output
                    oe <= 0;
                    case (ir[1:0])
                        2'b00:
                            ar <= din | ar;
                        2'b01:
                            ar <= din & ar;
                        2'b10:
                            ar <= din ^ ar;
                        default:
                            ar <= ar;
                    endcase
                    next_addr <= next_addr;
                end
                8'h24: begin    // Shift A left
                    ir <= 0;
                    ar <= {ar[30:0], 1'b0};
                    addr_sel <= 0;
                    oe <= 0;
                    next_addr <= next_addr;
                end
                8'h25: begin    // Shift A right (arithmetic)
                    ir <= 0;
                    ar <= {ar[31], ar[31:1]};
                    addr_sel <= 0;
                    oe <= 0;
                    next_addr <= next_addr;
                end
                default: begin  // Unknown instruction
                    ir <= 0; 
                    addr_sel <= 0;
                    oe <= 0;
                    next_addr <= addr_inc;
                end
            endcase
        end
    end

endmodule

module memory (
    input wire clk,
    input wire [14:0] addr,
    input wire [31:0] din,
    output wire [31:0] dout,
    input wire rw
);
    (* ram_style = "distributed" *)reg [31:0] memory [0:32767];

    initial begin
        // Initialize 10 to 1
        memory[0] = 32'h0001;   // LDA
        memory[1] = 32'h0001;   // #h1
        memory[2] = 32'h0003;   // STA
        memory[3] = 32'h0010;   // h10

        // Shift left repeatedly
        memory[4] = 32'h0081;   // LDA (indirect)
        memory[5] = 32'h0010;   // h10
        memory[6] = 32'h0022;   // XOR
        memory[7] = 32'hAAAAAAAA;   // #hAAAAAAAA
        memory[8] = 32'h0003;   // STA
        memory[9] = 32'h0010;   // h10
        memory[10] = 32'h0010;  // JMP
        memory[11] = 32'h0004;  // h4
    end

    always @(posedge clk) begin
        if (~rw) memory[addr] <= din;
    end
    assign dout = memory[addr];

endmodule

