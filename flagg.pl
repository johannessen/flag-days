#! /opt/perlbrew-bin/perl
use 5.028;
use Mojolicious::Lite;
use utf8;

use Date::Gregorian qw(:weekdays :months);
use Astro::Sunrise qw(:constants);
use DateTime;
use DateTime::TimeZone;

#plugin 'DefaultHelpers';

my $DEFAULT_ALT = 6;

sub flag_countries {
	my $c = shift;
	return ("NO", "DE") if defined $c->param('de');
	return ("NO");
}

sub flag_occasions {
	my $c = shift;
	my $country = shift;
	
	my @today = ();
	if ( defined $c->param('today') ) {
		my (undef, $m, $d) = Date::Gregorian->new->set_today->get_ymd;
		@today = (
			{ month => $m, day => $d, name => "(today)" },
		);
	}
	
	if ($country =~ m/NO/i) {
		return (
			@today,
			{ month => JANUARY,  day =>  1, name => "1. nyttårsdag", wiki_en => "New_Year%27s_Day" },
			{ month => JANUARY,  day => 21, name => "H.K.H. Prinsesse Ingrid Alexandra", wiki_en => "Princess_Ingrid_Alexandra_of_Norway" },
			{ month => FEBRUARY, day =>  6, name => "Samefolkets dag", wiki_en => "S%C3%A1mi_National_Day" },
			{ month => FEBRUARY, day => 21, name => "H.M. Kong Harald V", wiki_en => "Harald_V_of_Norway" },
			{ easter => 0, name => "1. påskedag", wiki_en => "Easter" },
			{ easter => 7*7, name => "1. pinsedag", wiki_en => "Pentecost" },
			{ month => MAY,      day =>  1, name => "Offentlig høytidsdag", wiki_en => "International_Workers%27_Day" },
			{ month => MAY,      day =>  8, name => "Frigjøringsdagen", wiki_en => "Victory_in_Europe_Day" },
			{ month => MAY,      day => 17, name => "Grunnlovsdagen", wiki_en => "Norwegian_Constitution_Day" },
			{ month => JUNE,     day =>  7, name => "Unionsoppløsningen", wiki_en => "Dissolution_of_the_union_between_Norway_and_Sweden" },
			{ month => JULY,     day =>  4, name => "H.M. Dronning Sonja", wiki_en => "Queen_Sonja_of_Norway" },
			{ month => JULY,     day => 20, name => "H.K.H. Kronprins Haakon Magnus", wiki_en => "Haakon,_Crown_Prince_of_Norway" },
			{ month => JULY,     day => 29, name => "Olsokdagen", wiki_en => "Olsok" },
			{ month => AUGUST,   day => 19, name => "H.K.H. Kronprinsesse Mette-Marit", wiki_en => "Mette-Marit,_Crown_Princess_of_Norway" },
			{ month => DECEMBER, day => 25, name => "1. juledag", wiki_en => "Christmas" },
			# + Dagen for stortingsvalg
		);
	}
	elsif ($country =~ m/DE/i) {
		return (
			@today,
			{ month => JANUARY,  day => 27, name => "Tag des Gedenkens an die Opfer des Nationalsozialismus", halfstaff => 1, wiki_en => "International_Holocaust_Remembrance_Day" },
			{ month => MAY,      day =>  1, name => "Tag der Arbeit", wiki_en => "International_Workers%27_Day" },
			{ month => MAY,      day =>  9, name => "Europatag", wiki_en => "Europe_Day" },
			{ month => MAY,      day => 23, name => "Jahrestag der Verkündung des Grundgesetzes", wiki_en => "Basic_Law_for_the_Federal_Republic_of_Germany" },
			{ month => JUNE,     day => 17, name => "Jahrestag des 17. Juni 1953", wiki_en => "East_German_uprising_of_1953" },
			{ month => JULY,     day => 20, name => "Jahrestag des Attentats vom 20. Juli 1944", wiki_en => "20_July_plot" },
			{ month => OCTOBER,  day =>  3, name => "Tag der Deutschen Einheit", wiki_en => "German_Unity_Day" },
			{ advent => -2*7, name => "Volkstrauertag", halfstaff => 1, wiki_en => "Volkstrauertag" },
			# + Tag der Wahl zum Deutschen Bundestag
			# + Tag der Wahl zum Europäischen Parlament
		);
	}
	else {
		die "Flag occasions for country '$country' not available";
	}
}

sub flag_order {
	my $c = shift;
	my $country = shift;
	return $country;
# 	my @countries = flag_countries($c);
# 	my $num = 0;
# 	for my $a_country ( @countries ) {
# 		last if $a_country eq $country;
# 		$num++;
# 	}
# 	return $num;
}

sub flag_occasions_for {
	my $c = shift;
	my $year = shift;
	
}

sub _occasions_missing {
	my $c = shift;
	my $flag_days = shift;
	my $occasions = shift;
	my $keys = shift;
	
	my @countries = flag_countries($c);
	my %not_present = ();
	foreach my $country ( @countries ) {
		my $max = $occasions->{$country} - 1;
		$not_present{$country} = {};
		foreach my $id ( 0 .. $max ) {
			$not_present{$country}->{$id} = 1;
		}
	}
	
	foreach my $key ( @$keys ) {
		my $country = $flag_days->{$key}->{country};
		my $id = $flag_days->{$key}->{id};
		$not_present{$country}->{$id} = 0;
	}
	foreach my $country ( sort keys %not_present ) {
		foreach my $id ( sort keys %{$not_present{$country}} ) {
			return 1 if $not_present{$country}->{$id};
		}
	}
	return 0;
}

sub flag_days {
	my $c = shift;
	
	# We'd like to list one full year of flag days, starting today.
	# Additionally, we'd like the most recent flag day from the past
	# (for comparison).
	
	# Determine the years of interest. This code assumes 1/1 is a flag day.
	my $today = Date::Gregorian->new->set_today;
	my ($today_y, $today_m, $today_d) = $today->get_ymd;
	my @years = ($today_y, $today_y + 1);
	@years = ($today_y - 1, $today_y) if $today_m == JANUARY && $today_d == 1;
	
	# Get ALL flag days from those years.
	my %flag_days = ();
	my $occasions = {};
	for my $year (@years) {
		my $easter = $today->new->set_easter($year);
		my $advent = $today->new->set_ymd($year, DECEMBER, 25)->set_weekday(SUNDAY, '<')->add_days(-3*7);
		for my $country (flag_countries($c)) {
			my $occasion_counter = 0;
			for my $o (flag_occasions($c, $country)) {
				my $flag_day;
				$flag_day = $today->new->set_ymd($year, $o->{month}, $o->{day}) if defined $o->{month};
				$flag_day = $easter->new->add_days($o->{easter}) if defined $o->{easter};
				$flag_day = $advent->new->add_days($o->{advent}) if defined $o->{advent};
				next unless $flag_day;
				my $key = sprintf "%04d-%02d-%02d-%s", $flag_day->get_ymd, flag_order($c, $country);
				$flag_days{$key} = { date => $flag_day, name => $o->{name}, country => $country, id => $occasion_counter++ };
				$flag_days{$key}->{fixed} = defined $o->{month};
				$flag_days{$key}->{wiki_en} = $o->{wiki_en} if defined $o->{wiki_en};
			}
			$occasions->{$country} = $occasion_counter;
		}
	}
	
	# Filter down the flag days to those days that interest us, starting with today as the first day.
	my @countries = flag_countries($c);
	my @keys_all = sort keys %flag_days;
	my $key_first;
	for my $key (@keys_all) {
		if ( $flag_days{$key}->{date}->compare($today) >= 0 ) {
			$key_first = $key;
			last;
		}
	}
	my @keys = ();
	for (my $i = 0; $i < @keys_all; $i++) {
		my $key = $keys_all[$i];
		next if $key lt $key_first;
		unshift @keys, $keys_all[$i - 1] if ! @keys && $i > 0;  # bug: if that particular date has more than one occasion, all need to be added
		my $m = _occasions_missing($c, \%flag_days, $occasions, \@keys);
		last if ! $m;
		push @keys, $key;
	}
	
	# Return filtered result.
	my $filtered_days = {};
	foreach my $key (@keys) {
		$filtered_days->{$key} = $flag_days{$key};
	}
	return $filtered_days;
}

sub sun_rise_set {
	my $c = shift;
	my $date = shift;
	my $position = shift;
	my $altitude = shift // $DEFAULT_ALT;
	
	my ($year, $month, $day) = $date->get_ymd;
	
	my $dt = DateTime->from_object(object => $date);
	my $tz = DateTime::TimeZone->new( name => 'Europe/Oslo' );
	my $offset = $tz->offset_for_datetime($dt);
	
	my ($sunrise, $sunset) = Astro::Sunrise::sunrise( {
		year => $year, month => $month, day => $day,
		@$position,
		tz => 1, isdst => $offset / 3600 - 1,  # tz+isdst = UTC offset in hours
		precise => 1,
		alt => DEFAULT + $altitude,
	} );
	
	return ($sunrise, $sunset);
}

sub flag_hoist_lower {
	my $c = shift;
	my $date = shift;
	my $position = shift;
	my $altitude = shift;
	
	my ($sunrise, $sunset) = sun_rise_set($c, $date, $position, $altitude);
#	my (undef, $month, undef) = $date->get_ymd;
#	my $winter = $month == NOVEMBER || $month == DECEMBER || $month == JANUARY || $month == FEBRUARY;
	
	$sunrise =~ s/://;
	$sunrise = "1000" if $sunrise > 1000;
#	$sunrise = "0900" if $sunrise < 900 && $winter;
	$sunrise = "0800" if $sunrise < 800;
	$sunrise =~ s/(\d\d)(\d\d)/$1:$2/;
	$sunset =~ s/://;
	$sunset = "1500" if $sunset < 1500;
	$sunset = "2100" if $sunset > 2100;
	$sunset =~ s/(\d\d)(\d\d)/$1:$2/;
	
	return ($sunrise, $sunset);
}


get '' => sub {
	my $c = shift;
	
	my $position = [ lon => 5.8, lat => 60.0 ];
	my $altitude = $c->param('alt') // $DEFAULT_ALT;
	$altitude =~ s/,/./;
	$altitude = 0 + $altitude;
	
	my $flag_days = flag_days($c);
	
	foreach my $key (sort keys %$flag_days) {
		my $flag_day = $flag_days->{$key};
		my ($hoist, $lower) = flag_hoist_lower($c, $flag_day->{date}, $position, $altitude);
		$flag_day->{hoist} = $hoist;
		$flag_day->{lower} = $lower;
	}
	
	foreach my $key (sort keys %$flag_days) {
		my $flag_day = $flag_days->{$key};
		my ($year) = $flag_day->{date}->get_ymd;
		$year =~ s/^20/’/;
		$flag_day->{year_short} = $year;
	}
	
	my $today = Date::Gregorian->new->set_today;
	my $next_flag_date;
	foreach my $key (sort keys %$flag_days) {
		my $flag_day = $flag_days->{$key};
		$flag_day->{days_until} = $today->get_days_until($flag_day->{date});
		$next_flag_date = $flag_day->{date} if ! $next_flag_date && $flag_day->{days_until} >= 0 && $flag_day->{wiki_en};  # no wiki link => "today" entry
		if ($next_flag_date && $next_flag_date->compare($flag_day->{date}) == 0) {
			$flag_day->{next} = 1;
		}
	}
	
	
	$c->render(
		template => 'flag',
		flag_days => $flag_days,
		altitude => $altitude,
	);
};

app->start;

__DATA__

@@ flag.html.ep
<!DOCTYPE html>
<title>Flag Days</title>
<style>
h1 { font-size: 1.5em; }
th { font-weight: normal; font-size: .8em; text-align: left; }
th, td { padding-right: .8em; }
tr.next { font-weight: bold; }
tr.next td:first-child a { padding-right: 24px; background: url(data:image/gif;base64,R0lGODlhEAAMAJEDAP8AAM3Z5wBokP%2F%2F%2FyH5BAEAAAMALAAAAAAQAAwAAAIkhB0Sxw25nINyqhqyVronAYbi6EFl1lAVo67I5b6RM9T2jQ8FADs%3D) no-repeat right center; }
form input[name=alt] { text-align: center; }
</style>

<h1>Flag Days</h1>

<p>Ølve generally observes the flag days given in Norwegian law:


<table>
<tr><th>Occasion <th>Date <th>Hoist <th>Lower
% my @months = qw(January February March April May June July August September October November December);
% my $i = 0;
% for my $key ( sort keys %$flag_days ) {
%  my $f = $flag_days->{$key};
%  my ($y, $m, $d) = $f->{date}->get_ymd;

<tr<%= $f->{next} ? " class=next" : "" %>>
%  if ($f->{wiki_en}) {
<td><a href="https://en.wikipedia.org/wiki/<%= $f->{wiki_en} %>"><%= $f->{name} %>
%  } else {
<td><%= $f->{name} %>
%  }
<td><%= $d %> <%= $months[$m - 1] %> <%= $f->{fixed} && ($m != 1 || $d != 1) && $i++ ? "" : $f->{year_short} %>
<td><%= $f->{hoist} %>
<td><%= $f->{lower} %>
% }

<tr><td>Dagen for stortingsvalg <td colspan=3><em>varies</em>
</table>

<p>Note that the hoist and lower times given in this table are based on the sunrise and sunset times for Ølve as calculated from an almanac for <%= $altitude %>° of terrain altitude. Depending on your location in Ølve and the terrain around you, the sun will rise and set later or earlier, in some cases up to several hours later or earlier.

<form method=GET action=""><p>Assume a terrain altitude of <input type=text name=alt value=<%= $altitude %> style="width:2em">° above the horizontal plane and <input type=submit value=Recompute>!</form>

<p>Additionally, the times in this table take into account Norwegian flag customs <!-- https://www.crwflags.com/fotw/flags/no-law.html#rules --> (and common sense). Areas far up north get very little sunlight during the winter, therefore the flag is flown during dawn and dusk as well. In particular, if the sun has not risen by 10:00, the flag should be hoisted anyway and it should fly at least until 15:00 even if sunset happens earlier. Conversely, the flag should never fly after 21:00 or before 08:00 <!--(09:00 in winter)--> regardless of sunset and sunrise.

<p>The law does not regulate use of the flag on private property at land. It is not customary to fly the flag on bad weather days in Ølve. However, it is customary to fly the flag on exceptional private occasions such as weddings and funerals.

<p>To avoid the eyesore of a bare flag pole, it is customary to fly a pennant instead of the flag on days that are not flag days. Pennants are flown day and night. However, <a href="https://en.wikipedia.org/wiki/Seamanship">good seamanship</a> frowns upon unnecessary flags and pennants being flown during periods of high winds in order to protect the fabric.

<p>Ships (and boats) use the flag as their <a href="https://en.wikipedia.org/wiki/Ensign">sign of nationality</a> and therefore display the flag every day while at sea. In fact, any ship on an international journey is generally required to do so by law while in foreign waters (cf. <a href="https://lovdata.no/LTI/forskrift/2018-12-20-2056/%C2%A717">Lovdata</a><!-- Forskrift om utenlandske fartøyers anløp til og ferdsel i norsk territorialfarvann FOR-2018-12-20-2056, § 17 -->). Ships display the flag of the country they are registered in.

<p>Foreign ships visiting Ølve display the Norwegian flag in addition to their own. This is done as a matter of courtesy, but also to signal that these ships accept the applicability of Norwegian laws on the Norwegian territorial waters they are visiting. The <a href="https://en.wikipedia.org/wiki/Maritime_flag#Courtesy_flag">courtesy flag</a> is smaller in size than the national flag and is flown in a prominent position. On a sailing yacht, for example, the preferred position is under the starboard spreader.

