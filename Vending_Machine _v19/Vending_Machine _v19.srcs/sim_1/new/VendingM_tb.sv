`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.11.2021 12:05:27
// Design Name: 
// Module Name: VendingM_tb
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


module VendingM_tb();


  logic i_coin                = 1'b0;
  logic [2:0] i_sel                 ;
  logic i_abort               = 1'b0;
  logic i_clk                 = 1'b0;
  logic i_rst                 = 1'b0;
  logic i_prod_dispensed_conf = 1'b0;
  logic i_coins_returned_conf = 1'b0;
  logic o_coin_retn                 ;
  logic [1:0] o_prod                ;
  logic o_disp                      ;



always #5ns i_clk = ~i_clk;




VendingM VendingM_i(
   .i_coin                (i_coin               ),
   .i_sel                 (i_sel                ),
   .i_abort               (i_abort              ),
   .i_clk                 (i_clk                ),
   .i_rst                 (i_rst                ),
   .i_prod_dispensed_conf (i_prod_dispensed_conf),
   .o_coin_retn           (o_coin_retn          ),
   .o_prod                (o_prod               ),
   .o_disp                (o_disp               )
    );




    initial begin
        // ======================== Do a reset at the beginning =================================================
        #3ns;
        i_rst <= 1'b1;
        #20ns;
        i_rst <= 1'b0;
        #30ns; 
        i_sel = `NO_SELECTION;
        #10ns;
    
        // ======================================================================================================
        // ================ Dispensing of  a soft drink =========================================================    
        assert (!o_disp) else $warning("The pulse signal to dispenser ist stuck at 1.");
        assert (o_prod == `NO_SELECTION_bin) else $warning("One product seems to be selected, even no user input was done yet.");
        
        // User selects a drink
        i_sel = `SOFT_DRINK;
        #30ns;   
        // The selected product shall be decoded corectly from 3-bit signal to a 2-bit signal
        assert (o_prod == `SOFT_DRINK_bin) else $warning("o_prod signal does not correspond to the selected drink.");
        
        
        // Take so many coins, until the price is reached
        // We assume  that the i_coin signal stays asserted for one clk_cycle pulse
        repeat(`SOFT_DRINK_price) begin
            i_coin <= 1'b1;  
            #10ns;    
            i_coin <= 1'b0;  
            #10ns;         
        end
        
        i_sel = `NO_SELECTION;
        #30ns
        
        @(posedge i_clk)
        @(posedge i_clk)
        
        // the output signal to the dispenser shall be now be asserted
        assert (o_disp) else $warning("The pulse signal to dispenser ist stuck at 0.");
        #50ns;
        
        // simulate a confirmation from the dispenser, that the product was dispensed
        i_prod_dispensed_conf <= 1'b1;     
        #10ns;
        i_prod_dispensed_conf <= 1'b0;      
        
        #100ns;
        
        
        
        
        // ======================================================================================================
        // ================ Dispensing of energy drink interrupted by the timeout =============================== 
        
        // User selects a drink
        i_sel = `ENERGY_DRINK;
        #30ns;  
        assert (o_prod == `ENERGY_DRINK_bin) else $warning("o_prod signal does not correspond to the selected drink");    
    
        //the user inserts the coins too slow 
        repeat(`ENERGY_DRINK_price - 1) begin
            i_coin <= 1'b1;  
            #10ns;    
            i_coin <= 1'b0;  
            #10ns;         
        end
        
        // wait longer than the timeout value
        #(((`TIMEOUT_MAX*10)+1)*1ns);
        
        // at this point, the vending machine returns the conis back to the user
        i_sel = `NO_SELECTION;
        #30ns
        
        // due to the return event, no product shall be selected
        assert (o_prod == `NO_SELECTION_bin) else $warning("o_prod signal wrong");
       
     
     
        // ======================================================================================================
        // ================ Dispensing of water interrupted by a user abort ===================================== 
        
        // User selects a drink
        i_sel = `SPARKLING_WATER;
        #30ns;  
        assert (o_prod == `SPARKLING_WATER_bin) else $warning("o_prod signal does not correspond to the selected drink");      
       
        // the user pres the ABORT button
        i_abort <= 1'b1;
        #10ns; 
        i_abort <= 1'b0;
        #10ns; 
        
        #10ns;
        i_sel = `NO_SELECTION;
        
        #100ns;
        assert (o_prod == `NO_SELECTION_bin) else $warning("o_prod signal does not correspond to the selected drink"); 
                
        #50ns;
        $finish;
    
    end

endmodule
