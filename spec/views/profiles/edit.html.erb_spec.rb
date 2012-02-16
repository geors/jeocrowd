require 'spec_helper'

describe "profiles/edit" do
  before(:each) do
    @profile = assign(:profile, stub_model(Profile,
      :full_search_times => 1,
      :max_neighbors_for_core => 1,
      :{threshold_for_removal => "",
      :{threshold_for_removal => "",
      :hot_tiles_count_average => 1,
      :tiles_apart_for_sparse_grids => 1,
      :visualize_clearing_time => 1,
      :benchmark_publish_interval => 1
    ))
  end

  it "renders the edit profile form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => profiles_path(@profile), :method => "post" do
      assert_select "input#profile_full_search_times", :name => "profile[full_search_times]"
      assert_select "input#profile_max_neighbors_for_core", :name => "profile[max_neighbors_for_core]"
      assert_select "input#profile_{threshold_for_removal", :name => "profile[{threshold_for_removal]"
      assert_select "input#profile_{threshold_for_removal", :name => "profile[{threshold_for_removal]"
      assert_select "input#profile_hot_tiles_count_average", :name => "profile[hot_tiles_count_average]"
      assert_select "input#profile_tiles_apart_for_sparse_grids", :name => "profile[tiles_apart_for_sparse_grids]"
      assert_select "input#profile_visualize_clearing_time", :name => "profile[visualize_clearing_time]"
      assert_select "input#profile_benchmark_publish_interval", :name => "profile[benchmark_publish_interval]"
    end
  end
end
