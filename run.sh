#!/bin/bash

# 指定Vivado的路径
VivadoPath="/home/dzw/tools/Xilinx/Vivado/2019.2/bin/"

# 指定要运行的Tcl脚本文件路径
TclScript="run.tcl"

# 运行Vivado并执行Tcl脚本
$VivadoPath/vivado -mode tcl -source $VivadoPath/$TclScript
