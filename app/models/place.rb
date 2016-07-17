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

  def self.find_by_short_name short_name
    collection.find("address_components.short_name" => short_name)
  end

  def self.to_places view
    places = []
    view.each do |place|
      places << Place.new(place)
    end
    return places
  end

  def self.find id
    place = collection.find(:_id => BSON::ObjectId.from_string(id)).first
    Place.new(place) if !place.nil?
  end

  def self.all(offset=0, limit=nil)
    result = collection.find.skip(offset)
    result = result.limit(limit) if !limit.nil?
    places = []
    result.each do |place|
      places << Place.new(place)
    end
    return places
  end

  def destroy
    Place.collection.find(:_id => BSON::ObjectId.from_string(@id)).delete_one
  end

  # returns a list of AddressComponents and their related id, formatted address and geolocation
  def self.get_address_components(sort={}, offset=0, limit=nil)
    agg = [
      {"$project" => {"_id" => 1, "address_components" => 1, "formatted_address" => 1, "geometry.geolocation" => 1}},
      {"$unwind" => "$address_components"}
    ]
    agg << {"$sort" => sort} if !sort.empty?
    agg << {"$skip" => offset}
    agg << {"$limit" => limit} if !limit.nil?
    collection.aggregate(agg)
  end

  # returns a distinct collection of country names
  def self.get_country_names
    collection.aggregate([
      {"$project" => {"address_components.long_name" => 1, "address_components.types" => 1}},
      {"$unwind" => "$address_components"},
      {"$unwind" => "$address_components.long_name"},
      {"$unwind" => "$address_components.types"},
      {"$match" => {"address_components.types" => "country"}},
      {"$group" => {"_id" => "$address_components.long_name"}}
    ]).to_a.map {|h| h[:_id]}
  end
end
