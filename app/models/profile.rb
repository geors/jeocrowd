class Profile  
  include MongoMapper::Document
  
  key :name                        , String 
  key :full_search_times           , Fixnum , :required => true, :numeric => true, :not_in => [0]       , :default => 1
  key :max_neighbors_for_core      , Fixnum , :required => true, :numeric => true, :in => (4..8).entries, :default => 7
  key :threshold_for_removal       , Float  , :required => true, :numeric => true, :not_in => [0.0]     , :default => 0.02
  key :hot_tiles_average           , Fixnum , :required => true, :numeric => true                       , :default => 5
  key :tiles_apart_for_sparse_grids, Fixnum , :required => true, :numeric => true                       , :default => 10
  key :visualize_clearing_time     , Fixnum , :required => true, :numeric => true                       , :default => 2000
  key :benchmark_publish_interval  , Fixnum , :required => true, :numeric => true                       , :default => 30000
  key :browsers                    , Fixnum , :required => true, :numeric => true, :not_in => [0]       , :default => 1  
  key :active                      , Boolean                                                            , :default => false
  
  many :searches
  
end
