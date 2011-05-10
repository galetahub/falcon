module Falcon
  module Base
    def self.included(base)
      base.extend SingletonMethods
    end
    
    module SingletonMethods
      #
      # falcon_encode 'media', :source => lambda { |file| file.data.path }, 
      #               :profiles => ['web_mp4', 'web_ogg']
      #
      # falcon_encode 'media', :source => :method_return_path_to_file, 
      #               :profiles => ['web_mp4', 'web_ogg']
      #               :metadata => :method_return_options_hash,
      #               :encode => lambda { |encoding| encoding.delay.encode }
      #
      def falcon_encode(name, options = {})
        extend ClassMethods
        include InstanceMethods
          
        options.assert_valid_keys(:source, :profiles, :metadata, :encode)
        
        unless respond_to?(:falcon_encoding_definitions)
          class_attribute :falcon_encoding_definitions, :instance_writer => false
          self.falcon_encoding_definitions = {}
        end
        
        self.falcon_encoding_definitions[name] = options
        
        has_many :falcon_encodings, 
          :class_name => 'Falcon::Encoding', 
          :as => :videoable,
          :dependent => :delete_all

        after_save :save_falcon_medias
        before_destroy :destroy_falcon_medias
        
        define_falcon_callbacks :encode, :"#{name}_encode"
        
        define_method name do |*args|
          a = falcon_media_for(name)
          (args.length > 0) ? a.to_s(args.first) : a
        end

        define_method "#{name}=" do |source_path|
          falcon_media_for(name).assign(source_path)
        end

        define_method "#{name}?" do
          falcon_media_for(name).exist?
        end
      end
    end
    
    module ClassMethods
      def define_falcon_callbacks(*callbacks)
        define_callbacks *[callbacks, {:terminator => "result == false"}].flatten
        callbacks.each do |callback|
          eval <<-end_callbacks
            def before_#{callback}(*args, &blk)
              set_callback(:#{callback}, :before, *args, &blk)
            end
            def after_#{callback}(*args, &blk)
              set_callback(:#{callback}, :after, *args, &blk)
            end
          end_callbacks
        end
      end
    end
    
    module InstanceMethods
      
      def falcon_media_for(name)
        @_falcon_medias ||= {}
        @_falcon_medias[name] ||= Media.new(name, self, self.class.falcon_encoding_definitions[name])
      end

      def each_falcon_medias
        self.class.falcon_encoding_definitions.each do |name, definition|
          yield(name, falcon_media_for(name))
        end
      end
      
      protected
      
        def save_falcon_medias
          each_falcon_medias do |name, media|
            media.send(:save)
          end
        end
        
        def destroy_falcon_medias
          each_falcon_medias do |name, media|
            media.send(:destroy)
          end
        end
    end
  end
end
