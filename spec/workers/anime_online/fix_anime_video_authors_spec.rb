describe AnimeOnline::FixAnimeVideoAuthors do
  let(:service) { AnimeOnline::FixAnimeVideoAuthors.new }
  let!(:author_1) { create :anime_video_author, name: name, id: 555_555 }
  let!(:anime_video_1) { create :anime_video, author: author_1 }

  describe '#perform' do
    context 'cleanup' do
      let!(:anime_video_1) {}
      let(:name) { 'test' }
      before { service.perform }

      it { expect { author_1.reload }.to raise_error ActiveRecord::RecordNotFound }
    end

    context 'quality change' do
      before { service.perform }

      context 'author name' do
        let(:name) { '(bd) test' }
        it do
          expect(author_1.reload.name).to eq 'test'
          expect(anime_video_1.reload).to have_attributes(
            quality: 'bd',
            anime_video_author_id: author_1.id
          )
        end
      end

      context 'no author name' do
        let(:name) { '(bd)' }
        it do
          expect { author_1.reload }.to raise_error ActiveRecord::RecordNotFound
          expect(anime_video_1.reload).to have_attributes(
            quality: 'bd',
            anime_video_author_id: nil
          )
        end
      end
    end

    describe 'name change' do
      before { allow(service).to receive :change_videos_quality }
      after { expect(service).to_not have_received :change_videos_quality }

      let!(:author_2) {}
      let!(:anime_video_2) {}

      before { service.perform }

      context 'valid name' do
        let(:name) { 'zzzz' }
        it { expect(author_1.reload.name).to eq name }
      end

      context 'quality in name' do
        let(:name) { 'DVD-спэшлы' }
        it { expect(author_1.reload.name).to eq name }
      end

      context 'invalid name' do
        describe 'name replaced' do
          context 'name example' do
            let(:name) { 'aNiDuB' }
            it { expect(author_1.reload.name).to eq 'AniDUB' }
          end

          context 'name with prefix' do
            let(:name) { 'xaNiDuB' }
            it { expect(author_1.reload.name).to eq 'AniDUB' }
          end

          context 'name with postfix' do
            let(:name) { 'aNiDuBx' }
            it { expect(author_1.reload.name).to eq 'AniDUB' }
          end

          context 'tv domain' do
            let(:name) { 'AniLibria.TV' }
            it { expect(author_1.reload.name).to eq 'AniLibria' }
          end

          context 'brackets after' do
            let(:name) { 'AniDUB [test]' }
            it { expect(author_1.reload.name).to eq 'AniDUB (test)' }
          end

          context 'symbol in the beginning' do
            let(:name) { 'и test' }
            it { expect(author_1.reload.name).to eq 'test' }
          end

          context 'digit in the beginning' do
            let(:name) { '1 test' }
            it { expect(author_1.reload.name).to eq '1 test' }
          end

          context 'name in square brackets' do
            let(:name) { '[AniDUB]' }
            it { expect(author_1.reload.name).to eq 'AniDUB' }
          end

          context 'name in square brackets with translators' do
            let(:name) { '[AniDUB] Test, Foo' }
            it { expect(author_1.reload.name).to eq 'AniDUB (Test & Foo)' }
          end

          context 'name with commas' do
            let(:name) { 'AniDUB (Test, Foo)' }
            it { expect(author_1.reload.name).to eq 'AniDUB (Test & Foo)' }
          end

          context 'name with double spaces' do
            let(:name) { 'AniDUB  (Test,  Foo)' }
            it { expect(author_1.reload.name).to eq 'AniDUB (Test & Foo)' }
          end

          context 'name with space inside brackets' do
            let(:name) { 'AniDUB ( Test, Foo )' }
            it { expect(author_1.reload.name).to eq 'AniDUB (Test & Foo)' }
          end

          context 'name with russian and' do
            let(:name) { 'AniDUB (Test и Foo)' }
            it { expect(author_1.reload.name).to eq 'AniDUB (Test & Foo)' }
          end

          context 'name in round brackets' do
            let(:name) { '(fofofo)' }
            it { expect(author_1.reload.name).to eq 'fofofo' }
          end

          context 'trash after name' do
            let(:name) { 'AniStar.ru™' }
            it { expect(author_1.reload.name).to eq 'AniStar' }
          end

          context 'studio after author' do
            let(:name) { 'Cuba77 [AniDUB]' }
            it { expect(author_1.reload.name).to eq 'AniDUB (Cuba77)' }
          end

          context 'author similar to studio' do
            let(:name) { 'Mirazell & Annie & SlyfeFreeDub' }
            it { expect(author_1.reload.name).to eq 'Mirazell & Annie & SlyfeFreeDub' }
          end

          context 'AniStar' do
            context 'with space' do
              let(:name) { 'Ani Star' }
              it { expect(author_1.reload.name).to eq 'AniStar' }
            end

            context 'without space' do
              let(:name) { 'AniStar' }
              it { expect(author_1.reload.name).to eq 'AniStar' }
            end
          end

          context 'SovetRomantica' do
            context 'with space' do
              let(:name) { 'Sovet Romantica' }
              it { expect(author_1.reload.name).to eq 'SovetRomantica' }
            end

            context 'without space' do
              let(:name) { 'SovetRomantica' }
              it { expect(author_1.reload.name).to eq 'SovetRomantica' }
            end

            context 'with minus' do
              let(:name) { 'Sovet-Romantica' }
              it { expect(author_1.reload.name).to eq 'SovetRomantica' }
            end
          end

          context 'SHIZA' do
            context 'with Project' do
              let(:name) { 'SHIZA Project' }
              it { expect(author_1.reload.name).to eq 'SHIZA Project' }
            end

            context 'without Project' do
              let(:name) { 'SHIZA' }
              it { expect(author_1.reload.name).to eq 'SHIZA Project' }
            end

            context 'with minus' do
              let(:name) { 'SHIZA-Project' }
              it { expect(author_1.reload.name).to eq 'SHIZA Project' }
            end
          end

          context 'AniMaunt' do
            context 'animaunt.ru' do
              let(:name) { 'animaunt.ru' }
              it { expect(author_1.reload.name).to eq 'AniMaunt' }
            end

            context 'aanimaunt' do
              let(:name) { 'aanimaunt' }
              it { expect(author_1.reload.name).to eq 'AniMaunt' }
            end

            context 'аanimaunt' do
              let(:name) { 'аanimaunt' }
              it { expect(author_1.reload.name).to eq 'AniMaunt' }
            end
          end

          context 'Amazing Dubbing' do
            let(:name) { ['Amaizing Dubbing', 'Amazing Dubing'].sample }
            it { expect(author_1.reload.name).to eq 'Amazing Dubbing' }
          end

          context 'SeM&Ko' do
            let(:name) { %w[SEM&KO sem&ko Sem&Ko].sample }
            it { expect(author_1.reload.name).to eq 'SeM&Ko' }

          end
        end

        describe 'author already exists' do
          let!(:author_2) { create :anime_video_author, name: 'AniDUB', id: 666_666 }
          let!(:anime_video_2) { create :anime_video, author: author_2 }

          let(:name) { 'aNiDuB' }

          it do
            expect { author_1.reload }.to raise_error ActiveRecord::RecordNotFound
            expect(author_2.anime_videos).to have(2).items
          end
        end
      end
    end
  end
end
