require 'rubygems'
require 'sinatra'
require 'mongo'
require 'open-uri'
require 'json'

NEEDS_UPDATE = false

configure :development do
  @mhost = 'localhost'
  @mport = 27017
  @mauth = false
end

configure :production do
  @mhost = 'YOUR.MONGODB.HOST.COM'
  @mport = 27017
  @mauth = true
end

MONGO = Mongo::Connection.new(@mhost, @mport).db('likeomatic')
MONGO.authenticate('user', 's3kret') if @mauth

get '/' do
  erb :index
end

get '/i' do
  # Tracking
  begin
    MONGO["bm_clicks"].insert({:when => Time.now.utc.to_i, :ip => @env['HTTP_X_REAL_IP'] || @env['REMOTE_ADDR']})
  rescue
    # o_O
  end
  
  # Needs update?
  return '' unless NEEDS_UPDATE
  
  # We need an update
  '<span style="font: normal normal 16px/24px Helvetica,Arial,sans-serif;color:#000;background:#ff9;padding:5px;"><strong>Hey there!</strong> There is a new version of the <a href="http://likeomatic.heroku.com/">Like-o-matic</a> bookmarklet. <a href="http://likeomatic.heroku.com/">Get the new bookmarklet here &rarr;</a></span>'
end

get '/likes' do
  url = params[:url]
  begin
    r = open('http://www.facebook.com/plugins/like.php?href=' + URI.encode(url)).read
    m = r.match(/(\d+) p/)
    unless m && m[1]
      # Try 'one person'
      l = 0
      puts r
      l = 1 if r =~ /one person/i || r=~ /[a-z] likes? this/i
      json = {:stat => 'ok', :url => url, :likes => l}
    else
      json = {:stat => 'ok', :url => url, :likes => m[1].to_i}
    end
  rescue => e
    puts e.inspect
    json = {:stat => 'fail', :likes => 0}
  end
  content_type 'text/javascript', :charset => 'utf-8'
  json.to_json
end
