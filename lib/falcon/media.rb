require 'fileutils'

module Falcon
  class Media
    def self.default_options
      @default_options ||= {
        :profiles => ['web_mp4', 'web_ogg'],
        :metadata => {},
        :source => nil,
        :encode => nil
      }
    end
    
    attr_reader :name, :instance, :options
    
    def initialize(name, instance, options = {})
      @name = name
      @instance = instance
      @options = self.class.default_options.merge(options)
      @profiles = @options[:profiles]
      @encode = @options[:encode]
      @dirty = false
    end
    
    # Array of processing profiles
    def profiles
      unless @normalized_profiles
        @normalized_profiles = {}
        (@profiles.respond_to?(:call) ? @profiles.call(self) : @profiles).each do |name|
          @normalized_profiles[name] = Falcon::Profile.find(name)
        end
      end
      
      @normalized_profiles
    end
    
    # List of generated video files
    def sources
      @sources ||= profiles.values.map{|profile| url(profile) }
    end
    
    # A hash of metadatas for video:
    # 
    # { :title => '', :author => '', :copyright => '', 
    #   :comment => '', :description => '', :language => ''}
    #
    def metadata
      @metadata ||= begin
        method = @options[:metadata]
        method.respond_to?(:call) ? method.call(self) : instance.send(method)
      end
    end
    
    # Path for media source file
    def source_path
      @source_path ||= begin
        method = options[:source]
        method.respond_to?(:call) ? method.call(instance) : instance.send(method)
      end
    end
    
    def output_directory
      @output_directory ||= File.dirname(source_path)
    end
    
    # Returns true if there are changes that need to be saved.
    def dirty?
      @dirty
    end
    
    # Returns the path of the generated media file by profile object or profile name
    def path(profile)
      Falcon::Profile.detect(profile).path(source_path, name)
    end
    
    # Returns the public URL of the media, with a given profile
    def url(profile)
      "/" + path(profile).relative_path_from( Rails.root.join('public') )
    end
    
    def save
      flush_deletes
      create_encodings
      @dirty = false
      true
    end
    
    # Destroy files end encodings
    def destroy
      flush_deletes
      @dirty = false
      true
    end
    
    # Check if source file exists
    def exist?
      File.exist?(source_path)
    end
    
    # Check if source encoded by all profiles
    def all_ready?
      instance.falcon_encodings.success.count == profiles.keys.size
    end
    
    def ready?(profile)
      instance.falcon_encodings.with_profile(profile).success.exists?
    end
    
    def assign(source)
      if File.exist?(source)
        @source_path = source
        @dirty = true
      end
    end
    
    # Yield generated screenshots and remove them
    def screenshots(&block)
      Dir.glob(File.join(output_directory, '*.{jpg,JPG}').to_s).each do |filepath|
  	    yield filepath
  	    FileUtils.rm(filepath, :force => true)
  	  end
    end
    
    protected
    
      def create_encodings
        profiles.each do |profile_name, profile|
          encoding = create_encoding(profile_name)
          start_encoding(encoding)
        end
      end
      
      def create_encoding(profile_name)
        instance.falcon_encodings.create(
          :name => name, 
          :profile_name => profile_name, 
          :source_path => source_path)
      end
      
      # Start encoding direcly or send it into method if set
      def start_encoding(encoding)
        if @encode
          @encode.respond_to?(:call) ? @encode.call(encoding) : instance.send(@encode, encoding)
        else
          encoding.encode
        end
      end
      
      # Clear generated files and created encodings
      def flush_deletes
        instance.falcon_encodings.clear
      end
  end
end
