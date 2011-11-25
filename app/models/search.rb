class Search
  include MongoMapper::Document

  MAX_XP_PAGES = 16
  XP_TIMEOUT = 15.seconds * 1000
  
  key :keywords,   String
  key :phase,      String,  :default => "exploratory"
  key :pages,      Array,   :default => []   # Array of Fixnum
  key :xpTiles,    Hash,    :default => {}
  key :levels,     Array,   :default => []   # Array of Fixnum
  key :rfTiles,    Array,   :default => []   # Array of Hashes
  key :statistics, Hash,    :default => {}
  
  ensure_index :keywords, :unique => true
  
  def logger
    ActiveRecord::Base.logger
  end
  
  def current_client=(timestamp)
    if phase == "exploratory"
      current_page = next_available_xp_page(timestamp)
      self.pages[current_page] = timestamp if current_page
      if current_page == pages.length
        push :pages => timestamp unless current_page == MAX_XP_PAGES
      else
        set :pages => pages
      end
      reload
      self.current_client = timestamp if pages.detect { |page| page == timestamp } .nil? unless pages.length == MAX_XP_PAGES
    elsif phase == "refinement"
      
    end
  end
  
  def next_available_xp_page(timestamp)
    return nil if pages.length == MAX_XP_PAGES
    pages.each_with_index do |page, index|
      # You cannot use Time.now.to_i here because you might steal the job of another client
      # that you started together with, after XP_TIMEOUT time during the initiation of the search
      # since in xp search timestamps are not auto-updated
      return index if (timestamp - page > XP_TIMEOUT) && (page > MAX_XP_PAGES - 1)
    end
    [pages.length, MAX_XP_PAGES - 1].min
  end
  
  def updateExploratory(results, page, original_timestamp)
    ActiveRecord::Base.logger.debug "updating exploratory search... with page #{page} and timestamp #{original_timestamp}"
    logger.debug "Current pages: #{pages.inspect}"
    self.pages[page] = page
    logger.debug "Calculated pages: #{pages.inspect}"
    self.current_client = new_timestamp = (Time.now.to_f * 1000).to_i
    logger.debug "Sending pages: #{pages.inspect}"
    
    self.xpTiles = xpTiles.merge Hash[results] do |key, old_val, new_val|
      if !old_val.nil?
        val = {}
        val["points"] = (new_val["points"] + old_val["points"]).uniq
        val["degree"] = val["points"].size
        val
      end
    end
    new_timestamp
  end
  
  def exploratory_completed?
    pages.length == MAX_XP_PAGES && pages.all? { |page| page < MAX_XP_PAGES }
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
    (Time.now.to_f * 1000).to_i
  end
  
end
