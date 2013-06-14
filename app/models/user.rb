class User < ActiveRecord::Base
  attr_accessible :email, :name

  has_many :services

  #  def update_location(service, location)
  # self.services.where(:provider=> service).first.ulocation = location
  # self.save
  # end




end
