class EmailWorker
  include Sidekiq::Worker

  def perform(submiter_email, interactor, movie, interaction_type)
    InteractionMail.interaction_mail(submiter_email,interactor,movie,interaction_type).deliver
  end

end
