require 'spec_helper'

describe SeyuQuery do
  let(:person) { create :person, name: 'test', seyu: true }
  let(:query) { SeyuQuery.new(search: 'test') }
  before do
    create :person, name: 'testZzz', seyu: true
    person
    character = create :character, person_roles: [create(:person_role, role: Person::SeyuRoles.sample, person: person)]
    create :anime, characters: [character]
    create :person, japanese: 'シュタインズ', seyu: true
    create :person, name: 'qwert'
  end

  describe 'fill_works' do
    before do
      1.upto(6) {
        character = create :character, person_roles: [create(:person_role, role: Person::SeyuRoles.sample, person: person)]
        create :anime, characters: [character]
      }
    end
    let(:fetched_query) { query.fill_works(query.fetch) }

    it { fetched_query.first.best_works.should have(PeopleQuery::WorksLimit).items }
    it { fetched_query.first.last_works.should have(PeopleQuery::WorksLimit).items }
  end
end
