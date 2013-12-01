#!/usr/bin/env ruby
#-*- encoding: utf-8 -*-

require 'ruby-audio'
require 'optparse'


class AudiobookPacer

  attr_accessor :silence_limit
  attr_accessor :silence_length
  attr_accessor :ratio
  
  def initialize
    @silence_limit = 0.02
    @silence_length = 0.6
    @ratio = 1.25
  end
  
  def pace(input, output)

    @rate = input.info.samplerate
    @channels = input.info.channels
    @samples = @rate * 60
    @silence_samples = @silence_length * @rate
    
    @input_samples = 0
    @output_samples = 0
        
    buf = RubyAudio::Buffer.new("float", @samples, input.info.channels)
    tmp = RubyAudio::Buffer.new("float", (@samples * ratio).to_i + 100, input.info.channels)

        
    while input.read(buf) != 0
  
      @input_samples += buf.real_size
      puts "Processing #{@input_samples / @rate} / #{input.info.frames / @rate} s"
      
      pos = 0
      while pos < buf.real_size
        silence_start, silence_length = find_silence(buf, pos)
  
        if !silence_start.nil?
              
          if pos < silence_start
            write(output, buf, pos, silence_start - pos, tmp)
          end
  
          interpolate(buf, silence_start, silence_length, tmp, (silence_length * ratio).to_i)
          write(output, tmp)
          pos = silence_start + silence_length
          
        else
          # No silence found
          write(output, buf, pos, buf.real_size - pos, tmp)
          pos = buf.real_size
        end
      end
    end
    puts "Original length was #{@input_samples / @rate} s, modified is #{@output_samples / @rate} s (#{@output_samples * 100 / @input_samples}%)"  
  end
  
  def interpolate(input, input_start, input_length, output, output_length)
    output.real_size = 0
    output_length.times do |i|
      j = i * input_length / output_length
      output[i] = input[input_start + j]
    end
  end
  
  def write(output, buf, start = 0, length = buf.real_size, tmp = nil)
    if start == 0 and length == buf.real_size
      output.write(buf)
      @output_samples += buf.real_size
    else
      # Unfortunately the Gem doesn't offer writing a portion of a buffer
      tmp.real_size = 0
      length.times { |i| tmp[i] = buf[start + i] }
      output.write(tmp)
      @output_samples += tmp.real_size
    end
  end
  
  def find_silence(buf, position)
    silence_start = -1
    silence_length = 0
  
    while position < buf.real_size
      if silence?(buf[position])
        if silence_start < 0
          silence_start = position
        end
        silence_length += 1
      else
        if silence_length > @silence_samples
          return silence_start, silence_length
        else
          silence_start = -1
          silence_length = 0
        end
      end
      position += 1
    end
  
    if silence_length > @silence_samples
      return silence_start, silence_length
    else
      return nil, nil
    end
  end
  
  def silence?(sample)
    sample.all? { |s| s < @silence_limit }
  end

end


if $0 == __FILE__
  
  pacer = AudiobookPacer.new

  opts = OptionParser.new do |opts|
    opts.banner = "Usage:  ruby audiobookpacer.rb [options] <input.wav> <output.wav>"
    opts.separator ""

    opts.on("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  
    opts.on("--silence LIMIT", Float, "Sample values below LIMIT are considered silence (default #{pacer.silence_limit})") do |limit|
      pacer.silence_limit = limit
    end
    
    opts.on("--length LENGTH", Float, "Silent gaps longer than LENGTH are modified (default #{pacer.silence_length} s)") do |length|
      pacer.silence_length = length.to_f
    end
    
    opts.on("--ratio RATIO", Float, "Silent gaps are modified to RATIO times their original length (default #{pacer.ratio})") do |ratio|
      pacer.ratio = ratio.to_f
    end
    
    opts.separator ""
  end
  opts.parse!
  
  if ARGV.size != 2
    puts opts
    exit 1
  end

  input = RubyAudio::Sound.open(ARGV[0])
  output = RubyAudio::Sound.open(ARGV[1], 'w', input.info.clone)
  pacer.pace(input, output)
  output.close
  input.close

end

