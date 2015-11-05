package util;

use 5.010;
use strict;

sub read_file {
	my $filename = shift;
	my $f = do {
		local $/ = undef;
		open FILE, $filename or die "Couldn't open file: $!";
		binmode FILE;
		my $file = <FILE>;
		close FILE;
		$file;
	};
	return $f;
}

1;
