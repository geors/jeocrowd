module SearchesHelper
  
  def search_option(label, &block)
    render(:layout => "layouts/search_option.html", :locals => {:label => label}) do
      yield
    end
  end
  
end
