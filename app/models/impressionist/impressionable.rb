module Impressionist
  module Impressionable
    def is_impressionable
      has_many :impressions, :as=>:impressionable, :dependent => :destroy
      include InstanceMethods
      extend ClassMethods
    end
    
    module ClassMethods
      # Returns the most popular records by impression count for models that have been made impressionable.
      # Useful for creating 'most popular' lists
      # Accepts start_date and end_date as options hash for filtering
      #
      def most_popular_by_impression_count(options = {})
        options.reverse_merge!(:start_date => nil, :end_date => Time.now)
        obj = ActiveRecord::Base.send(:class_of_active_record_descendant, self).to_s
        
        res = obj.constantize.select("#{obj.tableize}.*, COUNT(impressions.id) AS impressions_count").group("#{obj.tableize}.id").joins(:impressions).order("impressions_count DESC").limit(options[:limit])
        
        # Filter by date range if start date specified
        res = res.where("impressions.created_at >= ? and impressions.created_at <= ?",options[:start_date],options[:end_date]) unless options[:start_date].blank?
        return res
      end
    end
    
    module InstanceMethods
      def impressionable?
        true
      end
      
      def impressionist_count(options={})
        options.reverse_merge!(:filter=>:request_hash, :start_date=>nil, :end_date=>Time.now)
        imps = options[:start_date].blank? ? impressions : impressions.where("created_at>=? and created_at<=?",options[:start_date],options[:end_date])
        if options[:filter]!=:all
          imps = imps.select(options[:filter]).group(options[:filter])
        end
        imps.all.size
      end
      
      # OLD METHODS - DEPRECATE IN V0.5
      def impression_count(start_date=nil,end_date=Time.now)
        impressionist_count({:start_date=>start_date, :end_date=>end_date, :filter=>:all})
      end

      def unique_impression_count(start_date=nil,end_date=Time.now)
        impressionist_count({:start_date=>start_date, :end_date=>end_date, :filter=> :request_hash})
      end
      
      def unique_impression_count_ip(start_date=nil,end_date=Time.now)
        impressionist_count({:start_date=>start_date, :end_date=>end_date, :filter=> :ip_address})
      end
      
      def unique_impression_count_session(start_date=nil,end_date=Time.now)
        impressionist_count({:start_date=>start_date, :end_date=>end_date, :filter=> :session_hash})
      end
    end
  end
end
