module control(in,funcin,regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop1,aluop2,balrz,jr,jrsal,jmadd,balmn);
input [5:0] in;
input [5:0] funcin;
output regdest,alusrc,memtoreg,regwrite,memread,memwrite,branch,aluop1,aluop2,balrz,jr,jrsal,jmadd,balmn;
wire rformat,lw,sw,beq,bn,brz,jumpreg,jrs,jma,blm;
assign rformat=~|in;
assign lw=in[5]& (~in[4])&(~in[3])&(~in[2])&in[1]&in[0];
assign sw=in[5]& (~in[4])&in[3]&(~in[2])&in[1]&in[0];
assign beq=~in[5]& (~in[4])&(~in[3])&in[2]&(~in[1])&(~in[0]);
assign bn=in[5] & (~in[4]) & (~in[3]) & in[2] & (~in[1]) & in[0];
assign brz=(~funcin[5]) & funcin[4] & (~funcin[3]) & funcin[2] & funcin[1] & (~funcin[0]);
assign jumpreg=(~funcin[5]) & (~funcin[4]) & funcin[3] & (~funcin[2]) & (~funcin[1]) & (~funcin[0]);
assign jrs=(~in[5])&in[4]&in[3]&(~in[2])&(~in[1])&in[0];
assign jma=funcin[5] & funcin[4] & (~funcin[3]) & (~funcin[2]) & funcin[1] & (~funcin[0]);
assign blm=in[5]&(~in[4])&(~in[3])&in[2]&(~in[1])&(~in[0]);


assign regdest=rformat;
assign alusrc=lw|sw;
assign memtoreg=lw;
assign regwrite=(lw|blm) | (~jumpreg && rformat) | (~jma && rformat);
assign memread=lw|jrs|jma;
assign memwrite=sw;
assign branch=beq|bn;
assign aluop1=rformat;
assign aluop2=beq;
assign balrz=brz;
assign jr=jumpreg && rformat;
assign jrsal=jrs;
assign jmadd=jma && rformat;
assign balmn=blm;
endmodule
