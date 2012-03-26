namespace :experiment do

  task :run, [] => :environment do |t, args|
    experiments = YAML.load_file(File.join(Rails.root, "test", "fixtures", "xps.yml"))
    browsers = ["google-chrome", "chromium-browser"] * 8
    profiles    = Profile.all.to_hash_with_key_and_array(:category)
    experiments.each_pair do |category, all_keywords|
      all_keywords.each do |keywords|
        existing_searches = Search.where(:keywords => keywords, :completed_at.ne => nil).all
        puts "\nFound #{existing_searches.count} existing searches..."
        existing_searches.each_with_index do |existing_search, index|
          puts "#{"%03d" % (index + 1)}. searching '#{keywords}' with profile '#{existing_search.profile.name}'" +
                " [#{existing_search.completed_at.nil? ? "incomplete" : "completed"}]"
        end
        remaining_profiles = (profiles[category] || []) - existing_searches.map(&:profile)
        if remaining_profiles.any?
          new_searches = []
          puts "\nWill attempt to search with these profiles:"
          remaining_profiles.each_with_index do |remaining_profile, index|
            puts "#{"%03d" % (index + 1)}. will search '#{keywords}' with profile '#{remaining_profile.name}'"
            search = Search.find_or_create_by_keywords_and_profile_id keywords, remaining_profile.id
            search.xp_reset
            new_searches << search
          end
          instances = Instance.all
          pids = []
          new_searches.each_with_index do |search, index|
            puts "Launching #{search.profile.browsers} browsers"
            search.profile.browsers.times do |i|
              command = browsers[i]
              pid = Process.spawn({}, browsers[i], "http://#{instances[i].address}/searches/#{search.id}")
              Process.detach pid
              pids << pid
              sleep(0.5)
            end
            loop do
              print "."
              sleep(30)
              search_completed = !Search.find_by_id(search.id).completed_at.nil?
              if search_completed
                puts "\n#{"%03d" % (index + 1)}. search '#{keywords}' with profile '#{search.profile.try(:name) || "[no_profile]"}' COMPLETED"
                puts "Killing browsers..."
                pids.each do |pid|
                  Process.kill("KILL", pid) rescue nil
                end
                pids.clear
                break
              end
            end
          end
        else
          puts "<--- #{keywords } ---> ALL PROFILES COMPLETED"
        end
      end
    end
  end
  
end
