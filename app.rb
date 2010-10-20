require 'rubygems'
require 'sinatra'
require 'beanstalk-client'
require 'dm-core'
require 'dm-migrations'
require 'dm-serializer'
require 'json'

class Contact 
  include DataMapper::Resource
	property :id, Serial
	property :name, String
	property :phone, String
end

configure do 
	DataMapper.finalize
	DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/dev.db")
	DataMapper.auto_upgrade!
end

set :public, 'public'

get '/' do
	send_file(File.join('public', 'index.html'))
end

get '/contacts' do
	cache_control :no_store
	content_type :json
	Contact.all.to_json
end

post '/contact/create' do
	c = Contact.create params
	broadcast("add", c.id, c)
end

post '/contact/delete/:id' do
	puts params
	c = Contact.get(params[:id])
	c.destroy
	broadcast("delete", params[:id])
end

post '/contact/edit/:id' do
	c = Contact.get(params[:id])
	c.update params
	c.save
	broadcast("update", params[:id], c)
end

helpers do 
	def broadcast(action, id, data = nil) 
		bt = Beanstalk::Pool.new(['localhost:11300'])
		json = {:action => action, :id => id, :item => data}.to_json
		bt.put json 
		"OK"
	end
end
