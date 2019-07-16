extension Model.Map:Codable 
{
    enum CodingKeys:String, CodingKey 
    {
        case points
        case backgroundImage = "background_image"
    }
    
    init(from decoder:Decoder) throws 
    {
        let serialized:KeyedDecodingContainer<CodingKeys> = 
            try decoder.container(keyedBy: CodingKeys.self)
        
        let points:[Vector3<Float>] = try serialized.decode([Vector3<Float>].self, forKey: .points)
        let backgroundImage:String? = try serialized.decode(String?.self, forKey: .backgroundImage)
        self.init(quasiUnitLengthPoints: points, backgroundImage: backgroundImage)
    }
    
    func encode(to encoder:Encoder) throws 
    {
        var serialized:KeyedEncodingContainer<CodingKeys> = 
            encoder.container(keyedBy: CodingKeys.self)
        
        try serialized.encode(self.points,          forKey: .points)
        try serialized.encode(self.backgroundImage, forKey: .backgroundImage)
    }
}
