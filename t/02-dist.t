
use 5.010;
use strict;
use FindBin;
use lib "t/lib","lib","$FindBin::Bin/../blib/lib","$FindBin::Bin/../blib/arch";
use Test::More;
use util;

use Image::pHash;

is(
    Image::pHash::dist(
        Image::pHash::hash('test_images/image.jpg'),
        Image::pHash::hash('test_images/image.png'),
    ),
    46,
    "Got distance between the two images"
);

is(
    Image::pHash::dist(
        Image::pHash::hash('test_images/image.jpg'),
        Image::pHash::hash('test_images/image.jpg'),
    ),
    0,
    "Images are the same"
);

is(
    Image::pHash::dist(
        Image::pHash::hash('test_images/image.gif'),
        Image::pHash::hash(\util::read_file('test_images/image.gif')),
    ),
    0,
    "Images are the same"
);

done_testing();
