class ServicesController < ApplicationController
  before_filter :authenticate_user!, :except => [:create, :signup, :newaccount, :failure, :update_location]
  protect_from_forgery :except => [:create]

  # GET all authentication services assigned to the current user
  def index
    @services = current_user.services.order('provider asc')
  end

  # POST to remove an authentication service
  def destroy
    # remove an authentication service linked to the current user
    @service = current_user.services.find(params[:id])

    if session[:service_id] == @service.id
      flash[:error] = 'You are currently signed in with this account!'
    else
      @service.destroy
    end

    redirect_to services_path
  end

  # POST from signup view
  def newaccount
    if params[:commit] == "Cancel"
      session[:authhash] = nil
      session.delete :authhash
      redirect_to root_url
    else  # create account
      @newuser = User.new
      @newuser.name = session[:authhash][:name]
      @newuser.email = session[:authhash][:email]
      @newuser.services.build(:oauth_token => session[:authhash][:token], :oauth_secret => session[:authhash][:secret], :provider => session[:authhash][:provider], :uid => session[:authhash][:uid], :uname => session[:authhash][:name], :uemail => session[:authhash][:email], :ulocation => session[:authhash][:location])

      if @newuser.save!
        # signin existing user
        # in the session his user id and the service id used for signing in is stored
        session[:user_id] = @newuser.id
        session[:service_id] = @newuser.services.first.id

        flash[:notice] = 'Your account has been created and you have been signed in!'
        redirect_to services_path
      else
        flash[:error] = 'This is embarrassing! There was an error while creating your account from which we were not able to recover.'
        redirect_to services_path
      end
    end
  end

  # Sign out current user
  def signout
    if current_user
      session[:user_id] = nil
      session[:service_id] = nil
      session.delete :user_id
      session.delete :service_id
      flash[:notice] = 'You have been signed out!'
    end
    redirect_to root_url
  end




  # callback: success
  # This handles signing in and adding an authentication service to existing accounts itself
  # It renders a separate view if there is a new user to create
  def create
    # get the service parameter from the Rails router
    params[:service] ? service_route = params[:service] : service_route = 'No service recognized (invalid callback)'

    # get the full hash from omniauth
    omniauth = request.env['omniauth.auth']

    # continue only if hash and parameter exist
    if omniauth and params[:service]

      # map the returned hashes to our variables first - the hashes differs for every service

      # create a new hash
      @authhash = Hash.new

      if service_route == 'facebook'
        omniauth['credentials']['token'] ? @authhash[:token] =  omniauth['credentials']['token'] : @authhash[:token] = ''
        omniauth['credentials']['secret'] ? @authhash[:secret] =  omniauth['credentials']['secret'] : @authhash[:secret] = ''
        omniauth['extra']['raw_info']['email'] ? @authhash[:email] =  omniauth['extra']['raw_info']['email'] : @authhash[:email] = ''
        omniauth['extra']['raw_info']['name'] ? @authhash[:name] =  omniauth['extra']['raw_info']['name'] : @authhash[:name] = ''
        omniauth['extra']['raw_info']['id'] ?  @authhash[:uid] =  omniauth['extra']['raw_info']['id'].to_s : @authhash[:uid] = ''
        omniauth['info']['location'] ? @authhash[:location] =  omniauth['info']['location'] : @authhash[:location] = ''
        omniauth['provider'] ? @authhash[:provider] = omniauth['provider'] : @authhash[:provider] = ''
      elsif service_route == 'github'
        omniauth['credentials']['token'] ? @authhash[:token] =  omniauth['credentials']['token'] : @authhash[:token] = ''
        omniauth['credentials']['secret'] ? @authhash[:secret] =  omniauth['credentials']['secret'] : @authhash[:secret] = ''
        omniauth['info']['email'] ? @authhash[:email] =  omniauth['info']['email'] : @authhash[:email] = ''
        omniauth['info']['name'] ? @authhash[:name] =  omniauth['info']['name'] : @authhash[:name] = ''
        omniauth['extra']['raw_info']['id'] ? @authhash[:uid] =  omniauth['extra']['raw_info']['id'].to_s : @authhash[:uid] = ''
        omniauth['provider'] ? @authhash[:provider] =  omniauth['provider'] : @authhash[:provider] = ''
        omniauth['extra']['raw_info']['location'] ? @authhash[:location] =  omniauth['extra']['raw_info']['location'].to_s : @authhash[:location] = ''
      elsif service_route == 'linkedin'
        omniauth['credentials']['token'] ? @authhash[:token] =  omniauth['credentials']['token'] : @authhash[:token] = ''
        omniauth['credentials']['secret'] ? @authhash[:secret] =  omniauth['credentials']['secret'] : @authhash[:secret] = ''
        omniauth['info']['email'] ? @authhash[:email] =  omniauth['info']['email'] : @authhash[:email] = ''
        omniauth['info']['name'] ? @authhash[:name] =  omniauth['info']['name'] : @authhash[:name] = ''
        omniauth['extra']['raw_info']['id'] ? @authhash[:uid] =  omniauth['extra']['raw_info']['id'].to_s : @authhash[:uid] = ''
        omniauth['provider'] ? @authhash[:provider] =  omniauth['provider'] : @authhash[:provider] = ''
        omniauth['info']['location'] ? @authhash[:location] =  omniauth['info']['location'] : @authhash[:location] = ''
      elsif ['google', 'google_apps', 'yahoo', 'twitter', 'myopenid', 'open_id'].index(service_route) != nil
        omniauth['credentials']['token'] ? @authhash[:token] =  omniauth['credentials']['token'] : @authhash[:token] = ''
        omniauth['credentials']['secret'] ? @authhash[:secret] =  omniauth['credentials']['secret'] : @authhash[:secret] = ''
        omniauth['info']['email'] ? @authhash[:email] =  omniauth['info']['email'] : @authhash[:email] = ''
        omniauth['info']['name'] ? @authhash[:name] =  omniauth['info']['name'] : @authhash[:name] = ''
        omniauth['uid'] ? @authhash[:uid] = omniauth['uid'].to_s : @authhash[:uid] = ''
        omniauth['info']['location'] ? @authhash[:location] =  omniauth['info']['location'] : @authhash[:location] = ''
        omniauth['provider'] ? @authhash[:provider] = omniauth['provider'] : @authhash[:provider] = ''
      else
        # debug to output the hash that has been returned when adding new services
        render :text => omniauth.to_yaml
        return
      end

      if @authhash[:uid] != '' and @authhash[:provider] != ''

        auth = Service.find_by_provider_and_uid(@authhash[:provider], @authhash[:uid])

        # if the user is currently signed in, he/she might want to add another account to signin
        if user_signed_in?
          if auth
            flash[:notice] = 'Your account at ' + @authhash[:provider].capitalize + ' is already connected with this site.'
            redirect_to services_path
          else
            current_user.services.create!(:oauth_token => @authhash[:token], :oauth_secret => @authhash[:secret], :provider => @authhash[:provider], :uid => @authhash[:uid], :uname => @authhash[:name], :uemail => @authhash[:email], :ulocation => @authhash[:location]) #,
            flash[:notice] = 'Your ' + @authhash[:provider].capitalize + ' account has been added for signing in at this site.'
            redirect_to services_path
          end
        else
          if auth
            # signin existing user
            # in the session his user id and the service id used for signing in is stored
            session[:user_id] = auth.user.id
            session[:service_id] = auth.id

            flash[:notice] = 'Signed in successfully via ' + @authhash[:provider].capitalize + '.'
            redirect_to services_path
          else
            # this is a new user; show signup; @authhash is available to the view and stored in the sesssion for creation of a new user
            session[:authhash] = @authhash
            render signup_services_path
          end
        end
      else
        flash[:error] =  'Error while authenticating via ' + service_route + '/' + @authhash[:provider].capitalize + '. The service returned invalid data for the user id.'
        #redirect_to signin_path
      end
    else
      flash[:error] = 'Error while authenticating via ' + service_route.capitalize + '. The service did not return valid data.'
      #redirect_to signin_path
    end
  end
##
  # callback: failure
  def failure
    flash[:error] = 'There was an error at the remote authentication service. You have not been signed in.'
    redirect_to root_url
  end

  def update_location

    location = params[:location]
    Twitter.update_profile(:location => location)
    flash[:notice] = 'Your location has been successfully updated.'
    github = Octokit::Client.new(:login =>'bryanchang', :password => ENV['GITHUB_PW'] )
    github.update_user(:location => location)

    u = User.find_by_id(session[:user_id]) if session[:user_id]
    u.services.where(:provider=>"twitter").first.update_attribute(:ulocation, params[:location])
    u.services.where(:provider=>"github").first.update_attribute(:ulocation, params[:location])
    u.save

    redirect_to services_path
  end

end
