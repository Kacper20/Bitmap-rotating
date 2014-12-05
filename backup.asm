#BM:2
#sizeof_file:4
#nieważne:4
#offset_of_data:4
.data
        header:        .space 16
        path1:      .asciiz "/Users/kacper/Studia/Assembly/10.bmp"
        output: .asciiz "/Users/kacper/Studia/Assembly/out.bmp"
        hello: .asciiz " helloOne\n"
        hellozero: .asciiz " helloZERO\n"
        switch: .asciiz "switch\n"
        spa: .space 14
        mega: .space 300
.text 
#t1 - file descriptor(opening), pozniej sluzy do trzymania w ktorym pixelu bylismy dla danego wiersza
#t2 - adres zaalokowanej pamieci dla nowej bitmapy
#t3 - tymczasowy wskanik
#t0 - adres zaalokowanej pamieci przez nas, do trzymania input bitmapy.
#s0  - pamiec do zaalokowania(rozmiar), pozniej uzywany jako tymczasowy
#s1 - offset, pozniej tez uzywany jako tymczasowy


#s3 - szerokosc bitmapy(oryginalnej) i wysokosc zmienionej
#s4 - wysokosc bitmapy (oryginalnej) i szerokosc zmienionej.
#s5 = rozmiar wiersza orginalnego obrazka(po dodaniu paddingu)
#s6 - szerokosc bitmapy(w bajtach) po zmianach -

#s2, s7 - wolne, uzywane w ONE.
main:
      la   $a0,   path1
      li   $a2,   0
      li   $a1,   0 
      li   $v0,   13 #open file
      syscall 
      #przechowujemy deskryptor pliku w razie czego(t1)
      move    $t1,    $v0
      #przeczytac BM:
      move   $a0,   $t1
      li    $v0,   14  #read from file     
      la    $a1,    header   
      li    $a2,    2
      syscall    
      #przeczytanie rozmiaru pliku wejsciowego, aby skopiowac go do pamieci(alokacja), YOLO
      move   $a0,   $t1
      li    $v0,   14     
      la    $a1,    header   
      li    $a2,    4
      syscall 
      lw $s0, header
      
      #wszystko gra
      #ladujemy 4 bajty nieznaczace.
      move   $a0,   $t1
      li    $v0,   14  #read from file     
      la    $a1,    header   
      li    $a2,    4
      syscall 
      
      #ladujemy offset do $s1 - 
       move   $a0,   $t1
      li    $v0,   14  #read from file     
      la    $a1,    header   
      li    $a2,    4
      syscall 
      lw    $s1, header
      
      
      
      #Alokujemy pamiec, gdzie czytane beda informacje.
      #t0 zawiera adres zaalokowanej pamieci
      move    $a0,    $s0
      li    $v0, 9
      syscall
      move $t0 ,$v0
      
      #czytamy dane z pliku do naszego miejsca zaalokowanego na stosie.
      move   $a0,   $t1
      li    $v0,   14  #read from file     
      move    $a1,    $t0
      move    $a2,    $s0
      syscall 
      #***********t1, s0, s1 WOLNE**********
       #zamykamy plik, deskryptor $t1 jest wolny 
      move $a0, $t1
      li $v0, 16
      syscall
      #czytam szerokosc bitmapy - skladuje w s3
      lw $s3 , 4($t0) 
      #czytam wysokosc bitmapy - skladuje w s4
      lw $s4 , 8($t0)
      
      #s5 = rozmiar wiersza(w bajtach) orginalnego obrazka(po dodaniu paddingu)
      li $t3, 0
      add $t3, $s3, 31
      srl $t3, $t3, 5
      sll $t3, $t3, 2
      move $s5, $t3
      #t3 nadal to tymczasowy element
      # s3 rozmiar wiersza to w obroconej bitmapie
      #s6 to rozmiar wiersza obroconej kolumny(po dodaniu paddingu)
      li $t3, 0
      add $t3, $s4, 31
      srl $t3, $t3, 5
      sll $t3, $t3, 2
      move $s6, $t3
      
      #w 7 skladujemy rozmiar bitmapy, ktora powinnismy zaalokowac(wiersze * kolumny)
      mul $s7, $s6, $s3 
      #alokujemy pamiec na nowa bitmape.
      #t2 zawiera adres nowej pamieci
      move    $a0,    $s7
      li    $v0, 9
      syscall
      move $t2 ,$v0
      
      
     
       #ustawianie wskaznika pliku - jest ustawiony na tablice pikseli obecnie.
      sub $s1,	$s1, 14
      add $t0,	$t0, $s1 
      
      #t0 wskaznik ktorego nie zmieniamy!
      
      
      
      
      # w t1 mamy sobie tymczasowy wskaznik 
      
      move $t6, $s3 # bedziemy zmniejszali co 1. zaladowany jest iloscia bitow, ktore powinny byc w wierszu! :) 
      move $t1, $t0 # 
      lb $t4, ($t1) # do tymczasowego chodzenia po row
      li $t5, 1 #t5 bada w ktorym jestesmy wierszu
      li $t3, 0x80 # przygotowana maska
      #S0, S1 uzywamy
      
      # musimy ustawic na ostatni wiersz. wierszy jest tyle, ile kolumn oryginalnej. Wartosc trzymana jest w S3.
      #skaczymy za kazdym razem o padding dla nowej, czyli: s6
      
      sub $t7, $s3, 1
      mul $t7, $s6, $t7
      # jestemy teraz s0 na 1 bajcie gornego rogu. 
      move $s0, $t2

      #logi.

      
      add $s0, $s0, $t7
      move $s1, $s0 # s1 trzyma ta wartosc, abysmy mogli pozniej wracac!
      # poruszamy sie s0.
      # w kazdym kolejnym bicie (zero albo jeden) przeskakujemy odejmujemy od adresu dlugosc paddingu(s0-s6)
      li $t8, 0x80 #ladujemy maske do PISANIA
      b try_bits #zaczynamy chodzenie po tablicy pikseli
      
try_bytes:       
      li $t3, 0x80
      add $t1, $t1, 1#przejscie do kolejnego bajtu 
      lb $t4, ($t1)
try_bits:
      beqz $t6, next_row #jesli juz zrobilismy wszystkie bity - skaczemy do nastepnego wiersza
      sub $t6, $t6, 1  #kolejny bit
      and $t7, $t4, $t3 #maskujemy, sprawdzamy wynik
      beq $t7, $t3, one 
      
      
      
      ###LOGIIII.
      #wypisujemy na ktorym jestesmy pikselu i ktory ROW.
      #najpierw wiersz:
      move $a0, $t5
      li $v0, 1
      syscall
      #log piksel.
      sub $t7, $s3, $t6
      move $a0, $t7
      li $v0, 1
      syscall     
      la $a0, hellozero
      li $v0, 4
      syscall
      
      #wskaznik piszacy przesuwamy.
      sub $s0, $s0, $s6
      
      # znalezlismy zero
      srl $t3, $t3, 1
      beqz $t3, try_bytes # skonczyla nam sie maska, skaczemy do kolejnego bajtu.
      #nie skonczyla sie - jeszcze raz try_bits.
      #ZLE bo mamy skok warunkowy i bezwarunkowy - optymalizacja NA KONCU jesli zdarze.
      b try_bits
      
next_row:
      #zwiekszamy zmienna dotyczaca wskaznikaa.	
      add $t5, $t5, 1
      bgt $t5, $s4, end
      
      li $t7, 7
      and $t7 $t5, $t7
      
      beq $t7 1, switch_column
      # przesuwamy maske - i tutaj o jaka wartosc - przyjmujemy ze na razie o 1 zawsze(maks 8x8 bitmapa, POZNIEJ DO ZMIANY)
      #sprawdzamy, czy moze nie musimy przejsc piszacym do kolejnego bajtu (wieksze niz 8)
      #nadal mamy pozostac w tym samym bajcie, wiec wracamy do poczatku, maske przesuwamy o 1.
      move $s0, $s1 # powraca on do poczatku
      srl $t8, $t8, 1
      move $t6, $s3 # wartosc liczaca pixele w wierszu zostaje na nowo ustawiona
      add $t0, $t0, $s5  #przesuwamy wskaznik wiersza na kolejny, przeskakuje o wielkosc wiersza(z paddingiem)
      move $t1, $t0
      lb $t4, ($t1)
      li $t3, 0x80 # maska do sprawdzania bitow na nowo
      b, try_bits
      
switch_column:
	la $a0, switch
        li $v0, 4
      syscall 
	
	
	add $s1, $s1, 1
	move $s0, $s1
	li $t8, 0x80
	move $t6, $s3 # wartosc liczaca pixele w wierszu zostaje na nowo ustawiona
      	add $t0, $t0, $s5  #przesuwamy wskaznik wiersza na kolejny, przeskakuje o wielkosc wiersza(z paddingiem)
      	move $t1, $t0
      	lb $t4, ($t1)
      	li $t3, 0x80 # maska do sprawdzania bitow na nowo
      	b, try_bits
	
	
      
one:
 	#pod $t6 mamy ilosc pozostalych pikseli w wierszu. - 
 	#t7 to wartosc rowna iloscwszystkich-ilosc tych ktore pozostaly == obecnypiksel na ktorym bylismy w oryginalnej
 	# w t5 mamy ktory to byl wiersz wczesniej
 	# w t1 ktory to byl piksel
 	#s0  to  poczatek naszej tablicy pikseli w miejscu zaalokowanym wskazywanym przez t2(robimy tymczasowy wskaznik
 	#s1 mowi nam ktory to teraz ma byc wiersz
 	#s7 to licznik petli
 	#jesli mielismy y wiersz, bedzie to teraz y piksel
 	#jesli mielismy x piksel, bedzie to teraz (liczba kolumn w nowej - x) + 1 wiersz.	
 	
 	 #**********LOG*******    	 	     	 	
      move $a0, $t5
      li $v0, 1
      syscall 
      #log piksel.
      sub $t7, $s3, $t6
      move $a0, $t7
      li $v0, 1
      syscall 
      la $a0, hello
      li $v0, 4
      syscall
      lb $t9, ($s0)
      or $t9, $t9, $t8
      sb $t9, ($s0)
      #piszemy na piszacym, a na koncu go przesuwamy
      sub $s0, $s0, $s6 #przesuwamy piszacy!
      
      srl $t3, $t3, 1    	     	
      beqz $t3, try_bytes # skonczyla nam sie maska, skaczemy do kolejnego bajtu.
     	 #nie skonczyla sie - jeszcze raz try_bits.
      	#ZLE bo mamy skok warunkowy i bezwarunkowy - optymalizacja NA KONCU jesli zdarze.
      b try_bits    	
      
      
      
      #
end:         # tworzymy output bitmape.
la   $a0,   path1
li   $a2,   0
li   $a1,   0 
li   $v0,   13 #open file
syscall   
move    $t1,    $v0 #przechowujemy deskryptor pliku.
# Open (for writing) a file that does not exist
  li   $v0, 13       # system call for open file
  la   $a0, output     # output file name
  li   $a1, 1        # Open for writing (flags are 0: read, 1: write)
  li   $a2, 0        # mode is ignored
  syscall            # open a file (file descriptor returned in $v0)
  move $s6, $v0      # save the file descriptor 



      #ladujemy header!
       move   $a0,   $t1
      li    $v0,   14  #read from file     
      la    $a1,    mega   
      li    $a2,    2
      syscall 
      
       ###############################################################
  
  ###############################################################
  # Write to file just opened
  li   $v0, 15       # system call for write to file
  move $a0, $s6      # file descriptor 
  la   $a1, mega   # address of buffer from which to write
  li   $a2, 130       # hardcoded buffer length
  syscall            # write to file
  ###############################################################
  
  li   $v0, 15       # system call for write to file
  move $a0, $s6      # file descriptor 
  move   $a1, $t2   # address of buffer from which to write
  li   $a2, 40       # hardcoded buffer length
  syscall            # write to file
  # Close the file 
  li   $v0, 16       # system call for close file
  move $a0, $s6      # file descriptor to close
  syscall            # close file
  ###############################################################
      
      li	$v0,	10
      syscall

        