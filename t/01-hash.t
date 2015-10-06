use Test::More;

use Image::pHash;
use Image::Size;
use Data::Dumper;

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

my $image_jpg_path = 'test_images/image.jpg';
my $image_png_path = 'test_images/image.png';

my ($jpg_x, $jpg_y) = imgsize($image_jpg_path);

my @image_jpg = (read_file($image_jpg_path));
my @image_png = (read_file($image_png_path));

is(Image::pHash::hash($image_jpg_path),
   7128083241579100457,
   "Got hash for a jpg test image"
);

is(Image::pHash::hash($image_png_path),
   13420489463138834004,
   "Got hash for a png test image"
);

is(Image::pHash::hash_mem(@image_jpg),
   Image::pHash::hash($image_jpg_path),
   "Got hash for an in-memory jpg test image"
);

is(Image::pHash::hash_mem(@image_png),
   Image::pHash::hash($image_png_path),
   "Got hash for an in-memory png test image"
);


done_testing();
