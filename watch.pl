#!/usr/bin/perl
use strict;
use warnings;
use LWP::Simple;

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
    $counts[$i]=int(rand(512))+32;
    $starts[$i]=int(rand(255-32))+32;
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
        $starts[$i]++;
        if($starts[$i]>255){
	   $starts[$i]=32;
  	};
      };
    };
    sleep 0.05
  };
}

sub numbers_to_current_time() {
};

# вывод времени
sub display_time() {
   my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
   my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
   if( $sec > 5 ){
#цветомузыка однако
#в рабочей версии нужно инвертировать условие
     printf "%s %02d ",$abbr[$mon],$mday;
     &random_symbols();
     &numbers_to_current_time();
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
