class Search
  include MongoMapper::Document

  MAX_XP_PAGES = 16
  XP_TIMEOUT = 10000 # is ms
  RF_BLOCK_SIZE = 5

  attr_accessor :new_timestamp
  attr_accessor :new_page
  attr_accessor :new_block

  key :keywords,                            String
  key :min_date,                            String
  key :max_date,                            String
  key :phase,                               String, :default => "exploratory"
  key :pages,                               Array,  :default => []   # Array of Fixnum
  (0..15).each do |i|
    key :"xp_page_#{i}",                    Hash,   :default => {}
  end
  key :levels,                              Array,  :default => []   # Array of Fixnum
  (0..6).each do |i|
    key :"rf_level_assing_keys_#{i}",       Array,  :default => []   # Array of String ids
    key :"rf_level_mark_keys_#{i}",         Array,  :default => []   # Array of String ids
    key :"rf_level_#{i}",                   Array,  :default => []   # Array of Hashes
  end
  key :statistics,                          Hash,   :default => {}
  key :exploratory_loading_time,            Fixnum, :default => 0
  key :exploratory_saving_time,             Fixnum, :default => 0
  key :exploratory_client_processing_time,  Fixnum, :default => 0
  key :exploratory_server_processing_time,  Fixnum, :default => 0
  key :exploratory_to_provider_data,        Fixnum, :default => 0
  key :exploratory_from_provider_data,      Fixnum, :default => 0
  key :refinement_loading_time,             Fixnum, :default => 0
  key :refinement_saving_time,              Fixnum, :default => 0
  key :refinement_client_processing_time,   Fixnum, :default => 0
  key :refinement_server_processing_time,   Fixnum, :default => 0
  key :refinement_to_provider_data,         Fixnum, :default => 0
  key :refinement_from_provider_data,       Fixnum, :default => 0
  key :filtering_counts,                    Hash,   :default => {}
  key :completed_at,                        Time,   :default => nil
  key :profile_change,                      Boolean,:deafult => false
  timestamps!

  belongs_to :profile

  ensure_index :keywords
  ensure_index :profile_id
  ensure_index [[:keywords, 1], [:profile_id, 1]]
  ensure_index [[:keywords, 1], [:profile_id, 1], [:min_date, 1], [:max_date, 1]]
  ensure_index :created_at

  scope :incomplete, where(:completed_at => nil)
  scope :completed, where(:completed_at.ne => nil)

  validates_presence_of :profile

  def logger
    Logger.new(STDOUT)
  end

  def get_paramater(p)
    case p
    when :XP_TIMEOUT    then return (profile && profile.waiting_on_reload) || XP_TIMEOUT
    when :RF_BLOCK_SIZE then return (profile && profile.rf_block_size)     || RF_BLOCK_SIZE
    end
  end

  def xp_reset
    self.phase = "exploratory"
    self.pages = []
    (0..15).each do |i|
      self[:"xp_page_#{i}"] = {}
    end
    self.levels = []
    (0..6).each do |i|
      self[:"rf_level_assing_keys_#{i}"] = []
      self[:"rf_level_mark_keys_#{i}"]   = []
      self[:"rf_level_#{i}"]             = []
    end
    self.created_at = Time.now
    self.completed_at = nil
    self.exploratory_loading_time = 0
    self.exploratory_saving_time = 0
    self.exploratory_client_processing_time = 0
    self.exploratory_server_processing_time = 0
    self.exploratory_to_provider_data = 0
    self.exploratory_from_provider_data = 0
    self.refinement_loading_time = 0
    self.refinement_saving_time = 0
    self.refinement_client_processing_time = 0
    self.refinement_server_processing_time = 0
    self.refinement_to_provider_data = 0
    self.refinement_from_provider_data = 0
    self.profile_change = false
    save :safe => true
  end

  def rf_reset
    self.phase = "exploratory"
    self.levels = []
    (0..6).each do |i|
      self[:"rf_level_assing_keys_#{i}"] = []
      self[:"rf_level_mark_keys_#{i}"]   = []
      self[:"rf_level_#{i}"]             = []
    end
    self.completed_at = nil
    self.refinement_loading_time = 0
    self.refinement_saving_time = 0
    self.refinement_client_processing_time = 0
    self.refinement_server_processing_time = 0
    self.refinement_to_provider_data = 0
    self.refinement_from_provider_data = 0
    save :safe => true
  end

  #############################################################################

  def benchmarks
    attributes.reject{ |k, v| k.index("_time").nil? }
  end

  def xp_benchmarks
    benchmarks.reject{ |k, v| k.index("exploratory").nil? }
  end

  def rf_benchmarks
    benchmarks.reject{ |k, v| k.index("refinement").nil? }
  end

  def total_xp_time
    xp_benchmarks.values.sum
  end

  def total_rf_time
    rf_benchmarks.values.sum
  end

  def total_provider_data
    to_provider_data + from_provider_data
  end

  def to_provider_data
    exploratory_to_provider_data + refinement_to_provider_data
  end

  def from_provider_data
    exploratory_from_provider_data + refinement_from_provider_data
  end

  def xp_to_data_percentage
    exploratory_to_provider_data / to_provider_data.to_f * 100 rescue "NaN"
  end

  def rf_to_data_percentage
    refinement_to_provider_data / to_provider_data.to_f * 100 rescue "NaN"
  end

  def xp_from_data_percentage
    exploratory_from_provider_data / from_provider_data.to_f * 100 rescue "NaN"
  end

  def rf_from_data_percentage
    refinement_from_provider_data / from_provider_data.to_f * 100 rescue "NaN"
  end

  def total_available_points
    statistics[:total_available_points]
  end

  (0..6).each do |i|
    define_method "fc#{i}" do
      begin
        filtering_counts[i.to_s].empty? ? [0, 0, 0] : filtering_counts[i.to_s]
      rescue
        [0, 0, 0]
      end
    end
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
    set :levels => levels
  end

  def change_phase(p)
    self.phase = p
    set :phase => phase
  end

  #############################################################################

  def set_current_client(timestamp)
    reload
    if phase == "exploratory"
      next_available_xp_page(timestamp)
    elsif phase == "refinement"
      next_available_rf_block(current_level, get_paramater(:RF_BLOCK_SIZE), timestamp)
    end
    self.new_timestamp = timestamp
  end

  def old_page_index(current_timestamp)
    pages.each_with_index do |page, index|
      return index if (current_timestamp - page > get_paramater(:XP_TIMEOUT)) && (page > MAX_XP_PAGES - 1)
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
        # OR maybe consider re-assinging if there is no job for current client and the xp is incomplete
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
    results ||= {}
    results = Hash[results].values_to_i!.remove_dots_from_keys_and_convert_values_to_integers
    pages[page] = page
    set :"xp_page_#{page}" => results, :pages => pages
    set_current_client (Time.now.to_f * 1000).to_i
  end

  def hollow_level?(results)
    results.all? { |k, v| v == -1 }
  end

  def set_hollow_level_keys(results, level)
    self[:"rf_level_assing_keys_#{level}"] = self[:"rf_level_mark_keys_#{level}"] = results.keys
    set :"rf_level_assing_keys_#{level}" => results.keys, :"rf_level_mark_keys_#{level}" => results.keys
  end

  def next_available_rf_block(level, num, timestamp)
    self.new_block = self[:"rf_level_assing_keys_#{level}"].slice! 0, num
    pull_all :"rf_level_assing_keys_#{level}" => new_block unless new_block.nil?
    if new_block.blank? && !self[:"rf_level_mark_keys_#{level}"].blank?
      push_all :"rf_level_assing_keys_#{level}" => self[:"rf_level_mark_keys_#{level}"]
      reload
      next_available_rf_block(level, num, timestamp)
    end
  end

  def merged_rf_tiles
    m = []
    levels.reject!(&:nil?)
    (levels | [[(levels.min || 0) - 1, 0].max]).sort.reverse.each do |level|
      m[level] = {}
      self[:"rf_level_mark_keys_#{level}"].each do |k|
        m[level][k] = -1
      end
      self[:"rf_level_#{level}"].each do |hsh|
        m[level].merge! hsh
      end
    end
    m
  end

  def update_rf(results, level, original_timestamp, max_level = nil)
    logger.debug "updating from refinement search... with level #{level}"
    change_phase "refinement"
    mark_levels level, max_level
    results = Hash[results].values_to_i!.remove_dots_from_keys_and_convert_values_to_integers
    if !hollow_level? results
      new_results = results.reject{ |k, v| v == 0 }
      push :"rf_level_#{level}" => new_results unless new_results.blank?
      pull_all :"rf_level_mark_keys_#{level}" => results.keys
    else
      set_hollow_level_keys results, level
    end
    set_current_client (Time.now.to_f * 1000).to_i
  end

  def update_values(params)
    params.values_to_i!
    statistics.merge! :total_available_points => params[:total_available_points]      if params[:total_available_points]
    set :statistics             => statistics
    set :completed_at           => Time.now                      if completed_at.nil? && params[:completed] == "completed"
    update_hash params[:data_counters]                                                if params[:data_counters]
    update_hash params[:benchmarks]                                                   if params[:benchmarks]
    set :filtering_counts => params[:counts]                                          if params[:counts]
    update_xp params[:xpTiles], params[:page],  params[:timestamp]                    if params[:page]
    update_rf params[:rfTiles], params[:level], params[:timestamp], params[:maxLevel] if params[:rfTiles] && params[:level]
  end

  def update_hash h
    h.values_to_i!
    increment h
    reload
  end

  def total_running_time(force_date = false)
    if created_at && completed_at
      if force_date
        completed_at - created_at.to_f
      else
        (completed_at.to_f - created_at.to_f) * 1000
      end
    else
      "not completed yet"
    end
  end

end
