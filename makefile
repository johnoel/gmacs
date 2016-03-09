all:
	$(MAKE) clean
	$(MAKE) --directory=./src
	$(MAKE) tests

tests:
	#$(MAKE) --directory=./examples/demo
	#$(MAKE) --directory=./examples/bbrkc/TwoSex
	#$(MAKE) --directory=./examples/bbrkc/M1
	$(MAKE) --directory=./examples/smbkc SAFE=true

clean:
	$(MAKE) --directory=./src clean
	$(MAKE) --directory=./examples/smbkc clean
