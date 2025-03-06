@[Link("libturbojpeg")]
lib LibTurboJPEG
  enum TJINIT
    TJINIT_COMPRESS
    TJINIT_DECOMPRESS
    TJINIT_TRANSFORM
  end

  enum TJPARAM
    TJPARAM_STOPONWARNING
    TJPARAM_BOTTOMUP
    TJPARAM_NOREALLOC
    TJPARAM_QUALITY
    TJPARAM_SUBSAMP
    TJPARAM_JPEGWIDTH
    TJPARAM_JPEGHEIGHT
    TJPARAM_PRECISION
    TJPARAM_COLORSPACE
    TJPARAM_FASTUPSAMPLE
    TJPARAM_FASTDCT
    TJPARAM_OPTIMIZE
    TJPARAM_PROGRESSIVE
    TJPARAM_SCANLIMIT
    TJPARAM_ARITHMETIC
    TJPARAM_LOSSLESS
    TJPARAM_LOSSLESSPSV
    TJPARAM_LOSSLESSPT
    TJPARAM_RESTARTBLOCKS
    TJPARAM_RESTARTROWS
    TJPARAM_XDENSITY
    TJPARAM_YDENSITY
    TJPARAM_DENSITYUNITS
    TJPARAM_MAXMEMORY
    TJPARAM_MAXPIXELS
    TJPARAM_SAVEMARKERS
  end

  enum TJPF
    TJPF_RGB
    TJPF_BGR
    TJPF_RGBX
    TJPF_BGRX

    TJPF_XBGR
    TJPF_XRGB
    TJPF_GRAY
    TJPF_RGBA

    TJPF_BGRA
    TJPF_ABGR
    TJPF_ARGB
    TJPF_CMYK

    TJPF_UNKNOWN
  end

  enum TJCS
    TJCS_RGB
    TJCS_YCbCr
    TJCS_GRAY
    TJCS_CMYK
    TJCS_YCCK
  end

  enum TJSAMP
    #  4:4:4 chrominance subsampling (no chrominance subsampling)
    #
    #  The JPEG or YUV image will contain one chrominance component for every
    #  pixel in the source image.

    TJSAMP_444

    #  4:2:2 chrominance subsampling
    #
    #  The JPEG or YUV image will contain one chrominance component for every 2x1
    #  block of pixels in the source image.

    TJSAMP_422

    #  4:2:0 chrominance subsampling
    #
    #  The JPEG or YUV image will contain one chrominance component for every 2x2
    #  block of pixels in the source image.

    TJSAMP_420

    #  Grayscale
    #
    #  The JPEG or YUV image will contain no chrominance components.

    TJSAMP_GRAY

    #  4:4:0 chrominance subsampling
    #
    #  The JPEG or YUV image will contain one chrominance component for every 1x2
    #  block of pixels in the source image.
    #
    #  @note 4:4:0 subsampling is not fully accelerated in libjpeg-turbo.

    TJSAMP_440

    #  4:1:1 chrominance subsampling
    #
    #  The JPEG or YUV image will contain one chrominance component for every 4x1
    #  block of pixels in the source image.  All else being equal\n a JPEG image
    #  with 4:1:1 subsampling is almost exactly the same size as a JPEG image
    #  with 4:2:0 subsampling, and in the aggregate, both subsampling methods
    #  produce approximately the same perceptual quality.  However, 4:1:1 is
    #  better able to reproduce sharp horizontal features.
    #
    #  @note 4:1:1 subsampling is not fully accelerated in libjpeg-turbo.

    TJSAMP_411

    #  4:4:1 chrominance subsampling
    #
    #  The JPEG or YUV image will contain one chrominance component for every 1x4
    #  block of pixels in the source image.  All else being equal, a JPEG image
    #  with 4:4:1 subsampling is almost exactly the same size as a JPEG image
    #  with 4:2:0 subsampling, and in the aggregate, both subsampling methods
    #  produce approximately the same perceptual quality.  However, 4:4:1 is
    #  better able to reproduce sharp vertical features.
    #
    #  @note 4:4:1 subsampling is not fully accelerated in libjpeg-turbo.

    TJSAMP_441

    #  Unknown subsampling
    #
    #  The JPEG image uses an unusual type of chrominance subsampling.  Such
    #  images can be decompressed into packed-pixel images, but they cannot be
    #  - decompressed into planar YUV images,
    #  - losslessly transformed if #TJXOPT_CROP is specified and #TJXOPT_GRAY is
    #  not specified, or
    #  - partially decompressed using a cropping region.

    TJSAMP_UNKNOWN = -1
  end

  enum TJERR
    TJERR_WARNING
    TJERR_FATAL
  end

  enum TJXOP
    TJXOP_NONE
    TJXOP_HFLIP
    TJXOP_VFLIP
    TJXOP_TRANSPOSE

    TJXOP_TRANSVERSE
    TJXOP_ROT90
    TJXOP_ROT180
    TJXOP_ROT270
  end

  enum TJComponentID
    # componentID ID number of the image plane (0 = Y, 1 = U/Cb, 2 = V/Cr)
    Y  = 0_i32
    U  = 1_i32
    V  = 2_i32
    Cb = U
    Cr = V
  end

  struct TJRegion
    x : Int32
    y : Int32
    w : Int32
    h : Int32
  end

  struct TJScalingFactor
    num : Int32
    denom : Int32
  end

  struct TJTransform
    #  Cropping region
    r : TJRegion

    #  One of the @ref TJXOP "transform operations"
    op : Int32

    #  The bitwise OR of one of more of the @ref TJXOPT_ARITHMETIC
    #  "transform options"

    options : Int32

    #  Arbitrary data that can be accessed within the body of the callback
    #  function

    data : Void*

    #  A callback function that can be used to modify the DCT coefficients after
    #  they are losslessly transformed but before they are transcoded to a new
    #  JPEG image.  This allows for custom filters or other transformations to be
    #  applied in the frequency domain.
    #
    #  @param coeffs pointer to an array of transformed DCT coefficients.  (NOTE:
    #  This pointer is not guaranteed to be valid once the callback returns, so
    #  applications wishing to hand off the DCT coefficients to another function
    #  or library should make a copy of them within the body of the callback.)
    #
    #  @param arrayRegion #tjregion structure containing the width and height of
    #  the array pointed to by `coeffs` as well as its offset relative to the
    #  component plane.  TurboJPEG implementations may choose to split each
    #  component plane into multiple DCT coefficient arrays and call the callback
    #  function once for each array.
    #
    #  @param planeRegion #tjregion structure containing the width and height of
    #  the component plane to which `coeffs` belongs
    #
    #  @param componentID ID number of the component plane to which `coeffs`
    #  belongs.  (Y, Cb, and Cr have, respectively, ID's of 0, 1, and 2 in
    #  typical JPEG images.)
    #
    #  @param transformID ID number of the transformed image to which `coeffs`
    #  belongs.  This is the same as the index of the transform in the
    #  `transforms` array that was passed to #tj3Transform().
    #
    #  @param transform a pointer to a #tjtransform structure that specifies the
    #  parameters and/or cropping region for this transform
    #
    #  @return 0 if the callback was successful, or -1 if an error occurred.

    # int (*customFilter) (short *coeffs, tjregion arrayRegion,
    #  tjregion planeRegion, int componentID, int transformID,
    #  struct tjtransform *transform);
    callback : Void*
  end

  type TJHandle = Void*

  # Create a new TurboJPEG instance.
  fun tj3Init(initType : Int32) : TJHandle

  # Destroy a TurboJPEG instance.
  fun tj3Destroy(tjhandle : TJHandle)

  # Returns a descriptive error message explaining why the last command failed
  fun tj3GetErrorStr(tjhandle : TJHandle) : UInt8*

  # Returns a code indicating the severity of the last error
  fun tj3GetErrorCode(tjhandle : TJHandle) : Int32

  # Set the value of a parameter.
  fun tj3Set(tjhandle : TJHandle, param : TJPARAM, value : Int32) : Int32

  # Get the value of a parameter.
  fun tj3Get(tjhandle : TJHandle, param : TJPARAM) : Int32

  # Allocate a byte buffer for use with TurboJPEG.
  fun tj3Alloc(bytes : LibC::SizeT) : Void*

  # Free a byte buffer previously allocated by TurboJPEG.
  fun tj3Free(buffer : Void*)

  # The maximum size of the buffer (in bytes) required to hold a JPEG image with the given parameters.
  fun tj3JPEGBufSize(width : Int32, height : Int32, jpegSubsamp : TJSAMP) : LibC::SizeT

  # The size of the buffer (in bytes) required to hold a unified planar YUV image with the given parameters.
  fun tj3YUVBufSize(width : Int32, align : Int32, height : Int32, subsamp : TJSAMP) : LibC::SizeT

  # The size of the buffer (in bytes) required to hold a YUV image plane with the given parameters.
  fun tj3YUVPlaneSize(componentID : TJComponentID, width : Int32, stride : Int32, height : Int32, subsamp : TJSAMP) : LibC::SizeT

  # The plane width of a YUV image plane with the given parameters.
  fun tj3YUVPlaneWidth(componentID : Int32, width : Int32, subsamp : TJSAMP) : Int32

  # The plane height of a YUV image plane with the given parameters.
  fun tj3YUVPlaneHeight(componentID : Int32, height : Int32, subsamp : TJSAMP) : Int32

  # Embed an ICC (International Color Consortium) color management profile in JPEG images generated by subsequent compression and lossless transformation operations.
  fun tj3SetICCProfile(tjhandle : TJHandle, iccBuf : UInt8*, iccSize : LibC::SizeT) : Int32

  # Compress a packed-pixel RGB, grayscale, or CMYK image with 2 to 8 bits of data precision per sample into a JPEG image with the same data precision.
  fun tj3Compress8(tjhandle : TJHandle, srcBuf : UInt8*, width : Int32, pitch : Int32, height : Int32, pixelFormat : TJPF, jpegBuf : UInt8**, jpegSize : LibC::SizeT*) : Int32

  # Compress a packed-pixel RGB, grayscale, or CMYK image with 9 to 12 bits of data precision per sample into a JPEG image with the same data precision.
  fun tj3Compress12(tjhandle : TJHandle, srcBuf : Int16*, width : Int32, pitch : Int32, height : Int32, pixelFormat : TJPF, jpegBuf : UInt8**, jpegSize : LibC::SizeT*) : Int32

  # Compress a packed-pixel RGB, grayscale, or CMYK image with 13 to 16 bits of data precision per sample into a lossless JPEG image with the same data precision.
  fun tj3Compress16(tjhandle : TJHandle, srcBuf : UInt16*, width : Int32, pitch : Int32, height : Int32, pixelFormat : TJPF, jpegBuf : UInt8**, jpegSize : LibC::SizeT*) : Int32

  # Compress a set of 8-bit-per-sample Y, U (Cb), and V (Cr) image planes into an 8-bit-per-sample JPEG image.
  fun tj3CompressFromYUVPlanes8(tjhandle : TJHandle, srcPlanes : UInt8**, width : Int32, strides : Int32*, height : Int32, jpegBuf : UInt8**, jpegSize : LibC::SizeT*) : Int32

  # Compress an 8-bit-per-sample unified planar YUV image into an 8-bit-per-sample JPEG image.
  fun tj3CompressFromYUV8(tjhandle : TJHandle, srcBuf : UInt8*, width : Int32, align : Int32, height : Int32, jpegBuf : UInt8**, jpegSize : LibC::SizeT*) : Int32

  # Encode an 8-bit-per-sample packed-pixel RGB or grayscale image into separate 8-bit-per-sample Y, U (Cb), and V (Cr) image planes.
  fun tj3EncodeYUVPlanes8(tjhandle : TJHandle, srcBuf : UInt8*, width : Int32, pitch : Int32, height : Int32, pixelFormat : TJPF, dstPlanes : UInt8**, strides : Int32*) : Int32

  # Encode an 8-bit-per-sample packed-pixel RGB or grayscale image into an 8-bit-per-sample unified planar YUV image.
  fun tj3EncodeYUV8(tjhandle : TJHandle, srcBuf : UInt8*, width : Int32, pitch : Int32, height : Int32, pixelFormat : TJPF, dstBuf : UInt8*, align : Int32) : Int32

  # Retrieve information about a JPEG image without decompressing it, or prime the decompressor with quantization and Huffman tables.
  fun tj3DecompressHeader(tjhandle : TJHandle, jpegBuf : UInt8*, jpegSize : LibC::SizeT) : Int32

  # Retrieve the ICC (International Color Consortium) color management profile (if any) that was previously extracted from a JPEG image.
  fun tj3GetICCProfile(tjhandle : TJHandle, iccBuf : UInt8**, iccSize : LibC::SizeT*) : Int32

  # Returns a list of fractional scaling factors that the JPEG decompressor supports.
  fun tj3GetScalingFactors(numScalingFactors : Int32*) : TJScalingFactor*

  # Set the scaling factor for subsequent lossy decompression operations.
  fun tj3SetScalingFactor(tjhandle : TJHandle, scalingFactor : TJScalingFactor) : Int32

  # Set the cropping region for partially decompressing a lossy JPEG image into a packed-pixel image.
  fun tj3SetCroppingRegion(tjhandle : TJHandle, croppingRegion : TJRegion) : Int32

  # Retrieve information about a JPEG image without decompressing it, or prime the decompressor with quantization and Huffman tables.
  # fun tj3DecompressHeader(tjhandle : TJHandle, jpegBuf : UInt8*, jpegSize : LibC::SizeT) : Int32

  # Decompress a JPEG image with 2 to 8 bits of data precision per sample into a packed-pixel RGB, grayscale, or CMYK image with the same data precision.
  fun tj3Decompress8(tjhandle : TJHandle, jpegBuf : UInt8*, jpegSize : LibC::SizeT, dstBuf : UInt8*, pitch : Int32, pixelFormat : TJPF) : Int32

  # Decompress a JPEG image with 9 to 12 bits of data precision per sample into a packed-pixel RGB, grayscale, or CMYK image with the same data precision.
  fun tj3Decompress12(tjhandle : TJHandle, jpegBuf : UInt8*, jpegSize : LibC::SizeT, dstBuf : Int16*, pitch : Int32, pixelFormat : TJPF) : Int32

  # Decompress a lossless JPEG image with 13 to 16 bits of data precision per sample into a packed-pixel RGB, grayscale, or CMYK image with the same data precision.
  fun tj3Decompress16(tjhandle : TJHandle, jpegBuf : UInt8*, jpegSize : LibC::SizeT, dstBuf : UInt16*, pitch : Int32, pixelFormat : TJPF) : Int32

  # Decode a set of 8-bit-per-sample Y, U (Cb), and V (Cr) image planes into an 8-bit-per-sample packed-pixel RGB or grayscale image.
  fun tj3DecompressToYUVPlanes8(tjhandle : TJHandle, jpegBuf : UInt8*, jpegSize : LibC::SizeT, dstPlanes : UInt8**, strides : Int32*) : Int32

  # Decompress an 8-bit-per-sample JPEG image into an 8-bit-per-sample unified planar YUV image.
  fun tj3DecompressToYUV8(tjhandle : TJHandle, jpegBuf : UInt8*, jpegSize : LibC::SizeT, dstBuf : UInt8*, align : Int32) : Int32

  # Decode an 8-bit-per-sample unified planar YUV image into an 8-bit-per-sample packed-pixel RGB or grayscale image.
  fun tj3DecodeYUVPlanes8(tjhandle : TJHandle, srcPlanes : UInt8**, strides : Int32, dstBuf : UInt8*, width : Int32, pitch : Int32, height : Int32, pixelFormat : TJPF) : Int32

  # Decode an 8-bit-per-sample unified planar YUV image into an 8-bit-per-sample packed-pixel RGB or grayscale image.
  fun tj3DecodeYUV8(tjhandle : TJHandle, srcBuf : UInt8*, align : Int32, dstBuf : UInt8*, width : Int32, pitch : Int32, height : Int32, pixelFormat : TJPF) : Int32

  # The maximum size of the buffer (in bytes) required to hold a JPEG image transformed with the given transform parameters and/or cropping region.
  fun tj3TransformBufSize(tjhandle : TJHandle, transform : TJTransform*) : LibC::SizeT

  # Losslessly transform a JPEG image into another JPEG image.
  fun tj3Transform(tjhandle : TJHandle, jpegBuf : UInt8*, jpegSize : LibC::SizeT, n : Int32, dstBufs : UInt8**, dstSizes : LibC::SizeT*, transforms : TJTransform*) : Int32

  # Load a packed-pixel image with 2 to 8 bits of data precision per sample from disk into memory.
  fun tj3LoadImage8(tjhandle : TJHandle, filename : UInt8*, width : Int32*, align : Int32, height : Int32*, pixelFormat : TJPF*) : UInt8*

  # Load a packed-pixel image with 9 to 12 bits of data precision per sample from disk into memory
  fun tj3LoadImage12(tjhandle : TJHandle, filename : UInt8*, width : Int32*, align : Int32, height : Int32*, pixelFormat : TJPF*) : Int16*

  # Load a packed-pixel image with 13 to 16 bits of data precision per sample from disk into memory.
  fun tj3LoadImage16(tjhandle : TJHandle, filename : UInt8*, width : Int32*, align : Int32, height : Int32*, pixelFormat : TJPF*) : UInt16*

  # Save a packed-pixel image with 2 to 8 bits of data precision per sample from memory to disk.
  fun tj3SaveImage8(tjhandle : TJHandle, filename : UInt8*, buffer : UInt8*, width : Int32, pitch : Int32, height : Int32, pixelFormat : TJPF) : Int32

  #   Save a packed-pixel image with 9 to 12 bits of data precision per sample from memory to disk.
  fun tj3SaveImage12(tjhandle : TJHandle, filename : UInt8*, buffer : Int16*, width : Int32, pitch : Int32, height : Int32, pixelFormat : TJPF) : Int32

  # Save a packed-pixel image with 13 to 16 bits of data precision per sample from memory to disk.
  fun tj3SaveImage16(tjhandle : TJHandle, filename : UInt8*, buffer : UInt16*, width : Int32, pitch : Int32, height : Int32, pixelFormat : TJPF) : Int32
end
