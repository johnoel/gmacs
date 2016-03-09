all:
	$(MAKE) --directory=./src

tests:
	#$(MAKE) --directory=./examples/demo
	#$(MAKE) --directory=./examples/bbrkc/TwoSex
	#$(MAKE) --directory=./examples/bbrkc/M1
	$(MAKE) --directory=./examples/smbkc SAFE=true

clean:
	$(MAKE) clean --directory=./src
	$(MAKE) --directory=./examples/smbkc clean
