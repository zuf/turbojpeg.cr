require "./spec_helper"

describe TurboJPEG do
  # TODO: Write tests

  context "class" do
    it "should return scaling_factor" do
      sf = TurboJPEG.scaling_factor(num: 7, denom: 8)
      sf.num.should eq 7
      sf.denom.should eq 8
      sf.to_s.should eq "7/8"
    end

    it "should init with valid params" do
      # withoud args (default to :transform)
      TurboJPEG.new.should be_truthy

      # with symbols
      TurboJPEG.new(:compress).should be_truthy
      TurboJPEG.new(:decompress).should be_truthy
      TurboJPEG.new(:transform).should be_truthy

      # with enums
      TurboJPEG.new(TurboJPEG::InitType::COMPRESS).should be_truthy
      TurboJPEG.new(TurboJPEG::InitType::DECOMPRESS).should be_truthy
      TurboJPEG.new(TurboJPEG::InitType::TRANSFORM).should be_truthy
    end

    it "should decompress header" do
      jpeg_file = File.join(File.dirname(__FILE__), "test_data", "gray_gradient.jpg")

      File.size(jpeg_file).should be > 0

      tj = TurboJPEG.new(:decompress)
      tj.should be_truthy

      # Should rise error for wrong file
      expect_raises(File::NotFoundError) { tj.read_file("/tmp/non_existed/random/file.ppm") }

      tj.read_file jpeg_file
      tj.input_buffer.size.should eq(File.size(jpeg_file))

      tj.width.should eq(256)
      tj.height.should eq(256)
      tj.get(:width).should eq(256)
      tj.get(:height).should eq(256)
      tj.subsamp.should eq(TurboJPEG::Samp::SAMP_GRAY)
      tj.get(:subsamp).should eq(TurboJPEG::Samp::SAMP_GRAY.value)
      tj.get(:jpegwidth).should eq(256)
      tj.get(:jpegheight).should eq(256)
      tj.get(:precision).should eq(8)
      tj.get(:colorspace).should eq(TurboJPEG::Colorspace::GRAY.value)
      tj.colorspace.should eq(TurboJPEG::Colorspace::GRAY)
    end

    it "should raise error for wrong params" do
      tj = TurboJPEG.new
      expect_raises(TurboJPEG::Error) { tj.set(:colorspace, 123) }
    end

    it "should decompress 8 bpp image" do
      jpeg_file = File.join(File.dirname(__FILE__), "test_data", "gray_gradient.jpg")
      File.size(jpeg_file).should be > 0

      tj = TurboJPEG.new(:decompress)
      tj.should be_truthy

      tj.read_file jpeg_file
      buf = Bytes.new(256*256*3)
      buf = tj.decompress(buf)
      buf.size.should eq 256*256*3

      uncompressed_tempfile = File.tempfile("test_", ".ppm")
      begin
        tj.save_image8(buf, uncompressed_tempfile.path)
        File.size(uncompressed_tempfile.path).should be > buf.size
        # TODO: Instead expected_ppm_header use StringScanner or regex.
        # Because PPM can be delimited by differend kind of spaces.
        expected_ppm_header = "P6\n#{tj.scaled_width} #{tj.scaled_height}\n255\n"
        File.open(uncompressed_tempfile.path, "rb") { |f| f.gets(delimiter: Char::ZERO, limit: expected_ppm_header.size).should eq(expected_ppm_header) }
        expect_raises(TurboJPEG::Error) { tj.save_image8(buf, "/tmp/non_existed/random/file.ppm") }
      ensure
        uncompressed_tempfile.delete
      end
    end

    it "should allow to set scaling_factor" do
      jpeg_file = File.join(File.dirname(__FILE__), "test_data", "gray_gradient.jpg")
      File.size(jpeg_file).should be > 0

      tj = TurboJPEG.new(:decompress)
      tj.should be_truthy
      tj.set_scaling_factor 1, 2

      tj.read_file jpeg_file
      tj.width.should eq(256)
      tj.height.should eq(256)
      tj.get(:width).should eq(256)
      tj.get(:height).should eq(256)

      tj.scaled_width.should eq(128)
      tj.scaled_height.should eq(128)

      tj.scaling_factor.num.should eq(1)
      tj.scaling_factor.denom.should eq(2)

      buf = Bytes.new(128*128*3)
      buf = tj.decompress(buf)
      buf.size.should eq 128*128*3

      uncompressed_tempfile = File.tempfile("test_", ".ppm")
      begin
        tj.save_image8(buf, uncompressed_tempfile.path)
        File.size(uncompressed_tempfile.path).should be > buf.size
        # TODO: Instead expected_ppm_header use StringScanner or regex.
        # Because PPM can be delimited by differend kind of spaces.
        expected_ppm_header = "P6\n#{tj.scaled_width} #{tj.scaled_height}\n255\n"
        File.open(uncompressed_tempfile.path, "rb") { |f| f.gets(delimiter: Char::ZERO, limit: expected_ppm_header.size).should eq(expected_ppm_header) }
        expect_raises(TurboJPEG::Error) { tj.save_image8(buf, "/tmp/non_existed/random/file.ppm") }
      ensure
        uncompressed_tempfile.delete
      end

      tj.set_scaling_factor 1, 8
      tj.width.should eq(256)
      tj.height.should eq(256)
      tj.get(:width).should eq(256)
      tj.get(:height).should eq(256)

      tj.scaled_width.should eq(256//8)
      tj.scaled_height.should eq(256//8)

      expect_raises(TurboJPEG::Error) { tj.set_scaling_factor 1, 1024*1024 }
      expect_raises(TurboJPEG::Error) { tj.set_scaling_factor 1, -88888 }
    end
  end

  it "encode work with lowlevel bindings" do
    img_side = 256 # image side size

    # Fill image buffer with simpl grayscale gradient
    image_buf = Bytes.new(img_side*img_side).fill { |n| (n % 256).to_u8 }

    # Init TurboJPEG context
    handle = LibTurboJPEG.tj3Init(LibTurboJPEG::TJINIT::TJINIT_COMPRESS)
    handle.should be_truthy

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

  it "decode works with lowlevel bindings" do
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
      handle.should be_truthy

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

      # # Decode part

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
