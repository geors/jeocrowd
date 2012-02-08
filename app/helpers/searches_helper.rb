module SearchesHelper
  
  def search_option(label, extra = nil, &block)
    render(:layout => "layouts/search_option", :format => "html", :locals => {:label => label, :extra => extra}) do
      yield
    end
  end
  
  def benchmark_width(current, total, total_width=920, at_least=100, how_many=4)
    occupied = at_least * how_many
    free = total_width - occupied
    r = (current.to_f / total * free + at_least).to_i rescue at_least
    r - 10
  end
  
  def primary_show(v)
    if params[:show_time]
      if v / 1000 == 0
        "#{v} ms"
      else
        l Time.at(v / 1000, (v % 1000) * 1000).utc, :format => :only_time
      end
    else
      v
    end
  end
  
  def secondary_show(v)
    unless params[:show_time]
      if v / 1000 == 0
        "#{v} ms"
      else
        l Time.at(v / 1000, (v % 1000) * 1000).utc, :format => :only_time
      end
    else
      v
    end
    
  end
  
end
