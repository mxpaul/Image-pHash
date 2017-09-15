#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use FindBin;
use lib "t/lib","lib","$FindBin::Bin/../blib/lib","$FindBin::Bin/../blib/arch";

use Image::pHash;

open(my $f, '<', "$FindBin::Bin/data/no_global_colormap.gif") or die "open $!";
my $pic = do{local $/= undef; <$f>};
ok(1, "Before phash");
my $phash = Image::pHash::hash(\$pic);
is($phash, '17873537905857357532', 'phash ok for gif with no global color map');

done_testing();
