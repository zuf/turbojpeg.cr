# turbojpeg.cr

Crystal bindings to [libjpeg-turbo](https://libjpeg-turbo.org/) (turbojpeg), superior JPEG image codec.
This bindings provides access to [TurboJPEG C API v3.1](https://rawcdn.githack.com/libjpeg-turbo/libjpeg-turbo/main/doc/turbojpeg/group___turbo_j_p_e_g.html)

## Status of this project

For now only raw crystal bindings for TurboJPEG are avaliable.
More higher level crystal wrapper will be done in the future.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     turbojpeg:
       github: zuf/turbojpeg.cr
   ```

2. Run `shards install`

## Usage

See also another [examples](./example/).

### Decoding

```crystal
require "turbojpeg"

file_path = "/tmp/photo.jpg"
out_file = "/tmp/uncompressed.ppm"
file_size = File.size(file_path)

# Read entire file to jpeg_data  
jpeg_data = Bytes.new(file_size)
File.open(file_path, "rb") { |f| f.read(jpeg_data)}  

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
```


### Encoding

```crystal
require "turbojpeg"

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
```