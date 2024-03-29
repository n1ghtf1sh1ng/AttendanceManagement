require 'sinatra'
require 'digest/md5'
require 'active_record'
require 'date'

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection :development

class Pass < ActiveRecord::Base
end

class Worktime < ActiveRecord::Base
end

class Work < ActiveRecord::Base
end

set :environment, :production
set :sessions,
    expire_after: 300, # seconds 
    secret: 'n1ghtf1sh1ng'

get '/' do
    redirect '/login'
end

# ログインフォーム
get '/login' do
    erb :loginscr
end

# ログイン認証
post '/auth' do
    trial_id = params[:id]
    trial_pass = params[:pass]
    begin
        a = Pass.find(trial_id)
    rescue => e
        session[:login_flag] = false
        # ログイン失敗
        session[:error_flag] = -1
        redirect '/error'
    end
    db_hashed = a.hashed
    db_salt = a.salt
    trial_hashed = Digest::MD5.hexdigest(db_salt + trial_pass)
    for i in 0..100
        trial_hashed = Digest::MD5.hexdigest(db_salt + trial_hashed)
    end

    if db_hashed == trial_hashed
        session[:login_flag] = true
        session[:id] = params[:id]
        session[:name] = a.name
        year = Date.today.year
        month = Date.today.month
        if a.auth == 1
            redirect 'register_form'
        else
            redirect '/' + year.to_s + '/' + month.to_s
        end
    else
        # ログイン失敗
        session[:error_flag] = -1
        redirect '/error'
    end
end

# 各種エラーページ
get '/error' do
    erb :error
end

# アカウント作成成功ページ
get '/success' do
    erb :success
end

# 新規アカウント登録フォーム
get '/register_form' do
    if session[:login_flag] == true
        @pass = Pass.all
        erb :register
    else
        # 未ログインエラー
        session[:error_flag] = -3
        redirect '/error'
    end
end

# 新規アカウント登録
post '/register_form/register' do
    if session[:login_flag] == true
        begin
            if params[:pass] != params[:repass]
                session[:error_flag] = -2
                redirect '/error'
            end
            r = Random.new
            salt = Digest::MD5.hexdigest(r.bytes(20))
            hashed = Digest::MD5.hexdigest(salt + params[:pass])
            for i in 0..100
                hashed = Digest::MD5.hexdigest(salt + hashed)
            end
            s = Pass.new
            s.id = params[:id]
            s.salt = salt
            s.hashed = hashed
            s.name = params[:name]
            s.auth = 0
            s.save
            redirect '/success'
        rescue => e
            session[:error_flag] = -4
            redirect '/error'
        end
    else
        # 未ログインエラー
        session[:error_flag] = -3
        redirect '/error'
    end
end

# カレンダー表示
get '/:year/:month' do
    if session[:login_flag] == true
        y = params['year']
        m = params['month']
        year = y.to_i
        month = m.to_i
        if year <= 2100 && year >= 1900 && month <= 12 && month >= 1
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
        # 未ログインエラー
        session[:error_flag] = -3
        redirect '/error'
    end
end

# 来月のカレンダーに移動
get '/:year/:month/next' do
    if session[:login_flag] == true
        y = params['year']
        m = params['month']
        year = y.to_i
        if 1 <= m.to_i && m.to_i <= 11
            month = m.to_i + 1
        elsif m.to_i == 12
            month = 1
            year += 1
        end
        redirect '/' + year.to_s + '/' + month.to_s
    else
        # 未ログインエラー
        session[:error_flag] = -3
        redirect '/error'
    end
end

# 先月のカレンダーに移動
get '/:year/:month/last' do
    if session[:login_flag] == true
        y = params['year']
        m = params['month']
        year = y.to_i
        if 2 <= m.to_i && m.to_i <= 12
            month = m.to_i - 1
        elsif m.to_i == 1
            month = 12
            year -= 1
        end
        redirect '/' + year.to_s + '/' + month.to_s
    else
        # 未ログインエラー
        session[:error_flag] = -3
        redirect '/error'
    end
end

# 勤務情報登録フォーム
get '/:year/:month/:day' do
    if session[:login_flag] == true
        session[:date] = params['year'] + '-' + params['month'] + '-' + params['day']
        wt_hashed = Digest::MD5.hexdigest(session[:id] + session[:date])
        begin
            @wt = Worktime.find(wt_hashed)
        rescue => e
            @wt = nil
        end
        if @wt
            @actual_time = @wt.end_time[0,2].to_i*60 + @wt.end_time[3,2].to_i - @wt.start_time[0,2].to_i*60 - @wt.start_time[3,2].to_i - @wt.break_time
        else
            @actual_time = 0
        end
        @w = Work.where(member_id: session[:id]).where(date: session[:date])
        if @w.empty?
            session[:w_id] = 0
        end
        erb :contents
    else
        # 未ログインエラー
        session[:error_flag] = -3
        redirect '/error'
    end
end

# 勤務時間登録
post '/:year/:month/:day/worktime' do
    if session[:login_flag] == true
        if params[:update] == "0"
            worktime = Worktime.new
        else params[:update] == "1"
            worktime = Worktime.find(Digest::MD5.hexdigest(session[:id] + session[:date]))
        end
        worktime.member_id = session[:id]
        worktime.date = params['year'] + '-' + params['month'] + '-' + params['day']
        wt_hashed = Digest::MD5.hexdigest(session[:id] + session[:date])
        worktime.id = wt_hashed
        if params[:absence] == "1"
            worktime.start_time = "00:00"
            worktime.end_time = "00:00"
            worktime.break_time = 0
        elsif params[:absence] == "0"
            worktime.start_time = params[:start]
            worktime.end_time = params[:end]
            worktime.break_time = params[:break]
        end
        worktime.save
        redirect '/' + params['year'] + '/' + params['month'] + '/' + params['day']
    else
        # 未ログインエラー
        session[:error_flag] = -3
        redirect '/error'
    end
end

# 作業入力
post '/:year/:month/:day/work' do
    if session[:login_flag] == true
        work = Work.new
        session[:w_id] += 1
        work.work_id = session[:w_id]
        work.member_id = session[:id]
        work.date = params['year'] + '-' + params['month'] + '-' + params['day']
        work.project = params[:project]
        work.category = params[:category]
        work.time = params[:time]
        w_hashed = Digest::MD5.hexdigest(session[:id] + session[:date] + session[:w_id].to_s)
        work.id = w_hashed
        work.save
        redirect '/' + params['year'] + '/' + params['month'] + '/' + params['day']
    else
        # 未ログインエラー
        session[:error_flag] = -3
        redirect '/error'
    end
end

# 作業削除
delete '/:year/:month/:day/w_del' do
    if session[:login_flag] == true
        w_hashed = Digest::MD5.hexdigest(session[:id] + session[:date] + params[:w_id].to_s)
        w = Work.find(w_hashed)
        w.destroy
        redirect '/' + params['year'] + '/' + params['month'] + '/' + params['day']
    else
        # 未ログインエラー
        session[:error_flag] = -3
        redirect '/error'
    end
end

# ログアウト処理
get '/logout' do
    session.clear
    erb :logout
end
