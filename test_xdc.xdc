create_clock -name main -period 10 [get_ports sys_clk]
# system clock: 100MHz
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports {sys_clk}]

# reset button: S2 (the middle button)
set_property -dict {PACKAGE_PIN R15 IOSTANDARD LVCMOS33} [get_ports {reset}]

# leds
# order: leds[0] for the rightmost, and leds[1] for the leftmost
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {leds[0]}]
set_property -dict {PACKAGE_PIN J2 IOSTANDARD LVCMOS33} [get_ports {leds[1]}]
set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports {leds[2]}]
set_property -dict {PACKAGE_PIN H4 IOSTANDARD LVCMOS33} [get_ports {leds[3]}]
set_property -dict {PACKAGE_PIN J4 IOSTANDARD LVCMOS33} [get_ports {leds[4]}]
set_property -dict {PACKAGE_PIN G3 IOSTANDARD LVCMOS33} [get_ports {leds[5]}]
set_property -dict {PACKAGE_PIN G4 IOSTANDARD LVCMOS33} [get_ports {leds[6]}]
set_property -dict {PACKAGE_PIN F6 IOSTANDARD LVCMOS33} [get_ports {leds[7]}]

# BCD displayer: using the right half
# order: an[0] for the rightmost one,
set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS33} [get_ports {an[3]}]
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS33} [get_ports {an[2]}]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports {an[1]}]
set_property -dict {PACKAGE_PIN G6 IOSTANDARD LVCMOS33} [get_ports {an[0]}]
# from digit[0] to digit[7]: 
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports {digit[0]}]
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports {digit[1]}]
set_property -dict {PACKAGE_PIN D3 IOSTANDARD LVCMOS33} [get_ports {digit[2]}]
set_property -dict {PACKAGE_PIN F4 IOSTANDARD LVCMOS33} [get_ports {digit[3]}]
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33} [get_ports {digit[4]}]
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports {digit[5]}]
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports {digit[6]}]
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports {digit[7]}]

#set_input_delay 3 -clock main [get_ports reset]

#set_output_delay 0 -clock main [get_ports leds]
#set_output_delay 0 -clock main [get_ports an]
#set_output_delay 0 -clock main [get_ports digit]