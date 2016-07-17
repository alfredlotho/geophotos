class Photo

  attr_accessor :id, :location
  attr_writer :contents

  def self.mongo_client
   Mongoid::Clients.default
  end

  def initialize(doc = nil)
    if !doc.nil?
      @id = doc[:_id].to_s
      @location = Point.new(doc[:metadata][:location])
    end
  end

  def persisted?
    !@id.nil?
  end

  # stores a new instance of Photo to GridFS
  def save
    if persisted?
      #do nothing for now
    else
      gps = EXIFR::JPEG.new(@contents).gps
      @location = Point.new(:lng => gps.longitude, :lat => gps.latitude)
      description = {}
      description[:content_type] = "image/jpeg"
      description[:metadata] = {}
      description[:metadata][:location] = @location.to_hash
      @contents.rewind
      grid_file = Mongo::Grid::File.new(@contents.read, description)
      id = self.class.mongo_client.database.fs.insert_one(grid_file)
      @id=id.to_s
      @id
    end
  end

end
