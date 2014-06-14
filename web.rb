require 'digest/sha1'
require "sinatra"
require "slim"
require 'sinatra/form_helpers'
require_relative "config"

enable :sessions
set :session_secret, 'f560ef7d5932d321525c7fe1203f34b98492896391660a4a407ff7125947791964661482efe8483a3b8b91f0dbad59fa40a4acfe2a93b800328ebc64233409d6'
set :slim, :layout_engine => :slim, :layout => :"layout.html"

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
  current_user.searches_dataset[params[:id]].destroy
  redirect "/searches", 302
end

get "/searches" do
  @searches = current_user.searches
  slim :"searches/index.html"
end

get "/search/:search_id/iterations" do
  @iterations = current_user.iterations(params[:search_id])
end

get "/iterations/:id" do
  @iteration = current_user.iteration(params[:id])
end

get "/iterations/:id/flat_snapshots" do
  @flat_snapshot = current_user.flat_snapshots(params[:id])
end

get "/searches/:search_id/last_flat_snapshots" do
  @flat_snapshots = current_user
    .last_flat_snapshots(params[:search_id])
  slim :"flat_snapshots/index.html"
end

post "/black_lists/:flat_id/toggle" do
  query = {user_id: current_user.id, flat_id: params[:flat_id]}

  black_list = BlackList.where(query)
  black_list.empty? ? BlackList.create(query) : black_list.destroy
  head :ok
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
