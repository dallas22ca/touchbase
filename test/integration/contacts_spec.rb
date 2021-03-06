require_relative "../test_helper"

describe Contact do
  fixtures :all

  it "requires a user and name" do
    Contact.new.valid?.should == false
    users(:joe).contacts.new(name: "Dallas").valid?.should == true
  end
  
  it "should be unique" do
    Contact.destroy_all
    joe = users(:joe)

    2.times do
      joe.contacts.create(name: "Same Same", data: { same: :same })
    end
    
    joe.contacts.count.should == 1
  end
  
  it "data changes are overwriteable" do
    data = { "awesome" => "cool" }
    joe = users(:joe)
    contact = contacts(:valid)
    contact.update_column :user_id, joe.id
    contact.update_attributes data: data, overwrite: true
    contact.pending_data.should == nil
    contact.data.should == data
  end
  
  it "data changes are be ignored if not overwritten explicitly" do
    data = { "awesome" => "cool" }
    joe = users(:joe)
    contact = contacts(:valid)
    contact.update_column :user_id, joe.id
    contact.update_attributes data: data
    contact.pending_data.should == data
    contact.overwrite = true
    contact.save
    contact.pending_data.should == nil
  end
  
  it "pending data can be written" do
    pending_data = { "awesome" => "cool" }
    joe = users(:joe)
    contact = contacts(:valid)
    contact.update_column :user_id, joe.id
    contact.data = pending_data
    contact.save
    contact.write_pending
    contact.save
    contact.data.should == pending_data
    contact.pending_data.should == nil
  end
  
  it "contact first_name and last_name" do
    joe = users(:joe)
    contact = joe.contacts.create!(name: nil, data: { "first-name" => "Cool", "last-name" => "Cat" })
    contact.name.should == "Cool Cat"
    contact.data["first-name"].should == nil
  end
end