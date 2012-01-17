class Search
  include MongoMapper::Document

  MAX_XP_PAGES = 16
  XP_TIMEOUT = 15.seconds * 1000
  RF_BLOCK_SIZE = 5
  RF_TIMEOUT = (3 * RF_BLOCK_SIZE).seconds * 1000
  
  key :keywords,   String
  key :phase,      String,  :default => "exploratory"
  key :pages,      Array,   :default => []   # Array of Fixnum
  key :xpTiles,    Hash,    :default => {}
  key :levels,     Array,   :default => []   # Array of Fixnum
  key :rfTiles,    Array,   :default => []   # Array of Hashes
  key :statistics, Hash,    :default => {}
  key :loading_time,  Fixnum, :default => 0
  key :saving_time,   Fixnum, :default => 0
  key :client_processing_time, Fixnum, :default => 0
  key :server_processing_time, Fixnum, :default => 0

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
      level = [levels.compact.min - 1, 0].max
      assign_new_refinement_block(level, RF_BLOCK_SIZE, timestamp)
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
    
    benchmark = (Time.now.to_f * 1000).to_i
    self.xpTiles = xpTiles.merge Hash[results] do |key, old_val, new_val|
      if !old_val.nil?
        val = {}
        val["points"] = (new_val["points"] + old_val["points"]).uniq
        val["degree"] = val["points"].size
        val
      end
    end
    increment :server_processing_time => (Time.now.to_f * 1000).to_i - benchmark
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
    benchmark = (Time.now.to_f * 1000).to_i
    results.each_pair do |id, degree|
      results[id] = degree.to_i
    end
    results = Hash[results]
    self.rfTiles[level] ||= {}
    self.rfTiles[level] = rfTiles[level].merge results
    self.rfTiles[level] = rfTiles[level].reject { |id, degree| degree == 0 }
    # logger.debug rfTiles[level].to_yaml
    new_timestamp = (Time.now.to_f * 1000).to_i
    new_block = assign_new_refinement_block(level, RF_BLOCK_SIZE, new_timestamp)
    increment :server_processing_time => (Time.now.to_f * 1000).to_i - benchmark
    [new_block, new_timestamp]
  end
  
  def assign_new_refinement_block(level, num, timestamp)
    new_block = []
    if !rfTiles[level].nil?
      rfTiles[level].keys.sort.each do |key|
        if rfTiles[level][key] == -1 || (rfTiles[level][key] < 0 && timestamp.abs - rfTiles[level][key].abs > RF_TIMEOUT)
          new_block << key
          self.rfTiles[level][key] = -timestamp
        end
        break if new_block.length >= num
      end
    end
    new_block
  end
  
end
