class driver;
   apb_transaction tr;
   virtual apb_interface vif;
   mailbox gdmbx;

function new(mailbox gdmbx,virtual apb_interface vif);
   this.vif=vif;
   this.gdmbx=gdmbx;
endfunction
task initial_reset();
  vif.presetn=1'b0;
   #30;
  vif.presetn=1'b1;
endtask
task run();
initial_reset();
   forever begin
      gdmbx.get(tr);
      @(vif.dcb);
      vif.psel    <=0;  //IDLE state
      vif.penable <=0;
      @(vif.dcb);
      vif.psel    <=1;  //SET_UP state
      vif.penable <=0;
      vif.pwrite  <=tr.pwrite;
      vif.pwdata  <=tr.pwdata;
      vif.paddr   <=tr.paddr;
      @(vif.dcb);
      vif.psel    <=1;  //ACCESS state
      vif.penable <=1;
      tr.print("DRV");
      if(!$test$plusargs("zerowaitstate"))wait(vif.pready);
   end
endtask
endclass
