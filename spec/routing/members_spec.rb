# -*- encoding : utf-8 -*-
require "spec_helper"

describe "The member controller" do
  context "disabled invite paths" do
    it "should include a named route to the member's invite page" do
      {get: member_invite_path}.should route_to("home#index")
    end
    it "should include a named route to accept invitations" do
      {get: accept_invitation_path}.should route_to("home#index")
    end
  end

  it "should include a named route to send invites by e-mail" do
    {post: member_invite_by_email_path}.should route_to("members#invite_by_email")
  end
  it "should include a named route to show a member's invite list" do
    {get: member_invite_list_path}.should route_to("members#invite_list")
  end
end
