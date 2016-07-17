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

  def self.all(offset=0, limit=nil)
    photos=[]
    documents = mongo_client.database.fs.find.skip(offset)
    documents = documents.limit(limit) if !limit.nil?
    documents.each do |doc| 
      photos << Photo.new(doc)
    end
    return photos
  end

  def self.id_criteria id
    {_id:BSON::ObjectId.from_string(id)}
  end

  def id_criteria
    self.class.id_criteria @id
  end

  def self.find id
    document = mongo_client.database.fs.find(id_criteria(id)).first
    return document.nil? ? nil : Photo.new(document)
  end

  def contents
    document = self.class.mongo_client.database.fs.find_one(id_criteria)
    if document
      buffer = ""
      document.chunks.reduce([]) do |x,chunk| 
          buffer << chunk.data.data 
      end
      return buffer
    end
  end

  def destroy
    self.class.mongo_client.database.fs.find(id_criteria).delete_one
  end

end
