class SearchesController < ApplicationController

  def index
    @searches = Search.all
  end

  def show
    @search = Search.find(params[:id])
    return if @search.nil?
    if params[:restart_exploratory]
      @search.xp_reset
    elsif params[:restart_refinement] && @search.phase != "exploratory"
      @search.rf_reset
    end
    @search.current_client = @timestamp = (Time.now.to_f * 1000).to_i
    @search.save
  end

  def new
    @search = Search.new
  end

  def create
    @search = Search.find_by_keywords(params[:search] && params[:search][:keywords]) || Search.new(params[:search])
    @search.statistics = {:created_at => Time.now}
    if @search.save
      redirect_to search_url(@search, :browsers => params[:browsers])
    else
      render action: "new"
    end
  end

  def update
    benchmark = (Time.now.to_f * 1000).to_i
    @search = Search.find(params[:id])
    @search.statistics[:total_available_points] = params[:total_available_points].to_i if params[:total_available_points]
    if params[:xpTiles] && params[:page]
      @new_timestamp = @search.updateExploratory params[:xpTiles], params[:page].to_i, params[:timestamp].to_i
    end
    if params[:rfTiles] && params[:level]
      @new_block, @new_timestamp = @search.updateRefinement params[:rfTiles], params[:level].to_i, params[:maxLevel].try(:to_i)
    end
    @search.save
    if params[:benchmarks]
      params[:benchmarks].each do |k, v|
        params[:benchmarks][k] = v.to_i
      end
      @search.increment params[:benchmarks]
    end
    @level = params[:level]
    @search.increment :"#{@search.phase}_server_processing_time" => (Time.now.to_f * 1000).to_i - benchmark
    @search.reload
  end

  def destroy
    @search = Search.find(params[:id])
    @search.destroy
    redirect_to searches_url
  end
end
