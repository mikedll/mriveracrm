class InvitationsController < ApplicationController

  before_filter :find_invitation

  def find_invitation
    @invitation = Invitation.find params[:id]
  end

end
