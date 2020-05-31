transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+E:/GIT/cpu11/am4/hdl/org/tbe {E:/GIT/cpu11/am4/hdl/org/tbe/config.v}
vlog -vlog01compat -work work +incdir+E:/GIT/cpu11/am4/hdl/org/rtl {E:/GIT/cpu11/am4/hdl/org/rtl/am4.v}
vlog -vlog01compat -work work +incdir+E:/GIT/cpu11/am4/hdl/org/rtl {E:/GIT/cpu11/am4/hdl/org/rtl/am4_qbus.v}
vlog -vlog01compat -work work +incdir+E:/GIT/cpu11/am4/hdl/org/rtl {E:/GIT/cpu11/am4/hdl/org/rtl/am4_plm.v}
vlog -vlog01compat -work work +incdir+E:/GIT/cpu11/am4/hdl/org/tbe {E:/GIT/cpu11/am4/hdl/org/tbe/de0_top.v}

vlog -vlog01compat -work work +incdir+E:/GIT/cpu11/am4/hdl/org/syn/de0/../../tbe {E:/GIT/cpu11/am4/hdl/org/syn/de0/../../tbe/de0_tb4.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneiii_ver -L rtl_work -L work -voptargs="+acc"  tb4

add wave *
view structure
view signals
run -all
