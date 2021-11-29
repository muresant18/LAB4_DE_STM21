`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: FH-JOANNEUM
// Engineer: Muresan Timotei, Sumper Johanna
// 
// Create Date: 21.11.2021 11:05:25
// Design Name: Vending Machine (State Machine)
// Module Name: VendingM
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


module VendingM(
    input i_coin,
    input [2:0] i_sel,
    input i_abort,
    input i_clk,
    input i_rst,
    input i_prod_dispensed_conf,        // das war nicht in der Angabe !!!! 
    output o_coin_retn,
    output [1:0] o_prod,
    output o_disp
    );
	
	// for the input selection (one-hot)
	`define ENERGY_DRINK    3'b100
	`define SOFT_DRINK      3'b010
	`define SPARKLING_WATER 3'b001
	`define NO_SELECTION    3'b000
	// for the output 
	`define ENERGY_DRINK_bin    2'b10
	`define SOFT_DRINK_bin      2'b01
	`define SPARKLING_WATER_bin 2'b00
	`define NO_SELECTION_bin    2'b11
	
    `define ENERGY_DRINK_price 3
	`define SOFT_DRINK_price 2
	`define SPARKLING_WATER_price 1
	
	// define the timeout value. 20x10ns = 200ns
	`define TIMEOUT_MAX 20 
	
	typedef enum logic [2:0] {
		IDLE,
		RETURN_COINS,
		WAIT_FOR_COINS,
		DISPENSE_PRODUCT
		} states_type;
		
	states_type actual_fsm_state = IDLE;
	states_type next_fsm_state = IDLE;

	logic [5:0] timeout_cnt = 5'b0;
	logic [2:0] coins_cnt = 3'b0;
	
	// signals to be connected to the outputs
    logic coin_retn;;      
    logic [1:0] prod;        
    logic disp;               	

	
	//convert the select signal from one-hot-coded 3-bits signal to a 2 bits-binary signal
    always_comb
    begin
        case (i_sel)
            `ENERGY_DRINK:    begin prod <= `ENERGY_DRINK_bin   ; end  
            `SOFT_DRINK:      begin prod <= `SOFT_DRINK_bin     ; end     
            `SPARKLING_WATER: begin prod <= `SPARKLING_WATER_bin; end
            `NO_SELECTION:    begin prod <= `NO_SELECTION_bin   ; end   
        endcase       
    end
    
	
    // Update the states
    always_ff @(posedge i_clk) begin
        if (i_rst)
            actual_fsm_state <= IDLE;
        else
            actual_fsm_state <= next_fsm_state;
    end
	
	// Change the states (combinational logic)
	always_comb
	begin
	   next_fsm_state <= actual_fsm_state;
	   case(actual_fsm_state)
	       IDLE: begin
	           if(i_sel != `NO_SELECTION)
	               next_fsm_state <= WAIT_FOR_COINS;
	       end
	       RETURN_COINS: begin
	           if(coins_cnt <= 0)
	               next_fsm_state <= IDLE;
	       end
	       WAIT_FOR_COINS: begin 
               next_fsm_state <= WAIT_FOR_COINS; 
               
               if(i_abort || ((timeout_cnt >= `TIMEOUT_MAX)))
                    next_fsm_state <= RETURN_COINS;
               
               else begin   
                   // Sub-States of the WAIT_FOR_COINS state
                   case(i_sel)
                        `ENERGY_DRINK: begin  
                            if (coins_cnt >= `ENERGY_DRINK_price)
                                next_fsm_state <= DISPENSE_PRODUCT;
                        end
                        `SOFT_DRINK: begin  
                            if (coins_cnt >= `SOFT_DRINK_price)
                                next_fsm_state <= DISPENSE_PRODUCT;                    
                        end     
                        `SPARKLING_WATER: begin  
                            if (coins_cnt >= `SPARKLING_WATER_price)
                                next_fsm_state <= DISPENSE_PRODUCT;                    
                        end  
                   endcase
	           end
	       end
	       DISPENSE_PRODUCT: begin 
	           if (i_prod_dispensed_conf)
	               next_fsm_state <= IDLE;
               else if(i_abort)
                    next_fsm_state <= RETURN_COINS;	               
	       end	   
	   endcase	
	end
	

	// Sequential logic for the Vending machine
	// Here happens things :)
    always_ff @(posedge i_clk) begin	
	   coin_retn <= 1'b0;
       disp <= 1'b0;

	   case(actual_fsm_state)
	       IDLE: begin
	          coins_cnt <= 3'b0;
	          disp <= 1'b0;
	       end
	       RETURN_COINS: begin
               coin_retn <= 1'b1; 
               if(coins_cnt > 0)
                   coins_cnt <= coins_cnt - 1;         
	       end
	       WAIT_FOR_COINS: begin 
	           if (timeout_cnt <= `TIMEOUT_MAX)
	               timeout_cnt = timeout_cnt + 1;
	           else    
	               timeout_cnt <= 5'b0;
	               
	               
               if(i_coin)
                   coins_cnt <= coins_cnt+1;
	       end
	       DISPENSE_PRODUCT: begin 
	           disp <= 1'b1;  
	           coins_cnt <= 3'b0; // give the drink, get the money :)
	       end	
	   endcase
    end // end of always_ff
    
    
    // connect the outpus to the internal signals
    assign o_coin_retn = coin_retn;
    assign o_prod      = prod     ;
    assign o_disp      = disp     ;   
    
endmodule
