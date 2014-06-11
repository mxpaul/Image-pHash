use Test::More;

use Image::pHash;

is(Image::pHash::hash('test_images/image.jpg'),
   7128083241579100457,
   "Got hash for a jpg test image"
);

is(Image::pHash::hash('test_images/image.png'),
   13420489463138834004,
   "Got hash for a png test image"
);


done_testing();
