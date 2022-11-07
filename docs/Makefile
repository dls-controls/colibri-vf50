include ../CONFIG

html: conf.py $(wildcard *.rst)
	$(SPHINX_BUILD) -nE -b html . html

clean:
	rm -rf html

.PHONY: clean
