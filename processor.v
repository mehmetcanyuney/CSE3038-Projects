module processor;
reg [31:0] pc; //32-bit prograom counter
reg clk; //clock
reg [7:0] datmem[0:31]; //32-size data and instruction memory (8 bit(1 byte) for each location)
reg [7:0] mem[0:255];
wire [31:0]
dataa,	//Read data 1 output of Register File
datab,	//Read data 2 output of Register File
out2,		//Output of mux with ALUSrc control-mult2
out3,		//Output of mux with MemToReg control-mult3
out4,		//Output of mux with (Branch&ALUZero) control-mult4
out5,   //Output of mux with (N status register & branch) control-mult5
out6,   //Output of mux with (Z status register & balrz) control-mult6
out7,   //Output of mux with (adder1out & out3) control-mult7
out8,   //Output of mux with (jr) control-mult8
out9,   //Output of mux with (pc & jrsal) control-mult9
out10,  //Output of mux with (dataadress & jrsal) control-mult10
out11,  //Output of mux with (writedata & jrsal) control-mult11
out12,  //Output of mux with (balmn & dpack) control-mult12
out13,  //Output of mux with (datab & balmn) control-mult13
sum,		//ALU result
extad,	//Output of sign-extend unit
adder1out,	//Output of adder which adds PC and 4-add1
adder2out,	//Output of adder which adds PC+4 and 2 shifted sign-extend result-add2
pseudojump,  //Pseudo jump adress
pseudojumpshifted,
sextad;	//Output of shift left 2 unit

reg Z, N;

wire [5:0] inst31_26;	//31-26 bits of instruction
wire [4:0]
inst25_21,	//25-21 bits of instruction
inst20_16,	//20-16 bits of instruction
inst15_11,	//15-11 bits of instruction
out1;		//Write data input of Register File

wire [15:0] inst15_0;	//15-0 bits of instruction

wire [31:0] instruc,	//current instruction
dpack;	//Read data output of memory (data read from memory)

wire [2:0] gout;	//Output of ALU control unit

wire zout,	//Zero output of ALU
signout,
pcsrc,	//Output of AND gate with Branch and ZeroOut inputs
njumpsrc, //Output of And gate with branch and n status register inputs
nbalrz, //Output of and gate with balrz and z status register inputs
nbalmn, //Output of and gate with balmn and n status register inputs
//Control signals
regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop1,aluop0,balrz,jr,jrsal,jmadd,balmn,noupdatestat;

//32-size register file (32 bit(1 word) for each register)
reg [31:0] registerfile[0:31];

integer i;

// datamemory connections

always @(posedge clk)
//write data to memory
if (memwrite)
begin
//sum stores address,datab stores the value to be written
datmem[out10[4:0]+3]=datab[7:0];
datmem[out10[4:0]+2]=datab[15:8];
datmem[out10[4:0]+1]=datab[23:16];
datmem[out10[4:0]]=datab[31:24];
end

//instruction memory
//4-byte instruction
 assign instruc={mem[pc],mem[pc+1],mem[pc+2],mem[pc+3]};
 assign inst31_26=instruc[31:26];
 assign inst25_21=instruc[25:21];
 assign inst20_16=instruc[20:16];
 assign inst15_11=instruc[15:11];
 assign inst15_0=instruc[15:0];


// registers

assign dataa=registerfile[inst25_21];//Read register 1
assign datab=registerfile[inst20_16];//Read register 2
always @(posedge clk)
 registerfile[out1]= regwrite ? out13:registerfile[out1];//Write data to register

//read data from memory, sum stores address
assign dpack={datmem[out10[5:0]],datmem[out10[5:0]+1],datmem[out10[5:0]+2],datmem[out10[5:0]+3]};

//multiplexers
//mux with RegDst control
mult2_to_1_5  mult1(out1, instruc[20:16],instruc[15:11],regdest);

//mux with ALUSrc control
mult2_to_1_32 mult2(out2, datab,extad,alusrc);

//mux with MemToReg control
mult2_to_1_32 mult3(out3, sum,dpack,memtoreg);

//mux with (Branch&ALUZero) control
mult2_to_1_32 mult4(out4, adder1out,adder2out,pcsrc);

//mux with (N status register & brach) control
mult2_to_1_32 mult5(out5, out4, pseudojump, njumpsrc);

//mux with (Z status register & balrz) Control
mult2_to_1_32 mult6(out6, out5, dataa, nbalrz);

//mux with (adderout1 & memtoreg mux out) Control
mult2_to_1_32 mult7(out7, out3, adder1out, nbalrz);

//mux with (jr) Control
mult2_to_1_32 mult8(out8, out6, dataa, jr);

//mux with (jrsal & pc) control
mult2_to_1_32 mult9(out9, out8, dpack, jrsal);

//mux with (jrsal & dataadress) Control
mult2_to_1_32 mult10(out10, sum, dataa, jrsal);

//mux with (jmadd & dataadress) Control
mult2_to_1_32 mult11(out11, out9, dpack, jmadd);

//mux with (balmn & dataadress) Control
mult2_to_1_32 mult12(out12, out11, dpack, nbalmn);

//mux with (balmn & datab) control
mult2_to_1_32 mult13(out13, out7, adder1out, (nbalmn | jmadd));

// load pc
always @(negedge clk)
begin
  pc=out12;
  if(jrsal) //due to not lose information in memory
  begin
    datmem[out10[4:0]+3]=adder1out[7:0];
    datmem[out10[4:0]+2]=adder1out[15:8];
    datmem[out10[4:0]+1]=adder1out[23:16];
    datmem[out10[4:0]]=adder1out[31:24];
  end
end

// alu, adder and control logic connections

//ALU unit
alu32 alu1(sum,dataa,out2,zout,signout,gout,instruc[10:6]);

//adder which adds PC and 4
adder add1(pc,32'h4,adder1out);

//adder which adds PC+4 and 2 shifted sign-extend result
adder add2(adder1out,sextad,adder2out);

//Control unit
control cont(instruc[31:26],instruc[5:0],regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,
aluop1,aluop0,balrz,jr,jrsal,jmadd,balmn,noupdatestat);

//Sign extend unit
signext sext(instruc[15:0],extad);

//ALU control unit
alucont acont(aluop1,aluop0,instruc[5],instruc[4],instruc[3],instruc[2], instruc[1], instruc[0] ,gout);

//Shift-left 2 unit
shift shift2(sextad,extad);

//Shift-left 2 unit
shift shift2_2(pseudojumpshifted, {{6{instruc[25]}} ,instruc[25:0]});

//pseudojump format prepared
assign pseudojump = {adder1out[31:28], pseudojumpshifted[27:0]};

//AND gate
assign pcsrc=branch && zout;

//AND gate
assign njumpsrc=branch && N;

//AND gate
assign nbalrz=balrz && Z;

//AND gate
assign nbalmn=balmn && N;

//Status registers
always @(posedge clk)
  begin
    if(~noupdatestat) //if instruction == balmn, we need to keep old status registers (balmn also uses ALU), so that we freeze the update state
    begin
      Z = zout ? 1'b1:1'b0;
      N = signout ? 1'b1:1'b0;
    end
  end


//initialize datamemory,instruction memory and registers
//read initial data from files given in hex
initial
begin
$readmemh("initDm.dat",datmem); //read Data Memory
$readmemh("initIM.dat",mem);//read Instruction Memory
$readmemh("initReg.dat",registerfile);//read Register File

	for(i=0; i<31; i=i+1)
	$display("Instruction Memory[%0d]= %h  ",i,mem[i],"Data Memory[%0d]= %h   ",i,datmem[i],
	"Register[%0d]= %h",i,registerfile[i]);
end

initial
begin
pc=0;

end
initial
begin
clk=0;
//40 time unit for each cycle
forever #20  clk=~clk;
end
initial
begin
  $monitor($time,"PC %h",pc,"  SUM %h",sum,"   INST %h",instruc[31:0],
"   REGISTER %h %h %h %h ",registerfile[4],registerfile[5], registerfile[6],registerfile[1] );
end
endmodule
