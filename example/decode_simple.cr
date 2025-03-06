require "../src/turbojpeg"

file_path = "/tmp/photo.jpg"
out_file = "/tmp/photo_uncompressed.ppm"

file_size = File.size(file_path)

jpeg_data = Bytes.new(file_size)
# Read entire file to jpeg_data
File.open(file_path, "rb") { |f| f.read(jpeg_data) }

# Init turbojpeg context
handle = LibTurboJPEG.tj3Init(LibTurboJPEG::TJINIT::TJINIT_DECOMPRESS)
raise "Failed to initialize" unless handle

# Get decompress jpeg header
err = LibTurboJPEG.tj3DecompressHeader(handle, jpeg_data, file_size)
raise "Failed to read JPEG header for #{file_path}" if err != 0

# Get image params
width = LibTurboJPEG.tj3Get(handle, LibTurboJPEG::TJPARAM::TJPARAM_JPEGWIDTH)
height = LibTurboJPEG.tj3Get(handle, LibTurboJPEG::TJPARAM::TJPARAM_JPEGHEIGHT)

# Decompressed jpeg to rgb_data
rgb_data = Bytes.new(width * height * 3)
res = LibTurboJPEG.tj3Decompress8(handle, jpeg_data, file_size, rgb_data, 0, LibTurboJPEG::TJPF::TJPF_RGB)

# Save decompressed jpeg as rgb data
err = LibTurboJPEG.tj3SaveImage8(handle, out_file, rgb_data, width, 0, height, LibTurboJPEG::TJPF::TJPF_RGB)
raise "Image saving failed" if err != 0

# Free jpegturbo context
LibTurboJPEG.tj3Destroy(handle)

puts "Decoded image saved to #{out_file}"
