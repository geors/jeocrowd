class Search < CouchRest::Model::Base
  
  property :keywords,   String
  property :phase,      String,   :default => "exploratory"
  property :pages,      [Fixnum], :default => []
  property :statistics, Hash,     :default => {}
  
end
