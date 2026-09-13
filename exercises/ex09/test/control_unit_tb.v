`timescale 1ns/1ps

module control_unit_tb;

    localparam OP_RTYPE = 6'b000000;
    localparam OP_LW    = 6'b100011;
    localparam OP_SW    = 6'b101011;
    localparam OP_BEQ   = 6'b000100;
    localparam OP_ADDI  = 6'b001000;
    localparam OP_BOGUS = 6'b111111;

    localparam F_ADD = 6'b100000;
    localparam F_SUB = 6'b100010;
    localparam F_AND = 6'b100100;
    localparam F_OR  = 6'b100101;
    localparam F_SLT = 6'b101010;
    localparam F_SLL = 6'b000000;
    localparam F_SRL = 6'b000010;
    localparam F_BOGUS = 6'b111111;

    localparam ALU_AND = 4'b0000, ALU_OR = 4'b0001, ALU_ADD = 4'b0010,
               ALU_SLL = 4'b0100, ALU_SRL = 4'b0101, ALU_SUB = 4'b0110, ALU_SLT = 4'b0111;

    integer pass_count = 0;
    integer total_count = 0;

    task check(input ok, input [767:0] label);
        begin
            total_count = total_count + 1;
            if (ok) pass_count = pass_count + 1;
            else $display("[FAIL] %0s", label);
        end
    endtask

    // ---------------- main_decoder ----------------
    reg  [5:0] md_opcode;
    wire md_reg_dst, md_branch, md_mem_read, md_mem_to_reg, md_mem_write, md_alu_src, md_reg_write;
    wire [1:0] md_alu_op;
    main_decoder dut_md(.opcode(md_opcode), .reg_dst(md_reg_dst), .branch(md_branch),
                         .mem_read(md_mem_read), .mem_to_reg(md_mem_to_reg), .mem_write(md_mem_write),
                         .alu_src(md_alu_src), .reg_write(md_reg_write), .alu_op(md_alu_op));

    task check_main(input [5:0] opcode_val, input exp_reg_dst, input exp_branch, input exp_mem_read,
                     input exp_mem_to_reg, input exp_mem_write, input exp_alu_src, input exp_reg_write,
                     input [1:0] exp_alu_op, input [767:0] label);
        begin
            md_opcode = opcode_val; #1;
            check(md_reg_dst === exp_reg_dst && md_branch === exp_branch && md_mem_read === exp_mem_read &&
                  md_mem_to_reg === exp_mem_to_reg && md_mem_write === exp_mem_write &&
                  md_alu_src === exp_alu_src && md_reg_write === exp_reg_write && md_alu_op === exp_alu_op,
                  label);
        end
    endtask

    // ---------------- alu_decoder ----------------
    reg  [1:0] ad_alu_op;
    reg  [5:0] ad_funct;
    wire [3:0] ad_alu_control;
    alu_decoder dut_ad(.alu_op(ad_alu_op), .funct(ad_funct), .alu_control(ad_alu_control));

    task check_alu_dec(input [1:0] alu_op_val, input [5:0] funct_val, input [3:0] exp_ctrl, input [767:0] label);
        begin
            ad_alu_op = alu_op_val; ad_funct = funct_val; #1;
            check(ad_alu_control === exp_ctrl, label);
        end
    endtask

    // ---------------- control_unit (integration) ----------------
    reg  [5:0] cu_opcode, cu_funct;
    wire cu_reg_dst, cu_branch, cu_mem_read, cu_mem_to_reg, cu_mem_write, cu_alu_src, cu_reg_write;
    wire [3:0] cu_alu_control;
    control_unit dut_cu(.opcode(cu_opcode), .funct(cu_funct), .reg_dst(cu_reg_dst), .branch(cu_branch),
                         .mem_read(cu_mem_read), .mem_to_reg(cu_mem_to_reg), .mem_write(cu_mem_write),
                         .alu_src(cu_alu_src), .reg_write(cu_reg_write), .alu_control(cu_alu_control));

    task check_cu(input [5:0] opcode_val, input [5:0] funct_val,
                  input exp_reg_dst, input exp_branch, input exp_mem_read, input exp_mem_to_reg,
                  input [3:0] exp_alu_control, input exp_mem_write, input exp_alu_src, input exp_reg_write,
                  input [767:0] label);
        begin
            cu_opcode = opcode_val; cu_funct = funct_val; #1;
            check(cu_reg_dst === exp_reg_dst && cu_branch === exp_branch && cu_mem_read === exp_mem_read &&
                  cu_mem_to_reg === exp_mem_to_reg && cu_alu_control === exp_alu_control &&
                  cu_mem_write === exp_mem_write && cu_alu_src === exp_alu_src && cu_reg_write === exp_reg_write,
                  label);
        end
    endtask

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, control_unit_tb);

        // ===================== main_decoder =====================
        check_main(OP_RTYPE, 1,0,0,0,0,0,1, 2'b10, "main_decoder: R-type signals incorrect");
        check_main(OP_LW,    0,0,1,1,0,1,1, 2'b00, "main_decoder: lw signals incorrect");
        check_main(OP_SW,    0,0,0,0,1,1,0, 2'b00, "main_decoder: sw signals incorrect");
        check_main(OP_BEQ,   0,1,0,0,0,0,0, 2'b01, "main_decoder: beq signals incorrect");
        check_main(OP_ADDI,  0,0,0,0,0,1,1, 2'b00, "main_decoder: addi signals incorrect");
        check_main(OP_BOGUS, 0,0,0,0,0,0,0, 2'b00, "main_decoder: unrecognized opcode must produce all-safe defaults");

        // ===================== alu_decoder =====================
        check_alu_dec(2'b00, 6'b0, ALU_ADD, "alu_decoder: alu_op=00 must always select ADD");
        check_alu_dec(2'b01, 6'b0, ALU_SUB, "alu_decoder: alu_op=01 must always select SUB");
        check_alu_dec(2'b10, F_ADD, ALU_ADD, "alu_decoder: R-type add funct incorrect");
        check_alu_dec(2'b10, F_SUB, ALU_SUB, "alu_decoder: R-type sub funct incorrect");
        check_alu_dec(2'b10, F_AND, ALU_AND, "alu_decoder: R-type and funct incorrect");
        check_alu_dec(2'b10, F_OR,  ALU_OR,  "alu_decoder: R-type or funct incorrect");
        check_alu_dec(2'b10, F_SLT, ALU_SLT, "alu_decoder: R-type slt funct incorrect");
        check_alu_dec(2'b10, F_SLL, ALU_SLL, "alu_decoder: R-type sll funct incorrect");
        check_alu_dec(2'b10, F_SRL, ALU_SRL, "alu_decoder: R-type srl funct incorrect");
        check_alu_dec(2'b10, F_BOGUS, ALU_AND, "alu_decoder: unrecognized funct under alu_op=10 must default to AND");

        // ===================== control_unit integration =====================
        // Matches exactly the control bundles ex08's testbench hardcoded per instruction.
        check_cu(OP_ADDI, 6'b0,   0,0,0,0, ALU_ADD, 0,1,1, "control_unit: addi bundle incorrect");
        check_cu(OP_RTYPE, F_ADD, 1,0,0,0, ALU_ADD, 0,0,1, "control_unit: add bundle incorrect");
        check_cu(OP_RTYPE, F_SUB, 1,0,0,0, ALU_SUB, 0,0,1, "control_unit: sub bundle incorrect");
        check_cu(OP_RTYPE, F_AND, 1,0,0,0, ALU_AND, 0,0,1, "control_unit: and bundle incorrect");
        check_cu(OP_RTYPE, F_OR,  1,0,0,0, ALU_OR,  0,0,1, "control_unit: or bundle incorrect");
        check_cu(OP_RTYPE, F_SLT, 1,0,0,0, ALU_SLT, 0,0,1, "control_unit: slt bundle incorrect");
        check_cu(OP_SW,   6'b0,   0,0,0,0, ALU_ADD, 1,1,0, "control_unit: sw bundle incorrect");
        check_cu(OP_LW,   6'b0,   0,0,1,1, ALU_ADD, 0,1,1, "control_unit: lw bundle incorrect");
        check_cu(OP_BEQ,  6'b0,   0,1,0,0, ALU_SUB, 0,0,0, "control_unit: beq bundle incorrect");

        if (pass_count == total_count)
            $display("RESULT: PASS (%0d/%0d checks)", pass_count, total_count);
        else
            $display("RESULT: FAIL (%0d/%0d checks passed)", pass_count, total_count);

        $finish;
    end

endmodule
