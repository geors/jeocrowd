class Instance  
  include MongoMapper::Document

  key :host,    String
  key :port,    String
  key :priority,Fixnum
  
  def self.websites
    Instance.all.map &:address
  end
  
  def address
    "#{host}:#{port}"
  end
  
end
