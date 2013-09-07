require 'digest/sha1'
require "sinatra"
require "slim"
require 'sinatra/form_helpers'
require_relative "config"

enable :sessions
set :session_secret, 'f560ef7d5932d321525c7fe1203f34b98492896391660a4a407ff7125947791964661482efe8483a3b8b91f0dbad59fa40a4acfe2a93b800328ebc64233409d6'

before { request.path_info.sub! %r{/$}, '' }
before do 
  authorize!  
end

get "/searches/new" do 
  slim :"searches/form.html"
end

post "/search" do
  @search = Search.create params[:search]
  current_user.add_search @search
  redirect "/searches", 302
end

delete "/search/:id" do
  Search[params[:id]].destroy
  redirect "/searches", 302
end

get "/searches" do
  @searches = Search.all
  slim :"searches/index.html"
end

get "/search/:search_id/iterations" do
  @iterations = Search[params[:search_id]]
end

get "/iterations/:id" do
  @iteration = Iteration[params[:id]]
end

get "/iterations/:id/flat_snapshots" do
  @iteration = Iteration[params[:id]]
  @flat_snapshots = @iteration.flat_snapshots
end

get "/searches/:search_id/last_flat_snapshots" do
  @flat_snapshots = Search[params[:search_id]].last_flat_snapshots
  @flat_snapshots.sort!{|x, y| x.price <=> y.price}
  slim :"flat_snapshots/index.html"
end

# Authentication
helpers do
  def authorize!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    auth ||=  Rack::Auth::Basic::Request.new(request.env)
    login, password = auth.provided? && auth.basic? && auth.credentials
    self.current_user = User.all.find do |u| 
      u.login == login && u.password == password 
    end
  end

  def current_user=(user)
    if user
      session['user_id'] = user.id
      @current_user = user
    end
  end

  def current_user
    user_id = session['user_id']
    @current_user ||= User[user_id] if user_id 
  end
end
