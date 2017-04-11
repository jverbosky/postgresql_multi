class FileValidation

  attr_reader :file_types, :file_ext, :file_data

  def initialize
    @file_types = {
      gif: "image/gif",
      jpg: "image/jpeg",
      png: "image/png"
    }
    @file_ext = {
      gif: [".gif", ".GIF"],
      jpg: [".jpg", ".JPG", ".jpe", ".JPE", ".jpeg", ".JPEG"],
      png: [".png", ".PNG"]
    }
    @file_data = {
      gif: ["\x47\x49\x46\x38\x37\x61", "\x47\x49\x46\x38\x39\x61"],
      jpg: ["\xFF\xD8\xFF\xE0", "\xFF\xD8\xFF\xE1"],
      png: ["\x89\x50\x4E\x47\x0D\x0A\x1A\x0A"]
    }
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
    gif?(details) || jpg?(details) || png?(details)
  end

end