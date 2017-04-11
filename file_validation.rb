class FileValidation

  attr_reader :file_types, :file_ext, :file_data

  def initialize
    @file_types = {
      bmp:  "image/bmp",
      gif: "image/gif",
      jpg: "image/jpeg",
      png: "image/png",
      tiff: "image/tiff"
    }
    @file_ext = {
      bmp: [".bmp", ".BMP"],
      gif: [".gif", ".GIF"],
      jpg: [".jpg", ".JPG", ".jpe", ".JPE", ".jpeg", ".JPEG"],
      png: [".png", ".PNG"],
      tiff: [".tif", ".TIF", ".tiff", ".TIFF"]
    }
    @file_data = {
      bmp: "BM",
      gif: ["\x47\x49\x46\x38\x37\x61", "\x47\x49\x46\x38\x39\x61"],
      jpg: ["\xFF\xD8\xFF\xE0", "\xFF\xD8\xFF\xE1"],
      png: ["\x89\x50\x4E\x47\x0D\x0A\x1A\x0A"],
      tiff: ["\x4d\x4d\x00\x2a", "\x49\x49\x2a\x00"]
    }
  end

  def bmp?(details)
    (@file_types[:bmp] == details[:type]) &&
    (@file_ext[:bmp].include? details[:ext]) &&
    (@file_data[:bmp] == details[:data][0, 2])
  end

  def gif?(details)
    (@file_types[:gif] == details[:type]) &&
    (@file_ext[:gif].include? details[:ext]) &&
    (@file_data[:gif].include? details[:data][0, 6])
  end

  def jpg?(details)
    (@file_types[:jpg] == details[:type]) &&
    (@file_ext[:jpg].include? details[:ext]) &&
    (@file_data[:jpg].include? details[:data][0, 4])
  end

  def png?(details)
    (@file_types[:png] == details[:type]) &&
    (@file_ext[:png].include? details[:ext]) &&
    (@file_data[:png].include? details[:data])
  end

  def tiff?(details)
    (@file_types[:tiff] == details[:type]) &&
    (@file_ext[:tiff].include? details[:ext]) &&
    (@file_data[:tiff].include? details[:data][0, 4])
  end

  def get_details(file_hash)
    details = {}
    details[:type] = file_hash[:type]
    details[:ext] = File.extname(file_hash[:filename])
    binary = File.binread(file_hash[:tempfile])[0, 8]
    details[:data] = binary.force_encoding("UTF-8")
    return details
  end

  def validate_file(file_hash)
    details = get_details(file_hash)
    bmp?(details) || gif?(details) || jpg?(details) || png?(details) || tiff?(details)
  end

end