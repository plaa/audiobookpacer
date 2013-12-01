Audiobook Pacer
===============

This script allows changing the reading pace of audiobooks.  It does so by lengthening or shortening pauses the reader takes between sentences / paragraphs.


Usage
-----

The following command lengthens all pauses longer than 0.6 seconds by 25%.  Use `./audiobookpacer.rb -h` for all options.

    ./audiobookpacer.rb --length 0.6 --ratio 1.25 input.wav output.wav

These default values are suitable for making The Hunger Games audiobook more enjoyable.


Since the program cannot read/write MP3's natively, there's a separate script that converts an entire directory of MP3 files:

    ./convert-mp3.sh input_dir/ output_dir/ --length 0.6 --ratio 1.25


Prerequisites
-------------

For the main script:

* Ruby
* libsndfile development files
  * `sudo apt-get install libsndfile1-dev`
* ruby-audio gem
  * `gem install ruby-audio`


For the MP3 conversion script:

* mpg123
* lame
* id3cp
  * `sudo apt-get install mpg123 lame libid3-tools`


