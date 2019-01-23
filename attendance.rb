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
        session[:date_flag] = true
        if a.time == nil
            session[:testdata] = "This is page to manage attendance.\nFirst login."
        else
            session[:testdata] = "This is page to manage attendance.\nLast login:#{a.time}"
        end
        a.time = DateTime.now.strftime("%Y-%m-%d-%H%M")
        a.save
        redirect '/contentspage'
    else
        redirect '/failure'
    end
end

get '/failure' do
    erb :failure
end

get '/contentspage' do
    if (session[:login_flag] == true)
        year = Date.today.year
        month = Date.today.month
        redirect '/contentspage/' + year.to_s + '/' + month.to_s
    else
        erb :badrequest
    end
end

get '/contentspage/:year/:month' do
    if (session[:login_flag] == true)
        y = params['year']
        m = params['month']
        year = y.to_i
        month = m.to_i
        if year <= 2100 && year >= 1900 && month <= 12 && month >= 1 then  
            @d = Date.new(year, month)
            @p = @d - 1
            @e = Date.new(year, month, -1)
            erb :calendar
        else 
            @d = Date.new(Date.today.year, Date.today.month)
            @p = @d - 1
            @e = Date.new(@d.year, @d.month, -1)
            erb :calendar
        end
    else
        erb :badrequest
    end
end

get '/contentspage/:year/:month/next' do
    if (session[:login_flag] == true)
        y = params['year']
        m = params['month']
        year = y.to_i
        if 1 <= m.to_i && m.to_i <= 11 then
            month = m.to_i + 1
        elsif m.to_i == 12 then
            month = 1
            year += 1
        end
        redirect '/contentspage/' + year.to_s + '/' + month.to_s
    else
        erb :badrequest
    end
end

get '/contentspage/:year/:month/last' do
    if (session[:login_flag] == true)
        y = params['year']
        m = params['month']
        year = y.to_i
        if 2 <= m.to_i && m.to_i <= 12 then
            month = m.to_i - 1
        elsif m.to_i == 1 then
            month = 12
            year -= 1
        end
        redirect '/contentspage/' + year.to_s + '/' + month.to_s
    else
        erb :badrequest
    end
end

get '/logout' do
    session.clear
    erb :logout
end
