module ApplicationHelper
  
  def include_google_maps
    javascript_include_tag("http://maps.google.com/maps/api/js?sensor=#{sensor_enabled?}") if (map_needed?)
  end

  def map_needed?
    true
  end

  def sensor_enabled?
    false
  end
  
end
