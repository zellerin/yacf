extern  __attribute__((regparm(1))) int* sh_encode(unsigned int* buffer);
const char*iobuff;

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

int old_c=0;

static int skip_spaces(void)
{
  while (*iobuff++<=' ');
  iobuff--;
}

int read_buffer(void)
{
  static unsigned char ibuff[40960];
  int data=read(0,  ibuff, 40900);
  if (data==0) return 0;
  ibuff[data-1]=' ';
  ibuff[data]='_';
  ibuff[data+1]=0;
  iobuff=ibuff;
}

int abuff[40960]; int i; int*buff=abuff, *nbuff;

typedef __attribute__((regparm(1))) int fn_t(int);
fn_t do_parse;

__attribute__((regparm(1))) int do_shift_parse(int color) 
{
  color &= 0xf0;
  color >>= 4;
  color *= 0x11;
  do_parse(color);
}

__attribute__((regparm(1))) int do_colon(int color)
{
    iobuff+=2;
    return do_parse(0x23);
}

__attribute__((regparm(1))) int do_semicolon(int color)
{
    buff=sh_encode(buff);
    if ((color&0xf)==5 || (color&0xf)==3) {
      buff[-1]+=(color & 0xf);
    } else {
      buff[-1]+=2;
      color=0x77;
    }
    return do_shift_parse(color);
}

__attribute__((regparm(1))) int do_evaluate(int color)
{
    iobuff+=2;
    return do_parse(0x77);
}


__attribute__((regparm(1))) int do_compile(int color)
{
    iobuff+=2;
    return do_parse(0x22);
}

__attribute__((regparm(1))) int do_start_comment(int color)
{
    iobuff+=2;
    old_c=color;
    return do_parse(0x55);
}

__attribute__((regparm(1))) int do_end_comment(int color)
{
    iobuff+=2;
    return do_shift_parse(old_c);
}

__attribute__((regparm(1))) int do_dump(int color)
{
  write(1, abuff, 4*(buff-abuff));
  return 0;
}

__attribute__((regparm(1))) int do_one_char_generic(int color)
{
  buff=sh_encode(buff);
  buff[-1]+=(color & 0xf);
  return do_shift_parse(color);
}

__attribute__((regparm(1))) int do_digit(int color)
{
  if ((color & 0xf)!=5) {
    *buff++=16*(*iobuff-'0')+1;
    iobuff+=2;
    return do_shift_parse(color);
  }
  return do_one_char_generic(color);
}

__attribute__((regparm(1))) int do_new_page(int color)
{
  while ((buff - abuff) & 0x7f) {*buff++=0;}
  iobuff+=2;
  return do_parse(color);
}


__attribute__((regparm(1))) int do_read_buffer(int color)
{
  write(1, abuff, 4*(buff-abuff));
  buff=abuff;
  read_buffer();
  do_parse(color);
}

static fn_t *const one_char_fns[]={
  [0 ... 95]=do_one_char_generic,
  ['_'-32]=do_read_buffer,
  [':'-32]=do_colon,
  [';'-32]=do_semicolon,
  ['['-32]=do_evaluate,
  [']'-32]=do_compile,
  ['('-32]=do_start_comment,
  [')'-32]=do_end_comment,
  ['%'-32]=do_new_page,
  [127-32]=do_dump,
  [16 ... 25]=do_digit
};

__attribute__((regparm(1))) int do_one_char_word(int color)
{
  fn_t * fn=one_char_fns[iobuff[0]-' '];
  return fn(color);
}

__attribute__((regparm(1))) int do_parse(int color)
{
  skip_spaces();
  if (iobuff[1]<=' '){
    return do_one_char_word(color);
  } else {
    /* Multi-character word */
    char* tailptr;
    int res=strtol(iobuff, &tailptr, 10);
    if ((color & 0xf)!=5 && *tailptr<=' '){
      *buff++=res*16+1;
      iobuff=tailptr;
      skip_spaces();
    } else if (iobuff[0]=='#' && iobuff[1]=='x') {
      res=strtol(iobuff+2, &tailptr, 16);
      *buff++=res*16+6;
      iobuff=tailptr;
      skip_spaces();
    } else {
      nbuff=sh_encode(buff);
      switch (*buff){
      case 0x19000000:
      case 0x4aae2000:
      case 0x6a0c8000:
      case 0xc6a40000:
	if ((color & 0xf)==7) color=(color &0xf0) | 4;
      }
      *buff+=(color & 0xf);
      buff=nbuff;
    }
    return do_shift_parse(color);
  }
}

int main()
{
  read_buffer();
  return do_parse(0x77);
}
