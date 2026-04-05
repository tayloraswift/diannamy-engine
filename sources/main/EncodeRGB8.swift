import PNG

func EncodeV8(v: [UInt8], size: (x: Int, y: Int), path: String) throws {
    let layout: PNG.Layout = .init(format: .v8(fill: nil, key: nil))
    let image: PNG.Image  = .init(packing: v, size: size, layout: layout)
    try image.compress(path: path, level: 9)
}
func LoadRGBA(path: String) throws -> ([PNG.RGBA<UInt8>], (Int, Int)) {
    guard
    let image: PNG.Image = try .decompress(path: path) else {
        fatalError("failed to open file '\(path)'")
    }

    let rgba: [PNG.RGBA<UInt8>] = image.unpack(as: PNG.RGBA<UInt8>.self)
    return (rgba, image.size)
}
