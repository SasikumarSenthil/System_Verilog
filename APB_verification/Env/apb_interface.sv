interface apb_interface();
   logic pclk;
   logic presetn;
   logic psel;
   logic penable;
   logic pwrite;
   logic [31:0]paddr;
   logic[31:0]pwdata;
   logic[31:0]prdata;
   logic pready;
   logic pslverr;
   clocking dcb @(posedge pclk);
      output psel,penable,pwrite,paddr,pwdata;
      input prdata,pready,pslverr;
   endclocking

   clocking mcb @(posedge pclk);
      input psel,penable,pwrite,paddr,pwdata,prdata,pready,pslverr;
   endclocking

   property apb_protocol_validation;
      @(posedge pclk) $rose(psel) ##1 penable |-> ##[0:5] pready;
   endproperty

   apb_label:assert property (apb_protocol_validation)
                           $display("PASS: APB Validation Done.");
                     else  $display("FAIL: APB Validation Fail");

   //modport dmp(clocking dcb);
   //modport mmp(clocking mcb);
endinterface
     
