############################################################
all:
##	echo -e "\nFile Organization by [wc *.h *.cc]" >> code.txt
##	echo -e "  lines words bytes" >> code.txt
##	wc $(HEADER) $(SOURCE) >> code.txt      
##	echo -e "\f" >> code.txt
	cats -f define.v MieruEMB.v minilcd.v MipsCore.v init.v iocon.v *.ucf > code.txt
	a2ps --medium=a4 -f 5.6 code.txt -o  code.ps
	ps2pdf13 -sPAPERSIZE=a4 code.ps
	rm -f code.txt code.ps
