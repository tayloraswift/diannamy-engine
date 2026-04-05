import PNG

func EncodeRGB8(rgba: [PNG.RGBA<UInt8>], size: (x: Int, y: Int), path: String) throws {
    let layout: PNG.Layout = .init(format: .rgb8(palette: [], fill: nil, key: nil))
    let image: PNG.Image  = .init(packing: rgba, size: size, layout: layout)
    try image.compress(path: path, level: 9)
}
