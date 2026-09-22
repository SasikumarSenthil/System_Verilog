class apb_transaction;
   bit psel;
   bit penable;
   rand bit pwrite;
   rand bit [31:0]pwdata;
   rand bit [31:0]paddr;

   bit [31:0]prdata;
   bit pready;
   bit pslverr;
   
   constraint paddr_1{!paddr inside{0,4,8,12};}
   constraint paddr_2{soft paddr inside {[16:256]};}
   function void print(input string tag);
      $display("[%0s] pwrite=%0b pwdata=%0h paddr=%0d prdata=%0h pready=%0b pslverr=%0b",tag,pwrite,pwdata,paddr,prdata,pready,pslverr);
   endfunction


endclass
