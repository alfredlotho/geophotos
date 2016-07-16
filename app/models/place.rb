class Place

  attr_accessor :id, :formatted_address, :location, :address_components

  def self.mongo_client
   Mongoid::Clients.default
  end

  # convenience method for access to collection
  def self.collection
   self.mongo_client['places']
  end  

  # bulk load a JSON document with places information into the collection
  def self.load_all file
    contents = file.read
    collection.insert_many(JSON.parse(contents))
    file.close
  end

  def initialize params
    @id = params[:_id].to_s
    @address_components = []
    params[:address_components].each do |ac|
      @address_components << AddressComponent.new(ac)
    end
    @formatted_address = params[:formatted_address]
    @location = Point.new(params[:geometry][:geolocation])
  end

end
