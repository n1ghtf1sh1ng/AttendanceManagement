require 'digest/md5'
require 'active_record'
require 'date'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class Pass < ActiveRecord::Base
end

# User input from keyboard
trial_id = "shimizu"
trial_pass = "kaketo"

# Search recorded info
begin
    a = Pass.find(trial_id)
    db_id = a.id
    db_salt = a.salt
    db_hashed = a.hashed
rescue => e
    puts "User #{trial_id} is not found."
    exit(-1)
end

# Generate a hashed value
trial_hashed = Digest::MD5.hexdigest(db_salt + trial_pass)
for i in 0..100
    trial_hashed = Digest::MD5.hexdigest(db_salt + trial_hashed)
end

# Display internal variables
puts "--- DB ---"
puts "id = #{db_id}"
puts "salt = #{db_salt}"
puts "hashed passwd = #{db_hashed}"
puts ""
puts "--- TRIAL ---"
puts "id = #{trial_id}"
puts "passwd = #{trial_pass}"
puts "hashed passwd = #{trial_hashed}"
puts ""

# Success?
if db_hashed == trial_hashed
    if a.time == nil
        puts "Login Success (first login)"
    else
        puts "Login Success (last login:#{a.time})"
    end
    a.time = DateTime.now.strftime("%Y-%m-%d-%H%M")
    a.save
else
    puts "Login Failure"
end
