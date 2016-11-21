class InteractionMail < ActionMailer::Base
  default from: "deliverootesting@gmail.com"

  #fill the template and send
  def interaction_mail(submiter_email,interactor,movie,interaction_type)
    @interactor = interactor
    @interaction_type = interaction_type
    @movie = movie
    mail to: submiter_email, subject: "A user interacted with your movie"
  end
end
