module Falcon
  module ActiveRecord
    def self.included(base)
      base.extend ClassMethods
    end
    
    module ClassMethods
      def falcon_encode(options = {})
        options = {:name => 'falcon'}.merge(options)
        options.assert_valid_keys(:source, :name, :profiles)
        
        class_attribute :falcon_encode_options, :instance_writer => false
        self.falcon_encode_options = options
        
        unless self.is_a?(ClassMethods)
          include InstanceMethods
          
          has_many :falcon_encodings, :class_name => 'Falcon::Encoding', :dependent => :destroy
          
          after_create :create_falcon_encodings
        end
        
      end
    end
    
    module InstanceMethods
      protected
      
        def create_falcon_encodings
          source_path = send(self.class.falcon_encode_options[:source])
          
          self.class.falcon_encode_options[:profiles].each do |profile_name|
            falcon_encodings.create(:profile_name => profile_name, :source_path => source_path)
          end
        end
    end
  end
end
