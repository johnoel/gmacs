EXEC = gmacs
ifeq ($(OPT),TRUE)
	DIST = ../../src/build/release/
else
	DIST = ../../src/build/debug/
endif
ARGS = -nox -iprint 50 
ts := $(shell /bin/date "+%Y-%m-%d---%H-%M-%S")
pn = gmpl_$(ts)
R_OPTS=--no-save --no-restore --no-init-file --no-site-file -e 'library(knitr); knit("plot.Rmd")'
plotscript = plot.md
all: run

$(EXEC): $(DIST)$(EXEC).tpl
	ln -sf $(DIST)$(EXEC) $@

$(DIST)$(EXEC).tpl:
	$(MAKE) --directory=../../src

run: $(EXEC)
	 ./$(EXEC) $(ARGS)

png: 
	R CMD BATCH plot.R

# Need to add test for existence of plot.md...
html:
	R ${R_OPTS} # -e 'library(knitr); knit("plot.Rmd")'
	pandoc -V geometry:margin=1in plot.md -o ${pn}.html 
	open ${pn}.html
pdf:
	R ${R_OPTS} # -e 'library(knitr); knit("plot.Rmd")'
	pandoc -V geometry:margin=1in plot.md -o ${pn}.pdf 
	open ${pn}.html

clean:
	rm -f $(EXEC)
	rm -f admodel.*
	rm -f plot.md
	rm -f plot.html
	rm -f $(EXEC)  $(EXEC).[brces]* $(EXEC).*[0123456789] *.rpt *.log variance

clobber: clean
	rm -f *.par *_in.* *.rep
