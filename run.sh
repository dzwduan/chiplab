#!/bin/bash

# 指定Vivado的路径
VivadoPath="/home/dzw/tools/Xilinx/Vivado/2019.2/bin/"

# 指定要运行的Tcl脚本文件路径
TclScript="run.tcl"

# 运行Vivado并创建Tcl脚本
# $VivadoPath/vivado -mode tcl -source $VivadoPath/$TclScript

# 运行Vivado并执行Tcl脚本，开启GUI
$VivadoPath/vivado cdp_ede_local/mycpu_env/soc_verify/soc_bram/run_vivado/project/loongson.xpr