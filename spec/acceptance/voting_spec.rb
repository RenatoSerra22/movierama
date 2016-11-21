require 'rails_helper'
require 'capybara/rails'
require 'support/pages/movie_list'
require 'support/pages/movie_new'
require 'support/with_user'
require 'sidekiq/testing'
Sidekiq::Testing.fake!

RSpec.describe 'vote on movies', type: :feature do

  let(:page) { Pages::MovieList.new }

  before do
    #just in case
    EmailWorker.jobs.clear
    author = User.create(
      uid:  'null|12345',
      name: 'Bob',
      email: 'deliverootesting@gmail.com'
    )
    Movie.create(
      title:        'Empire strikes back',
      description:  'Who\'s scruffy-looking?',
      date:         '1980-05-21',
      user:         author
    )
    author2 = User.create(
      uid:  'null|54321',
      name: 'Peter'
    )
    Movie.create(
      title:        'Dr Strange',
      description:  'Super heroes',
      date:         '2016-11-15',
      user:         author2
    )
  end

  context 'when logged out' do
    it 'cannot vote' do
      page.open
      expect {
        page.like('Empire strikes back')
      }.to raise_error(Capybara::ElementNotFound)
    end
  end

  context 'when logged in' do
    with_logged_in_user

    before { page.open }

    it 'can like' do
      page.like('Empire strikes back')
      expect(page).to have_vote_message
      #Can like and has email so message is pushed to queue
      assert_equal 1, EmailWorker.jobs.size
      EmailWorker.drain
    end

    it 'can hate' do
      page.hate('Empire strikes back')
      expect(page).to have_vote_message
      #Can hate and has email so message is pushed to queue
      assert_equal 1, EmailWorker.jobs.size
      EmailWorker.drain
    end

    it 'can unlike' do
      page.like('Empire strikes back')
      #Can like and has email so message is pushed to queue
      assert_equal 1, EmailWorker.jobs.size
      EmailWorker.drain
      page.unlike('Empire strikes back')
      expect(page).to have_unvote_message
      #Can unlike and has email but unlike doesnt trigger emails
      assert_equal 0, EmailWorker.jobs.size
    end

    it 'can unhate' do
      page.hate('Empire strikes back')
      #Can hate and has email so message is pushed to queue
      assert_equal 1, EmailWorker.jobs.size
      EmailWorker.drain
      page.unhate('Empire strikes back')
      expect(page).to have_unvote_message
      #Can unhate and has email but unlike doesnt trigger emails
      assert_equal 0, EmailWorker.jobs.size
    end

    it 'cannot like twice' do
      expect {
        2.times { page.like('Empire strikes back') }
      }.to raise_error(Capybara::ElementNotFound)
      #Only 1 of the 2 votes is casted, so it should have only one message in queue
      assert_equal 1, EmailWorker.jobs.size
      EmailWorker.drain
    end

    it 'cannot send emails without email' do
      page.like('Dr Strange')
      expect(page).to have_vote_message
      #Can like and but has no email so message is not pushed to queue
      assert_equal 0, EmailWorker.jobs.size
    end

    it 'cannot like own movies' do
      Pages::MovieNew.new.open.submit(
        title:       'The Party',
        date:        '1969-08-13',
      description: 'Birdy nom nom')
      page.open
      expect {
        page.like('The Party')
      }.to raise_error(Capybara::ElementNotFound)
      #No vote should be casted on own movies
      assert_equal 0, EmailWorker.jobs.size
    end

  end

end
