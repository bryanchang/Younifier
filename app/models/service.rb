class Service < ActiveRecord::Base
  attr_accessible :oauth_token, :oauth_secret, :provider, :uemail, :uid, :uname, :user_id, :ulocation

  belongs_to :user

  # def update_location # location
  #   Twitter.update_profile(:location => 'SF, baby')
  #   redirect_to services_path
  # end

    # # some api call to update this service provider
    # case current_user.services.provider
    #   when 'twitter'
    #     user = Twitter::Client.new(
    #       oauth_token:
    #       oauth_secret:
    #     )

    #   when 'github'
    #     # interact with twitter api
    #   when 'twitter'
    #     # interact with twitter api
    #   when 'twitter'
    #     # interact with twitter api
    #   end
  # end

end


#   u = User.find(1)
#   user.services.each do |s|
#     s.update_location 'San Francisco'
#   end

