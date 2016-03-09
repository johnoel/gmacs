EXEC = gmacs
ARGS = -nox -iprint 50 

ifeq ($(SAFE),FALSE)
	DIST = ../../src/build/release/
else
	DIST = ../../src/build/debug/
endif

ifdef ComSpec
    RM=del /F /Q
else
    RM=rm -rf
endif

all: run

run: $(DIST)/$(EXEC)
	PATH=$(DIST):$(PATH) $(EXEC) $(ARGS)
	-R CMD BATCH plot.R

sim: $(DIST)/$(EXEC)
	PATH=$(DIST):$(PATH) $(EXEC) -ainp gmacs.par -sim 123

plot:
	R CMD BATCH plot.R

clean:
	@$(RM) -f $(EXEC)
	@$(RM) -f admodel.*
	@$(RM) -f $(EXEC)  $(EXEC).[brces]* $(EXEC).*[0123456789] *.rpt *.log variance
	$(RM) gmacs
	$(RM) admodel.cov
	$(RM) admodel.dep
	$(RM) admodel.hes
	$(RM) checkfile.rep
	$(RM) fmin.log
	$(RM) gmacs.b01
	$(RM) gmacs.b02
	$(RM) gmacs.b03
	$(RM) gmacs.bar
	$(RM) gmacs.cor
	$(RM) gmacs.eva
	$(RM) gmacs.log
	$(RM) gmacs.p01
	$(RM) gmacs.p02
	$(RM) gmacs.p03
	$(RM) gmacs.par
	$(RM) gmacs.r01
	$(RM) gmacs.r02
	$(RM) gmacs.r03
	$(RM) gmacs.rep
	$(RM) gmacs.std
	$(RM) gmacs_files_in.dat
	$(RM) gmacs_in.ctl
	$(RM) gmacs_in.dat
	$(RM) gradient.1
	$(RM) gradient.2
	$(RM) gradient.3
	$(RM) gradient.dat
	$(RM) mcout.rep
	$(RM) variance


clobber: clean
	@$(RM) -f *.par *_in.* *.rep
