class Point

  attr_accessor :longitude, :latitude

  def to_hash
    {:type => "Point", :coordinates => [@longitude, @latitude]}
  end

  def initialize params
    if !params[:coordinates].nil?
      @longitude = params[:coordinates][0]
      @latitude = params[:coordinates][1]
    else
      @longitude = params[:lng]
      @latitude = params[:lat]
    end
  end

end
