class SearchesController < ApplicationController

  def index
    @searches = Search.sort(:created_at.desc)
    @searches = !params[:profile].blank? ? @searches.find_all_by_profile_id(params[:profile]) : 
      params[:keywords].blank? ? @searches.all : @searches.find_all_by_keywords(params[:keywords])
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
    active_profile = Profile.find_by_active(true)
    @search = Search.find_by_keywords_and_profile_id(params[:search][:keywords], active_profile.id) || Search.new(params[:search])
    @search.profile = active_profile
    if @search.save :safe => true
      redirect_to search_url(@search, :browsers => params[:browsers])
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
    redirect_to searches_url
  end
end
