
module abp_top;
import apb_pkg::*;
apb_interface vif();
apb_slave dut(.dif(vif));
apb_test testh;
initial begin
   vif.pclk=1'b0;
   forever #10 vif.pclk=~vif.pclk;
end
initial begin
   testh=new(vif);
   testh.run();
   #1500 $finish;
end
final begin
 //  $display("FINAL COVERAGE=%0.2f",testh.env.sco.apb_cov1.get_coverage());
end
endmodule
