require 'spec_helper'

describe "profiles/index" do
  before(:each) do
    assign(:profiles, [
      stub_model(Profile,
        :full_search_times => 1,
        :max_neighbors_for_core => 1,
        :{threshold_for_removal => "",
        :{threshold_for_removal => "",
        :hot_tiles_average => 1,
        :tiles_apart_for_sparse_grids => 1,
        :visualize_clearing_time => 1,
        :benchmark_publish_interval => 1
      ),
      stub_model(Profile,
        :full_search_times => 1,
        :max_neighbors_for_core => 1,
        :{threshold_for_removal => "",
        :{threshold_for_removal => "",
        :hot_tiles_average => 1,
        :tiles_apart_for_sparse_grids => 1,
        :visualize_clearing_time => 1,
        :benchmark_publish_interval => 1
      )
    ])
  end

  it "renders a list of profiles" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => "".to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "tr>td", :text => 1.to_s, :count => 2
  end
end
