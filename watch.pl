#!/usr/bin/perl
use strict;
use warnings;
use LWP::Simple;
use Switch;

# инициализация дисплея
sub display_init() {
   $| = 1; # включаем автоматическое сбрасывание буфера
   binmode(STDOUT,':raw'); # на всякий случай
   print pack("C",0x14); # отправляем дисплею программный сброс
   print pack("C",0x0e); # выключаем курсор
   print pack("CCCC",0x19,0x30,0xff,0x07); # яркость на минимум
   print pack("CCCCCCC",0x18,0xf6,0x00,0x04,0x44,0x40,0x00); # знак градуса
}

# переход в указанную позицию
sub display_goto() {
   my ($x, $y) = @_;
   my $pos = $x + $y*20;
   print pack("CC",0x1b,$pos);
}

# получение текущей погоды
sub get_weather() {
   my ($city) = @_;
   my $url = "http://www.google.com/ig/api?weather=$city";
   my $data = get $url or return undef;
   if($data =~ /<current_conditions>(.+?)<\/current_conditions>/) {
       my $weather = $1;
       my %info;
       while($weather =~ /<(.+?) data="(.+?)"\/>/g) {
           $info{$1} = $2;
       }
       return \%info;
   }
   return undef;
}

sub random_symbols() {
  my @counts = ( );
  my @starts = ( );
  my $i = 0;
  for($i=0;$i<6;$i++){
    $counts[$i]=int(rand(512))+32;#Это количество итераций - от 32 до 511+32
    $starts[$i]=int(rand(255-33))+33;#Мы же не хотим пробел?
  };
  my $flag=1;
  while($flag){

    &display_goto(7,0);
    printf "%c%c:%c%c:%c%c",$starts[0],$starts[1],$starts[2],$starts[3],$starts[4],$starts[5];
    $flag=0;
    for($i=0;$i<6;$i++){
      if($counts[$i]>0){
	$flag = 1;
        $counts[$i]--;
	switch($starts[$i]) {
		case [0xf2] {  $starts[$i]=0x21	}
		case [0x9f] {  $starts[$i]=0xe0	}
		else {	$starts[$i]++ }
	};
      };
    };
    sleep 0.05 #а здесь задержка, 0.05 секунды - это 20 раз в секунду, то есть
	#до 27 секунд на рандом (512+32)/20
  };
}

sub numbers_to_current_time() {
   my($sec,$min,$hour) = @_;
   my $flag = 1;
   while($flag){
     $flag = (($sec > 0 )&&($min > 0 ) && ($hour > 0));
     &display_goto( 7 , 0 );
     printf "%02d:%02d:%02d",$hour,$min,$sec;
     if($sec > 0 ){
	$sec--;
     };
     if($min >0 ){
	$min--;
     };
     if($hour >0 ){
	$hour--;
     };
     sleep 0.1;#Задержка на отсчёт - до 6 секунд в худшем случае
   };
};

# вывод времени
sub display_time() {
   my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
   my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
   if( $sec < 5 ){
#цветомузыка однако
     printf "%s %02d ",$abbr[$mon],$mday;
     &numbers_to_current_time($hour,$min,$sec);
     sleep 2;#Ну рандом прошёл. Дали впечатлиться
     &random_symbols();
   }else{
      printf "%s %02d %02d:%02d:%02d",$abbr[$mon],$mday,$hour,$min,$sec;
   };
}

# вывод температуры
sub display_weather {
   my $city = shift;
   my $info = &get_weather($city);
   if(!$info) {
       print "Err!";
       return;
   }
   my $temp = int($info->{temp_c});
   printf("%+3d%s",$temp,chr(0xf6));
}


&display_init();

my $last_weather_update = 0;

while(1) {

   # показываем время
   &display_goto(0,0);
   &display_time();

   # и погоду (примерно каждые 5 минут)
   if((time() - $last_weather_update) > 5*60) {
       &display_goto(16,0);
       &display_weather("Petersburg");
       $last_weather_update = time();
   }

   sleep 1;
}
