all: testcpp testc

clean:
	rm -f testcpp
	rm -f testc
	rm -f *.json

testcpp: test.cpp
	bear -- g++ -Wall -std=c++11 -g -O0 -o testcpp test.cpp

testc: test.c
	bear --append -- gcc -Wall -g -O0 -o testc test.c -lm
