require 'sinatra'

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
    username = params[:uname]
    pass = params[:pass]

    if((username == "shimizu") && (pass == "kaketo"))
        session[:login_flag] = true
        session[:testdata] = "This is page to manage attendance."
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
        @a = session[:testdata]
        erb :contents
    else
        erb :badrequest
    end
end

get '/logout' do
    session.clear
    erb :logout
end
