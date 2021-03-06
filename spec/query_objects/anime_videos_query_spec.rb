describe AnimeVideosQuery do
  let!(:anime_1) { create :anime, name: 'anime_1_test' }
  let!(:anime_2) { create :anime, name: 'anime_2_test' }
  let!(:anime_3) { create :anime, :with_video, name: 'anime_3_test', rating: Anime::ADULT_RATING }

  let!(:anime_1_video) { create :anime_video, anime: anime_1, created_at: 2.days.ago }
  let!(:anime_2_video) { create :anime_video, anime: anime_2, created_at: 1.day.ago }

  subject { AnimeVideosQuery.new(is_adult).fetch }

  context 'adult' do
    let(:is_adult) { true }
    its(:to_a) { should have(1).item }
  end

  context 'not_adult' do
    let(:is_adult) { false }
    its(:to_a) { should have(2).items }
    its(:first) { should eq anime_2 }
  end
end
