require 'spec_helper'

describe "instances/edit.html.erb" do
  before(:each) do
    @instance = assign(:instance, stub_model(Instance,
      :host => "MyString",
      :port => "MyString",
      :priority => 1
    ))
  end

  it "renders the edit instance form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form", :action => instances_path(@instance), :method => "post" do
      assert_select "input#instance_host", :name => "instance[host]"
      assert_select "input#instance_port", :name => "instance[port]"
      assert_select "input#instance_priority", :name => "instance[priority]"
    end
  end
end
