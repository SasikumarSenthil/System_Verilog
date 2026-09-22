INF=../env/apb_interface.sv
RTL=../rtl/apb_slave_design.sv
PKG=../test/apb_pkg.sv
TOP=../top/apb_top.sv
INC= +incdir+../test/ +incdir+../env/ +incdir+../top/
COVER=-cm line+cond+fsm+tgl+branch+assert

RUN=vcs -R -full64 -sverilog -kdb -debug_access+all ${RTL} ${INF} ${PKG} ${TOP} ${INC} ${COVER} 
run:
	${RUN}
runzero:
	${RUN} +zerowaitstate
tc1:
	${RUN} -cm_dir $(TEST1)_coverage.vdb +$(TEST1) -l $(TEST1).log 
TEST1=apb_write_read_test
tc2:
	${RUN} -cm_dir $(TEST2)_coverage.vdb +$(TEST2) -l $(TEST2).log 
TEST2=apb_write_test
tc3:
	${RUN} -cm_dir $(TEST3)_coverage.vdb +$(TEST3) -l $(TEST3).log 
TEST3=apb_read_test
tc4:
	${RUN} -cm_dir $(TEST4)_coverage.vdb +$(TEST4) -l $(TEST4).log
TEST4=apb_slverr_test
tc5:
	${RUN} -cm_dir $(TEST5)_coverage.vdb +$(TEST5) -l $(TEST5).log +zerowaitstate 
TEST5=apb_write_read_test_zerowait
tc6:
	${RUN} -cm_dir $(TEST6)_coverage.vdb +$(TEST6) -l $(TEST6).log +zerowaitstate 
TEST6=apb_write_test_zerowait
tc7:
	${RUN} -cm_dir $(TEST7)_coverage.vdb +$(TEST7) -l $(TEST7).log +zerowaitstate 
TEST7=apb_read_test_zerowait
tc8:
	${RUN} -cm_dir $(TEST8)_coverage.vdb +$(TEST8) -l $(TEST8).log +zerowaitstate 
TEST8=apb_slverr_test_zerowait
tc9:
	${RUN} -cm_dir $(TEST9)_coverage.vdb +$(TEST9) -l $(TEST9).log +zerowaitstate 
TEST9=apb_reset_test
tc10:
	${RUN} -cm_dir $(TEST10)_coverage.vdb +$(TEST10) -l $(TEST10).log +zerowaitstate 
TEST10=apb_reset_test_zerowait

tc: tc1 tc2 tc3 tc4 tc5 tc6 tc7 tc8 tc9 tc10
merge:
	urg -dir $(TEST1)_coverage.vdb $(TEST2)_coverage.vdb $(TEST3)_coverage.vdb $(TEST4)_coverage.vdb $(TEST5)_coverage.vdb $(TEST6)_coverage.vdb $(TEST7)_coverage.vdb $(TEST8)_coverage.vdb $(TEST9)_coverage.vdb $(TEST10)_coverage.vdb -format both -report merged_report -dbname merged.vdb
cov:
	verdi -cov -covdir ./merged.vdb &
final:tc merge cov

clean:
	rm -rf *.log *.vdb fle* v* simv* mer* nova* ucl* DVE* cs*
