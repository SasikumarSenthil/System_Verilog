class apb_environment;
   virtual apb_interface vif;
   mailbox gdmbx=new();
   mailbox msmbx=new();
   generator gen;
   driver drv;
   monitor mon;
   scoreboard sco;
   function new(virtual apb_interface vif);
   this.vif=vif;
   endfunction
 task build();
    gen=new(gdmbx);
    drv=new(gdmbx,vif);
    mon=new(msmbx,vif);
    sco=new(msmbx,vif);
 endtask
task run();
  fork
   gen.run();
   drv.run();
   mon.run();
   sco.run();
join_none;
endtask
endclass
