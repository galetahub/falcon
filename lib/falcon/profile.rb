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
      :command => nil,
      :audio_codec => "libfaac",
      :audio_bitrate => 128, 
      :audio_sample_rate => 48000  
    }
    
    def initialize(name, options = {})
      options.assert_valid_keys(DEFAULTS.keys)
      options = DEFAULTS.merge(options)
      
      @name = name.to_s
      
      if self.class.exists?(@name)
        raise "Profile name: #{@name} already registered."
      end
      
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
    
    def path(source, prefix = nil)
      dirname = File.dirname(source)
      filename = File.basename(source, File.extname(source))
      filename = [prefix, filename].compact.join('_') + '.' + extname
      
      Pathname.new(File.join(dirname, filename))
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
    
    def update(options)
      options.each do |key, value|
        send("#{key}=", value)
      end
    end
    
    class << self
      def find(name)
        @@all.detect { |p| p.name == name.to_s } 
      end
      alias :get :find
      
      def [](name)
        find(name)
      end
      
      def exists?(name)
        !find(name).nil?
      end
      
      def detect(name)
        name.is_a?(Falcon::Profile) ? name : find(name.to_s)
      end
    end
  end
end
