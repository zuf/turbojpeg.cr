require "../src/turbojpeg"

jpeg_file = "/tmp/image_small_gray_gradient.jpg"
img_side = 256 # image side size

# Fill image buffer with simpl grayscale gradient
image_buf = Bytes.new(img_side*img_side).fill { |n| (n % 256).to_u8 }

# Init TurboJPEG context
handle = LibTurboJPEG.tj3Init(LibTurboJPEG::TJINIT::TJINIT_COMPRESS)

# Set color sampling and jpeg quality
LibTurboJPEG.tj3Set(handle, LibTurboJPEG::TJPARAM::TJPARAM_SUBSAMP, LibTurboJPEG::TJSAMP::TJSAMP_GRAY)
LibTurboJPEG.tj3Set(handle, LibTurboJPEG::TJPARAM::TJPARAM_QUALITY, 90)

# Get maximum jpeg size
out_buf_size = LibTurboJPEG.tj3JPEGBufSize(img_side, img_side, LibTurboJPEG::TJSAMP::TJSAMP_GRAY)
raise "Can't get buffer size: #{String.new(LibTurboJPEG.tj3GetErrorStr(handle))}" if out_buf_size == 0

# Allocate buffer for maximum jpeg size
out_buffer = LibTurboJPEG.tj3Alloc(out_buf_size)
raise "Can't allocate memory" if out_buffer.null?

# Compress xor_image_buf to jpeg
# Note: out_buf_size will contain actual jpeg buffer size after this call
err = LibTurboJPEG.tj3Compress8(handle, image_buf, img_side, 0, img_side, LibTurboJPEG::TJPF::TJPF_GRAY, pointerof(out_buffer).as(Pointer(Pointer(UInt8))), pointerof(out_buf_size))
raise "Can't compress image: #{String.new(LibTurboJPEG.tj3GetErrorStr(handle))}" if err != 0

# Save jpeg data to file
File.open(jpeg_file, "wb") do |f|
  f.write Bytes.new(out_buffer.as(Pointer(UInt8)), out_buf_size)
end

# Free memory
LibTurboJPEG.tj3Free(out_buffer)
LibTurboJPEG.tj3Destroy(handle)

puts "Image saved to: #{jpeg_file}"
