class scoreboard;
   virtual apb_interface vif;
   mailbox msmbx;
   apb_transaction tr;
   
   bit[31:0]mem[0:256]; //local memory for comparision purpose
   bit[31:0] expected_prdata;

function new(mailbox msmbx,virtual apb_interface vif);
   this.vif=vif;
   this.msmbx=msmbx;
   apb_cov1=new();
   endfunction:new
   covergroup apb_cov1;
      CP1:coverpoint tr.paddr {bins b1={[0:127]};bins b2={32'hFFFF_FFFF};}
      CP2:coverpoint tr.pwdata{bins b3={[0:255]};}
      CP3:coverpoint tr.prdata{bins b4={[0:255]};}
      CP4:coverpoint tr.psel  {bins b5={1};ignore_bins b6={0};}
      CP5:coverpoint tr.pwrite{bins b7={1};bins b8={0};}
      CP2_X_CP5:cross CP2,CP5;
      CP3_X_CP5:cross CP3,CP5;
   endgroup:apb_cov1

   task run();
      forever begin
      if(vif.presetn==0)begin
         foreach(mem[i])mem[i]=i;
         @(posedge vif.pclk);
   end
   else begin
      msmbx.get(tr);
      apb_cov1.sample();
      tr.print("SCO");
      ->ev;
      if(tr.paddr<257)begin
      if(tr.pwrite) mem[tr.paddr]=tr.pwdata;
      else begin 
         expected_prdata=mem[tr.paddr];
         
      if(tr.prdata==expected_prdata)
         $display("PASS => Actual=%0h<=>%0h Expected",tr.prdata,expected_prdata);
      else
         $display("FAIL => Actual=%0h<=>%0h Expected",tr.prdata,expected_prdata);
   end
   end
   else $display("[SCO] PADDR is out of range, unable to do WRITE/READ");
   $display("==========================================================");
end
end
   endtask
endclass : scoreboard
