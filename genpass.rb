require 'digest/md5'
require 'active_record'
require 'date'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class Pass < ActiveRecord::Base
end

# Base information

userid = "shimizu"
username = "ShimizuKaketo"
rawpasswd = "kaketo"
r = Random.new
salt = Digest::MD5.hexdigest(r.bytes(20))
hashed = Digest::MD5.hexdigest(salt + rawpasswd)

for i in 0..100
    hashed = Digest::MD5.hexdigest(salt + hashed)
end

puts "salt = #{salt}"
puts "username = #{username}"
puts "userid = #{userid}"
puts "raw passwd = #{rawpasswd}"
puts "hashed passwd = #{hashed}"

# Update database
s = Pass.new
s.id = userid
s.salt = salt
s.hashed = hashed
s.name = username
s.time = nil
s.save

# Display all entries in database
@s = Pass.all
@s.each do |a|
    puts a.id + "\t" + a.name + "\t" + a.salt + "\t" + a.hashed
end
