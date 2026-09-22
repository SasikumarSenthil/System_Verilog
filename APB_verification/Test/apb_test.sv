`include "/home/dvft1326/apb_sv_project/test/apb_write_read_test.sv"
`include "/home/dvft1326/apb_sv_project/test/apb_write_test.sv"
`include "/home/dvft1326/apb_sv_project/test/apb_read_test.sv"
`include "/home/dvft1326/apb_sv_project/test/apb_slverr_test.sv"
`include "/home/dvft1326/apb_sv_project/test/apb_write_read_test_zerowait.sv"
`include "/home/dvft1326/apb_sv_project/test/apb_write_test_zerowait.sv"
`include "/home/dvft1326/apb_sv_project/test/apb_read_test_zerowait.sv"
`include "/home/dvft1326/apb_sv_project/test/apb_slverr_test_zerowait.sv"
`include "/home/dvft1326/apb_sv_project/test/apb_reset_test.sv"
`include "/home/dvft1326/apb_sv_project/test/apb_reset_test_zerowait.sv"
class apb_test;
   apb_environment env;
   virtual apb_interface vif;
   apb_write_read_test apb_wr_rd;
   apb_write_test apb_wr;
   apb_read_test apb_rd;
   apb_slverr_test apb_slverr;
   apb_write_read_test_zerowait apb_wr_rd_zero;
   apb_write_test_zerowait apb_wr_zero;
   apb_read_test_zerowait apb_rd_zero;
   apb_slverr_test_zerowait apb_slverr_zero;
   apb_reset_test apb_reset;
   apb_reset_test_zerowait apb_reset_zero;


   function new(virtual apb_interface vif);
      this.vif=vif;
   endfunction

      task run();
         env=new(vif);
         
          if($test$plusargs("apb_write_read_test_zerowait"))begin
            $display("time %0t inside APB_WRITE_READ_TEST_ZEROWAIT",$time);
            apb_wr_rd_zero=new(env.gdmbx);
            env.build();
            env.gen=apb_wr_rd_zero;
            env.run();
         end
         else if($test$plusargs("apb_write_test_zerowait"))begin
            $display("time %0t inside APB_WRITE_TEST_ZEROWAIT",$time);
            apb_wr_zero=new(env.gdmbx);
            env.build();
            env.gen=apb_wr_zero;
            env.run();
         end
         else if($test$plusargs("apb_read_test_zerowait"))begin
            $display("time %0t inside APB_READ_TEST_ZEROWAIT",$time);
            apb_rd_zero=new(env.gdmbx);
            env.build();
            env.gen=apb_rd_zero;
            env.run();
         end
         else if($test$plusargs("apb_slverr_test_zerowait"))begin
            $display("time %0t inside APB_SLVERR_TEST_ZEROWAIT",$time);
            apb_slverr_zero=new(env.gdmbx);
            env.build();
            env.gen=apb_slverr_zero;
            env.run();
         end
          else if($test$plusargs("apb_reset_test_zerowait"))begin
            $display("time %0t inside APB_RESET_TEST_ZEROWAIT",$time);
            apb_reset_zero=new(env.gdmbx);
            env.build();
            env.gen=apb_reset_zero;
            fork
            env.run();
            #100 vif.presetn=1'b0;
            #150 vif.presetn=1'b1;
            #850 vif.presetn=1'b0;
            #950 vif.presetn=1'b1;

            join
         end

         else if($test$plusargs("apb_reset_test"))begin
            $display("time %0t inside APB_RESET_TEST",$time);
            apb_reset=new(env.gdmbx);
            env.build();
            env.gen=apb_reset;
            fork
            env.run();
            #100 vif.presetn=1'b0;
            #150 vif.presetn=1'b1;
            #850 vif.presetn=1'b0;
            #950 vif.presetn=1'b1;

            join
         end
         else if($test$plusargs("apb_write_read_test"))begin
            $display("time %0t inside APB_WRITE_READ_TEST",$time);
            apb_wr_rd=new(env.gdmbx);
            env.build();
            #10
            env.gen=apb_wr_rd;
            env.run();
         end
         else if($test$plusargs("apb_write_test"))begin
            $display("time %0t inside APB_WRITE_TEST",$time);
            apb_wr=new(env.gdmbx);
            env.build();
            env.gen=apb_wr;
            env.run();
         end
         else if($test$plusargs("apb_read_test"))begin
            $display("time %0t inside APB_READ_TEST",$time);
            apb_rd=new(env.gdmbx);
            env.build();
            env.gen=apb_rd;
            env.run();
         end
         else if($test$plusargs("apb_slverr_test"))begin
            $display("time %0t inside APB_SLVERR_TEST",$time);
            apb_slverr=new(env.gdmbx);
            env.build();
            env.gen=apb_slverr;
            env.run();
         end 
      endtask
   endclass
