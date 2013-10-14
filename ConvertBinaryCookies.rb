require 'rubygems'
require 'stringio'

if ARGV.length != 1
  puts 'Usage: Ruby ConvertBinaryCookies.rb <Full path to Cookies.binarycookies file>'
  exit
end

file_path = ARGV[0]
pages = []
File.open(file_path, "r") do |f|
  file_header = f.read(4)
  if file_header != 'cook'
    puts 'Not a Cookies.binarycookie file'
    exit
  end
  
  num_pages = f.read(4).unpack("N")[0]
  page_sizes = []
  num_pages.times do |i|
    page_size = f.read(4).unpack('N')[0]
    page_sizes.push(page_size)
  end
  
  page_sizes.each do |ps|
    page = f.read(ps)
    pages.push(page)
  end
end

def get_string(offset, io)
  io.seek(offset-4, IO::SEEK_SET)
  io.readline("\0").chomp("\0")
end

pages.each do |p|
  StringIO.open(p) do |page|
    page.read(4)
    num_cookies = page.read(4).unpack('I')[0]
    cookie_offsets = []
    num_cookies.times do |i|
      cookie_offset = page.read(4).unpack('I')[0]
      cookie_offsets.push(cookie_offset)
    end
    page.read(4)
    cookie_offsets.each do |co|
      page.seek(co, IO::SEEK_SET)
      cookie_size = page.read(4).unpack('I')[0]
      cookie = page.read(cookie_size)
      StringIO.open(cookie) do |cio|
        cio.read(4)
        flags = cio.read(4).unpack('I')[0]
        https_flag = (flags & 1 > 0).to_s.upcase
        httponly_flag = (flags & 4 > 0).to_s.upcase
        cio.read(4)
        domainoffset = cio.read(4).unpack('I')[0]
        nameoffset = cio.read(4).unpack('I')[0]
        pathoffset = cio.read(4).unpack('I')[0]
        valueoffset = cio.read(4).unpack('I')[0]
        endofcookie = cio.read(8)
        expiry_date = (cio.read(8).unpack('d')[0]+978307200).to_i
        create_date = (cio.read(8).unpack('d')[0]+978307200).to_i
        
        domain = get_string(domainoffset,cio)
        name = get_string(nameoffset,cio)
        path = get_string(pathoffset,cio)
        value = get_string(valueoffset,cio)
        
        puts "#{domain}\t#{httponly_flag}\t#{path}\t#{https_flag}\t#{expiry_date}\t#{name}\t#{value}"
      end
    end
  end
end