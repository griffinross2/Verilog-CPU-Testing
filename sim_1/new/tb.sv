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
    
    reg [31:0] a;
    reg [31:0] b;
    reg cin;
    reg cout;
    reg [31:0] sum;
    
    reg clk;
    initial begin 
        a = 32'h20000000;
        b = 32'h00400000;
        cin = 1'b0;
        clk = 0;
        add32(a, b, cin, cout, sum);
        forever begin
            #PERIOD clk = ~clk;
        end 
    end
endmodule
