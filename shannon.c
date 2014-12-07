/* Decode one word and paste it to the buffer at target - the buffer
 * grows down (!) 
 *
 * Structure of the word: 29bits word, 3 bits mask
 *
 * 29 bits contains letters in shannon coding (4, 5 or 7 bits per letter)
 */
#define MASK 7

#define MAGIC_FOUR(magic, flag)	magic>>(8*sizeflag);

unsigned const char letter_queue[]=
  " rtoeani" "smcylgfw" "dvpbhxuqkzj34567891-0.2/;:!+@*,?";

extern char * iobuff;

static unsigned int put_char(char letter, unsigned char size, unsigned int word)
{
    *--iobuff=letter;
    return word<<size;
}

unsigned int sh_decode (unsigned int word)
{
  word &=-8;
  while (word>0){
    unsigned char sizeflag = (word >> 30);
    // word sizeflag
    unsigned char size = MAGIC_FOUR(0x07050404, sizeflag);
    // word size sizeflag
    char offset = MAGIC_FOUR(0xb0f80000, sizeflag);
    // word size word size / rstack offset
    unsigned char shift = 32 - size;
    // word size offset word shift -- letter
    unsigned char letter=letter_queue[(word >> shift) + offset];
    // word size letter -- word
    word=put_char(letter, size, word);
  }
  return 0;
}

/* For each letter, store at letter-' ' its size less 4 (upper two
   bits) and opcode (lower seven or less bits) 
 
   Table generated automatically from letter_queue using */

unsigned const char letter_size_code[]= {
  0x00, 0xfa, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xfd, 0xfb, 0xfe, 0xf3, 0xf5, 0xf7, 
  0xf4, 0xf2, 0xf6, 0xeb, 0xec, 0xed, 0xee, 0xef, 0xf0, 0xf1, 0xf9, 0xf8, 0x00, 0x00, 0x00, 0xff, 
  0xfc, 0x05, 0xe3, 0x52, 0xe0, 0x04, 0x56, 0x55, 0xe4, 0x07, 0xea, 0xe8, 0x54, 0x51, 0x06, 0x03, 
  0xe2, 0xe7, 0x01, 0x50, 0x02, 0xe6, 0xe1, 0x57, 0xe5, 0x53, 0xe9, 0x00, 0x00, 0x00, 0x00, 0x00, 
  0x00, 0x05, 0xe3, 0x52, 0xe0, 0x04, 0x56, 0x55, 0xe4, 0x07, 0xea, 0xe8, 0x54, 0x51, 0x06, 0x03, 
  0xe2, 0xe7, 0x01, 0x50, 0x02, 0xe6, 0xe1, 0x57, 0xe5, 0x53, 0xe9, 0x00, 0x00, 0x00, 0x00, 0x00};

unsigned int* sh_encode(unsigned int*buffer)
{
  unsigned char letter;
  unsigned int word=0;
  unsigned int shift=3;
  while ((letter=*iobuff++)> ' '){
    unsigned int size_code=letter_size_code[letter-' '];
    int size=(4+(size_code >> 6));
    if (size+shift>32) goto done;
    word += ((size_code & ((size_code >=0xc0)?0x7f:0x1f))<<shift);
    shift+=size;
  }
 done:
  word <<= (32-shift);
  *buffer++=word;
  if (letter>' '){
    iobuff--;
    return sh_encode(buffer);
  }
  while (*iobuff++ <= ' ');
  iobuff--;
  return buffer;
}

#if 0
int prep_table()
{
  unsigned const char *p;
  for (p=letter_queue; p< letter_queue+8; p++){
    letter_size_code[*p-' ']=(p-letter_queue);
    letter_size_code[toupper(*p)-' ']=(p-letter_queue);
  }
  for (;p< letter_queue+16; p++){
    letter_size_code[*p-' ']=0x40 | (p-letter_queue+8);
    letter_size_code[toupper(*p)-' ']=0x40 | (p-letter_queue+8);
  }
  for (;p< letter_queue+sizeof(letter_queue); p++){
    letter_size_code[*p-' ']=(0xc0 | (p-letter_queue+80));
    letter_size_code[toupper(*p)-' ']=(0xc0 | (p-letter_queue+80));
  }


  unsigned char c;
  for (c=0; c<96; c++){
    if (0 == (c & 0xf)) printf("\n");
    printf("0x%02x%s ", letter_size_code[c], ((c==95)?"};\n":", "));
  }

}
#endif
