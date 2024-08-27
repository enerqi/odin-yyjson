OS=$(shell uname)

ifeq ($(OS), Darwin)
all: darwin
else
all: unix
endif

unix:
	mkdir -p ../lib
	$(CC) -c -O2 -Os -fPIC -Dyyjson_api_inline='' yyjson.c
	$(AR) rcs ../lib/yyjson.a        yyjson.o
	#$(CC) -fPIC -shared -Wl,-soname=yyjson.so         -o ../lib/yyjson.so        yyjson.o
	rm *.o

darwin:
	mkdir -p ../lib
	$(CC) -arch x86_64 -c -O2 -Os -fPIC -Dyyjson_api_inline='' yyjson.c -o yyjson-x86_64.o -mmacosx-version-min=10.12
	$(CC) -arch arm64  -c -O2 -Os -fPIC -Dyyjson_api_inline='' yyjson.c -o yyjson-arm64.o -mmacosx-version-min=10.12
	lipo -create yyjson-x86_64.o yyjson-arm64.o -output ../lib/darwin/yyjson.a
	rm *.o
