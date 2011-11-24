class Search < CouchRest::Model::Base

  MAX_XP_PAGES = 16
  XP_TIMEOUT = 10.seconds
  
  property :keywords,   String
  property :phase,      String,   :default => "exploratory"
  property :pages,      [Fixnum], :default => []
  property :xpTiles,    Hash,     :default => {}
  property :levels,     [Fixnum], :default => []  
  property :rfTiles,    [Hash],   :default => []
  property :statistics, Hash,     :default => {}
  
  design do
    view :by_keywords
  end
  
  def logger
    ActiveRecord::Base.logger
  end
  
  def current_client=(timestamp)
    if phase == "exploratory"
      current_page = next_available_xp_page
      logger.debug current_page
      self.pages[current_page] = timestamp if current_page
    elsif phase == "refinement"
      
    end
  end
  
  def next_available_xp_page
    return nil if pages.length == MAX_XP_PAGES
    pages.each_with_index do |page, index|
      return index if (Time.now.to_i - page > XP_TIMEOUT) && (page > MAX_XP_PAGES - 1)
    end
    [pages.length, MAX_XP_PAGES - 1].min
  end
  
  def updateExploratory(results, page, original_timestamp)
    ActiveRecord::Base.logger.debug "updating from exploratory search... with page #{page}"
    logger.debug "Current pages: #{pages.inspect}"
    self.pages[page] = page
    logger.debug "Calculated pages: #{pages.inspect}"
    self.current_client = original_timestamp
    logger.debug "Sending pages: #{pages.inspect}"
    
    self.xpTiles = xpTiles.merge Hash[results] do |key, old_val, new_val|
      if !old_val.nil?
        val = {}
        val["points"] = (new_val["points"] + old_val["points"]).uniq
        val["degree"] = val["points"].size
        val
      end
    end
  end
  
  def updateRefinement(results, level, max_level = nil)
    ActiveRecord::Base.logger.debug "updating from refinement search... with level #{level}"
    if max_level
      self.levels = []
      self.levels[max_level] = max_level
    else
      self.levels[level + 1] = level + 1 if level < levels.length
    end
    self.phase = "refinement"
    results.each_pair do |id, degree|
      results[id] = degree.to_i
    end
    self.rfTiles[level] ||= {}
    self.rfTiles[level] = rfTiles[level].merge Hash[results]
    self.rfTiles[level] = rfTiles[level].reject { |id, degree| degree == 0 }
  end
  
end
