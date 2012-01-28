# -*- encoding : utf-8 -*-
class MembersController < ApplicationController

  before_filter :authenticate_user!, :except => [:accept_invitation]
  before_filter :check_early_access, :only => [:showroom]
  before_filter :validate_token, :only => :accept_invitation
  before_filter :load_user, :only => [:invite, :showroom, :invite_list]
  before_filter :load_order, :except => [:invite_by_email, :invite_imported_contacts]
  before_filter :load_offline_variant, :only => [:showroom]
  before_filter :check_session_and_add_to_cart, :only => [:showroom]

  def invite
    @is_the_first_visit = first_visit_for_member?(@user)
    @facebook_app_id = FACEBOOK_CONFIG["app_id"]
    @redirect_uri = root_path

    yahoo_request = OauthImport::Yahoo.new.request
    if yahoo_request
      session['yahoo_request_token'], session['yahoo_request_secret'] = yahoo_request.token, yahoo_request.secret
      @yahoo_oauth_url = yahoo_request.authorize_url
    end
  end

  def accept_invitation
    session[:invite] = {:invite_token => params[:invite_token],
                        :invited_by => @inviting_member.name}

    redirect_to root_path(incoming_params)
  end

  def invite_by_email
    parsed_emails = params[:invite_mail_list].split(/,|;|\r|\t/).map(&:strip)
    invites = current_user.invites_for(parsed_emails)
    current_user.add_event(EventType::SEND_INVITE, "#{invites.length} invites sent")
    redirect_to(member_invite_path, :notice => "#{invites.length} convites enviados com sucesso!")
  end

  # I know it's a workaround, but our friends at yahoo did us
  # the favor of GET the allowed app giving params, not POST it.
  # -zanst
  def import_contacts
    begin
      email_provider = "yahoo"
      oauth_token = params[:oauth_token]
      oauth_secret = session['yahoo_request_secret']
      oauth_verifier = params[:oauth_verifier]
      contacts_adapter = ContactsAdapter.new(nil, nil, oauth_token, oauth_secret, oauth_verifier)
      @contacts = contacts_adapter.contacts(email_provider)
    rescue MultiJson::DecodeError, Net::HTTPFatalError, OAuth::Problem
      redirect_to(member_invite_path, :notice => "Seus contatos não puderam ser importados agora. Por favor tente novamente mais tarde.")
    end
  end

  def showroom
    @is_the_first_visit = first_visit_for_member?(@user)
  end

  def show_imported_contacts
    email_provider = params[:email_provider]
    login = params[:login]
    password = params[:password]
    contacts_adapter = ContactsAdapter.new(login, password)
    @contacts = contacts_adapter.contacts(email_provider)
  end

  def invite_imported_contacts
    invites = current_user.invites_for(params[:email_address])
    current_user.add_event(EventType::SEND_IMPORTED_CONTACTS, "#{invites.length} invites from imported contacts sent")
    redirect_to(member_invite_path, :notice => "#{invites.length} Convites enviados com sucesso!")
  end

  def invite_list
    @invites = @user.invites.page(params[:page]).per_page(15)
  end

  private

  def first_visit_for_member?(member)
    if member.first_visit?
      member.record_first_visit
      true
    else
      false
    end
  end

  def validate_token
    valid_format = User::InviteTokenFormat.match params[:invite_token]
    @inviting_member = User.find_by_invite_token(params[:invite_token]) if valid_format
    redirect_to(root_path, :alert => "Convite inválido") unless valid_format && @inviting_member
  end

  def incoming_params
    params.clone.delete_if {|key| ['controller', 'action','invite_token'].include?(key) }
  end

end
