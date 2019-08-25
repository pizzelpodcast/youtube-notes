require "rubygems"
require "bundler/setup"
require "shellwords"

module Pizzel
  class IntroFinder
    # Chromaprint samples the audio content at 11025 Hz with a frame size of
    # 4096 with 2/3 overlap, so each point in the fingerprint is 4096 / 11025
    # Hz / 3 = 0.124s
    #
    #   ref: http://www.randombytes.net/audio_comparison.html
    FINGERPRINT_DURATION = 0.124

    # Fingerprint of the intro, calculated with fpcalc
    INTRO_FINGERPRINT = [1901346119, 1901391175, 1633075063, 1641455463, 1641455415].freeze

    def initialize(ep_filename)
      @ep_filename = ep_filename
    end

    def fingerprint
      @fingerprint ||= fpcalc.find { |l| l.match(/^FINGERPRINT=/) }.split("=").last.split(",").map(&:to_i)
    end

    def offset
      @offset ||= min_hamming_distance_pos * FINGERPRINT_DURATION
    end

    private

    def fpcalc
      `fpcalc -raw -length 120 #{Shellwords.shellescape(@ep_filename)}`.split("\n")
    end

    def min_hamming_distance_pos
      distances = hamming_distances
      min_pos = 0
      distances.each_with_index do |d, i|
        min_pos = i if d < distances[min_pos]
      end
      min_pos
    end

    def hamming_distances
      0.upto(fingerprint.size - INTRO_FINGERPRINT.size).map { |i| hamming_distance_at(i) }
    end

    def hamming_distance_at(offset)
      hamming_distance(INTRO_FINGERPRINT, fingerprint[offset, INTRO_FINGERPRINT.length])
    end

    # Calculate hamming distance between 32 bit integer arrays.
    # In short we're calculating number of bits which are different.
    #
    # Read more: http://en.wikipedia.org/wiki/Hamming_distance
    #
    # It's sad to say but according to Stackoverflow it's the fastest
    # way to calculate hamming distance between 2 integers in ruby:
    #   (a^b).to_s(2).count("1")
    #
    #   ref: http://stackoverflow.com/questions/6395165/most-efficient-way-to-calculate-hamming-distance-in-ruby/6397116#6397116
    #
    def hamming_distance(a, b)
      distance = 0

      a.size.times do |i|
        distance += (a[i] ^ b[i]).to_s(2).count('1')
      end

      distance
    end
  end
end

#Dir["/home/pilaf/projects/pizzel/eps/ep*/pizzel-ep*-96kbps.mp3"].sort.each do |f|
#  puts "#{File.basename(f)}: #{Pizzel::IntroFinder.new(f).offset}"
#end
