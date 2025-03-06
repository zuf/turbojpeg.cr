require "./spec_helper"

describe TurboJPEG do
  # TODO: Write tests

  it "encode works" do
    img_side = 256 # image side size

    # Fill image buffer with simpl grayscale gradient
    image_buf = Bytes.new(img_side*img_side).fill { |n| (n % 256).to_u8 }

    # Init TurboJPEG context
    handle = LibTurboJPEG.tj3Init(LibTurboJPEG::TJINIT::TJINIT_COMPRESS)
    handle.should_not be_nil

    # Set color sampling and jpeg quality
    ret = LibTurboJPEG.tj3Set(handle, LibTurboJPEG::TJPARAM::TJPARAM_SUBSAMP, LibTurboJPEG::TJSAMP::TJSAMP_GRAY)
    ret.should eq(0)

    ret = LibTurboJPEG.tj3Set(handle, LibTurboJPEG::TJPARAM::TJPARAM_QUALITY, 90)
    ret.should eq(0)

    # Get maximum jpeg size
    out_buf_size = LibTurboJPEG.tj3JPEGBufSize(img_side, img_side, LibTurboJPEG::TJSAMP::TJSAMP_GRAY)
    out_buf_size.should be > 0

    # Allocate buffer for maximum jpeg size
    out_buffer = LibTurboJPEG.tj3Alloc(out_buf_size)
    out_buffer.should be_truthy

    # Compress xor_image_buf to jpeg
    err = LibTurboJPEG.tj3Compress8(handle, image_buf, img_side, 0, img_side, LibTurboJPEG::TJPF::TJPF_GRAY, pointerof(out_buffer).as(Pointer(Pointer(UInt8))), pointerof(out_buf_size))
    err.should eq(0)

    out_buf_size.should be > 0

    # Free memory
    LibTurboJPEG.tj3Free(out_buffer)
    LibTurboJPEG.tj3Destroy(handle)
  end

  it "decode works" do
    uncompressed_tempfile = File.tempfile("test_", ".ppm")
    out_file = uncompressed_tempfile.path
    jpeg_tempfile = File.tempfile("test_", ".jpg")
    jpeg_file = jpeg_tempfile.path

    begin
      img_side = 256 # image side size

      # Fill image buffer with simpl grayscale gradient
      image_buf = Bytes.new(img_side*img_side).fill { |n| (n % 256).to_u8 }

      # Init TurboJPEG context
      handle = LibTurboJPEG.tj3Init(LibTurboJPEG::TJINIT::TJINIT_COMPRESS)
      handle.should_not be_nil

      # Set color sampling and jpeg quality
      ret = LibTurboJPEG.tj3Set(handle, LibTurboJPEG::TJPARAM::TJPARAM_SUBSAMP, LibTurboJPEG::TJSAMP::TJSAMP_GRAY)
      ret.should eq(0)

      ret = LibTurboJPEG.tj3Set(handle, LibTurboJPEG::TJPARAM::TJPARAM_QUALITY, 30)
      ret.should eq(0)

      # Get maximum jpeg size
      out_buf_size = LibTurboJPEG.tj3JPEGBufSize(img_side, img_side, LibTurboJPEG::TJSAMP::TJSAMP_GRAY)
      out_buf_size.should be > 0

      # Allocate buffer for maximum jpeg size
      out_buffer = LibTurboJPEG.tj3Alloc(out_buf_size)
      out_buffer.should be_truthy

      # Compress xor_image_buf to jpeg
      err = LibTurboJPEG.tj3Compress8(handle, image_buf, img_side, 0, img_side, LibTurboJPEG::TJPF::TJPF_GRAY, pointerof(out_buffer).as(Pointer(Pointer(UInt8))), pointerof(out_buf_size))
      err.should eq(0)
      out_buf_size.should be > 0

      # Save jpeg data to file
      File.open(jpeg_file, "wb") do |f|
        f.write Bytes.new(out_buffer.as(Pointer(UInt8)), out_buf_size)
      end

      # Free memory
      LibTurboJPEG.tj3Free(out_buffer)
      LibTurboJPEG.tj3Destroy(handle)

      ## Decode part

      file_size = File.size(jpeg_file)

      jpeg_data = Bytes.new(file_size)
      # Read entire file to jpeg_data
      File.open(jpeg_file, "rb") { |f| f.read(jpeg_data) }

      # Init turbojpeg context
      handle = LibTurboJPEG.tj3Init(LibTurboJPEG::TJINIT::TJINIT_DECOMPRESS)
      handle.should be_truthy

      # Get decompress jpeg header
      err = LibTurboJPEG.tj3DecompressHeader(handle, jpeg_data, file_size)
      err.should eq(0)

      # Get image params
      width = LibTurboJPEG.tj3Get(handle, LibTurboJPEG::TJPARAM::TJPARAM_JPEGWIDTH)
      width.should eq(256)

      height = LibTurboJPEG.tj3Get(handle, LibTurboJPEG::TJPARAM::TJPARAM_JPEGHEIGHT)
      height.should eq(256)

      # Decompressed jpeg to rgb_data
      rgb_data = Bytes.new(width * height * 3)
      res = LibTurboJPEG.tj3Decompress8(handle, jpeg_data, file_size, rgb_data, 0, LibTurboJPEG::TJPF::TJPF_RGB)
      res.should eq(0)

      # Save decompressed jpeg as rgb data
      err = LibTurboJPEG.tj3SaveImage8(handle, out_file, rgb_data, width, 0, height, LibTurboJPEG::TJPF::TJPF_RGB)
      err.should eq(0)

      # Free jpegturbo context
      LibTurboJPEG.tj3Destroy(handle)
    ensure
      uncompressed_tempfile.delete
      jpeg_tempfile.delete
    end
  end
end
