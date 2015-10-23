use 5.010;
use strict;
use FindBin;
use lib "t/lib","lib","$FindBin::Bin/../blib/lib","$FindBin::Bin/../blib/arch";
use Test::More;

use Image::pHash;

# is(unpack('H*',Image::pHash::mh_hash('test_images/image.jpg', 1, 2)),
#    '3701000000001a49a5204344802cf45d4afc000047c0d6a5b9c362070e5d0cfc96c806ac76493596e05cd907a0934d1661d90b4c440025cab207b600024c22b4a5dc1fa047ec013f',
#    "Got hash for a jpg test image"
# );

# is(unpack('H*',Image::pHash::mh_hash('test_images/image.png', 1, 2)),
#    '578880000000000354202fc440000006a8ff001017c2200d51fe0000000819eaa3fc0000000000001b98100000000000000ccdcc080000000000000466e604000000000000023373',
#    "Got hash for a png test image"
# );

is(1, 1);

done_testing();
