describe FavouritesController do
  include_context :authenticated, :user

  [Anime, Manga, Character, Person].each do |klass|
    context klass.to_s do
      let(:entry) { create klass.name.downcase.to_sym }
      let(:method_name) { "fav_#{klass.name.downcase.pluralize}" }

      describe '#create' do
        it 'success' do
          expect {
            post :create, linked_type: entry.class.name, linked_id: entry.id
          }.to change(Favourite, :count).by(1)
          expect(user.send(method_name)).to include(entry)
        end

        it 'supports kind parameter' do
          expect {
            post :create, linked_type: entry.class.name, linked_id: entry.id, kind: Favourite::Producer
          }.to change(Favourite, :count).by(1)
          expect(user.fav_producers).to include(entry)
        end if klass == Person
      end

      describe '#destroy' do
        let!(:favourite) { create :favourite, linked: entry, user: user }

        it 'success' do
          expect {
            delete :destroy, linked_type: entry.class.name, linked_id: entry.id
          }.to change(Favourite, :count).by -1
          expect(user.reload.send(method_name)).not_to include(entry)
        end
      end
    end
  end
end
