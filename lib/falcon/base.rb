module Falcon
  module Base
    def self.included(base)
      base.extend SingletonMethods
    end
    
    module SingletonMethods
      def falcon_encode(options = {})
        options = {:name => 'falcon'}.merge(options)
        options.assert_valid_keys(:source, :name, :profiles)
        
        class_attribute :falcon_encode_options, :instance_writer => false
        self.falcon_encode_options = options
        
        unless self.is_a?(ClassMethods)
          include InstanceMethods
          extend ClassMethods
          
          has_many :falcon_encodings, 
            :class_name => 'Falcon::Encoding', 
            :as => :videoable,
            :dependent => :destroy
          
          after_create :create_falcon_encodings
        end
      end
    end
    
    module ClassMethods
      def falcon_source
        falcon_encode_options[:source]
      end
      
      def falcon_profiles
        falcon_encode_options[:profiles]
      end
      
      def falcon_name
        falcon_encode_options[:name]
      end
    end
    
    module InstanceMethods
    
      def falcon_source_path
        @falcon_source_path ||= begin
          method = self.class.falcon_source
          method.respond_to?(:call) ? method.call(self) : self.send(method)
        end
      end
      
      def falcon_path(profile)
        profile = profile.is_a?(Falcon::Profile) ? profile : Falcon::Profile.find(profile.to_s)
        profile.path(falcon_source_path, self.class.falcon_name)
      end
      
      def falcon_url(profile)
        falcon_path(profile).relative_path_from( Rails.root.join('public') )
      end
      
      protected
      
        def create_falcon_encodings
          self.class.falcon_profiles.each do |profile_name|
            self.falcon_encodings.create(
              :name => self.class.falcon_name, 
              :profile_name => profile_name, 
              :source_path => falcon_source_path)
          end
        end
    end
  end
end
