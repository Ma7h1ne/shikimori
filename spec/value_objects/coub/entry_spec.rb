describe Coub::Entry do
  subject(:entry) do
    Coub::Entry.new(
      permalink: 'zxc',
      image_template: 'z_%{version}_x',
      categories: categories,
      tags: tags,
      title: 'b',
      recoubed_permalink: nil,
      author: {
        permalink: 'n',
        name: 'm',
        avatar_template: 'a'
      }
    )
  end
  let(:categories) { [] }
  let(:tags) { [] }

  describe '#anime?' do
    it { is_expected.to be_anime }

    context 'has non anime categories' do
      let(:categories) { %w[music] }
      it { is_expected.to_not be_anime }

      context 'has anime tag' do
        let(:tags) { [%w[anime zzz], %w[аниме xxx]].sample }
        it { is_expected.to be_anime }
      end
    end
  end

  describe '#image_url' do
    it { expect(entry.image_url).to eq 'z_big_x' }
  end
end
