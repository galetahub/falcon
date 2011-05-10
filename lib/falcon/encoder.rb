require 'fileutils'
require 'web_video'

module Falcon
  module Encoder
    PROCESSING = 1
    SUCCESS = 2
    FAILURE = 3
      
    def self.included(base)
      base.send :include, InstanceMethods
      base.send :extend,  ClassMethods
    end
    
    module ClassMethods
      def self.extended(base)
        base.class_eval do
          belongs_to :videoable, :polymorphic => true
          
          attr_accessor :ffmpeg_resolution, :ffmpeg_padding
          
          attr_accessible :profile_name, :source_path
          
          validates_presence_of :profile_name, :source_path

          define_callbacks :encode, :terminator => "result == false", :scope => [:kind, :name]
          
          before_validation :set_resolution
          after_create :make_output_dir, :start_encoding
          before_encode :before_encoding
          after_encode :after_encoding
          
          scope :with_profile, lambda {|name| where(:profile_name => name).first }
        end
      end
      
      def before_encode(*args, &block)
        options = args.extract_options!
        if options.is_a?(Hash) && options[:on]
          options[:if] = Array.wrap(options[:if])
        end
        set_callback(:encode, :before, *(args << options), &block)
      end

      def after_encode(*args, &block)
        options = args.extract_options!
        options[:prepend] = true
        options[:if] = Array.wrap(options[:if])
        set_callback(:encode, :after, *(args << options), &block)
      end
    end
    
    module InstanceMethods
      
      def profile
        @profile ||= Falcon::Profile.find(profile_name)
      end
      
      def resolution
        self.width ? "#{self.width}x#{self.height}" : nil
      end
      
      def transcoder
        @transcoder ||= ::WebVideo::Transcoder.new(source_path)
      end
      
      def output_path
        @output_path ||= self.profile.path(source_path)
      end
      
      def output_directory
        @output_directory ||= File.dirname(self.output_path)
      end
      
      def profile_options(input_file, output_file)
        self.profile.encode_options.merge({
          :input_file => input_file,
          :output_file => output_file,
          :resolution => self.ffmpeg_resolution
          #:resolution_and_padding => self.ffmpeg_resolution_and_padding_no_cropping
        })
      end
      
      # Yield generated screenshots and remove them
      def screenshots(&block)
        Dir.glob("#{output_directory}/*.{jpg,JPG}").each do |filepath|
    	    yield filepath
    	    FileUtils.rm(filepath, :force => true)
    	  end
      end
      
      # A hash of metadatas for video:
      # 
      # { :title => '', :author => '', :copyright => '', 
      #   :comment => '', :description => '', :language => ''}
      #
      def metadata_options
        if videoable_method?(:falcon_metadata_options)
          videoable.falcon_metadata_options
        else
          {}
        end
      end
      
      def encode
        run_callbacks :encode do
          begun_encoding = Time.now

          self.status = PROCESSING
          self.save(:validate => false)

          begin
            self.encode_source
            self.generate_screenshots
            
            self.status = SUCCESS
            self.encoded_at = Time.now
            self.encoding_time = (Time.now - begun_encoding).to_i
            self.save(:validate => false)
          rescue
            self.status = FAILURE
            self.save(:validate => false)
            raise
          end
        end
      end
      
      def processing?
        self.status == PROCESSING
      end
      
      def fail?
        self.status == FAILURE
      end
      
      def success?
        self.status == SUCCESS
      end
      
      protected
        
        def start_encoding
          if videoable_method?(:falcon_encode)
            videoable.falcon_encode(self)
          else
            encode
          end
        end
        
        def set_resolution
          unless profile.nil?
            self.width ||= profile.width
            self.height ||= profile.height
          end
        end
        
        def ffmpeg_resolution_and_padding_no_cropping(v_width, v_height)
          # Calculate resolution and any padding
          in_w = v_width.to_f #self.video.width.to_f
          in_h = v_height.to_f #self.video.height.to_f
          out_w = self.width.to_f
          out_h = self.height.to_f

          begin
            aspect = in_w / in_h
            aspect_inv = in_h / in_w
          rescue
            #Merb.logger.error "Couldn't do w/h to caculate aspect. Just using the output resolution now."
            @ffmpeg_resolution = %(#{self.width}x#{self.height} )
            return 
          end

          height = (out_w / aspect.to_f).to_i
          height -= 1 if height % 2 == 1

          @ffmpeg_resolution = %(#{self.width}x#{height} )

          # Keep the video's original width if the height
          if height > out_h
            width = (out_h / aspect_inv.to_f).to_i
            width -= 1 if width % 2 == 1

            @ffmpeg_resolution = %(#{width}x#{self.height} )
            self.width = width
            self.save
          # Otherwise letterbox it
          elsif height < out_h
            pad = ((out_h - height.to_f) / 2.0).to_i
            pad -= 1 if pad % 2 == 1
            @ffmpeg_padding = %(-padtop #{pad} -padbottom #{pad})
          end
        end
        
        def encode_source  
          #stream = transcoder.source.video_stream
          ffmpeg_resolution_and_padding_no_cropping(self.width, self.height)
          options = self.profile_options(self.source_path, output_path)
          
          begin
            transcoder.convert(output_path, options) do |command| 
              # Audo 
              command << "-ar $audio_sample_rate$"
              command << "-ab $audio_bitrate_in_bits$"
              command << "-acodec $audio_codec$"
              command << "-ac 1"
              
              # Video 
              command << "-vcodec $video_codec$"
              command << "-b $video_bitrate_in_bits$"
              command << "-bt 240k"
              command << "-r $fps$"
              command << "-f $container$"
              
              # Metadata
              if metadata_options
                metadata_options.each do |key, value|
                  command << "-metadata #{key}='#{value}'"
                end
              end
              
              # Profile additional arguments
              command << self.profile.command
              
              command << @ffmpeg_padding
              command << "-y"
            end
          rescue ::WebVideo::CommandLineError => e
            ::WebVideo.logger.error("Unable to transcode video #{self.id}: #{e.class} - #{e.message}")
            return false
          end
        end
        
        def generate_screenshots
          image_files = output_path.gsub(File.extname(output_path), '_%2d.jpg')
          options = {:resolution => self.resolution, :count => 1, :at => :center}
          image_transcoder = ::WebVideo::Transcoder.new(output_path) 
          
          begin
            image_transcoder.screenshot(image_files, options) do |command|
              command << "-vcodec mjpeg"
              
              # The duration for which image extraction will take place
              #command << "-t 4"
              command << "-y"
            end
          rescue ::WebVideo::CommandLineError => e
            ::WebVideo.logger.error("Unable to generate screenshots for video #{self.id}: #{e.class} - #{e.message}")
            return false
          end
        end
        
        def before_encoding
          if videoable_method?(:falcon_before_encode)
            return videoable.falcon_before_encode(self)
          else
            return true
          end
        end
        
        def after_encoding
          if videoable_method?(:falcon_after_encode)
            videoable.falcon_after_encode(self)
          end
        end
        
        def make_output_dir
          FileUtils.mkdir_p( output_directory )
        end
        
        def videoable_method?(method_name)
          videoable && videoable.respond_to?(method_name.to_sym)
        end
    end
  end
end
