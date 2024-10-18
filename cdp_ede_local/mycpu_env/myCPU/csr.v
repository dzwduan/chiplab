`include "csr.vh"

module csr (
    input  wire        clk,
    input  wire        reset,
    // from to ds
    input  wire [13:0] rd_addr,
    output wire [31:0] rd_data,
    output wire        has_int,
    // from ws
    input  wire        csr_wr_en,
    input  wire [13:0] wr_addr,
    input  wire [31:0] wr_data,
    input  wire        excp_flush,
    input  wire        ertn_flush,
    input  wire [31:0] era_in,
    input  wire [ 8:0] esubcode_in,
    input  wire [ 5:0] ecode_in
    // input wire [7:0] interrupt
);

  localparam CRMD = 14'h0;
  localparam PRMD = 14'h1;
  localparam ECTL = 14'h4;
  localparam ESTAT = 14'h5;
  localparam ERA = 14'h6;
  localparam BADV = 14'h7;
  localparam EENTRY = 14'hc;
  localparam TLBIDX = 14'h10;
  localparam TLBEHI = 14'h11;
  localparam TLBELO0 = 14'h12;
  localparam TLBELO1 = 14'h13;
  localparam ASID = 14'h18;
  localparam PGDL = 14'h19;
  localparam PGDH = 14'h1a;
  localparam PGD = 14'h1b;
  localparam CPUID = 14'h20;
  localparam SAVE0 = 14'h30;
  localparam SAVE1 = 14'h31;
  localparam SAVE2 = 14'h32;
  localparam SAVE3 = 14'h33;
  localparam TID = 14'h40;
  localparam TCFG = 14'h41;
  localparam TVAL = 14'h42;
  localparam CNTC = 14'h43;
  localparam TICLR = 14'h44;
  localparam LLBCTL = 14'h60;
  localparam TLBRENTRY = 14'h88;
  localparam DMW0 = 14'h180;
  localparam DMW1 = 14'h181;
  localparam BRK = 14'h100;
  localparam DISABLE_CACHE = 14'h101;

  wire        crmd_wen = csr_wr_en & (wr_addr == CRMD);
  wire        prmd_wen = csr_wr_en & (wr_addr == PRMD);
  wire        ectl_wen = csr_wr_en & (wr_addr == ECTL);
  wire        estat_wen = csr_wr_en & (wr_addr == ESTAT);
  wire        era_wen = csr_wr_en & (wr_addr == ERA);
  wire        badv_wen = csr_wr_en & (wr_addr == BADV);
  wire        eentry_wen = csr_wr_en & (wr_addr == EENTRY);
  wire        save0_wen = csr_wr_en & (wr_addr == SAVE0);
  wire        save1_wen = csr_wr_en & (wr_addr == SAVE1);
  wire        save2_wen = csr_wr_en & (wr_addr == SAVE2);
  wire        save3_wen = csr_wr_en & (wr_addr == SAVE3);
  wire        tid_wen = csr_wr_en & (wr_addr == TID);
  wire        tcfg_wen = csr_wr_en & (wr_addr == TCFG);
  wire        tval_wen = csr_wr_en & (wr_addr == TVAL);
  wire        ticlr_wen = csr_wr_en & (wr_addr == TICLR);
  wire        BRK_wen = csr_wr_en & (wr_addr == BRK);


  reg         timer_en;  // 是否开始时钟自减
  reg  [31:0] csr_crmd;
  reg  [31:0] csr_prmd;
  reg  [31:0] csr_ectl;
  reg  [31:0] csr_estat;
  reg  [31:0] csr_era;
  reg  [31:0] csr_badv;
  reg  [31:0] csr_eentry;
  reg  [31:0] csr_save0;
  reg  [31:0] csr_save1;
  reg  [31:0] csr_save2;
  reg  [31:0] csr_save3;
  reg  [31:0] csr_tid;
  reg  [31:0] csr_tcfg;
  reg  [31:0] csr_tval;
  reg  [31:0] csr_ticlr;
  reg  [31:0] csr_brk;

  // estat对中断状态输入引脚信号采样，ecfg是局部中断使能，crmd ie是全局中断使能
  assign has_int = (csr_estat[`IS] != 13'b0 & csr_ectl[`LIE] != 13'b0) && csr_crmd[`IE];

  assign rd_data =  {32{rd_addr == CRMD  }}  & csr_crmd    |
                    {32{rd_addr == PRMD  }}  & csr_prmd    |
                    {32{rd_addr == ECTL  }}  & csr_ectl    |
                    {32{rd_addr == ESTAT }}  & csr_estat   |
                    {32{rd_addr == ERA   }}  & csr_era     |
                    {32{rd_addr == BADV  }}  & csr_badv    |
                    {32{rd_addr == EENTRY}}  & csr_eentry  |
                    {32{rd_addr == SAVE0 }}  & csr_save0   |
                    {32{rd_addr == SAVE1 }}  & csr_save1   |
                    {32{rd_addr == SAVE2 }}  & csr_save2   |
                    {32{rd_addr == SAVE3 }}  & csr_save3   |
                    {32{rd_addr == TID   }}  & csr_tid     |
                    {32{rd_addr == TCFG  }}  & csr_tcfg    |
                    {32{rd_addr == TICLR }}  & csr_ticlr   |
                    {32{rd_addr == TVAL  }}  & csr_tval    ;


  // crmd plv and ie
  always @(posedge clk) begin
    if (reset) begin
      csr_crmd[`PLV] <= 2'b0;
      csr_crmd[`IE]  <= 1'b0;
      csr_crmd[31:9] <= 23'b0;
    end else if (excp_flush) begin
      csr_crmd[`PLV] <= 2'b0;
      csr_crmd[`IE]  <= 1'b0;
    end else if (ertn_flush) begin
      csr_crmd[`PLV] <= csr_prmd[`PPLV];
      csr_crmd[`IE]  <= csr_prmd[`PIE];
    end else if (crmd_wen) begin
      csr_crmd[`PLV] <= wr_data[`PLV];
      csr_crmd[`IE]  <= wr_data[`IE];
    end
  end

  // prmd excp save state
  always @(posedge clk) begin
    if (reset) begin
      csr_prmd <= 32'b0;
    end else if (excp_flush) begin
      csr_prmd[`PPLV] <= csr_crmd[`PLV];
      csr_prmd[`PIE]  <= csr_crmd[`IE];
    end else if (prmd_wen) begin
      csr_prmd[`PPLV] <= wr_data[`PPLV];
      csr_prmd[`PIE]  <= wr_data[`PIE];
    end
  end

  // estat is ecode esubcode, 仅有1:0两个bit能写入
  always @(posedge clk) begin
    if (reset) begin
      csr_estat <= 32'b0;
      timer_en  <= 1'b0;
    end else begin
      // 定时器设置
      // ticlr[0] ==1, 清除时钟中断标记estat[11], 但是csr_ticlr不变化，直接读csr_ticlr = 0
      if (ticlr_wen && wr_data[`CLR]) begin
        csr_estat[11] <= 1'b0;
      end
      // tcfg[0]写使能, 定时器才会进行自减
      else if (tcfg_wen) begin
        timer_en <= wr_data[`EN];
      end
      // 如果定时器在进行自减，且减到1，开启定时器中断，再在下一个周期继续自减;如果periodic为0，下一个周期不自减
      else if(timer_en && (csr_tval == 32'b0)) begin
        csr_estat[11] <= 1'b1;
        timer_en <= wr_data[`PERIODIC];
      end
      // interrupt设置
      // csr_estat[9:2] <= interrupt;
      // 出发例外，更新ecode esubcode到stat
      if (excp_flush) begin
        csr_estat[`ESUBCODE] <= esubcode_in;
        csr_estat[`ECODE] <= ecode_in;
      end else if (estat_wen) begin
        csr_estat[1:0] <= wr_data[1:0];
      end
    end
  end

  // tid 初始化时设置编号
  always @(posedge clk) begin
    if (reset) begin
      csr_tid <= 32'b0;
    end else if (tid_wen) begin
      csr_tid <= wr_data;
    end
  end

  // tcfg 配置定时器
  always @(posedge clk) begin
    if (reset) begin
      csr_tcfg[`EN] <= 1'b0;
    end else if (tcfg_wen) begin
      csr_tcfg[`EN] <= wr_data[`EN];
      csr_tcfg[`PERIODIC] <= wr_data[`PERIODIC];
      csr_tcfg[`INITVAL] <= wr_data[`INITVAL];
    end
  end

  // ticlr 定制中断清除，第0位有用, 对第0位写1，清除时钟中断标记
  always @(posedge clk) begin
    if (reset) begin
      csr_ticlr <= 32'b0;
    end
  end

  // tval 仅可读不可写,软件可通过读取该寄存器来获知定时器当前的计数值
  always @(posedge clk) begin
    if (tcfg_wen) begin
      csr_tval <= {csr_tcfg[`INITVAL], 2'b0};
    end else if (timer_en) begin
      if (csr_tval != 32'b0) begin
        csr_tval <= csr_tval - 32'b1;
      end else if (csr_tval == 32'b0) begin
        csr_tval <= csr_tcfg[`PERIODIC] ? {csr_tcfg[`INITVAL], 2'b0} : 32'hffffffff;
      end
    end
  end

  // era 当触发例外时，触发例外的指令的PC将被记录在该寄存器中。
  always @(posedge clk) begin
    if (excp_flush) begin
      csr_era <= era_in;
    end else if (era_wen) begin
      csr_era <= wr_data;
    end
  end

  // eentry 低6位恒为0
  always @(posedge clk) begin
    if (reset) begin
      csr_eentry <= 32'b0;
    end else if (eentry_wen) begin
      csr_eentry[31:6] <= wr_data[31:6];
    end
  end

  always @(posedge clk) begin
    if (save0_wen) begin
      csr_save0 <= wr_data;
    end
  end

  always @(posedge clk) begin
    if (save1_wen) begin
      csr_save1 <= wr_data;
    end
  end

  always @(posedge clk) begin
    if (save2_wen) begin
      csr_save2 <= wr_data;
    end
  end

  always @(posedge clk) begin
    if (save3_wen) begin
      csr_save3 <= wr_data;
    end
  end




endmodule
