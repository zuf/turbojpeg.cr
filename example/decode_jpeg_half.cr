require "../src/turbojpeg"

file_path = "/tmp/photo.jpg"
out_file = "/tmp/photo_half_uncompressed.ppm"
file_size = File.size(file_path)

@[AlwaysInline]
def scaled(dimension, scaling_factor : LibTurboJPEG::TJScalingFactor)
  (((dimension) * scaling_factor.num + scaling_factor.denom - 1) // scaling_factor.denom)
end

# Read entire file to buffer
# You can also use LibC.mmap for that purpose which more efficient
jpeg_data = Bytes.new(file_size)
jpeg_data = Bytes.new(file_size)
# Read entire file to jpeg_data
File.open(file_path, "rb") { |f| f.read(jpeg_data) }

# Init turbojpeg context
handle = LibTurboJPEG.tj3Init(LibTurboJPEG::TJINIT::TJINIT_DECOMPRESS)
raise "Failed to initialize" unless handle

# Set scaling factor to 1/2 (half resolution of decoded image)
scaling_factor = LibTurboJPEG::TJScalingFactor.new(num: 1, denom: 2)
error = LibTurboJPEG.tj3SetScalingFactor(handle, scaling_factor)
raise "Error while setting scaling factor" if error < 0

# Get decompress jpeg header
err = LibTurboJPEG.tj3DecompressHeader(handle, jpeg_data, file_size)
raise "Failed to read JPEG header for #{file_path}" if err != 0

# Get image params
width = LibTurboJPEG.tj3Get(handle, LibTurboJPEG::TJPARAM::TJPARAM_JPEGWIDTH)
height = LibTurboJPEG.tj3Get(handle, LibTurboJPEG::TJPARAM::TJPARAM_JPEGHEIGHT)
subsamp = LibTurboJPEG::TJSAMP.from_value(LibTurboJPEG.tj3Get(handle, LibTurboJPEG::TJPARAM::TJPARAM_SUBSAMP))
precision = LibTurboJPEG.tj3Get(handle, LibTurboJPEG::TJPARAM::TJPARAM_PRECISION)
colorspace = LibTurboJPEG.tj3Get(handle, LibTurboJPEG::TJPARAM::TJPARAM_COLORSPACE)

# Decompressed jpeg to buffer
scaled_width = scaled(width, scaling_factor)
scaled_height = scaled(height, scaling_factor)
buffer_size = scaled_width * scaled_height * 3
rgb_data = Bytes.new(buffer_size)
pixel_format = LibTurboJPEG::TJPF::TJPF_RGB
res = LibTurboJPEG.tj3Decompress8(handle, jpeg_data, file_size, rgb_data, 0, pixel_format)

# Save decompressed jpeg as rgb data
err = LibTurboJPEG.tj3SaveImage8(handle, out_file, rgb_data, scaled_width, 0, scaled_height, pixel_format)
raise "Image saving failed" if err != 0

LibTurboJPEG.tj3Destroy(handle)

puts "Decoded image saved to #{out_file}"
