require 'sinatra'
require 'digest/md5'
require 'active_record'
require 'date'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class Pass < ActiveRecord::Base
end

set :environment, :production
set :sessions,
    expire_after: 7200,
    secret: 'abcdefghij0123456789'

get '/' do
    redirect '/login'
end

get '/login' do
    erb :loginscr
end

post '/auth' do
    trial_id = params[:id]
    trial_pass = params[:pass]
    begin
        a = Pass.find(trial_id)
        db_id = a.id
        db_name = a.name
        db_salt = a.salt
        db_hashed = a.hashed
    rescue => e
        puts "User #{trial_id} is not found."
        session[:login_flag] = false
        redirect '/failure'
    end
    trial_hashed = Digest::MD5.hexdigest(db_salt + trial_pass)
    for i in 0..100
        trial_hashed = Digest::MD5.hexdigest(db_salt + trial_hashed)
    end

    if db_hashed == trial_hashed
        session[:login_flag] = true
        if a.time == nil
            session[:testdata] = "This is page to manage attendance.\nFirst login."
        else
            session[:testdata] = "This is page to manage attendance.\nLast login:#{a.time}"
        end
        a.time = DateTime.now.strftime("%Y-%m-%d-%H%M")
        a.save
        redirect '/contentspage'
    else
        session[:login_flag] = false
        redirect '/failure'
    end
end

get '/failure' do
    erb :failure
end

get '/contentspage' do
    if (session[:login_flag] == true)
        # @a = session[:testdata]
        # erb :contents
        @d = Date.today
        @d = Date.new(@d.year, @d.month)
        @p = @d - 1
        @e = Date.new(@d.year, @d.month, -1)
        erb :calendar
    else
        erb :badrequest
    end
end

get '/logout' do
    session.clear
    erb :logout
end
