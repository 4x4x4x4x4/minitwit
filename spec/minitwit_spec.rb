require_relative '../app'
require 'rspec'
require 'rest-client'
require 'json'
require 'http-cookie'

BASE_URL = 'http://localhost:5001'

def register(username, password, password2 = nil, email = nil)
    password2 ||= password
    email ||= "#{username}@example.com"
    RestClient.post(
      "#{BASE_URL}/register",
      { username: username, password: password, password2: password2, email: email },
      { follow_redirects: true }
    )
  rescue RestClient::ExceptionWithResponse => e
    e.response
  end

def login(username, password)
  response = RestClient.post(
    "#{BASE_URL}/login",
    {username: username, password: password},
    follow_redirects: true
  )
  cookies = if response.cookies.is_a?(Hash)
              response.cookies
            else
              response.cookies.each_with_object({}) do |(name, cookie), hash|
                hash[name] = cookie.is_a?(String) ? cookie : cookie.value
              end
            end
  [response, cookies]
rescue RestClient::ExceptionWithResponse => e
  e.response
end

def add_message(text, cookies)
  response = RestClient.post(
    "#{BASE_URL}/add_message",
    {text: text},
    {cookies: cookies, follow_redirects: true}
  )

  if text
    expect(response.body).to include("Your message was recorded")
  end

  response
rescue RestClient::ExceptionWithResponse => e
  e.response    
end

def register_and_login(username, password)
  register(username, password)
  response, cookies = login(username, password) # Capture session cookies
  [response, cookies]
end

def logout
  RestClient.get("#{BASE_URL}/logout", {follow_redirects: true})
rescue RestClient::ExceptionWithResponse => e
  e.response
end

def follow_user(username, cookies)
  response = RestClient.get("#{BASE_URL}/#{username}/follow", {cookies: cookies, follow_redirects: true})
  response
rescue RestClient::ExceptionWithResponse => e
  e.response
end

def unfollow_user(username, cookies)
  RestClient.get("#{BASE_URL}/#{username}/unfollow", {cookies: cookies, follow_redirects: true})
rescue RestClient::ExceptionWithResponse => e
  e.response
end

describe 'MiniTwit' do
  it 'registers users correctly' do
    response = register('user1', 'default')
    # Instead of checking for a flash message, we check that the login page is rendered.
    expect(response.body).to include('<form')
    
    response = register('user1', 'default')
    expect(response.body).to include('The username is already taken')

    response = register('', 'default')
    expect(response.body).to include('You have to enter a username')

    response = register('meh', '')
    expect(response.body).to include('You have to enter a password')

    response = register('meh', 'x', 'y')
    expect(response.body).to include('The two passwords do not match')

    response = register('meh', 'foo', 'foo', 'broken')
    expect(response.body).to include('You have to enter a valid email address')
  end

  it 'logs in and logs out correctly' do
    response, session = register_and_login('user1', 'default')
    expect(response.body).to include('You were logged in')

    response = logout
    expect(response.body).to include('You were logged out')

    response, _ = login('user1', 'wrongpassword')
    expect(response.body).to include('Invalid password')

    response, _ = login('user2', 'wrongpassword')
    expect(response.body).to include('Invalid username')
  end

  it 'records messages' do
    response, session = register_and_login('foo', 'default')
    add_message('test message 1', session)  
    add_message('<test message 2>', session)
    
    response = RestClient.get(BASE_URL, {cookies: session[:cookies]})
    
    expect(response.body).to include('test message 1')
    expect(response.body).to include('&lt;test message 2&gt;')
  end
  
  it 'handles timelines correctly' do
    response, session = register_and_login('foo', 'default')
    add_message('the message by foo', session)
    logout
    response, session = register_and_login('bar', 'default')
    add_message('the message by bar', session)

    response = RestClient.get("#{BASE_URL}/public", {cookies: session[:cookies]})
    expect(response.body).to include('the message by foo')
    expect(response.body).to include('the message by bar')

    response = RestClient.get("#{BASE_URL}/bar", {cookies: session[:cookies]})
    expect(response.body).not_to include('the message by foo')
    expect(response.body).to include('the message by bar')

    response = follow_user('foo', session)
    expect(response.body).to include('You are now following &#34;foo&#34;')

    response = RestClient.get("#{BASE_URL}/public", {cookies: session[:cookies]})
    expect(response.body).to include('the message by foo')
    expect(response.body).to include('the message by bar')

    response = RestClient.get("#{BASE_URL}/bar", {cookies: session[:cookies]})
    expect(response.body).not_to include('the message by foo')
    expect(response.body).to include('the message by bar')

    response = RestClient.get("#{BASE_URL}/foo", {cookies: session[:cookies]})
    expect(response.body).to include('the message by foo')
    expect(response.body).not_to include('the message by bar')

    response = unfollow_user('foo', session)
    expect(response.body).to include('You are no longer following &#34;foo&#34;')

    response = RestClient.get("#{BASE_URL}/bar", {cookies: session[:cookies]})
    expect(response.body).not_to include('the message by foo')
    expect(response.body).to include('the message by bar')
  end
end