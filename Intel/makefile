CC = gcc
ASS = nasm -f elf64
CFLAGS = -g -Wall -m64
AFLAGS =  `pkg-config --cflags --libs allegro-5 allegro_acodec-5 allegro_audio-5 allegro_color-5 allegro_dialog-5 allegro_font-5 allegro_image-5 allegro_main-5 allegro_memfile-5 allegro_physfs-5 allegro_primitives-5 allegro_ttf-5`

all: main.o transformation_aff.o
	$(CC) $(CFLAGS) -o transform main.o transformation_aff.o $(AFLAGS) 

transformation_aff.o: transformation_aff.s
	$(ASS) -o transformation_aff.o transformation_aff.s

main.o: main.c transformation_aff.h
	$(CC)  $(CFLAGS) -c -o main.o main.c

clean:
	rm -f *.o
