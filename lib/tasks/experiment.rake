namespace :experiment do
  
  desc "Run the experiments"
  task :run, [:keywords, :category] => :environment do |t, args|
    puts "---------------------------------------------------"
    keywords = args[:keywords].titleize
    category = args[:category].titleize
    
    existing_searches = Search.where(:keywords => Regexp.new(keywords, "i")).all
    if existing_searches.any?
      puts "\nFound #{existing_searches.count} existing searches..."
      existing_searches.each_with_index do |existing_search, index|
        puts "#{"%03d" % (index + 1)}. searching '#{keywords}' with profile '#{existing_search.profile.try(:name) || "[no_profile]"}' [#{existing_search.completed_at.nil? ? "incomplete" : "completed"}]"
      end
    end
    existing_profiles = Search.completed.where(:keywords => Regexp.new(keywords, "i")).map(&:profile)
    remaining_profiles = Profile.where(:name => Regexp.new(category, "i")).all
    remaining_profiles -= existing_profiles
    if remaining_profiles.any?
      puts "\nWill attempt to search with these profiles:"
      remaining_profiles.each_with_index do |remaining_profile, index|
        puts "#{"%03d" % (index + 1)}. will search '#{keywords}' with profile '#{remaining_profile.name}'"
        Search.find_or_create_by_keywords_and_profile_id keywords, remaining_profile.id
      end
    else
      puts "No remaining profiles for the specified category to search for... exiting."
    end
    instances = Instance.all
    Search.where(:keywords => Regexp.new(keywords, "i"), :profile_id.in => remaining_profiles.map(&:id)).each_with_index do |search, index|
      puts "Launching #{search.profile.browsers} browsers"
      search.profile.browsers.times do |i|
        # `firefox http://#{instances[i].address}/searches/#{search.id}`
        pid = Process.spawn({}, "firefox", "http://#{instances[i].address}/searches/#{search.id}")
        Process.detach pid
      end
      loop do
        print "."
        sleep(30)
        search_completed = !Search.find_by_id(search.id).completed_at.nil?
        if search_completed
          puts "#{"%03d" % (index + 1)}. search '#{keywords}' with profile '#{search.profile.try(:name) || "[no_profile]"}'"
          puts "Killing browsers..."
          `killall firefox`
        end
      end
    end
  end
  
end