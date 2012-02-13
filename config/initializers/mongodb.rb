#case Rails.env
#when "development"
#  MongoMapper.connection = Mongo::Connection.new('localhost', 27017, { :logger => Rails.logger })
#  MongoMapper.database = 'jeocrowd4s_development'
#  # MongoMapper.database.authenticate('admin', 'sekret')
#when "test"
#  
#when "production"
#  MongoMapper.connection = Mongo::Connection.new('staff.mongohq.com', '10034', { :logger => #Rails.logger })
#  MongoMapper.database = 'app1810029'
#  MongoMapper.database.authenticate('heroku', '448e011347c9ae6e757c88cfcc7ce670')
#end

begin
  MongoMapper.connection = Mongo::Connection.new('localhost', 27017,
    { :logger => Rails.logger })
  MongoMapper.database = 'jeocrowd4s_development'
  # MongoMapper.database.authenticate('admin', 'sekret')
rescue
  MongoMapper.connection = Mongo::Connection.new('staff.mongohq.com', '10034',
    { :logger => Rails.logger })
  MongoMapper.database = 'app1810029'
  MongoMapper.database.authenticate('heroku', '448e011347c9ae6e757c88cfcc7ce670')
end


class Hash
  
  def values_to_i!
    each_pair do |k, v|
      self[k] = v.to_i if v.is_a?(String) && v =~ /\d+/
      self[k] = v.values_to_i! if v.is_a?(Hash)
    end
    self
  end
  
  def remove_dots_from_keys_and_convert_values_to_integers
    c = {}
    each_pair do |k, v|
      c[k.to_s.gsub(".", "^^")] = if v.is_a?(Hash)
        v.remove_dots_from_keys_and_convert_values_to_integers
      elsif v.is_a?(String) && v =~ /\d+/
        v.to_i
      else
        v
      end
    end
    c
  end
  
  def replace_circumflex_with_dots_in_keys
    c = {}
    each_pair do |k, v|
      c[k.to_s.gsub("^^", ".")] = v
    end
    c
  end
  
end

class String 
  
  def replace_circumflex_with_dots
    to_s.gsub("^^", ".")
  end
  
end
