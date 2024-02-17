`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/14/2024 02:52:02 PM
// Design Name: 
// Module Name: tb
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


module tb(
    );
    
    timeunit 100ps;
    timeprecision 10ps;
    specparam PERIOD = 1000000 / 100 / 2;
    
    reg [31:0] din, dout;
    reg [15:0] addr;
    reg rw;
    reg clk, rst;
    integer done_reset;
    
    cpu cpu0 (clk, rst, din, dout, addr, rw);
    memory mem0 (clk, addr[14:0], dout, din, rw);
    
    always @(posedge clk) begin
        if (done_reset == 0) begin
            rst = 0;
        end else
            done_reset -= 1;
    end
    
    initial begin 
        clk = 0;
        rst = 1;
        done_reset = 2;
        forever begin
            #PERIOD clk = ~clk;
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
        $readmemh("C:/Users/griff/OneDrive/Documents/Vivado_Projects/CPU_Testing/CPU_Testing.srcs/rom.mem", memory);
    end

    always @(posedge clk) begin
        if (~rw) memory[addr] <= din;
    end
    assign dout = memory[addr];

endmodule
