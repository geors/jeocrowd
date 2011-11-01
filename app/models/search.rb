class Search < CouchRest::Model::Base
  
  property :keywords,   String
  property :phase,      String,   :default => "exploratory"
  property :pages,      [Fixnum], :default => []
  property :xpTiles,    Hash,     :default => {}
  property :statistics, Hash,     :default => {}
  
  
  def updateExploratory(results, page)
    ActiveRecord::Base.logger.debug "updating from exploratory search... with page #{page}"
    ActiveRecord::Base.logger.debug pages.inspect
    self.pages = pages.insert(page, page)
    ActiveRecord::Base.logger.debug pages.inspect
    self.xpTiles = xpTiles.merge Hash[results] do |key, new_val, old_val|
      if !old_val.nil?
        val = {}
        val["points"] = (new_val["points"] + old_val["points"]).uniq
        val["degree"] = val["points"].size
        val
      end
    end
  end
  
end
