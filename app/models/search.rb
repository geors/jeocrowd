class Search
  include MongoMapper::Document

  MAX_XP_PAGES = 16
  XP_TIMEOUT = 15.seconds * 1000
  RF_BLOCK_SIZE = 5
  RF_TIMEOUT = (3 * RF_BLOCK_SIZE).seconds * 1000

  attr_accessor :new_timestamp
  attr_accessor :new_page
  attr_accessor :new_block
  
  key :keywords,                            String
  key :phase,                               String, :default => "exploratory"
  key :pages,                               Array,  :default => []   # Array of Fixnum
  key :xp_tiles,                            Hash,   :default => {}
  (0..15).each do |i|                       
    key :"xp_page_#{i}",                    Hash,   :default => {}    
  end                                       
  key :levels,                              Array,  :default => []   # Array of Fixnum
  key :rfTiles,                             Array,  :default => []   # Array of Hashes
  key :statistics,                          Hash,   :default => {}
  key :created_at,                          Time,   :default => Time.now
  key :completed_at,                        Time,   :default => nil
  key :exploratory_loading_time,            Fixnum, :default => 0
  key :exploratory_saving_time,             Fixnum, :default => 0
  key :exploratory_client_processing_time,  Fixnum, :default => 0
  key :exploratory_server_processing_time,  Fixnum, :default => 0
  key :refinement_loading_time,             Fixnum, :default => 0
  key :refinement_saving_time,              Fixnum, :default => 0
  key :refinement_client_processing_time,   Fixnum, :default => 0
  key :refinement_server_processing_time,   Fixnum, :default => 0

  ensure_index :keywords, :unique => true
  
  def logger
    ActiveRecord::Base.logger
  end
  
  def xp_reset
    self.phase = "exploratory"
    self.pages = []
    self.xpTiles = {}
    self.levels = []
    self.rfTiles = []
    self.statistics = {:created_at => Time.now}
    self.exploratory_loading_time = 0
    self.exploratory_saving_time = 0
    self.exploratory_client_processing_time = 0
    self.exploratory_server_processing_time = 0
    self.refinement_loading_time = 0
    self.refinement_saving_time = 0
    self.refinement_client_processing_time = 0
    self.refinement_server_processing_time = 0
    save :safe => true
  end
  
  def rf_reset
    self.phase = "exploratory"
    self.levels = []
    self.rfTiles = []
    self.refinement_loading_time = 0
    self.refinement_saving_time = 0
    self.refinement_client_processing_time = 0
    self.refinement_server_processing_time = 0
    save :safe => true
  end
  
  #############################################################################

  def benchmarks
    attributes.reject{ |k, v| k.index("_time").nil? }
  end
  
  def client_benchmarks
    b = {}
    benchmarks.each do |k, v|
      b[k.camelize] = v if k.to_s.index(phase)
    end
    b
  end
  
  def current_level
    [levels.compact.min - 1, 0].max
  end
  
  def mark_levels(level, max_level)
    if max_level
      self.levels = []
      self.levels[max_level] = max_level
    else
      self.levels[level + 1] = level + 1 if level < levels.length
    end
  end

  #############################################################################
    
  def set_current_client(timestamp)
    if phase == "exploratory"
      next_available_xp_page(timestamp)
    elsif phase == "refinement"
      next_available_rf_block(current_level, RF_BLOCK_SIZE, timestamp)
    end
    self.new_timestamp = timestamp
  end
  
  def old_page_index(current_timestamp)
    pages.each_with_index do |page, index|
      return index if (current_timestamp - page > XP_TIMEOUT) && (page > MAX_XP_PAGES - 1)
    end
    nil
  end
  
  def xp_full?
    pages.length == MAX_XP_PAGES
  end
  
  def xp_completed?
    pages.length == MAX_XP_PAGES && pages.all? { |page| page < MAX_XP_PAGES }
  end
  
  def next_available_xp_page(timestamp)
    if xp_full?
      if xp_completed?
        return nil
      else
        # add if old_page_index(timestamp)
        # there might be a pending job that has not exceeded the timeout
        pages[old_page_index(timestamp)] = timestamp if old_page_index(timestamp)
        set :pages => pages
      end
    else
      push :pages => timestamp
    end
    reload
  end
  
  def merged_xp_tiles
    m = {}
    (0..15).each do |i|
      m.merge! self[:"xp_page_#{i}"] do |key, old_val, new_val|
        if !old_val.nil?
          val = {}
          val["points"] = (new_val["points"] + old_val["points"]).uniq
          val["degree"] = val["points"].size
          val
        end
      end
    end
    m
  end
  
  def update_xp(results, page, original_timestamp)
    logger.debug "updating exploratory search... with page #{page} and timestamp #{original_timestamp}"

    results = Hash[results].values_to_i!.remove_dots_from_keys_and_convert_values_to_integers
    pages[page] = page
    set :"xp_page_#{page}" => results, :pages => pages
    set_current_client (Time.now.to_f * 1000).to_i
  end
  
  def next_available_rf_block(level, num, timestamp)
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
  
  def update_values(params)
    params.values_to_i!
    statistics.merge! :total_available_points => params[:total_available_points]      if params[:total_available_points]
    statistics.merge! :completed_at           => Time.now                             if params[:completed] == "completed"
    set :statistics => statistics
    update_benchmarks params[:benchmarks]                                             if params[:benchmarks]
    logger.debug params[:xpTiles].class
    update_xp params[:xpTiles], params[:page],  params[:timestamp]                     if params[:xpTiles] && params[:page]
    update_rf params[:rfTiles], params[:level], params[:timestamp], params[:maxLevel]  if params[:rfTiles] && params[:level]
  end
  
  def update_benchmarks b
    b.values_to_i!
    increment b
    reload
  end
  
  
  def updateRF(results, level, original_timestamp, max_level = nil)
    logger.debug "updating from refinement search... with level #{level}"
    self.phase = "refinement"
    

    mark_levels(level, max_level)
    set_current_client (Time.now.to_f * 1000).to_i
  end
  
  def merge_rf_results
    results.each_pair do |id, degree|
      results[id] = degree.to_i
    end
    results = Hash[results]
    self.rfTiles[level] ||= {}
    self.rfTiles[level] = rfTiles[level].merge results
    self.rfTiles[level] = rfTiles[level].reject { |id, degree| degree == 0 }    
  end
  
  def total_running_time(force_date = false)
    if statistics[:created_at] && statistics[:completed_at]
      if force_date
        (statistics[:completed_at] - statistics[:created_at].to_f)
      else
        (statistics[:completed_at].to_f - statistics[:created_at].to_f) * 1000
      end
    else
      "not completed yet"
    end
  end
  
end


