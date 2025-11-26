all: feed broker 
feed: feed.c
	gcc -o feed feed.c
broker: manager.c
	gcc -o broker manager.c
clean:
	rm -f feed broker *.o
