#include <stdio.h>
#include <stdlib.h>
#include <allegro5/allegro5.h>
#include "allegro5/allegro_image.h"
#include "allegro5/allegro_font.h"
#include <allegro5/allegro_audio.h>
#include <allegro5/allegro_acodec.h>
#include "allegro5/allegro_native_dialog.h"
#include "transformation_aff.h"
#include <allegro5/allegro_ttf.h>

//Pliki źródłowe
#define FILENAMEINTEST "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/Test.bmp"
#define FILENAMEIN "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/obraz1.bmp"
#define FONT  "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/Amatic-Bold.ttf"
#define TRIANGLE "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/triangle.png"
#define TRIANGLE1 "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/triangle1.png"
#define TRIANGLEN "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/trianglen.png"
#define TRIANGLE1N "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/trianglen1.png"
#define SQUARE "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/square.png"
#define BUTTON "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/Button.png"
#define SOUNDUP "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/buttonup.wav"
#define SOUNDDOWN "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/buttondown.wav"
#define SOUNDSTART "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/buttonstart.wav"
#define TEST "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/test.wav"
#define FILENAMEOUT1 "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/Transformed1.bmp"
#define FILENAMEOUT2 "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/Transformed2.bmp"
#define TESTFILE "/home/kajkacz/Dropbox/Studia/ARKO/2Projekt/Resources/NewTest1.csv"

//Stałe
#define HEADERSIZE 54
#define WINHEIGHT 500
#define WINWIDTH 900
#define BUFFERSIZE 128
#define STARTVALUEPARAM 1
#define PI 3.14159265

//Struktura do zaimportowania bitmapy
typedef struct BM{
  unsigned char* pixels;
  unsigned char* targetPixels;
  unsigned char fileHeader[HEADERSIZE];
  int height;
  int width;
  int padding;
  int error ;
}BitmapStr;

const float FPS = 60; //Prędkość odświeżana

enum MYKEYS { //enum na potrzeby użycia klawiatury
  KEY_ESC,KEY_SPACE
};

void appendToTheTestfile(FILE* testfile,int iteration,long int one,long int two){ //Na potrzeby testów, funkcja do dołączania wyników w formacie csv
fprintf(testfile,"%i ; %li ; %li\n",iteration,one,two);
fflush(testfile);
}
BitmapStr*  loadImage(char* filename)	//Funkcja ładująca bitmapę z podanego pliku
{
	unsigned char fileHeader[HEADERSIZE];
	FILE* filePtr = fopen(filename,"rb");					

	if(filePtr == NULL)
	{
		BitmapStr* error  = (BitmapStr*)malloc(sizeof(BitmapStr)); 	//Alokujemy miejsce na wypadek błędu
		printf("Error Opening File");
		error->error = 1;
		return error;
	}

	fread(fileHeader,sizeof(unsigned char), HEADERSIZE, filePtr); //Read the header into header array

		///READ DATA FROM FILE HEADER
	int width = *(int*)&fileHeader[18];	
	int height = *(int*)&fileHeader[22];
	int padding = 0 ;
	while((width*3+padding)%4!=0)
		padding++;
	int newWidth = width*3 + padding;

	unsigned char *targetPixels = (unsigned char*)malloc(width*height*6*sizeof(unsigned char));
  	//printf("\nSize of table : %li \n", width*height*6*sizeof(unsigned char) );
	unsigned char *pixels = (unsigned char*)malloc(width*height*3*sizeof(unsigned char));
	unsigned char *rowOfData = (unsigned char*)malloc(newWidth * sizeof(unsigned int));
	
	if(pixels == NULL || rowOfData == NULL)
	{
		BitmapStr* error  = (BitmapStr*)malloc(sizeof(BitmapStr)); 	//Alokujemy miejsce na wypadek błędu
		printf("Malloc Error :( \n");
		error->error = 1;
		return error;
	}
	int index=0;
	int i = 0;
	int j = 0;
	for(i=0; i<height;i++)
	{
		fread(rowOfData,sizeof(unsigned char),newWidth,filePtr);
		for(j = 0 ; j <width * 3; j+=3)
		{
		index =(i*3*width)+ j;
		pixels[index+0] = rowOfData[j+0];
		pixels[index+1] = rowOfData[j+1];
		pixels[index+2] = rowOfData[j+2];
		}
	}
  BitmapStr* bitmap = (BitmapStr*)malloc(sizeof(BitmapStr));

	//Zapisujemy dane po wczytaniu
  bitmap->targetPixels = targetPixels;
  bitmap->pixels = pixels;
  bitmap->height = height;
  bitmap->width = width;
  bitmap->padding = padding;
	
  for(i=0;i<HEADERSIZE;i++)
    bitmap->fileHeader[i]=fileHeader[i];
	free(rowOfData);
	fclose(filePtr);
	return bitmap ;
}
int initializeAllTheStuff()
{
  //Check for all sourcefiles
  if(!(al_filename_exists(SOUNDUP)||al_filename_exists(SOUNDDOWN)||al_filename_exists(SOUNDSTART)
  ||al_filename_exists(BUTTON)||al_filename_exists(SQUARE)||al_filename_exists(TRIANGLE1N)||
  al_filename_exists(TRIANGLEN)||al_filename_exists(TRIANGLE1)||al_filename_exists(TRIANGLE)||
  al_filename_exists(FONT)||al_filename_exists(FILENAMEIN)))
  {
    fprintf(stderr, "One of source files missing!\n");
    return -1;
  }

  if(!al_init()) {    //Initialize allegro, exit if you can't
     fprintf(stderr, "failed to initialize allegro!\n");
     return -1;
  }
  if(!al_install_audio()){
     fprintf(stderr, "failed to initialize audio!\n");
     return -1;
  }

  if(!al_init_acodec_addon()){
     fprintf(stderr, "failed to initialize audio codecs!\n");
     return -1;
  }
    if (!al_reserve_samples(1)){
    fprintf(stderr, "failed to reserve samples!\n");
    return -1;
  }
  if(!al_init_font_addon()||!  al_init_ttf_addon())
  {
    printf("Font not initialized \n");
    return -1;
  }
   if(!al_install_mouse()){
      fprintf(stderr, "failed to initialize mouse!\n");
      return -1;
   }
   if(!al_install_keyboard()) {
   fprintf(stderr, "failed to initialize the keyboard!\n");
    return -1;
  }//Initialize keyboard, exit if you can't
  if(!al_init_image_addon())
  {
  fprintf(stderr, "failed to initialize bmp service!\n");
  return -1;
  }
  return 0;
}
void saveImage(char* filename, BitmapStr* bmp, int whichImage)
{
  int i,j = 0;
  int paddingFlag=1;

  FILE *filePtr = fopen(filename,"wb");

     //printf("\n FileHeader :");
	for(i=0;i<HEADERSIZE;i++)
  {
  putc(bmp->fileHeader[i],filePtr); //Printf pixels
	//printf("%c",bmp->fileHeader[i]);
  }
  for(i=whichImage*3*bmp->width*bmp->height  ;i<whichImage*3*bmp->width*bmp->height + 3*bmp->width*bmp->height;i++)
	{

		if(i%(3*bmp->width)==0&& i!=0&&paddingFlag)
			{
			i--;
			paddingFlag = 0;
			for(j=0;j<bmp->padding;j++)
				putc(0,filePtr);
			}
		else
			{
			paddingFlag = 1;
			putc(bmp->targetPixels[i],filePtr); //Printf pixels
			}

	}
  //printf("\nSave limit : %li\n",3*bmp->width*bmp->height);
	fclose(filePtr);
}

int main(int argc, char *argv[])
{
	if (argc < 1)				// check if text is provided CHANGE TO 2!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	{
		printf("\nTransformation program failed - not enough arguments \nPlease run program as \" ./%s <Name of image to transform\" \n", argv[0]);
		return -1 ;
	}

    initializeAllTheStuff();
	//All the pointers , for loading assets etc., and then initializing and loading all of them 
    ALLEGRO_BITMAP *targetbmp2= NULL, *targetbmp1= NULL,*original= NULL,*triangle= NULL,*button= NULL, *triangle1= NULL,*trianglen= NULL, *triangle1n= NULL, *square= NULL;
    ALLEGRO_EVENT_QUEUE *event_queue = NULL;
  	ALLEGRO_DISPLAY *display = NULL,*targetDisplay= NULL;
		ALLEGRO_MONITOR_INFO *info = NULL;
    ALLEGRO_TIMER *timer = NULL;
    ALLEGRO_SAMPLE * buttonup = NULL;
    ALLEGRO_SAMPLE * buttondown = NULL;
    ALLEGRO_SAMPLE * buttonstart = NULL;
    ALLEGRO_FONT *font = al_load_ttf_font(FONT,32,0 );
    bool key[2] = { false, false };
    info = malloc(sizeof(ALLEGRO_MONITOR_INFO));
    int changed= 0,winx= 0,winy= 0,mouseSwitch= 0,redraw = true;
    bool exit=false,secondWindowOn=false;
    timer = al_create_timer(1.0 / FPS);
    event_queue = al_create_event_queue();
    if(!timer) {
        fprintf(stderr, "failed to create timer!\n");
        return -1;
      }
    if (!font){
     fprintf(stderr, "Could not load font.\n");
     return -1;
      }

    buttonup = al_load_sample( SOUNDUP );
    buttondown = al_load_sample(SOUNDDOWN);
    buttonstart = al_load_sample(SOUNDSTART);
    if (!buttonstart || ! buttondown || !buttonup){
          printf( "Audio clip sample not loaded!\n" );
          return -1;
       }

    al_get_monitor_info(0,info);
		al_set_new_window_position((info->y2 - info->y1 - WINHEIGHT)/2,(info->x2 - info->x1 - WINWIDTH)/2);
    display = al_create_display(WINWIDTH,WINHEIGHT); //Create display, exit if it does not work
    if(!display) {
       fprintf(stderr, "failed to create display!\n");
       return -1;
    }
    al_set_window_title(display, "Affine transform - original image");
    al_clear_to_color(al_map_rgb(0,204,204));	//Set the color of window
    if(!event_queue) {
		    fprintf(stderr, "failed to create event_queue!\n");
		  al_destroy_display(display);
		  return -1;
    }


    al_register_event_source(event_queue, al_get_timer_event_source(timer));
		al_register_event_source(event_queue, al_get_keyboard_event_source());
    al_register_event_source(event_queue, al_get_mouse_event_source());

		original = al_load_bitmap(FILENAMEIN);
    triangle = al_load_bitmap(TRIANGLE);
		triangle1 = al_load_bitmap(TRIANGLE1);
    trianglen = al_load_bitmap(TRIANGLEN);
		triangle1n = al_load_bitmap(TRIANGLE1N);
    button = al_load_bitmap(BUTTON);
    square = al_load_bitmap(SQUARE);

    if(!original || !triangle || !square||!triangle1 || !button|| !trianglen || !triangle1n) {
		      al_show_native_message_box(display, "Error", "Error", "Failed to load image!", NULL, ALLEGRO_MESSAGEBOX_ERROR);
		      al_destroy_display(display);
		      return 0;
		   }
	//Drawing the contents of the window
			 al_draw_bitmap(original,(WINWIDTH-al_get_bitmap_width(original))/2,(WINHEIGHT- al_get_bitmap_height(original))/2 + 130,0);
       double parameters[4];
       char parametersChar[4][4];
       parameters[0]=parameters[1]=parameters[2]=parameters[3]=STARTVALUEPARAM;

       al_draw_text(font,al_map_rgb(255,255,255), 1,0,0,"Please provide parameters for first transform!");
       al_draw_text(font,al_map_rgb(255,255,255), 1,32,0,"Parameter One : ");
       al_draw_text(font,al_map_rgb(255,255,255), 190,32,0,"1");
       al_draw_text(font,al_map_rgb(255,255,255), WINWIDTH/4,32,0,"Parameter Two : ");
       al_draw_text(font,al_map_rgb(255,255,255), WINWIDTH/4 +190,32,0,"1");
       al_draw_bitmap(triangle,132,32,0);
       al_draw_bitmap(triangle1,WINWIDTH/4-37,35,0);
       al_draw_bitmap(triangle,WINWIDTH/4+132,32,0);
       al_draw_bitmap(triangle1,WINWIDTH/2-37,35,0);

       al_draw_text(font,al_map_rgb(255,255,255), WINWIDTH/2,0,0,"Please provide parameters for second transform!");
       al_draw_text(font,al_map_rgb(255,255,255), WINWIDTH/2,32,0,"Parameter One : ");
       al_draw_text(font,al_map_rgb(255,255,255),  WINWIDTH/2 + 190,32,0,"1");
       al_draw_text(font,al_map_rgb(255,255,255), 3*WINWIDTH/4,32,0,"Parameter Two : ");
       al_draw_text(font,al_map_rgb(255,255,255), 3*WINWIDTH/4 + 190,32,0,"1");
       al_draw_bitmap(triangle,WINWIDTH/2+132,32,0);
       al_draw_bitmap(triangle1,3*WINWIDTH/4-37,35,0);
       al_draw_bitmap(triangle,3*WINWIDTH/4+132,32,0);
       al_draw_bitmap(triangle1,WINWIDTH-37,35,0);

       al_draw_bitmap(button,WINWIDTH/2-72,85,0);

       al_flip_display();

    al_start_timer(timer);
	
    BitmapStr* pixels = loadImage(FILENAMEIN);
		do	//Pętla w której dzieje się program
		{
			ALLEGRO_EVENT ev;
			al_wait_for_event(event_queue, &ev);
      if(ev.type == ALLEGRO_EVENT_TIMER) { //Obsługa posczególnych eventów
        redraw = true;
      }
      else if(ev.type == ALLEGRO_EVENT_DISPLAY_CLOSE) {
        exit = true;
      }
      else if(ev.type == ALLEGRO_EVENT_MOUSE_BUTTON_DOWN) //Obsługa myszki
      {

        if(ev.mouse.button == 1 && ev.mouse.y>85&&ev.mouse.y<205 && ev.mouse.x>WINWIDTH/2-72&&ev.mouse.y<WINWIDTH/2+60 && !secondWindowOn)
        {
          secondWindowOn = true;
          al_play_sample(buttonstart,1.0,0,1.0,ALLEGRO_PLAYMODE_ONCE,NULL);
          targetDisplay=al_create_display(al_get_bitmap_width(original)*2  + 100 , al_get_bitmap_height(original) + 100 );
          al_set_window_title(targetDisplay, "Affine transform - transformed image");
          al_clear_to_color(al_map_rgb(0,180,180));	//Set the color of window



                    parameters[1]=0;
                    parameters[0]=1;

                    // printf ("Sine : %f, cosine : %f \n",parameters[0],parameters[1]);
                     printf ( "\nPointers : Original : %li, Target : %li\n",(long int)pixels->pixels,(long int)pixels->targetPixels );
        long int  test;
        int i =0;
        //FILE* testfile=fopen(TESTFILE,"a");
        // for(i=0;i<3*pixels->width*pixels->height;i++)
        //   {
        //
              test = (long int) transformation(pixels->pixels,pixels->targetPixels,pixels->width,pixels->height,i, parameters[0],parameters[1],parameters[2],parameters[3]);
        //     appendToTheTestfile(testfile,i,(long int)pixels->pixels,test);
        //     //printf("\n\nWartość : %li\n\n", test);
        //     fflush(stdout);
        //   }
        // free(testfile);

      //  printf("\nWartość limitu iteracji : \n  -Z C -> %li\n  -Z Assemblera -> %li\n",(long int)3*pixels->width*pixels->height,test);
          saveImage(FILENAMEOUT1,pixels,0);
          saveImage(FILENAMEOUT2,pixels,1);

          al_draw_text(font,al_map_rgb(255,255,255),al_get_bitmap_width(original)/2   ,0,0,"Transform 1");
          al_draw_text(font,al_map_rgb(255,255,255),3*al_get_bitmap_width(original)/2 + 33 ,0,0,"Transform 2");

          printf("\nWartość zwrócona z assemblera :\n -> %li\n\n", test);
          fflush(stdout);

          targetbmp1= al_load_bitmap(FILENAMEOUT1);
          targetbmp2= al_load_bitmap(FILENAMEOUT2);
          if (!targetbmp1||!targetbmp2)
          {
            al_show_native_message_box(display,"Malloc Error!","Malloc Error!",
            "Error allocating memory to target bitmap",NULL,ALLEGRO_MESSAGEBOX_ERROR);
            al_destroy_display(targetDisplay);
            break;
          }
          al_draw_bitmap(targetbmp1,33,50,0);
          al_draw_bitmap(targetbmp2,al_get_bitmap_width(original) + 66,50,0);

        }
        if(ev.mouse.button == 1 && ev.mouse.y>30&&ev.mouse.y<66) //Obsługa myszki w zakresie przycisków
        {
          al_get_window_position(display,&winx,&winy);
          mouseSwitch = ev.mouse.x;
          //printf("\nPrzesunięcie ekranu (%i,%i),Położenie myszki bez przesunięcia (%i,%i) \n",winx,winy,ev.mouse.x,ev.mouse.y);
          switch(mouseSwitch){
            case 135 ... 175:
          //  if(parameters[0]<9)
              parameters[0]++;
            sprintf(parametersChar[0],"%f",parameters[0]);
            changed = 0;
            al_play_sample(buttonup,1.0,0.0,1.0,ALLEGRO_PLAYMODE_ONCE,NULL);
            al_draw_bitmap(trianglen,132,32,0);
            al_draw_bitmap(square, 170,32,0);
            al_draw_text(font,al_map_rgb(255,255,255), 190,32,0,parametersChar[0]);
            break;
            case WINWIDTH/4-37 ... WINWIDTH/4:
            if(parameters[0]>0)
              parameters[0]--;
            sprintf(parametersChar[0],"%f",parameters[0]);
            changed = 1;
            al_play_sample(buttondown,1.0,0,1.0,ALLEGRO_PLAYMODE_ONCE,NULL);
            al_draw_bitmap(triangle1n,WINWIDTH/4-37,35,0);
            al_draw_bitmap(square, 170,32,0);
            al_draw_text(font,al_map_rgb(255,255,255), 190,32,0,parametersChar[0]);
            break;
            case WINWIDTH/4+132 ... WINWIDTH/4 + 172:
            //if(parameters[1]<9)
              parameters[1]++;
            sprintf(parametersChar[1],"%f",parameters[1]);
            changed = 2;
            al_play_sample(buttonup,1.0,0,1.0,ALLEGRO_PLAYMODE_ONCE,NULL);
            al_draw_bitmap(trianglen, WINWIDTH/4 + 132,32,0);
            al_draw_bitmap(square, WINWIDTH/4 + 175,32,0);
            al_draw_text(font,al_map_rgb(255,255,255), WINWIDTH/4 +190,32,0,parametersChar[1] );
            break;
            case WINWIDTH/2-37 ... WINWIDTH/2:
            if(parameters[1]>0)
              parameters[1]--;
            sprintf(parametersChar[1],"%f",parameters[1]);
            changed = 3;
            al_play_sample(buttondown,1.0,0,1.0,ALLEGRO_PLAYMODE_ONCE,NULL);
            al_draw_bitmap(triangle1n,WINWIDTH/2-37,35,0);
            al_draw_bitmap(square, WINWIDTH/4 + 175,32,0);
            al_draw_text(font,al_map_rgb(255,255,255), WINWIDTH/4 +190,32,0,parametersChar[1]);
            break;

            case WINWIDTH/2 + 135 ... WINWIDTH/2 + 175:
            //if(parameters[2]<9)
              parameters[2]++;
            sprintf(parametersChar[2],"%f",parameters[2]);
            changed = 4;
            al_play_sample(buttonup,1.0,0,1.0,ALLEGRO_PLAYMODE_ONCE,NULL);
            al_draw_bitmap(trianglen,WINWIDTH/2+132,32,0);
            al_draw_bitmap(square, WINWIDTH/2 + 170,32,0);
            al_draw_text(font,al_map_rgb(255,255,255), WINWIDTH/2 + 190,32,0,parametersChar[2]);
            break;
            case 3*WINWIDTH/4-37 ... 3*WINWIDTH/4:
            if(parameters[2]>0)
            parameters[2]--;
            sprintf(parametersChar[2],"%f",parameters[2]);
            changed = 5;
            al_play_sample(buttondown,1.0,0,1.0,ALLEGRO_PLAYMODE_ONCE,NULL);
            al_draw_bitmap(triangle1n,3*WINWIDTH/4-37,35,0);
            al_draw_bitmap(square, WINWIDTH/2 + 170,32,0);
            al_draw_text(font,al_map_rgb(255,255,255), WINWIDTH/2 + 190,32,0,parametersChar[2]);
            break;
            case 3*WINWIDTH/4+132 ... 3*WINWIDTH/4 + 172:
            //if(parameters[3]<9)
            parameters[3]++;
            sprintf(parametersChar[3],"%f",parameters[3]);
            changed = 6;
            al_play_sample(buttonup,1.0,0,1.0,ALLEGRO_PLAYMODE_ONCE,NULL);
            al_draw_bitmap(trianglen,3*WINWIDTH/4 + 132,32,0);
            al_draw_bitmap(square, 3*WINWIDTH/4 + 175,32,0);
            al_draw_text(font,al_map_rgb(255,255,255), 3*WINWIDTH/4 +190,32,0,parametersChar[3] );
            break;
            case WINWIDTH-37 ... WINWIDTH:
            if(parameters[3]>0)
            parameters[3]--;
            sprintf(parametersChar[3],"%f",parameters[3]);
            changed = 7;
            al_play_sample(buttondown,1.0,0,1.0,ALLEGRO_PLAYMODE_ONCE,NULL);
            al_draw_bitmap(triangle1n,WINWIDTH-37,35,0);
            al_draw_bitmap(square, 3*WINWIDTH/4 + 175,32,0);
            al_draw_text(font,al_map_rgb(255,255,255), 3*WINWIDTH/4 +190,32,0,parametersChar[3]);
            break;
          }
          al_flip_display();
        }
      }
			else if(ev.type == ALLEGRO_EVENT_KEY_DOWN) {
         switch(ev.keyboard.keycode) {
            case ALLEGRO_KEY_SPACE:
               key[KEY_SPACE] = true;
               break;

            case ALLEGRO_KEY_ESCAPE:
            if(!targetDisplay)
               key[KEY_ESC] = true;
            else
            {
               al_destroy_display(targetDisplay);
               secondWindowOn=false;
            }
               break;
            default:
            break;
         }
      }
      else if(ev.type == ALLEGRO_EVENT_KEY_UP) {
         switch(ev.keyboard.keycode) {
            case ALLEGRO_KEY_SPACE:
               key[KEY_SPACE] = false;
               break;

            case ALLEGRO_KEY_ESCAPE:
               key[KEY_ESC] = false;
               break;
			 }}

      if(redraw && al_is_event_queue_empty(event_queue)) {
               redraw = false;
               switch(changed){
               case 0:
               al_draw_bitmap(square, 132,32,0);
               al_draw_bitmap(triangle,132,32,0);
              break;
              case 1:
               al_draw_bitmap(square, WINWIDTH/4-37,32,0);
               al_draw_bitmap(triangle1,WINWIDTH/4-37,35,0);
              break;
              case 2:
               al_draw_bitmap(square, WINWIDTH/4+132,32,0);
               al_draw_bitmap(triangle,WINWIDTH/4+132,32,0);
              break;
              case 3:
               al_draw_bitmap(square, WINWIDTH/2-37,32,0);
               al_draw_bitmap(triangle1,WINWIDTH/2-37,35,0);
              break;
              case 4:
               al_draw_bitmap(square, WINWIDTH/2+132,32,0);
               al_draw_bitmap(triangle,WINWIDTH/2+132,32,0);
              break;
              case 5:
               al_draw_bitmap(square, 3*WINWIDTH/4-37,32,0);
               al_draw_bitmap(triangle1,3*WINWIDTH/4-37,35,0);
              break;
              case 6:
               al_draw_bitmap(square, 3*WINWIDTH/4+132,32,0);
               al_draw_bitmap(triangle,3*WINWIDTH/4+132,32,0);
              break;
              case 7:
               al_draw_bitmap(square, WINWIDTH-37,32,0);
               al_draw_bitmap(triangle1,WINWIDTH-37,35,0);
             }
             changed = 8;
               al_flip_display();
            }

	}while(!key[KEY_ESC]&&!exit);

  al_destroy_display(display);
    return 0;
}
