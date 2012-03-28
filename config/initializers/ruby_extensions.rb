# Be sure to restart your server when you modify this file.

# Add some extension methods to known Ruby classes

class String
  def to_params
    result = {}
    split('&').each do |element|
      element = element.split('=')
      result[element[0]] = element[1]
    end
    result
  end

  def s
    return nil if (nil? || strip.blank?)
    self
  end
end

class NilClass
  def s
    return nil if (nil? || strip.blank?)
    self
  end
end

class Hash
  def to_params
    if (respond_to?(:to_param))
      to_param
    else
      map { |key, value| "#{key}=#{value}" }.join("&")
    end
  end
  
  def map_hash(&block)
    mapped_hash = {}
    self.each do |key, value|
      mapped_hash[key] = yield key, value
    end
    mapped_hash
  end
  
  def map_hash_with_new_keys(&block)
    mapped_hash = {}
    self.each do |key, value|
      mapped_hash[yield(key, value)] = if value.is_a?(Hash)
        value.map_hash_with_new_keys(&block)
      elsif value.is_a? Array
        value.map { |e| e.is_a?(Hash) ? e.map_hash_with_new_keys(&block) : e }
      else
        value
      end
    end
    mapped_hash
  end
  
  def values_to_i!
    each_pair do |k, v|
      self[k] = v.to_i if v.is_a?(String) && v =~ /\d+/
      self[k] = v.values_to_i! if v.is_a?(Hash)
    end
    self
  end
end

class Array
  def to_hash_with_key(k)
    hash = {}
    self.each { |item| hash[item.send(*k)] = item }
    hash
  end

  def to_hash_with_key_and_array(k)
    hash = {}
    self.each { |item| hash[item.send(*k)] ||= []; hash[item.send(*k)] << item }
    hash
  end

  def to_hash_with_key_and_value(k, v)
    hash = {}
    self.each { |item| hash[item.send(*k)] = item.send(*v) }
    hash
  end

  def to_hash_with_key_and_array_value(k, v)
    hash = {}
    self.each { |item| hash[item.send(*k)] ||= []; hash[item.send(*k)] << item.send(*v) }
    hash
  end
end
