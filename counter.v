`timescale 1ns / 1ps


module wrapper (
    input clk,
    input [7:0]sw,
    output [3:0]seg_an,
    output [7:0]seg_cat
    );
    
wire [1:0]S1;                           //display select wires
wire clk_sig_1;                         //1Hz clock signal wire
wire clk_sig_2;                         //1kHz clock signal wire
wire [3:0]muxI0;                        //mux inputs
wire [3:0]muxI1;
wire [3:0]muxI2;
wire [3:0]muxI3;
wire [3:0]muxOut;                       //mux output


counter_1hz counter_1 (
                    .clk_in(clk),           //clk input
                    .clk_out(clk_sig_1)     //output 1Hz
                    );
                    
counter_1khz counter_1k (
    .clk_in(clk),
    .clk_out(clk_sig_2)                      //output 1kHz
    );
    
counter2bit counter_2bit(
    .clk_in(clk_sig_2),                      //1kHz input
    .S(S1)                                   //2 bit select signal
    );

decoder2_4 decoder0 (
    .S(S1),                                  //2 bit select signal
    .Y(seg_an)                              //output to 7 seg anodes
    );
    
mux4_1 mux1 (
    .I0(muxI0),                             //inputs
    .I1(muxI1),
    .I2(muxI2),
    .I3(muxI3),
    .S(S1),                                 //select
    .Y(muxOut)                              //output
    );
    
seg_decoder seg_decoder (
    .I(muxOut),                             //input
    .Y(seg_cat)                            //output
    );

BCD counter0 (
             .clk_in(clk_sig_1),            //1Hz input
             .ld(sw[0]),                    //load or run
             .ld_val(sw[7:4]),              //values to load in
             .S(sw[2:1]),                   //select witch display to load
             .Y0(muxI0),                    //segment outputs
             .Y1(muxI1),
             .Y2(muxI2),
             .Y3(muxI3)
             );

endmodule 

//decoder will select witch 7 segment annode is acctive
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

assign Y = tmp;                     //assign the temp register to the output

endmodule 

//4-bit 4:1 mux
module mux4_1 (
    input [3:0]I0,                          //inputs
    input [3:0]I1,
    input [3:0]I2,
    input [3:0]I3,
    input [1:0]S,                           //select
    output [3:0]Y                           //output
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

//2-bit counter
module counter2bit (
    input clk_in,                           //clk input
    output [1:0]S                           //output
    );

reg [1:0]counter = 2'b0;

always @ (posedge clk_in)
    counter <= counter + 1;                 //add one each clk cycle

assign S = counter;
endmodule 

//7 segment decoder
module seg_decoder (
    input [3:0]I,                           //input
    output [7:0]Y                           //output
    );

reg [7:0] cat = 8'b0;                       //cat represents 7 segment cathode

always @ (I) begin
    case (I)
        4'b0001: cat <= 8'b11111001;        //1 (only 0-9 is needed here)
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
    input clk_in,           //input clk
    input ld,               //load == 0: load values, load == 1: run counter
    input [1:0]S,           //select inputs
    input [3:0]ld_val,      //values to load in
    output [3:0]Y0,         //outputs
    output [3:0]Y1,
    output [3:0]Y2,
    output [3:0]Y3
    );
       
reg [3:0] counter0 = 4'b0;
reg [3:0] counter1 = 4'b0;
reg [3:0] counter2 = 4'b0;
reg [3:0] counter3 = 4'b0;

always @ (posedge clk_in) begin
    if (ld == 0) begin              //load in new values
        if (S == 2'b00)
            counter0 <= ld_val;
        else if (S== 2'b01)
            counter1 <= ld_val;
        else if (S == 2'b10)
            counter2 <= ld_val;
        else
            counter3 <= ld_val;
    end
    else begin                                          //run counter
        counter0 <= counter0 + 1;                       //incriment lowest digit
        if (counter0 == 4'b1001) begin                  //at 9 incriment next digit, rst lower digit
            counter0 <= 4'b0;
            counter1 <= counter1 + 1;
            
            if (counter1 == 4'b1001) begin              //repeat above
                counter1 <= 4'b0;
                counter2 <= counter2 + 1;
                
                if (counter2 == 4'b1001) begin
                    counter2 <= 4'b0;
                    counter3 <= counter3 + 1;
                    
                    if (counter3 == 4'b1001)
                        counter3 <= 4'b0;
                end
            end
        end
    end
end

assign Y0 = counter0;
assign Y1 = counter1;
assign Y2 = counter2;
assign Y3 = counter3;

endmodule 

//100MHz to 1kHz clock divider
module counter_1khz(
    input clk_in,                                       //input clk
    output clk_out                                      //output clk
    );

reg tmp = 1'b0;                                         //register will flip to create 1kHz clk
reg [26:0]counter = 27'd0;                              //counter counts to 100,000 (100MHz / 1KHz)

always @ (posedge clk_in) begin
    if (counter == 27'd99999) begin                     //max value reached, flip tmp and rst counter
        counter <= 16'd0;
        tmp <= ~tmp;
    end
    else if (counter == 27'd49999) begin                //50% duty cycle => flip tmp at half max value
        counter <= counter + 1;
        tmp <= ~tmp;
    end
    else
        counter <= counter + 1;                         //counter ++
end

assign clk_out = tmp;
endmodule

//100MHz to 1Hz clock divider
module counter_1hz(
    input clk_in,                                       //input clk
    output clk_out                                      //output clk
    );

reg tmp = 1'b0;                                         //flip to create clk_out
reg [26:0]counter = 27'd0;                              

always @ (posedge clk_in) begin
        if (counter == 27'd99999999) begin              //at max value rst counter and flip tmp
            counter <= 16'd0;                           //max value 100,000,000 = 100MHz/1Hz
            tmp <= ~tmp;
        end
        else if (counter == 27'd49999999) begin         //50% duty cycle => flip tmp at half max value
            counter <= counter + 1;
            tmp <= ~tmp;
        end
        else
            counter <= counter + 1;                     //incriment every clk cycle
end

assign clk_out = tmp;
endmodule
