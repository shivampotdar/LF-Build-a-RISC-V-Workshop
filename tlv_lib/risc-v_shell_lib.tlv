\m4_TLV_version 1d: tl-x.org
\SV
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/2d6d36baa4d2bc62321f982f78c8fe1456641a43/risc-v_defs.tlv'])

m4+definitions(['
   m4_define_vector(['M4_WORD'], 32)
   m4_define(['M4_EXT_I'], 1)
   
   m4_define(['M4_NUM_INSTRS'], 0)
   
   m4_echo(m4tlv_riscv_gen__body())
'])
  
\TLV fill_imem()
   // The program in an instruction memory.
   \SV_plus
      logic [31:0] instrs [0:M4_NUM_INSTRS-1];
      `define READONLY_MEM(ADDR, DATA) assign DATA = instrs[ADDR[\$clog2(\$size(instrs)) + 1 : 2]];         // Verilog macro for use by students
      assign instrs = '{
         m4_instr0['']m4_forloop(['m4_instr_ind'], 1, M4_NUM_INSTRS, [', m4_echo(['m4_instr']m4_instr_ind)'])
      };
   m4_ifelse_block(m4_sp_graph_dangerous, 1, [''], ['   
   /defaults
      {$is_lui, $is_auipc, $is_jal, $is_jalr, $is_beq, $is_bne, $is_blt, $is_bge, $is_bltu, $is_bgeu, $is_lb, $is_lh, $is_lw, $is_lbu, $is_lhu, $is_sb, $is_sh, $is_sw} = '0;
      {$is_addi, $is_slti, $is_sltiu, $is_xori, $is_ori, $is_andi, $is_slli, $is_srli, $is_srai, $is_add, $is_sub, $is_sll, $is_slt, $is_sltu, $is_xor} = '0;
      {$is_srl, $is_sra, $is_or, $is_and, $is_csrrw, $is_csrrs, $is_csrrc, $is_csrrwi, $is_csrrsi, $is_csrrci} = '0;
      {$is_load, $is_store} = '0;
      `BOGUS_USE($is_lui $is_auipc $is_jal $is_jalr $is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_lb $is_lh $is_lw $is_lbu $is_lhu $is_sb $is_sh $is_sw)
      `BOGUS_USE($is_addi $is_slti $is_sltiu $is_xori $is_ori $is_andi $is_slli $is_srli $is_srai $is_add $is_sub $is_sll $is_slt $is_sltu $is_xor)
      `BOGUS_USE($is_srl $is_sra $is_or $is_and $is_csrrw $is_csrrs $is_csrrc $is_csrrwi $is_csrrsi $is_csrrci)
   
   $ANY = /defaults<>0$ANY;
   
   m4_define(['m4_modified_mnemonic_expr'], ['m4_patsubst(m4_mnemonic_expr, ['_instr'], [''])'])
   $mnemonic[10*8-1:0] = m4_modified_mnemonic_expr $is_load ? "LOAD      " : $is_store ? "STORE     " : "ILLEGAL   ";
   `BOGUS_USE($mnemonic);
   '])

// A 2-rd 1-wr register file in |cpu that reads and writes in the given stages. If read/write stages are equal, the read values reflect previous writes.
// Reads earlier than writes will require bypass.
// \TLV rf(@_rd, @_wr)
//    // Reg File
//    @_wr
//       /xreg[31:0]
//          $wr = |cpu$rf_wr_en && (|cpu$rf_wr_index != 5'b0) && (|cpu$rf_wr_index == #xreg);
//          $value[31:0] = |cpu$reset ?   #xreg           :
//                         $wr        ?   |cpu$rf_wr_data :
//                                        $RETAIN;
//    @_rd
//       ?$rf_rd_en1
//          $rf_rd_data1[31:0] = /xreg[$rf_rd_index1]>>m4_stage_eval(@_wr - @_rd + 1)$value;
//       ?$rf_rd_en2
//          $rf_rd_data2[31:0] = /xreg[$rf_rd_index2]>>m4_stage_eval(@_wr - @_rd + 1)$value;
//       `BOGUS_USE($rf_rd_data1 $rf_rd_data2)

\TLV rf(_entries, _width, $_reset, _port1_mode, $_port1_en, $_port1_index, $_port1_data, _port2_mode, $_port2_en, $_port2_index, $$_port2_data, _port3_mode, $_port3_en, $_port3_index, $$_port3_data)
   // Reg File
   //@1
   /xreg[_entries-1:0]
      /* m4_argn(4, $@) */
      // m4_shift -> 
      // Read generic // 
      /* m4_forloop(['m4_regport_loop'], 1, 4, ['m4_argn(m4_eval(1 + m4_regport_loop * 4), $@)'])*/
      //$wr = m4_forloop(['m4_regport_loop'], 1, 4, ['m4_ifelse_block(['['_port']m4_regport_loop['_mode']'], W, ['['$_port']m4_regport_loop['_en'] || '], [''])'])
      $wr                  =  /top$_port1_en && (/top$_port1_index != 5'b0) && (/top$_port1_index == #xreg);
      $value[_width-1:0]   =  /top$_reset    ?  '0               :   
                              >>1$wr         ?  >>1/top$_port1_data :   
                                                $RETAIN;
   /cpuviz
      $rf_rd_en1 = /top$_port2_en;
      $rf_rd_en2 = /top$_port3_en;
      $rf_rd_index1[4:0] = /top$_port2_index;
      $rf_rd_index2[4:0] = /top$_port3_index;
      $rf_wr_index[4:0]  = /top$_port1_index;
      $rf_wr_en = /top$_port1_en;

   //?['']$_port2_en
   $$_port2_data[_width-1:0]  =  /xreg[/top$_port2_index]$value;

   //?['']$_port3_en
   $$_port3_data[_width-1:0]  =  /xreg[/top$_port3_index]$value;


// A data memory in |cpu at the given stage. Reads and writes in the same stage, where reads are of the data written by the previous transaction.
// \TLV dmem(@_stage)
//    // Data Memory
//    @_stage
//       /dmem[15:0]
//          $wr = |cpu$dmem_wr_en && (|cpu$dmem_addr == #dmem);
//          $value[31:0] = |cpu$reset ?   #dmem :
//                         $wr        ?   |cpu$dmem_wr_data :
//                                        $RETAIN;
//       ?$dmem_rd_en
//          $dmem_rd_data[31:0] = /dmem[$dmem_addr]>>1$value;
//       `BOGUS_USE($dmem_rd_data)

\TLV dmem(_entries, _width, $_reset, _port1_mode, $_port1_en, $_port1_index, $_port1_data, _port2_mode, $_port2_en, $_port2_index, $$_port2_data)
   // Reg File
   //@1
   /dmem[_entries-1:0]
      //$wr = m4_forloop(['m4_regport_loop'], 1, 4, ['m4_ifelse_block(['['_port']m4_regport_loop['_mode']'], W, ['['$_port']m4_regport_loop['_en'] || '], [''])'])
      $wr                  =  /top$_port1_en && (/top$_port1_index == #dmem);
      $value[_width-1:0]   =  /top$_reset    ?     #dmem               :   
                              >>1$wr         ?     >>1/top$_port1_data :   
                                                   $RETAIN;

   //?['']$_port2_en
   $$_port2_data[_width-1:0] = /dmem[/top$_port2_index]$value;

\TLV cpu_viz()
   m4_ifelse_block(m4_sp_graph_dangerous, 1, [''], ['
   // String representations of the instructions for debug.
   \SV_plus
      logic [40*8-1:0] instr_strs [0:M4_NUM_INSTRS];
      assign instr_strs = '{m4_asm_mem_expr "END                                     "};
   ///top
   /cpuviz
      /defaults
         /xreg[31:0]
            $value[31:0]         = 32'b0;
            $wr                  = 1'b0;
            `BOGUS_USE($value $wr)
            $dummy[0:0]          = 1'b0;
         /dmem[31:0]
            $value[31:0]      = 32'0;
            $wr               = 1'b0;
            `BOGUS_USE($value $wr)
            $dummy[0:0]       = 1'b0;
      
      $fetch_instr_str[40*8-1:0] = *instr_strs\[/top$pc[\$clog2(M4_NUM_INSTRS+1)+1:2]\];
      
      \viz_alpha
         initEach() {
            let imem_header = new fabric.Text("Instr. Memory", {
                  top: -29,
                  left: -440,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let decode_header = new fabric.Text("Instr. Decode", {
                  top: 0,
                  left: 65,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let rf_header = new fabric.Text("Reg. File", {
                  top: -29 - 40,
                  left: 307,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let dmem_header = new fabric.Text("Data. Memory", {
                  top: -29 - 40,
                  left: 450,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            return {objects: {imem_header, decode_header, rf_header, dmem_header}};
         },
         renderEach: function() {
            //debugger
            //
            // PC instr_mem pointer
            //
            let pc            = this.svSigRef(`L0_pc_a0`);
            let rd_valid      = this.svSigRef(`L0_rd_valid_a0`);
            let rd            = this.svSigRef(`L0_rd_a0`);
            let result        = this.svSigRef(`L0_result_a0`);
            let src1_value    = this.svSigRef(`L0_src1_value_a0`);
            let src2_value    = this.svSigRef(`L0_src2_value_a0`);
            let imm           = this.svSigRef(`L0_imm_a0`);
            let imm_valid     = this.svSigRef(`L0_imm_valid_a0`);
            let rs1           = this.svSigRef(`L0_rs1_a0`);
            let rs2           = this.svSigRef(`L0_rs2_a0`);
            let rs1_valid     = this.svSigRef(`L0_rs1_valid_a0`);
            let rs2_valid     = this.svSigRef(`L0_rs2_valid_a0`);
            let valid         = this.svSigRef(`L0_valid_a0`);
            let mnemonic      = this.svSigRef(`L0_mnemonic_a0`);
            
            let color = !(valid.asBool()) ? "gray" :
                                            "blue";
                                            
            let pcPointer = new fabric.Text("->", {
               top: 18 * (pc.asInt() / 4),
               left: -295,
               fill: color,
               fontSize: 14,
               fontFamily: "monospace"
            })
            let pc_arrow = new fabric.Line([23, 18 * (pc.asInt() / 4) + 6, 46, 35], {
               stroke: "#d0e8ff",
               strokeWidth: 2
            })
            let rs1_arrow = new fabric.Line([330, 18 * '$rf_rd_index1'.asInt() + 6 - 40, 190, 75 + 18 * 2], {
               stroke: "#d0e8ff",
               strokeWidth: 2,
               visible: '$rf_rd_en1'.asBool()
            })
            let rs2_arrow = new fabric.Line([330, 18 * '$rf_rd_index2'.asInt() + 6 - 40, 190, 75 + 18 * 3], {
               stroke: "#d0e8ff",
               strokeWidth: 2,
               visible: '$rf_rd_en2'.asBool()
            })
            let rd_arrow = new fabric.Line([330, 18 * '$rf_wr_index'.asInt() + 6 - 40, 168, 75 + 18 * 0], {
               stroke: "#d0d0ff",
               strokeWidth: 3,
               visible: '$rf_wr_en'.asBool()
            })
            //
            // Fetch Instruction
            //
            // TODO: indexing only works in direct lineage.  let fetchInstr = new fabric.Text('|fetch/instr_mem[$Pc]$instr'.asString(), {  // TODO: make indexing recursive.
            //let fetchInstr = new fabric.Text('$raw'.asString("--"), {
            //   top: 50,
            //   left: 90,
            //   fill: color,
            //   fontSize: 14,
            //   fontFamily: "monospace"
            //});
            //
            // Instruction with values.
            //
            let regStr = (valid, regNum, regValue) => {
               return valid ? `r${regNum}` : `rX`  // valid ? `r${regNum} (${regValue})` : `rX`
            };
            let immStr = (valid, immValue) => {
               return valid ? `i[${immValue}]` : ``;
            };
            let srcStr = ($src, $valid, $reg, $value) => {
               return $valid.asBool(false)
                          ? `\n      ${regStr(true, $reg.asInt(NaN), $value.asInt(NaN))}`
                          : "";
            };
            let str = `${regStr(rd_valid.asBool(false), rd.asInt(NaN), result.asInt(NaN))}\n` +
                      `  = ${mnemonic.asString()}${srcStr(1, rs1_valid, rs1, src1_value)}${srcStr(2, rs2_valid, rs2, src2_value)}\n` +
                      `      ${immStr(imm_valid.asBool(false), imm.asInt(NaN))}`;
            let instrWithValues = new fabric.Text(str, {
               top: 70,
               left: 65,
               fill: color,
               fontSize: 14,
               fontFamily: "monospace"
            });
            // Animate fetch (and provide onChange behavior for other animation).
            
            let fetch_instr_viz = new fabric.Text('$fetch_instr_str'.asString(), {
               top: 18 * (pc.asInt() / 4),
               left: -272,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace"
            })
            fetch_instr_viz.animate({top: 32, left: 50}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
            });
            
            let src1_value_viz = new fabric.Text(src1_value.asInt(0).toString(), {
               left: 316 + 8 * 4,
               top: 18 * rs1.asInt(0) - 40,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: rs1_valid.asBool(false)
            })
            setTimeout(() => {src1_value_viz.animate({left: 166, top: 70 + 18 * 2}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
            })}, 500)
            let src2_value_viz = new fabric.Text(src2_value.asInt(0).toString(), {
               left: 316 + 8 * 4,
               top: 18 * rs2.asInt(0) - 40,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: rs2_valid.asBool(false)
            })
            setTimeout(() => {src2_value_viz.animate({left: 166, top: 70 + 18 * 3}, {
                 onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                 duration: 500
            })}, 500)
            let result_shadow = new fabric.Text(result.asInt(0).toString(), {
               left: 146,
               top: 70,
               fill: "#d0d0ff",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: false
            })
            let result_viz = new fabric.Text(result.asInt(0).toString(), {
               left: 146,
               top: 70,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 800,
               visible: false
            })
            if (rd_valid.asBool()) {
               setTimeout(() => {
                  result_viz.setVisible(true)
                  result_shadow.setVisible(true)
                  result_viz.animate({left: 317 + 8 * 4, top: 18 * rd.asInt(0) - 40}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
               }, 1000)
            }
            
            return {objects: [pcPointer, pc_arrow, rs1_arrow, rs2_arrow, rd_arrow, instrWithValues, fetch_instr_viz, src1_value_viz, src2_value_viz, result_shadow, result_viz]};
         }
      m4_define(M4_COMMENT, 1)
      
      //
      /imem[m4_eval(M4_NUM_INSTRS-1):0]  // TODO: Cleanly report non-integer ranges.
         $rd_viz = !/top$reset && /top$pc[4:2] == #imem;
         $instr[31:0] = *instrs\[#imem\];
         $instr_str[40*8-1:0] = *instr_strs[imem];
         \viz_alpha
            initEach() {
              let binary = new fabric.Text("", {
                 top: 18 * this.getIndex(),  // TODO: Add support for '#instr_mem'.
                 left: -600,
                 fontSize: 14,
                 fontFamily: "monospace"
              })
              let disassembled = new fabric.Text("", {
                 top: 18 * this.getIndex(),  // TODO: Add support for '#instr_mem'.
                 left: -270,
                 fontSize: 14,
                 fontFamily: "monospace"
              })
              return {objects: {binary: binary, disassembled: disassembled}}
            },
            renderEach: function() {
               // Instruction memory is constant, so just create it once.
               if (!global.instr_mem_drawn) {
                  global.instr_mem_drawn = [];
               }
               if (!global.instr_mem_drawn[this.getIndex()]) {
                  global.instr_mem_drawn[this.getIndex()] = true
                  let binary_str       = '$instr'.asBinaryStr(NaN)
                  let disassembled_str = '$instr_str'.asString()
                  disassembled_str = disassembled_str.slice(0, -5)
                  //debugger
                  this.getInitObject("binary").setText(binary_str)
                  this.getInitObject("disassembled").setText(disassembled_str)
               }
               this.getInitObject("disassembled").set({textBackgroundColor: '$rd_viz'.asBool() ? "#b0ffff" : "white"})
            }
      
      //
      /xreg[31:0]
         $ANY = /top/xreg<>0$ANY;
         $rd = (/cpuviz$rf_rd_en1 && /cpuviz$rf_rd_index1 == #xreg) ||
               (/cpuviz$rf_rd_en2 && /cpuviz$rf_rd_index2 == #xreg);
         \viz_alpha
            initEach: function() {
               return {}  // {objects: {reg: reg}};
            },
            renderEach: function() {
               let rd = '$rd'.asBool(false);
               let mod = '$wr'.asBool(false);
               let reg = parseInt(this.getIndex());
               let regIdent = reg.toString().padEnd(2, " ");
               let newValStr = regIdent + ": " + (mod ? '$value'.asInt(NaN).toString() : "");
               let reg_str = new fabric.Text(regIdent + ": " + '>>1$value'.asInt(NaN).toString(), {
                  top: 18 * this.getIndex() - 40,
                  left: 316,
                  fontSize: 14,
                  fill: mod ? "blue" : "black",
                  fontWeight: mod ? 1000 : 400,
                  fontFamily: "monospace",
                  textBackgroundColor: rd ? "#b0ffff" : null
               })
               if (mod) {
                  setTimeout(() => {
                     console.log(`Reg ${this.getIndex()} written with: ${newValStr}.`)
                     reg_str.set({text: newValStr, dirty: true})
                     this.global.canvas.renderAll()
                  }, 1500)
               }
               return {objects: [reg_str]}
            }

      // Register file
      //
      m4_ifelse(M4_COMMENT, 0, ['
      /xreg[31:0]
         \viz_alpha
            initEach: function() {
               let regname = new fabric.Text("Reg File", {
                     top: -20,
                     left: 367,
                     fontSize: 14,
                     fontFamily: "monospace"
                  });
               let reg = new fabric.Text("", {
                  top: 18 * this.getIndex(),
                  left: 375,
                  fontSize: 14,
                  fontFamily: "monospace"
               });
               return {objects: {regname: regname, reg: reg}};
            },
            renderEach: function() {
               let mod = '$wr'.asBool(false);
               let reg = parseInt(this.getIndex());
               let regIdent = reg.toString();
               let oldValStr = mod ? `(${'>>1$value'.asInt(NaN).toString()})` : "";
               this.getInitObject("reg").setText(
                  regIdent + ": " +
                  '$value'.asInt(NaN).toString() + oldValStr);
               this.getInitObject("reg").setFill(mod ? "blue" : "black");
            }
      //
      // DMem
      //
      /dmem[31:0]
         \viz_alpha
            initEach: function() {
               let memname = new fabric.Text("Mini DMem", {
                     top: -20,
                     left: 460,
                     fontSize: 14,
                     fontFamily: "monospace"
                  });
               let mem = new fabric.Text("", {
                  top: 18 * this.getIndex(),
                  left: 468,
                  fontSize: 14,
                  fontFamily: "monospace"
               });
               return {objects: {memname: memname, mem: mem}};
            },
            renderEach: function() {
               let mod = '$wr'.asBool(false);
               let mem = parseInt(this.getIndex());
               let memIdent = mem.toString();
               let oldValStr = mod ? `(${'>>1$value'.asInt(NaN).toString()})` : "";
               this.getInitObject("mem").setText(
                  memIdent + ": " +
                  '$value'.asInt(NaN).toString() + oldValStr);
               this.getInitObject("mem").setFill(mod ? "blue" : "black");
            }
      '])
   '])
