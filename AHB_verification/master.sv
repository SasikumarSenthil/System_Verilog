`timescale 1ns/1ns

interface ahb_if(input logic clk);
  logic        hresetn;
  logic        hsel;
  logic        hwrite;
  logic [1:0]  htrans;
  logic [31:0] haddr;
  logic [2:0]  hsize;
  logic [2:0]  hburst;
  logic [31:0] hwdata;

  logic [1:0]  hresp;
  logic        hready;
  logic [31:0] hrdata;

  // Driver and monitor clocking blocks help avoid sampling/drive races.
  clocking drv_cb @(negedge clk);
    output hsel, hwrite, htrans, haddr, hsize, hburst, hwdata;
    input  hready, hresp, hrdata;
  endclocking

  clocking mon_cb @(posedge clk);
    input hresetn, hsel, hwrite, htrans, haddr, hsize, hburst, hwdata;
    input hready, hresp, hrdata;
  endclocking
endinterface


package ahb_tb_pkg;

  localparam logic [1:0] HTRANS_NONSEQ = 2'b00;
  localparam logic [1:0] HRESP_OKAY    = 2'b00;
  localparam logic [1:0] HRESP_ERROR   = 2'b01;

  typedef enum {TX_WRITE, TX_READ} tx_kind_e;

  class ahb_transaction;
    rand tx_kind_e    kind;
    rand bit [31:0]   addr;
    rand bit [2:0]    size;
    rand bit [31:0]   data;

    constraint legal_size_c {
      size inside {3'b000, 3'b001, 3'b010};
    }

    constraint legal_addr_c {
      addr inside {[0:252]};
    }

    function string convert2string();
      return $sformatf("%s addr=%08h size=%0d data=%08h",
                       kind.name(), addr, size, data);
    endfunction
  endclass


  class ahb_generator;
    mailbox #(ahb_transaction) gen2drv;

    function new(mailbox #(ahb_transaction) gen2drv);
      this.gen2drv = gen2drv;
    endfunction

    task run();
      ahb_transaction tr;

      // Directed write/read pairs make readback checks deterministic.
      tr = new();
      tr.kind = TX_WRITE;
      tr.addr = 32'h10;
      tr.size = 3'b000;
      tr.data = 32'h0000_00A5;
      gen2drv.put(tr);

      tr = new();
      tr.kind = TX_READ;
      tr.addr = 32'h10;
      tr.size = 3'b000;
      tr.data = 32'h0000_00A5;
      gen2drv.put(tr);

      tr = new();
      tr.kind = TX_WRITE;
      tr.addr = 32'h20;
      tr.size = 3'b001;
      tr.data = 32'h0000_BEEF;
      gen2drv.put(tr);

      tr = new();
      tr.kind = TX_READ;
      tr.addr = 32'h20;
      tr.size = 3'b001;
      tr.data = 32'h0000_BEEF;
      gen2drv.put(tr);

      tr = new();
      tr.kind = TX_WRITE;
      tr.addr = 32'h30;
      tr.size = 3'b010;
      tr.data = 32'h1234_5678;
      gen2drv.put(tr);

      tr = new();
      tr.kind = TX_READ;
      tr.addr = 32'h30;
      tr.size = 3'b010;
      tr.data = 32'h1234_5678;
      gen2drv.put(tr);
    endtask
  endclass


  class ahb_driver;
    virtual ahb_if vif;
    mailbox #(ahb_transaction) gen2drv;

    function new(virtual ahb_if vif,
                 mailbox #(ahb_transaction) gen2drv);
      this.vif = vif;
      this.gen2drv = gen2drv;
    endfunction

    task reset_signals();
      vif.drv_cb.hsel   <= 1'b0;
      vif.drv_cb.hwrite <= 1'b0;
      vif.drv_cb.htrans <= HTRANS_NONSEQ;
      vif.drv_cb.haddr  <= '0;
      vif.drv_cb.hsize  <= 3'b010;
      vif.drv_cb.hburst <= 3'b000;
      vif.drv_cb.hwdata <= '0;
    endtask

    task drive_one(ahb_transaction tr);
      int cycles;

      // The DUT checks the request, decodes it, then performs the transfer.
      @(vif.drv_cb);
      vif.drv_cb.hsel   <= 1'b1;
      vif.drv_cb.hwrite <= (tr.kind == TX_WRITE);
      vif.drv_cb.htrans <= HTRANS_NONSEQ;
      vif.drv_cb.haddr  <= tr.addr;
      vif.drv_cb.hsize  <= tr.size;
      vif.drv_cb.hburst <= 3'b000;
      vif.drv_cb.hwdata <= tr.data;

      // Keep the request stable while the DUT advances through its FSM.
      cycles = 0;
      do begin
        @(vif.drv_cb);
        cycles++;
        if (cycles > 8)
          $fatal(1, "Driver timeout waiting for hready: %s",
                 tr.convert2string());
      end while (vif.drv_cb.hready !== 1'b1);

      // Return bus to idle before the next transaction.
      reset_signals();
      repeat (2) @(vif.drv_cb);
    endtask

    task run();
      ahb_transaction tr;

      reset_signals();
      forever begin
        gen2drv.get(tr);
        drive_one(tr);
      end
    endtask
  endclass


  class ahb_monitor;
    virtual ahb_if vif;
    mailbox #(ahb_transaction) mon2scb;

    function new(virtual ahb_if vif,
                 mailbox #(ahb_transaction) mon2scb);
      this.vif = vif;
      this.mon2scb = mon2scb;
    endfunction

    task run();
      ahb_transaction observed;

      forever begin
        @(vif.mon_cb);
        if (vif.mon_cb.hresetn &&
            vif.mon_cb.hready === 1'b1 &&
            vif.mon_cb.hsel) begin
          observed = new();
          observed.kind = vif.mon_cb.hwrite ? TX_WRITE : TX_READ;
          observed.addr = vif.mon_cb.haddr;
          observed.size = vif.mon_cb.hsize;
          observed.data = vif.mon_cb.hwrite
                        ? vif.mon_cb.hwdata
                        : vif.mon_cb.hrdata;
          mon2scb.put(observed);
        end
      end
    endtask
  endclass


  class ahb_scoreboard;
    mailbox #(ahb_transaction) mon2scb;
    bit [7:0] model_mem [0:255];
    int checked;

    function new(mailbox #(ahb_transaction) mon2scb);
      this.mon2scb = mon2scb;
      checked = 0;
      foreach (model_mem[i])
        model_mem[i] = '0;
    endfunction

    function automatic bit [31:0] expected_read(
      bit [31:0] addr,
      bit [2:0] size
    );
      bit [31:0] value;
      value = '0;
      case (size)
        3'b000: value[7:0]   = model_mem[addr];
        3'b001: begin
          value[7:0]   = model_mem[addr];
          value[15:8]  = model_mem[addr+1];
        end
        3'b010: begin
          value[7:0]   = model_mem[addr];
          value[15:8]  = model_mem[addr+1];
          value[23:16] = model_mem[addr+2];
          value[31:24] = model_mem[addr+3];
        end
      endcase
      return value;
    endfunction

    task run();
      ahb_transaction tr;
      bit [31:0] expected;

      forever begin
        mon2scb.get(tr);

        if (tr.kind == TX_WRITE) begin
          case (tr.size)
            3'b000: model_mem[tr.addr] = tr.data[7:0];
            3'b001: begin
              model_mem[tr.addr]   = tr.data[7:0];
              model_mem[tr.addr+1] = tr.data[15:8];
            end
            3'b010: begin
              model_mem[tr.addr]   = tr.data[7:0];
              model_mem[tr.addr+1] = tr.data[15:8];
              model_mem[tr.addr+2] = tr.data[23:16];
              model_mem[tr.addr+3] = tr.data[31:24];
            end
          endcase
        end else begin
          expected = expected_read(tr.addr, tr.size);

          case (tr.size)
            3'b000: if (tr.data[7:0] !== expected[7:0])
              $error("Byte read mismatch at %08h: expected %02h got %02h",
                     tr.addr, expected[7:0], tr.data[7:0]);

            3'b001: if (tr.data[15:0] !== expected[15:0])
              $error("Halfword read mismatch at %08h: expected %04h got %04h",
                     tr.addr, expected[15:0], tr.data[15:0]);

            3'b010: if (tr.data !== expected)
              $error("Word read mismatch at %08h: expected %08h got %08h",
                     tr.addr, expected, tr.data);
          endcase
        end

        checked++;
        $display("Scoreboard checked transaction %0d: %s", checked,
                 tr.convert2string());
      end
    endtask
  endclass

endpackage


module tb_ahb_slave;
  import ahb_tb_pkg::*;

  logic clk = 1'b0;
  always #5 clk = ~clk;

  ahb_if bus(clk);

  ahb_slave dut (
    .clk     (clk),
    .hwdata  (bus.hwdata),
    .haddr   (bus.haddr),
    .hsize   (bus.hsize),
    .hburst  (bus.hburst),
    .hresetn (bus.hresetn),
    .hsel    (bus.hsel),
    .hwrite  (bus.hwrite),
    .htrans  (bus.htrans),
    .hresp   (bus.hresp),
    .hready  (bus.hready),
    .hrdata  (bus.hrdata)
  );

  mailbox #(ahb_transaction) gen2drv = new();
  mailbox #(ahb_transaction) mon2scb = new();

  ahb_generator   gen;
  ahb_driver      drv;
  ahb_monitor     mon;
  ahb_scoreboard  scb;

  initial begin
    bus.hresetn = 1'b0;
    bus.hsel    = 1'b0;
    bus.hwrite  = 1'b0;
    bus.htrans  = HTRANS_NONSEQ;
    bus.haddr   = '0;
    bus.hsize   = 3'b010;
    bus.hburst  = 3'b000;
    bus.hwdata  = '0;

    repeat (3) @(negedge clk);
    bus.hresetn = 1'b1;

    gen = new(gen2drv);
    drv = new(bus, gen2drv);
    mon = new(bus, mon2scb);
    scb = new(mon2scb);

    fork
      mon.run();
      scb.run();
      drv.run();
      gen.run();
    join_none

    wait (scb.checked == 6);
    $display("PASS: all %0d transactions checked.", scb.checked);
    $finish;
  end
endmodule
