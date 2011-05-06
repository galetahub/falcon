module Falcon
  class Profile
    cattr_accessor :all
    @@all = []
    
    attr_accessor :name, :player, :container, :extname, :width, :height, :fps, :command
    attr_accessor :video_bitrate, :video_codec
    attr_accessor :audio_codec, :audio_bitrate, :audio_sample_rate
    
    DEFAULTS = {
      :player => 'flash', 
      :container => "mp4", 
      :extname => 'mp4',
      :width => 480, 
      :height => 320, 
      :fps => 29.97, 
      :video_codec => "libx264",
      :video_bitrate => 500, 
      :command => "-vpre medium",
      :audio_codec => "libfaac",
      :audio_bitrate => 128, 
      :audio_sample_rate => 48000  
    }
    
    def initialize(name, options = {})
      options.assert_valid_keys(DEFAULTS.keys)
      options = DEFAULTS.merge(options)
      
      @name = name.to_s
      
      options.each do |key, value|
        send("#{key}=", value)
      end
      
      @@all << self
    end
    
    def audio_bitrate_in_bits
      self.audio_bitrate.to_i * 1024
    end

    def video_bitrate_in_bits
      self.video_bitrate.to_i * 1024
    end
    
    def path(source)
      source.chomp(File.extname(source)) + "." + extname
    end
    
    def encode_options
      { 
        :container => self.container, 
        :video_codec => self.video_codec,
        :video_bitrate_in_bits => self.video_bitrate_in_bits.to_s, 
        :fps => self.fps,
        :audio_codec => self.audio_codec.to_s, 
        :audio_bitrate => self.audio_bitrate.to_s, 
        :audio_bitrate_in_bits => self.audio_bitrate_in_bits.to_s, 
        :audio_sample_rate => self.audio_sample_rate.to_s
      }
    end
    
    class << self
      def find(name)
        @all.detect { |p| p.name == name.to_s } 
      end
      alias :get :find
      
      def [](name)
        find(name)
      end
    end
  end
end
