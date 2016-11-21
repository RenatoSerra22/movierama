require 'spec_helper'

RSpec.describe InteractionMail, type: :mailer do
  describe 'instructions' do
    let(:mail) { described_class.interaction_mail("movie_submiter@gmail.com","Peter","The Godfather","like").deliver}

    it 'renders the subject' do
      expect(mail.subject).to eq('A user interacted with your movie')
    end

    it 'renders the receiver email' do
      expect(mail.to).to eq(['movie_submiter@gmail.com'])
    end

    it 'body has the correct text' do
      expect(mail.body.encoded).to match('Peter has  liked your movie: The Godfather')
    end

  end
end
