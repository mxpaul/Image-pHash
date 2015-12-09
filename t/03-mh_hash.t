use 5.010;
use strict;
use FindBin;
use lib "t/lib","lib","$FindBin::Bin/../blib/lib","$FindBin::Bin/../blib/arch";
use Test::More;

use Image::pHash;
use util;

my @gif_images = ('test_images/image.gif', 'test_images/1.gif', 'test_images/2.gif', 'test_images/200_s.gif');

# is(unpack('H*',Image::pHash::mh_hash('test_images/image.jpg', 1, 2)),
#    '3701000000001a49a5204344802cf45d4afc000047c0d6a5b9c362070e5d0cfc96c806ac76493596e05cd907a0934d1661d90b4c440025cab207b600024c22b4a5dc1fa047ec013f',
#    "Got hash for a jpg test image"
# );

# is(unpack('H*',Image::pHash::mh_hash('test_images/image.png', 1, 2)),
#    '578880000000000354202fc440000006a8ff001017c2200d51fe0000000819eaa3fc0000000000001b98100000000000000ccdcc080000000000000466e604000000000000023373',
#    "Got hash for a png test image"
# );



is(unpack('H*',Image::pHash::mh_hash('test_images/image.jpg', 1, 2)),
   '57098000000017e871602bc44079747b489c0010fbc0fe7539530406ca5f18fc96c817a072493596ed5cd91524924912667c0bdb22002148fa079f0102c9117ca3fb1fa18fe449be',
   "Got hash for a jpg test image"
);

is(unpack('H*',Image::pHash::mh_hash('test_images/image.png', 1, 2)),
   '77c440000000001454203ba220000028a8ff00100a91105151fe000000080de2a3fc0000000000008b98100000000000000445cc080000000000000222e604000000000000011173',
   "Got hash for a png test image"
);

is(unpack('H*',Image::pHash::mh_hash('test_images/image.gif', 1, 2)),
   '00000000000810000000000000029bbc00000000001b70ddb40000000000091bb36c00000000001fe71f6c000000000013204c0400000000000dda2680000000000933357b4c4800',
   "Got hash for a gif test image"
);
	
is(unpack('H*', Image::pHash::mh_hash(\util::read_file('test_images/image.png'), 1, 2)),
	unpack('H*',Image::pHash::mh_hash('test_images/image.png', 1, 2)),
	"Got hash for a png test image (in-memory)"
);

is(unpack('H*', Image::pHash::mh_hash(\util::read_file('test_images/image.jpg'), 1, 2)),
	unpack('H*',Image::pHash::mh_hash('test_images/image.jpg', 1, 2)),
	"Got hash for a jpeg test image (in-memory)"
);

for my $gif_image (@gif_images) {
	my $mem_h = unpack('H*', Image::pHash::mh_hash(\util::read_file($gif_image), 1, 2));
	# warn "Got this hash for $gif_image: $mem_h";
	is($mem_h,
		unpack('H*',Image::pHash::mh_hash($gif_image, 1, 2)),
		"Got hash for a gif test image (in-memory) [$gif_image]"
	);
}

done_testing();
