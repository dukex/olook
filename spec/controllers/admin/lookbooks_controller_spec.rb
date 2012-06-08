require 'spec_helper'

describe Admin::LookbooksController do
  render_views
  let!(:product)      { FactoryGirl.create(:basic_shoe) }
  let!(:lookbook)      { FactoryGirl.create(:basic_lookbook,
                        :product_list => { "#{product.id}" => "1" },
                        :product_criteo => { "#{product.id}" => "1" } ) }
  let!(:lookbook_whitout_video)      { FactoryGirl.create(:basic_lookbook,
                        :name => "name_two",
                        :slug => "slug_two",
                        :product_list => { "#{product.id}" => "1" },
                        :product_criteo => { "#{product.id}" => "1" } ) }
  let!(:video)      { FactoryGirl.create(:video,
                        :video_relation_id => lookbook.id,
                        :video_relation_type => "Lookbook" ) }

  before :each do
    request.env['devise.mapping'] = Devise.mappings[:admin]
    @admin = FactoryGirl.create(:admin_superadministrator)
    sign_in @admin
  end

  describe "GET index" do
    let(:searched_lookbook) { FactoryGirl.create(:complex_lookbook) }
    let(:search_param) { {"name_contains" => searched_lookbook.name} }

    it "should search for a lookbook using the search parameter" do
      get :index, :search => search_param

      assigns(:lookbooks).should_not include(lookbook)
      assigns(:lookbooks).should include(searched_lookbook)
    end
  end

  describe "GET edit" do
    it "assigns the requested lookbook as @lookbook" do
      get :edit, :id => lookbook.id.to_s
      assigns(:lookbook).should eq(lookbook)
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested lookbook" do
        Lookbook.any_instance.should_receive(:update_attributes).with({'name' => 'name', 'slug' => 'name', 'video' => { 'title' => 'test', 'url' => 'url/test' } } )
        put :update, :id => lookbook.id, :lookbook => {'name' => 'name', 'slug' => 'name', 'video' => { 'title' => 'test', 'url' => 'url/test' } }
      end

      it "assigns the requested lookbook as @lookbook" do
        put :update, :id => lookbook.id, :lookbook => lookbook.attributes
        assigns(:lookbook).should eq(lookbook)
      end

      it "assigns the requested lookbook new video as @video" do
        put :update, :id => lookbook_whitout_video.id, :lookbook => {'name' => 'name_two', 'slug' => 'name_two'}, :video => { 'title' => 'test_two', 'url' => 'url/test_two' }
        assigns(:video).should eq(Video.last)
      end

      it "redirects to the lookbook" do
        put :update, :id => lookbook.id, :lookbook => lookbook.attributes
        response.should redirect_to admin_lookbook_path
      end
    end
    describe "with invalid params" do
      it "assigns the lookbook as @lookbook" do
        Lookbook.any_instance.stub(:save).and_return(false)
        put :update, :id => lookbook.id.to_s, :lookbook => {}
        assigns(:lookbook).should eq(lookbook)
      end

      it "re-renders the 'edit' template" do
        Lookbook.any_instance.stub(:save).and_return(false)
        put :update, :id => lookbook.id.to_s, :lookbook => {}
        flash[:notice].should be_blank
      end
    end
  end

   describe "DELETE destroy" do
    it "destroys the requested lookbook" do
      expect {
        delete :destroy, :id => lookbook.id.to_s
      }.to change(Lookbook, :count).by(-1)
    end

    it "redirects to the lookbooks list" do
      delete :destroy, :id => lookbook.id.to_s
      response.should redirect_to(admin_lookbooks_url)
    end
  end

end
