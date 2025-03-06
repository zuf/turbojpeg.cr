require "../src/turbojpeg"

jpeg_file = "/tmp/image.jpg"
jpeg_quality = 90
jpeg_color_samp = LibTurboJPEG::TJSAMP::TJSAMP_422

image_width = 1920
image_height = 1080

# Generate XOR image bytes for given size
def xor_image(width, height)
  buffer = Bytes.new(width*height*3)
  width.times do |x|
    height.times do |y|
      index = 3*(x + y*width)
      c = (x % 256 ^ y % 256).to_u8

      r = 255_u8 - c
      g = c % 128_u8
      b = c // 2_u8

      y_ratio = (255*y//width).to_u8

      r &+= y_ratio
      g &+= y_ratio
      b &+= y_ratio

      buffer[index] = r
      buffer[index + 1] = g
      buffer[index + 2] = b
    end
  end

  buffer
end

# Generate XOR image bytes (as Bytes with rgb pixels)
image_buf = xor_image(image_width, image_height)

# Init TurboJPEG context
handle = LibTurboJPEG.tj3Init(LibTurboJPEG::TJINIT::TJINIT_COMPRESS)
raise "Failed to initialize" unless handle

# Set color sampling
LibTurboJPEG.tj3Set(handle, LibTurboJPEG::TJPARAM::TJPARAM_SUBSAMP, jpeg_color_samp)

# Set color jpeg quality
LibTurboJPEG.tj3Set(handle, LibTurboJPEG::TJPARAM::TJPARAM_QUALITY, jpeg_quality)

# Use arithmetic encoding for better compression ratio (while compression is slower)
LibTurboJPEG.tj3Set(handle, LibTurboJPEG::TJPARAM::TJPARAM_ARITHMETIC, 1)
LibTurboJPEG.tj3Set(handle, LibTurboJPEG::TJPARAM::TJPARAM_PROGRESSIVE, 1)

# Get maximum jpeg size
out_buf_size = LibTurboJPEG.tj3JPEGBufSize(image_width, image_height, jpeg_color_samp)
raise "Can't get buffer size" if out_buf_size == 0

# Allocate buffer for maximum jpeg size
out_buffer = LibTurboJPEG.tj3Alloc(out_buf_size)
raise "Can't allocate memory" if out_buffer == nil

# Compress xor_image_buf to jpeg
# Note: out_buf_size will contain actual jpeg buffer size after this call
err = LibTurboJPEG.tj3Compress8(handle, image_buf, image_width, 0, image_height, LibTurboJPEG::TJPF::TJPF_RGB, pointerof(out_buffer).as(Pointer(Pointer(UInt8))), pointerof(out_buf_size))
raise "Can't compress image #{String.new(LibTurboJPEG.tj3GetErrorStr(handle))}" if err != 0

# Save jpeg data to file
File.open(jpeg_file, "wb") do |f|
  f.write Bytes.new(out_buffer.as(Pointer(UInt8)), out_buf_size)
end

# Free memory
LibTurboJPEG.tj3Free(out_buffer)
LibTurboJPEG.tj3Destroy(handle)

puts "Image saved to: #{jpeg_file}"
