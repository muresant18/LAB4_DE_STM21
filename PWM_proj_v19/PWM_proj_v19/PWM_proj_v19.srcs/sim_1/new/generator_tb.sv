`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: FH-JOANNEUM
// Engineer: Johanna Sumper, Timotei Muresan
// 
// Create Date: 12.11.2021 18:28:02
// Design Name: PWM Signal generator
// Module Name: generator_tb
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


module generator_tb();

    `define N_CYCLES_MODE 1'b1
    `define CONTINOUS_MODE 1'b0


    logic [15:0] i_duty = 16'h0004;
    logic [15:0] i_limit = 16'h7FFF;    // This Period correspond to the required Frequency
    logic i_mode = `CONTINOUS_MODE;    
    logic [7:0] i_n = 8'b101; 
    logic i_trig = 1'b0, i_clk= 1'b0, i_rst = 1'b0;         
    logic o_pwm;      
    
    logic [15:0] duty_counter = 16'b0;
    logic [15:0] period_lenght = 16'b0;
    logic [7:0] pulse_counter = 8'b0;
  
    always #5ns i_clk = ~i_clk;  

    pwm_module pwm_module_i( .i_duty (i_duty ),      
                             .i_limit(i_limit),      
                             .i_n    (i_n    ),      
                             .i_trig (i_trig ),      
                             .i_mode (i_mode ),      
                             .i_clk  (i_clk  ),      
                             .i_rst  (i_rst  ),      
                             .o_pwm  (o_pwm  ) );
                             
                    
    initial begin
    

        fork
        /* Using a Fork to start more threads in parallel.
           See  http://www.testbench.in/SV_26_FORK_JOIN.html
           All 5 threads, as well as the initial-begin will start simultaneously  (at the same simulation time).
           
           JOIN_NONE:
           The parent thread (the initial-begin) continues to execute concurrently (after 0 simulation time) 
           with all the threads started by the fork.
        */
        
                
            /********************* duty and period measurement   ***********************/ 
            THREAD_1: // counts the system-clock cycles while the o_pwm is aseerted
            begin
                forever begin
                    @(posedge i_clk)
                    if(o_pwm) begin
                        duty_counter <= duty_counter + 1;
                    end else begin
                        @(negedge i_clk)
                        duty_counter <= 16'b0;  
                    end     
                end
            end
            
            THREAD_2: // compares the number of counted system-clock cycles with the user-input value of the duty-clyle
            begin 
                forever begin
                    @(negedge o_pwm)
                    CHK_DUTY_CYCLE: assert (duty_counter == i_duty) 
                        else $warning("Duty Cylce does not match the i_duty value. i_duty = %d and duty_counter is %d.", i_duty, duty_counter);  
                end
            end       
            
            
            
            /*********************  period measurement  ***********************/  
            THREAD_3:  // measures the length of each period 
            begin    
                forever begin
                    // Start every time the o_pwm gets asserted (every period).
                    @(posedge o_pwm)  
                    while(period_lenght<=(i_limit ))begin
                        @(posedge i_clk)
                        period_lenght <= period_lenght + 1;
                        
                        if (period_lenght == (i_limit - 1) ) begin
                            period_lenght <= 16'b0;
                            
                            // We assume that at the end of each period, the PWM_O signal shall not be asserted.
                            // This assertion will fail if the duty cycle is 100%.
                            // Because of the divition of the value (see the line 180) the exact value of the i_limit 
                            // will not be reached. This is why we use here the tolerance 4.
                            if ((i_duty < (i_limit-4)) && (i_duty != 0)) begin
                                $display("End of one period. PMW_O = %b, period_lenght = %2d and i_limit-1 = %2d and i_duty = %2d", o_pwm, period_lenght, i_limit-1, i_duty);
                                CHK_PWM_PWM_AT_END_PERIOD: assert (!o_pwm) else $warning("PWM shall be deasserted, and is not."); 
                            end
                        end
                    end
                end
            end
            
            
            
            /*********************  PULSEs COUNTER  ***********************/ 
            THREAD_4: // counts the number of generated period (pwm pulses) while the module is runing in n-cycles mode
            begin
                forever begin
                    @(posedge o_pwm)
                    // Only count when in n-cycles mode
                    if (i_mode == `N_CYCLES_MODE) begin                    
                        pulse_counter <= pulse_counter + 1;     
                    end 
                end
            end
            
            THREAD_5:
            begin
                forever begin   
                
                    // This assertion will fain first time, at the beginning of N_CYCLES MODE
                    // because the number of counted pulses is still zero.
                    // This is why we have (pulse_counter !=0) in the condition for the assertion.
                    
                    @(posedge i_trig) 
                    if( (i_duty != 0)&&(i_mode == `N_CYCLES_MODE)&& (pulse_counter !=0)) begin      
                        $display("End of i_mode. pulse_counter = %2d and i_n = %2d", pulse_counter, i_n);
                        CHK_NUMBER_OF_PULSES: assert (pulse_counter == i_n) else $warning("Pulse_counter = %2d and not equal to i_n = %2d ", pulse_counter , i_n );      
                    end
                    
                    // reset the counter after the assertion
                    @(negedge i_trig)
                    if(pulse_counter != 0)
                        pulse_counter <= 8'b0;                   
                end
            end  
              
        join_none
        
        
        // trigger a reset
        #1ns;
        i_rst = 1'b1;
        #30ns;
        i_rst = 1'b0;
        #300ns;

        // ================ START TO TEST THE MODULE IN DIFFERENT MODES ==================
        
        // *** CONTINOUS MODE ***
        i_mode = `CONTINOUS_MODE;   // change the mode to continous  
        #1us;  
        i_duty = 16'h000F;
        #100ns;
        i_trig = 1'b1;
        #100ns;
        i_trig = 1'b0;
        #2ms;       
              
        
        // *** N_CYCLES MODE ***
        i_mode = `N_CYCLES_MODE;    // trigger <i_n> pwm periods
        #1us;
        
        for(shortint unsigned i=1; i<=4; i++) begin
            i_duty <= int'(i * (i_limit / 4));
            i_trig = 1'b1;
            #100ns;
            i_trig = 1'b0;

            #2ms;
        end
      
        #2us; 
        $finish;
    end  
endmodule
