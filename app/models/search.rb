class Search
  include MongoMapper::Document
  versioned_update

  MAX_XP_PAGES = 16
  XP_TIMEOUT = 15.seconds * 1000
  RF_BLOCK_SIZE = 5
  RF_TIMEOUT = (3 * RF_BLOCK_SIZE).seconds * 1000

  attr_accessor :new_timestamp
  attr_accessor :new_page
  attr_accessor :new_block
  
  key :keywords,   String
  key :phase,      String,  :default => "exploratory"
  key :pages,      Array,   :default => []   # Array of Fixnum
  key :xpTiles,    Hash,    :default => {}
  key :levels,     Array,   :default => []   # Array of Fixnum
  key :rfTiles,    Array,   :default => []   # Array of Hashes
  key :statistics, Hash,    :default => {}
  key :exploratory_loading_time,  Fixnum, :default => 0
  key :exploratory_saving_time,   Fixnum, :default => 0
  key :exploratory_client_processing_time, Fixnum, :default => 0
  key :exploratory_server_processing_time, Fixnum, :default => 0
  key :refinement_loading_time,  Fixnum, :default => 0
  key :refinement_saving_time,   Fixnum, :default => 0
  key :refinement_client_processing_time, Fixnum, :default => 0
  key :refinement_server_processing_time, Fixnum, :default => 0

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
    r = {}
    params.values_to_i!
    statistics[:total_available_points] = params[:total_available_points]             if params[:total_available_points]
    statistics[:completed_at]           = Time.now                                    if params[:completed] == "completed"
    save :safe => true if changed?
    update_benchmarks params[:benchmarks]                                             if params[:benchmarks]
    updateXP params[:xpTiles], params[:page], params[:timestamp]                      if params[:xpTiles] && params[:page]
    updateRF params[:rfTiles], params[:level], params[:timestamp], params[:maxLevel]  if params[:rfTiles] && params[:level]
  rescue
    update_values(params)
  end
  
  def update_benchmarks b
    b.values_to_i!
    increment b
    reload
  end
  
  def updateXP(results, page, original_timestamp)
    logger.debug "updating exploratory search... with page #{page} and timestamp #{original_timestamp}"

    self.xpTiles = xpTiles.merge Hash[results] do |key, old_val, new_val|
      if !old_val.nil?
        val = {}
        val["points"] = (new_val["points"] + old_val["points"]).uniq
        val["degree"] = val["points"].size
        val
      end
    end
    
    self.pages[page] = page
    logger.debug "Calculated pages: #{pages.inspect}"
    self.new_page = next_available_xp_page(timestamp)
    self.pages[new_page] = timestamp if new_page
    save :safe => true
    self.new_timestamp = timestamp
  end
  
  def exploratory_completed?
    pages.length == MAX_XP_PAGES && pages.all? { |page| page < MAX_XP_PAGES }
  end
  
  def updateRF(results, level, original_timestamp, max_level = nil)
    logger.debug "updating from refinement search... with level #{level}"
    self.phase = "refinement"
    
    results.each_pair do |id, degree|
      results[id] = degree.to_i
    end
    results = Hash[results]
    self.rfTiles[level] ||= {}
    self.rfTiles[level] = rfTiles[level].merge results
    self.rfTiles[level] = rfTiles[level].reject { |id, degree| degree == 0 }

    mark_levels(level, max_level)
    self.new_block = next_available_rf_block(current_level, RF_BLOCK_SIZE, timestamp)
    save :safe => true
    self.new_timestamp = timestamp
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


class Hash
  
  def values_to_i!
    each_pair do |k, v|
      self[k] = v.to_i if v.is_a?(String) && v =~ /\d+/
    end
  end
  
end