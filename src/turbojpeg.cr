require "./lib_turbo_jpeg"

class TurboJPEG
  VERSION = "0.1.1"
end

class TurboJPEG::Exception < Exception; end

class TurboJPEG::Error < TurboJPEG::Exception; end

class TurboJPEG::ClassError < TurboJPEG::Exception; end

class TurboJPEG::InitError < TurboJPEG::ClassError; end

class TurboJPEG
  @handle : LibTurboJPEG::TJHandle
  @input_buffer : Bytes?
  @mmap_view : Pointer(Void)
  @mmap_length : LibC::SizeT
  @scaling_factor : ScalingFactor

  getter! input_buffer
  getter! scaling_factor

  enum InitType
    COMPRESS   = LibTurboJPEG::TJINIT::TJINIT_COMPRESS
    DECOMPRESS = LibTurboJPEG::TJINIT::TJINIT_DECOMPRESS
    TRANSFORM  = LibTurboJPEG::TJINIT::TJINIT_TRANSFORM
  end

  enum Param
    STOPONWARNING = LibTurboJPEG::TJPARAM::TJPARAM_STOPONWARNING
    BOTTOMUP      = LibTurboJPEG::TJPARAM::TJPARAM_BOTTOMUP
    NOREALLOC     = LibTurboJPEG::TJPARAM::TJPARAM_NOREALLOC
    QUALITY       = LibTurboJPEG::TJPARAM::TJPARAM_QUALITY
    SUBSAMP       = LibTurboJPEG::TJPARAM::TJPARAM_SUBSAMP
    JPEGWIDTH     = LibTurboJPEG::TJPARAM::TJPARAM_JPEGWIDTH
    JPEGHEIGHT    = LibTurboJPEG::TJPARAM::TJPARAM_JPEGHEIGHT
    PRECISION     = LibTurboJPEG::TJPARAM::TJPARAM_PRECISION
    COLORSPACE    = LibTurboJPEG::TJPARAM::TJPARAM_COLORSPACE
    FASTUPSAMPLE  = LibTurboJPEG::TJPARAM::TJPARAM_FASTUPSAMPLE
    FASTDCT       = LibTurboJPEG::TJPARAM::TJPARAM_FASTDCT
    OPTIMIZE      = LibTurboJPEG::TJPARAM::TJPARAM_OPTIMIZE
    PROGRESSIVE   = LibTurboJPEG::TJPARAM::TJPARAM_PROGRESSIVE
    SCANLIMIT     = LibTurboJPEG::TJPARAM::TJPARAM_SCANLIMIT
    ARITHMETIC    = LibTurboJPEG::TJPARAM::TJPARAM_ARITHMETIC
    LOSSLESS      = LibTurboJPEG::TJPARAM::TJPARAM_LOSSLESS
    LOSSLESSPSV   = LibTurboJPEG::TJPARAM::TJPARAM_LOSSLESSPSV
    LOSSLESSPT    = LibTurboJPEG::TJPARAM::TJPARAM_LOSSLESSPT
    RESTARTBLOCKS = LibTurboJPEG::TJPARAM::TJPARAM_RESTARTBLOCKS
    RESTARTROWS   = LibTurboJPEG::TJPARAM::TJPARAM_RESTARTROWS
    XDENSITY      = LibTurboJPEG::TJPARAM::TJPARAM_XDENSITY
    YDENSITY      = LibTurboJPEG::TJPARAM::TJPARAM_YDENSITY
    DENSITYUNITS  = LibTurboJPEG::TJPARAM::TJPARAM_DENSITYUNITS
    MAXMEMORY     = LibTurboJPEG::TJPARAM::TJPARAM_MAXMEMORY
    MAXPIXELS     = LibTurboJPEG::TJPARAM::TJPARAM_MAXPIXELS
    SAVEMARKERS   = LibTurboJPEG::TJPARAM::TJPARAM_SAVEMARKERS

    # param synonyms
    WIDTH  = JPEGWIDTH
    HEIGHT = JPEGHEIGHT
  end

  enum Samp
    SAMP_444     = LibTurboJPEG::TJSAMP::TJSAMP_444
    SAMP_422     = LibTurboJPEG::TJSAMP::TJSAMP_422
    SAMP_420     = LibTurboJPEG::TJSAMP::TJSAMP_420
    SAMP_GRAY    = LibTurboJPEG::TJSAMP::TJSAMP_GRAY
    SAMP_440     = LibTurboJPEG::TJSAMP::TJSAMP_440
    SAMP_411     = LibTurboJPEG::TJSAMP::TJSAMP_411
    SAMP_441     = LibTurboJPEG::TJSAMP::TJSAMP_441
    SAMP_UNKNOWN = LibTurboJPEG::TJSAMP::TJSAMP_UNKNOWN
  end

  enum Colorspace
    RGB   = LibTurboJPEG::TJCS::TJCS_RGB
    YCbCr = LibTurboJPEG::TJCS::TJCS_YCbCr
    GRAY  = LibTurboJPEG::TJCS::TJCS_GRAY
    CMYK  = LibTurboJPEG::TJCS::TJCS_CMYK
    YCCK  = LibTurboJPEG::TJCS::TJCS_YCCK
  end

  enum PixelFormat
    RGB     = LibTurboJPEG::TJPF::TJPF_RGB
    BGR     = LibTurboJPEG::TJPF::TJPF_BGR
    RGBX    = LibTurboJPEG::TJPF::TJPF_RGBX
    BGRX    = LibTurboJPEG::TJPF::TJPF_BGRX
    XBGR    = LibTurboJPEG::TJPF::TJPF_XBGR
    XRGB    = LibTurboJPEG::TJPF::TJPF_XRGB
    GRAY    = LibTurboJPEG::TJPF::TJPF_GRAY
    RGBA    = LibTurboJPEG::TJPF::TJPF_RGBA
    BGRA    = LibTurboJPEG::TJPF::TJPF_BGRA
    ABGR    = LibTurboJPEG::TJPF::TJPF_ABGR
    ARGB    = LibTurboJPEG::TJPF::TJPF_ARGB
    CMYK    = LibTurboJPEG::TJPF::TJPF_CMYK
    UNKNOWN = LibTurboJPEG::TJPF::TJPF_UNKNOWN
  end

  alias ScalingFactor = LibTurboJPEG::TJScalingFactor

  struct ScalingFactor
    getter num
    getter denom

    def initialize(@num : Int32, @denom : Int32)
    end

    def to_s(io)
      io << num
      io << "/"
      io << denom
    end

    def self.unscaled
      new(1, 1)
    end
  end

  def self.scaling_factor(num : Int32 = 1, denom : Int32 = 1)
    ScalingFactor.new(num, denom)
  end

  def initialize(init_type : InitType = InitType::TRANSFORM)
    @scaling_factor = ScalingFactor.unscaled
    @mmap_view = Pointer(Void).null
    @mmap_length = 0

    @handle = LibTurboJPEG.tj3Init(LibTurboJPEG::TJINIT.from_value init_type.value)
    raise TurboJPEG::InitError.new("Can't init TurboJPEG") if @handle.null?
  end

  def finalize
    LibTurboJPEG.tj3Destroy(@handle)
    munmap
  end

  def read_file(jpeg_file_path, decompress_header : Bool = true)
    input_buffer = Bytes.new(File.size(jpeg_file_path))
    File.open(jpeg_file_path, "rb") { |f| f.read(input_buffer) }
    @input_buffer = input_buffer

    self.decompress_header if decompress_header
  end

  def munmap
    return if @mmap_view.null?

    result = LibC.munmap(@mmap_view, @mmap_length) if @mmap_view != LibC::MAP_FAILED && @mmap_view != Pointer(Void).null
    raise RuntimeError.from_errno("Cannot free mappend memory via munmap") if result != 0
  end

  def mmap_file(jpeg_file, prot = LibC::PROT_READ, flags = LibC::MAP_PRIVATE, offset = 0_u64)
    file_size = File.size(file_path)
    File.open(jpeg_file, "r") do |f|
      @mmap_view = LibC.mmap(nil, file_size, prot, flags, f.fd, offset)
      raise RuntimeError.from_errno("Cannot map memory (length=#{file_size.humanize_bytes})") if @mmap_view == LibC::MAP_FAILED || @mmap_view == nil || @mmap_view.null?
      @mmap_length = file_size
    end

    @input_buffer.new @mmap_view, @mmap_length
  end

  def decompress_header
    if buf = @input_buffer
      err = LibTurboJPEG.tj3DecompressHeader(@handle, buf, buf.size)
      raise TurboJPEG::Error.new("Failed to decompress JPEG header: #{last_error}") if err != 0
    end
  end

  def scaling_factor=(sf : ScalingFactor)
    err = LibTurboJPEG.tj3SetScalingFactor(@handle, sf)
    raise TurboJPEG::Error.new("Can't set scaling factor #{sf}: #{last_error}") if err != 0
    @scaling_factor = sf
  end

  def set_scaling_factor(num : Int32, denom : Int32)
    self.scaling_factor = self.class.scaling_factor(num, denom)
  end

  def width
    get :jpegwidth
  end

  def width=(val)
    set :jpegwidth, val
  end

  def height
    get :jpegheight
  end

  def height=(val)
    set :jpegheight, val
  end

  def subsamp
    TurboJPEG::Samp.from_value get(:subsamp)
  end

  def subsamp=(samp : TurboJPEG::Samp)
    set :subsamp, LibTurboJPEG::TJSAMP.from_value(samp.value)
  end

  def colorspace
    TurboJPEG::Colorspace.from_value get(:colorspace)
  end

  def precision
    get :precision
  end

  def colorspace=(cs : TurboJPEG::Colorspace)
    set(:colorspace, LibTurboJPEG::TJCS.from_value(cs))
  end

  def get(param : Param)
    val = LibTurboJPEG.tj3Get(@handle, LibTurboJPEG::TJPARAM.from_value(param.value))
    raise TurboJPEG::Error.new("Value for #{param} is unknown: #{last_error}") if val == -1
    val
  end

  def set(param : Param, value)
    ret = LibTurboJPEG.tj3Set(@handle, LibTurboJPEG::TJPARAM.from_value(param.value), value)
    raise TurboJPEG::Error.new("Cant set #{param} = #{value}: #{last_error}") if ret == -1
    ret
  end

  @[AlwaysInline]
  def scaled(dimension, scaling_factor : ScalingFactor = @scaling_factor)
    (((dimension) * scaling_factor.num + scaling_factor.denom - 1) // scaling_factor.denom)
  end

  @[AlwaysInline]
  def scaled_width
    scaled(width)
  end

  @[AlwaysInline]
  def scaled_height
    scaled(height)
  end

  def decompress(rgb_data : Bytes, pitch = 0, pixel_format : PixelFormat = PixelFormat::RGB) : Bytes
    buf = case precision
          when 8
            decompress8(rgb_data, pitch: pitch, pixel_format: pixel_format)
          else
            raise "Precision=#{precision} not supported yet in TurboJPEG wrapper. Use low level bindings LibTurboJPEG instead."
          end

    buf.not_nil!
  end

  def decompress8(rgb_data = Bytes.new(scaled_width * scaled_height * 3), pitch = 0, pixel_format : PixelFormat = PixelFormat::RGB)
    if input_buffer = @input_buffer
      ret = LibTurboJPEG.tj3Decompress8(@handle, input_buffer, input_buffer.size, rgb_data, pitch, LibTurboJPEG::TJPF.from_value(pixel_format.value))
      raise TurboJPEG::Error.new("JPEG decompress error: #{last_error}") if ret != 0
      return rgb_data
    else
      raise TurboJPEG::Error.new("Can't decompress empty jpeg buffer. Is it loaded?") if @input_buffer.nil?
    end
  end

  def save_image(rgb_data : Bytes, image_file_path : String, pitch = 0, pixel_format : PixelFormat = PixelFormat::RGB)
    case precision
    when 8
      save_image8(rgb_data, image_file_path, pitch, pixel_format)
    else
      raise "Precision=#{precision} not supported yet in TurboJPEG wrapper. Use low level bindings LibTurboJPEG instead."
    end
  end

  def save_image8(rgb_data : Bytes, image_file_path : String, pitch = 0, pixel_format : PixelFormat = PixelFormat::RGB)
    ret = LibTurboJPEG.tj3SaveImage8(@handle, image_file_path, rgb_data, scaled_width, pitch, scaled_height, LibTurboJPEG::TJPF.from_value(pixel_format.value))
    raise TurboJPEG::Error.new("JPEG decompress error: #{last_error}") if ret != 0
  end

  # def to_unsafe
  #   @handle
  # end

  def last_error
    "#{String.new(LibTurboJPEG.tj3GetErrorStr(@handle))} (error code: #{LibTurboJPEG.tj3GetErrorCode(@handle)})"
  end

  def self.last_error
    "#{String.new(LibTurboJPEG.tj3GetErrorStr(nil))} (error code: #{LibTurboJPEG.tj3GetErrorCode(nil)})"
  end
end
