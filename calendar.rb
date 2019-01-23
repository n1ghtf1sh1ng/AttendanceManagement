require "sinatra"
require "date"

set :environment, :production

get '/' do
    year = Date.today.year
    month = Date.today.month
    redirect '/' + year.to_s + '/' + month.to_s
end

get '/:year/:month' do
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
        @d = Date.today
        @d = Date.new(@d.year, @d.month)
        @p = @d - 1
        @e = Date.new(@d.year, @d.month, -1)
        erb :calendar
    end
end

next month
get '/:year/:month/next' do
    puts params['year']
    y = params['year']
    m = params['month']
    year = y.to_i
    if 1 <= m.to_i && m.to_i <= 11 then
        month = m.to_i + 1
    elsif m.to_i == 12 then
        month = 1
        year += 1
    end
    redirect '/' + year.to_s + '/' + month.to_s
end

# last month
get '/:year/:month/last' do
    y = params['year']
    m = params['month']
    year = y.to_i
    if 2 <= m.to_i && m.to_i <= 12 then
        month = m.to_i - 1
    elsif m.to_i == 1 then
        month = 12
        year -= 1
    end
    redirect '/' + year.to_s + '/' + month.to_s
end
