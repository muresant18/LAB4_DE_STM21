@echo off
REM ****************************************************************************
REM Vivado (TM) v2020.1 (64-bit)
REM
REM Filename    : simulate.bat
REM Simulator   : Xilinx Vivado Simulator
REM Description : Script for simulating the design by launching the simulator
REM
REM Generated by Vivado on Mon Nov 29 22:48:54 +0100 2021
REM SW Build 2902540 on Wed May 27 19:54:49 MDT 2020
REM
REM Copyright 1986-2020 Xilinx, Inc. All Rights Reserved.
REM
REM usage: simulate.bat
REM
REM ****************************************************************************
echo "xsim generator_tb_behav -key {Behavioral:sim_1:Functional:generator_tb} -tclbatch generator_tb.tcl -view C:/STM1/DE_c/Lab4/PWM_proj_v19/PWM_proj_v19/PWM_proj_v19.srcs/sim_1/imports/PWM_proj/generator_tb_behav.wcfg -log simulate.log"
call xsim  generator_tb_behav -key {Behavioral:sim_1:Functional:generator_tb} -tclbatch generator_tb.tcl -view C:/STM1/DE_c/Lab4/PWM_proj_v19/PWM_proj_v19/PWM_proj_v19.srcs/sim_1/imports/PWM_proj/generator_tb_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
