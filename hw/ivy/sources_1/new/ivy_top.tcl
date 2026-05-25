
set_app_var search_path [list . /ENTER YOUR DIRECTORY]


set link_library   [list "NanGate_15nm_OCL_fast.db"]
set target_library [list NanGate_15nm_OCL_fast.db]
# set_app_var link_library [list * ${target_library}]

set symbol_library ""


echo "Target Library: $target_library"
echo "Link Library: $link_library"

set_app_var search_path [list . /ENTER YOUR DIRECTORY]

read_file -format verilog [list \
    ivy_top.v \
    ipu.v \
    read_stage.v \
    compare_stage.v \
    prepare_stage.v \
    write_stage.v \
    INFER_SDPRAM.v \
]


# set_app_var enable_tristate false

# ungroup -all -flatten

# set_fix_multiple_port_nets -all -buffer_constants

current_design ivy_top
analyze -format verilog {ivy_top.v \
    ipu.v \
    read_stage.v \
    compare_stage.v \
    prepare_stage.v \
    write_stage.v \
    INFER_SDPRAM.v \
}

elaborate ivy_top


puts "DEBUG: INFER_SDPRAM is_black_box: [get_attribute [get_designs INFER_SDPRAM] is_black_box]"
puts "DEBUG: INFER_SDPRAM is_unresolved: [get_attribute [get_designs INFER_SDPRAM] is_unresolved]"

check_design

create_clock clk -name "ideal_clock" -period 1666.0
set_input_delay -clock ideal_clock -min 1 [all_inputs]
set_input_delay -clock ideal_clock -max 1 [all_inputs]

compile -map_effort high
# puts "==== Checking mapped cells ===="
# get_lib_cells NanGate_15nm_OCL/*
# report_cell

report_area -nosplit -hierarchy > /ENTER YOUR DIRECTORY/area.txt
report_timing -nosplit -transition_time -nets -attributes > /ENTER YOUR DIRECTORY/timing.txt
