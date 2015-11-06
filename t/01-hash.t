use 5.010;
use strict;
use FindBin;
use lib "t/lib","lib","$FindBin::Bin/../blib/lib","$FindBin::Bin/../blib/arch";
use Image::pHash;
use Data::Dumper;
use Test::More;
use util;

my $image_jpg_path = 'test_images/image.jpg';
my $image_png_path = 'test_images/image.png';
my $image_gif_path = 'test_images/image.gif';
my @gif_images = ('test_images/image.gif', 'test_images/1.gif', 'test_images/2.gif', 'test_images/200_s.gif');

my $image_jpg = util::read_file($image_jpg_path);
my $image_png = util::read_file($image_png_path);

is(Image::pHash::hash($image_jpg_path),
   7128083241579100457,
   "Got hash for a jpg test image"
);

is(Image::pHash::hash($image_png_path),
   13420489463138834004,
   "Got hash for a png test image"
);

is(Image::pHash::hash($image_gif_path),
   16590245461654031411,
   "Got hash for a gif test image"
);

is(Image::pHash::hash(\$image_jpg),
   Image::pHash::hash($image_jpg_path),
   "Got hash for an in-memory jpg test image"
);

is(Image::pHash::hash(\$image_png),
   Image::pHash::hash($image_png_path),
   "Got hash for an in-memory png test image"
);

for my $gif_image (@gif_images) {
   is(Image::pHash::hash(\util::read_file($gif_image)),
      Image::pHash::hash($gif_image),
      "Got hash for an in-memory gif test image [$gif_image]"
   );
}


done_testing();
