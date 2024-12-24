#!/bin/bash


# # 指定Vivado的路径
VivadoPath="/home/dzw/vivado2019/Vivado/2019.2/bin/"

# # 指定要运行的Tcl脚本文件路径
TclScript="/home/dzw/chiplab/cdp_ede_local/mycpu_env/soc_verify/soc_hs_bram/run_vivado/create_project.tcl"
# echo "VivadoPath: $VivadoPath"
# echo "TclScript: $TclScript"
# # 运行Vivado并创建Tcl脚本 for 
# "$VivadoPath/vivado" -mode tcl -source $TclScript

# # 运行Vivado并执行Tcl脚本，开启GUI
# $VivadoPath/
cd cdp_ede_local/mycpu_env/soc_verify/soc_hs_bram/run_vivado/project
vivado loongson.xpr