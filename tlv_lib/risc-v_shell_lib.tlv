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
   
   // mnemonic from warp-v lib expects all is_* to be defined
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

\TLV rf(_entries, _width, $_reset, $_port1_en, $_port1_index, $_port1_data, $_port2_en, $_port2_index, $$_port2_data, $_port3_en, $_port3_index, $$_port3_data)
   m4_ifelse_block(m4_sp_graph_dangerous, 1, [''], ['   
   $viz_rf_reset = m4_argn(3, $@);
   $viz_rf_wr_en = m4_argn(4, $@);
   $viz_rf_wr_index[\$clog2(_entries)-1:0]  = m4_argn(5, $@);
   $viz_rf_wr_data[31:0] = m4_argn(6, $@);
   
   $viz_rf_rd_en1 = m4_argn(7, $@);
   $viz_rf_rd_index1[\$clog2(_entries)-1:0] = m4_argn(8, $@);
   
   $viz_rf_rd_en2 = m4_argn(10, $@);
   $viz_rf_rd_index2[\$clog2(_entries)-1:0] = m4_argn(11, $@);
   '])
   
   /xreg[_entries-1:0]
      $wr                  =  /top$viz_rf_wr_en && (/top$viz_rf_wr_index == #xreg);
      $value[_width-1:0]   =  /top$viz_rf_reset    ?  #xreg               :
                              >>1$wr               ?  /top>>1$viz_rf_wr_data :
                                                      $RETAIN;
   
   $$_port2_data[_width-1:0]  =  $viz_rf_rd_en1 ? /xreg[/top$viz_rf_rd_index1]$value : 'X;
   $$_port3_data[_width-1:0]  =  $viz_rf_rd_en2 ? /xreg[/top$viz_rf_rd_index2]$value : 'X;
   

\TLV dmem(_entries, _width, $_reset, $_port1_en, $_port1_index, $_port1_data, $_port2_en, $_port2_index, $$_port2_data)
   m4_ifelse_block(m4_sp_graph_dangerous, 1, [''], ['
   $viz_dmem_reset = m4_argn(3, $@);
   
   $viz_dmem_wr_en = m4_argn(4, $@);
   $viz_dmem_wr_index[\$clog2(_entries)-1:0] = m4_argn(5, $@);
   
   $viz_dmem_rd_en = m4_argn(7, $@);;
   $viz_dmem_rd_index[\$clog2(_entries)-1:0] = m4_argn(8, $@);;
   '])
   
   /dmem[_entries-1:0]
      $wr                  =  /top$viz_dmem_wr_en && (/top$viz_dmem_wr_index == #dmem);
      $value[_width-1:0]   =  /top$viz_dmem_reset    ?     #dmem               :   
                              >>1$wr                 ?     /top>>1$_port1_data :   
                                                           $RETAIN;
   
   $$_port2_data[_width-1:0] = $viz_dmem_rd_en ? /dmem[/top$viz_dmem_rd_index]$value : 'X;
   

\TLV cpu_viz()
   m4_ifelse_block(m4_sp_graph_dangerous, 1, [''], ['
   // String representations of the instructions for debug.
   \SV_plus
      logic [40*8-1:0] instr_strs [0:M4_NUM_INSTRS];
      assign instr_strs = '{m4_asm_mem_expr "END                                     "};
   
   /cpuviz
      $sticky_zero = 1'b0;
      
      $fetch_instr_str[40*8-1:0] = *instr_strs\[/top$pc[\$clog2(M4_NUM_INSTRS+1)+1:2]\];
      $ANY = /top<>0$ANY;
      \viz_alpha
         initEach() {
            let imem_header = new fabric.Text("📒 Instr. Memory", {
                  top: -29,
                  left: -440,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let decode_header = new fabric.Text("⚙️ Instr. Decode", {
                  top: 0,
                  left: 40,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let rf_header = new fabric.Text("📂 Reg. File", {
                  top: -29 - 40,
                  left: 280,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let dmem_header = new fabric.Text("🗃️ Data Memory", {
                  top: -29 - 40,
                  left: 450,
                  fontSize: 18,
                  fontWeight: 800,
                  fontFamily: "monospace"
               })
            let error_header = new fabric.Text("🚨 Missing Signals", {
                  top: 350,
                  left: -400,
                  fontSize: 18,
                  fontWeight: 800,
                  fill: "red",
                  fontFamily: "monospace"
               })
            let error_box   = new fabric.Rect({
                  top: 400,
                  left: -500,
                  fill: "#ffffe0",
                  width: 400,
                  height: 300,
                  stroke: "black"
               })
            return {objects: {imem_header, decode_header, rf_header, dmem_header, error_header, error_box}};
         },
         renderEach: function() {
            debugger
            //
            var missing_list = "";
            
            siggen = (name) => {
               var sig = this.svSigRef(`L0_${name}_a0`)
               if (sig == null) {
                  missing_list += `◾ $${name}      \n`;
                  sig         = '$sticky_zero';
               }
               return sig
            }
            var example       =   siggen("error_eg")
            var pc            =   siggen("pc");
            var rd_valid      =   siggen("rd_valid");
            var rd            =   siggen("rd");
            var result        =   siggen("result");
            var src1_value    =   siggen("src1_value");
            var src2_value    =   siggen("src2_value");
            var imm           =   siggen("imm");
            var imm_valid     =   siggen("imm_valid");
            var rs1           =   siggen("rs1");
            var rs2           =   siggen("rs2");
            var rs1_valid     =   siggen("rs1_valid");
            var rs2_valid     =   siggen("rs2_valid");
            var valid         =   siggen("valid");
            var mnemonic      =   siggen("mnemonic");
            var rf_wr_data    =   siggen("rf_wr_data");
            
            let color = !(valid.asBool()) ? "gray" :
                                            "blue";
            let pcPointer = new fabric.Text("👉", {
               top: 18 * (pc.asInt() >> 2),
               left: -295,
               fill: color,
               fontSize: 14,
               fontFamily: "monospace"
            })
            let pc_arrow = new fabric.Line([23, 18 * (pc.asInt() >> 2) + 6, 46, 35], {
               stroke: "#d0e8ff",
               strokeWidth: 2
            })
            
            let rs1_arrow = new fabric.Line([330, 18 * '$viz_rf_rd_index1'.asInt() + 6 - 40, 190, 75 + 18 * 2], {
               stroke: "#d0e8ff",
               strokeWidth: 2,
               visible: '$viz_rf_rd_en1'.asBool()
            })
            let rs2_arrow = new fabric.Line([330, 18 * '$viz_rf_rd_index2'.asInt() + 6 - 40, 190, 75 + 18 * 3], {
               stroke: "#d0e8ff",
               strokeWidth: 2,
               visible: '$viz_rf_rd_en2'.asBool()
            })
            let rd_arrow = new fabric.Line([310, 18 * '$viz_rf_wr_index'.asInt() + 6 - 40, 168, 75 + 18 * 0], {
               stroke: "#d0d0ff",
               strokeWidth: 3,
               visible: '$viz_rf_wr_en'.asBool()
            })
            let ld_arrow = new fabric.Line([470, 18 * '$viz_dmem_rd_index'.asInt() + 6 - 40, 175, 75 + 18 * 1], {
               stroke: "#d0e8ff",
               strokeWidth: 2,
               visible: '$viz_dmem_rd_en'.asBool()
            })
            let st_arrow = new fabric.Line([470, 18 * '$viz_dmem_wr_index'.asInt() + 6 - 40, 175, 75 + 18 * 1], {
               stroke: "#d0d0ff",
               strokeWidth: 3,
               visible: '$viz_dmem_wr_en'.asBool()
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
               immValue = parseInt(immValue,2) + 2*(immValue[0] << 31)
               return valid ? `i[${immValue}]` : ``;
            };
            let srcStr = ($src, $valid, $reg, $value) => {
               return $valid.asBool(false)
                          ? `\n      ${regStr(true, $reg.asInt(NaN), $value.asInt(NaN))}`
                          : "";
            };
            let str = `${regStr(rd_valid.asBool(false), rd.asInt(NaN), result.asInt(NaN))}\n` +
                      `  = ${mnemonic.asString()}${srcStr(1, rs1_valid, rs1, src1_value)}${srcStr(2, rs2_valid, rs2, src2_value)}\n` +
                      `      ${immStr(imm_valid.asBool(false), imm.asBinaryStr())}`;
            let instrWithValues = new fabric.Text(str, {
               top: 70,
               left: 65,
               fill: color,
               fontSize: 14,
               fontFamily: "monospace"
            });
            // Animate fetch (and provide onChange behavior for other animation).
            
            let fetch_instr_viz = new fabric.Text('$fetch_instr_str'.asString(), {
               top: 18 * (pc.asInt() >> 2),
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
            
            let load_viz = new fabric.Text(rf_wr_data.asInt(0).toString(), {
               left: 470,
               top: 18 * '$viz_dmem_rd_index'.asInt() + 6 - 40,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 1000,
               visible: false
            })
            if ('$viz_dmem_rd_en'.asBool()) {
               setTimeout(() => {
                  load_viz.setVisible(true)
                  load_viz.animate({left: 165, top: 75 + 18 * 1 - 5}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
                  setTimeout(() => {
                     load_viz.setVisible(true)
                     load_viz.animate({left: 350, top: 18 * '$viz_rf_wr_index'.asInt() - 40}, {
                       onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                       duration: 500
                     })
                     }, 1000)
               }, 500)
            }
            
            let store_viz = new fabric.Text(src2_value.asInt(0).toString(), {
               left: 165,
               top: 75 + 18 * 1 - 5,
               fill: "blue",
               fontSize: 14,
               fontFamily: "monospace",
               fontWeight: 1000,
               visible: false
            })
            if ('$viz_dmem_wr_en'.asBool()) {
               setTimeout(() => {
                  store_viz.setVisible(true)
                  store_viz.animate({left: 515, top: 18 * '$viz_dmem_wr_index'.asInt() - 40}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
               }, 1000)
            }
            
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
            if (rd_valid.asBool() && !'$viz_dmem_rd_en'.asBool()) {
               setTimeout(() => {
                  result_viz.setVisible(true)
                  result_shadow.setVisible(true)
                  result_viz.animate({left: 317 + 8 * 4, top: 18 * rd.asInt(0) - 40}, {
                    onChange: this.global.canvas.renderAll.bind(this.global.canvas),
                    duration: 500
                  })
               }, 1000)
            }
            
            let missing_fill = new fabric.Text(missing_list, {
                  top: 420,
                  left: -480,
                  fontSize: 16,
                  fontWeight: 500,
                  fontFamily: "monospace",
                  fill: "purple"
               })
            
            return {objects: [pcPointer, pc_arrow, rs1_arrow, rs2_arrow, rd_arrow, instrWithValues, fetch_instr_viz, src1_value_viz, src2_value_viz, result_shadow, result_viz, ld_arrow, st_arrow, load_viz, store_viz, missing_fill]};
         }
      
      /imem[m4_eval(M4_NUM_INSTRS-1):0]  // TODO: Cleanly report non-integer ranges.
         $rd_viz = !/top$reset && /top$pc[31:2] == #imem;
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
      
      //\viz_alpha
      //   for(i = 0; i<32; i++){
      //      let rd = 
      
      /xreg[31:0]
         $ANY = /top/xreg<>0$ANY;
         $rd = (/top$viz_rf_rd_en1 && (/top$viz_rf_rd_index1 == #xreg)) ||
               (/top$viz_rf_rd_en2 && (/top$viz_rf_rd_index2 == #xreg));
         //$wr = (/top/cpuviz$rf_wr_en && (/top/cpuviz$rf_wr_index == #xreg));
         \viz_alpha
            initEach: function() {
               return {}  // {objects: {reg: reg}};
            },
            renderEach: function() {
               let rd = '$rd'.asBool(false);
               let mod = '$wr'.asBool(false);
               let reg = parseInt(this.getIndex());
               let regIdent = reg.toString().padEnd(2, " ");
               let newValStr = regIdent + ": ";
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
         
      /dmem[31:0]
         $ANY = /top/dmem<>0$ANY;
         $rd = (/top$viz_dmem_rd_en && /top$viz_dmem_rd_index == #dmem);
         \viz_alpha
            initEach: function() {
               return {}  // {objects: {reg: reg}};
            },
            renderEach: function() {
               let rd = '$rd'.asBool(false);
               let mod = '$wr'.asBool(false);
               let reg = parseInt(this.getIndex());
               let regIdent = reg.toString().padEnd(2, " ");
               let newValStr = regIdent + ": ";
               let dmem_str = new fabric.Text(regIdent + ": " + '>>1$value'.asInt(NaN).toString(), {
                  top: 18 * this.getIndex() - 40,
                  left: 480,
                  fontSize: 14,
                  fill: mod ? "blue" : "black",
                  fontWeight: mod ? 1000 : 400,
                  fontFamily: "monospace",
                  textBackgroundColor: rd ? "#b0ffff" : null
               })
               if (mod) {
                  setTimeout(() => {
                     console.log(`Reg ${this.getIndex()} written with: ${newValStr}.`)
                     dmem_str.set({text: newValStr, dirty: true})
                     this.global.canvas.renderAll()
                  }, 1500)
               }
               return {objects: [dmem_str]}
            }
   '])
