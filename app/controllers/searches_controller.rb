class SearchesController < ApplicationController

  def index
    @searches = Search.sort(:keywords, :profile_id, :min_date)
    @searches = !params[:profile].blank? ? @searches.find_all_by_profile_id(params[:profile]) : 
      params[:keywords].blank? ? [] : @searches.find_all_by_keywords(params[:keywords])
  end

  def show
    @search = Search.find(params[:id])
    return if @search.nil?
    if params[:restart_exploratory]
      @search.xp_reset
    elsif params[:restart_refinement] && @search.phase != "exploratory"
      @search.rf_reset
    end
    @search.set_current_client(@timestamp = (Time.now.to_f * 1000).to_i)
  end

  def new
    @search = Search.new
  end

  def create
    active_profile_id = Profile.find_by_active(true).try(:id)
    Time.zone = "UTC"
    params[:search][:min_date] ||= Time.parse((1..3).map { |i|
        params[:search].delete(:"min_date(#{i}i)")
    }. join("-")).to_date.to_s rescue params[:search][:min_date] = nil
    params[:search][:max_date] ||= Time.parse((1..3).map { |i|
                                    params[:search].delete(:"max_date(#{i}i)")
    }. join("-")).to_date.to_s rescue params[:search][:max_date] = nil
    @search = Search.find_by_keywords_and_profile_id_and_min_date_and_max_date(
                  params[:search][:keywords], active_profile_id,
                  params[:search][:min_date], params[:search][:max_date]
              ) || Search.new(params[:search])
    @search.profile_id = active_profile_id
    if @search.save :safe => true
      redirect_to search_url(@search, :init => 1)
    else
      render action: "new"
    end
  end

  def update
    benchmark = (Time.now.to_f * 1000).to_i
    @search = Search.find(params[:id])
    @search.update_values(params)
    @new_timestamp = @search.new_timestamp
    @new_page = @search.new_page
    @new_block = @search.new_block
    @search.increment(:"#{@search.phase}_server_processing_time" => (Time.now.to_f * 1000).to_i - benchmark) unless params[:benchmarks]
    @search.reload
  end

  def destroy
    @search = Search.find(params[:id])
    @search.destroy
    redirect_to :back
  end
  
  def status
    @experiments = YAML.load_file(File.join(Rails.root, "test", "fixtures", "xps.yml"))
  end
  
  def export
    params[:m] ||= "total_running_time"
    methods = params[:m].split(".")
    profiles = Profile.sort(:name).all
    keywords = Search.fields(:keywords).all.collect(&:keywords).uniq
    cvs = []
    cvs << ["search_term," + profiles.collect(&:name).map{ |c| Array.wrap(c) * methods.length * (params[:length] || 1).to_i}.join(",")]
    cvs << ["search_term," + (methods * profiles.length).map { |c| Array.wrap(c) * (params[:length] || 1).to_i}.join(",")]
    keywords.each do |keyword|
      row = []
      row << keyword
      profiles.each do |profile|
        methods.each do |method|
          row << Search.find_by_keywords_and_profile_id(keyword, profile.id).try(method.to_sym) rescue row << "--not supported--"
        end
      end
      cvs << row.join(",")
    end
    send_data cvs.join("\n"), :filename => "#{params[:m]}_#{Time.now.strftime("%Y.%M.%d_%H.%M")}.csv"
  end
  
end
