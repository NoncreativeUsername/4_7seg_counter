`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Gunnar Pederson
// 
// Create Date: 06/07/2021 12:33:12 PM
// Design Name: 
// Module Name: counter
// Project Name: 
// Target Devices: Zync 7000 family
// Tool Versions: Vivado 2020.2
// Description: completing parts 3-5 https://realdigital.org/doc/0bfaffd4efce9695a5aeec5595ae1949
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module wrapper (
    input clk,
    output [3:0]seg_an,
    output [7:0]seg_cat
    );
    
wire [1:0]S;                            //select wires
wire clk_sig_1;                         //1Hz clock signal wire
wire clk_sig_2;                         //1kHz clock signal wire
wire [3:0]an_wire;                      //anode select wire
wire [7:0]cat_wire;                     //cathode select wire
wire [3:0]muxI0;
wire [3:0]muxI1;
wire [3:0]muxI2;
wire [3:0]muxI3;
wire [3:0]muxOut;
wire [2:0]next;                         //clock from one digit to the next


counter_1hz counter_1 (
                    .clk_in(clk),
                    .clk_out(clk_sig_1)     //output 1Hz
                    );
                    
counter_1khz counter_1k (
    .clk_in(clk),
    .clk_out(clk_sig_2)                      //output 1kHz
    );
    
counter2bit counter_2bit(
    .clk_in(clk_sig_2),                     //1kHz input
    .S(S)                                   //2 bit select signal
    );
    
decoder2_4 decoder (
    .S(S),                                  //2 bit select signal
    .Y(an_wire)                              //output to 7 seg anodes
    );
    
mux4_1 mux (
    .I0(muxI0),
    .I1(muxI1),
    .I2(muxI2),
    .I3(muxI3),
    .S(S),
    .Y(muxOut)
    );
    
seg_decoder seg_decoder (
    .I(muxOut),
    .Y(cat_wire)
    );

BCD counter0 (
             .clk_in(clk_sig_1),
             .Y(muxI0),
             .clk_out(next[0])
             );
             
BCD counter1 (
             .clk_in(next[0]),
             .Y(muxI1),
             .clk_out(next[1])
             );
             
BCD counter2 (
             .clk_in(next[1]),
             .Y(muxI2),
             .clk_out(next[2])
             );
             
BCD counter3 (
             .clk_in(next[2]),
             .Y(muxI3)
             );
             
assign seg_an = an_wire;
assign seg_cat = cat_wire;

endmodule 


module decoder2_4 (
    input [1:0]S,                   //select input
    output [3:0]Y                   //output
    );

reg [3:0]tmp;
always @ (S) begin
    case (S)
        2'b01: tmp <= 4'b1101;
        2'b10: tmp <= 4'b1011;
        2'b11: tmp <= 4'b0111;
        default: tmp <= 4'b1110;
    endcase
end

assign Y = tmp;

endmodule 

module mux4_1 (
    input [3:0]I0,
    input [3:0]I1,
    input [3:0]I2,
    input [3:0]I3,
    input [1:0]S,
    output [3:0]Y
    );
    
reg [7:0]tmp = 8'b0;
    
always @ (S) begin
    case (S)
        2'b01: tmp <= I1;
        2'b10: tmp <= I2;
        2'b11: tmp <= I3;
        default: tmp <= I0;
    endcase
end

assign Y = tmp;

endmodule 

module counter2bit (
    input clk_in,
    output [1:0]S
    );

reg [1:0]counter = 2'b0;

always @ (posedge clk_in)
    counter <= counter + 1;

assign S = counter;
endmodule 

module seg_decoder (
    input [3:0]I,
    output [7:0]Y);

reg [7:0] cat = 8'b0;

always @ (I) begin
    case (I)
        4'b0001: cat <= 8'b11111001;        //1
        4'b0010: cat <= 8'b10100100;        //2
        4'b0011: cat <= 8'b10110000;        //3
        4'b0100: cat <= 8'b10011001;        //4
        4'b0101: cat <= 8'b10010010;        //5
        4'b0110: cat <= 8'b10000010;        //6
        4'b0111: cat <= 8'b11111000;        //7
        4'b1000: cat <= 8'b10000000;        //8
        4'b1001: cat <= 8'b10011000;        //9
        default: cat <= 8'b11000000;        //0
    endcase
end

assign Y = cat;
endmodule

module BCD (
    input clk_in,
    output [3:0]Y,
    output clk_out
    );
       
reg [3:0] counter = 4'b0;
reg out = 1'b0;

always @ (posedge clk_in) begin
    if (counter == 4'b1001) begin
        counter <= 4'b0;
        out <= 1;
    end
    else begin
        counter <= counter + 1;
        out <= 0;
    end
        
end

assign Y = counter;
assign clk_out = out;

endmodule 

module counter_1khz(
    input clk_in,
    output clk_out
    );

reg tmp = 1'b0;
reg [26:0]counter = 27'd0;

always @ (posedge clk_in) begin                        //create 1kHz counter based clock
    if (counter == 27'd99999) begin
        counter <= 16'd0;
        tmp <= ~tmp;
    end
    else if (counter == 27'd49999) begin
        counter <= counter + 1;
        tmp <= ~tmp;
    end
    else
        counter <= counter + 1;
end

assign clk_out = tmp;
endmodule

module counter_1hz(
    input clk_in,
    output clk_out
    );

reg tmp = 1'b0;
reg [26:0]counter = 27'd0;

always @ (posedge clk_in) begin                        //create 1Hz counter based clock
    if (counter == 27'd99999999) begin
        counter <= 16'd0;
        tmp <= ~tmp;
    end
    else if (counter == 27'd49999999) begin
        counter <= counter + 1;
        tmp <= ~tmp;
    end
    else
        counter <= counter + 1;
end

assign clk_out = tmp;
endmodule