use Test::More;

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

done_testing();
