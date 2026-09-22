class monitor;
   mailbox msmbx;
   virtual apb_interface vif;
   apb_transaction tr;

function new(mailbox msmbx,virtual apb_interface vif);
   this.vif=vif;
   this.msmbx=msmbx;
endfunction

task run();
   
   tr=new();
   forever begin
      @(vif.mcb)begin
         if(vif.mcb.psel && !vif.mcb.penable)begin
            @(vif.mcb);
            if(vif.mcb.psel&&vif.mcb.penable)begin
               if(!$test$plusargs("zerowaitstate"))wait(vif.mcb.pready);
               tr.psel     =vif.psel;
               tr.penable  =vif.penable;
               tr.pwrite   =vif.pwrite;
               tr.pwdata   =vif.pwdata;
               tr.paddr    =vif.paddr;
               tr.prdata   =vif.prdata;
               tr.pready   =vif.pready;
               tr.pslverr  =vif.pslverr;
            end
            tr.print("MON");
            msmbx.put(tr);
         end
      end
   end
endtask
endclass
