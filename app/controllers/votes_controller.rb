class VotesController < ApplicationController
  def create
    authorize! :vote, _movie

    _voter.vote(_type)
    #email the submiter
    _notify(current_user,_movie,_type)
    redirect_to root_path, notice: 'Vote cast'
  end

  def destroy
    authorize! :vote, _movie

    _voter.unvote
    redirect_to root_path, notice: 'Vote withdrawn'
  end

  private

  def _voter
    VotingBooth.new(current_user, _movie)
  end

  def _notify(interactor,movie,interaction_type)
    submiter_email = movie.user.email
    #Send the email only if we actually have an email to send to
    #Push it to a Redis queue and send it async, because the result is slow and irrelevant to the user
    EmailWorker.perform_async(submiter_email, interactor.name, movie.title, interaction_type) if submiter_email
  end

  def _type
    case params.require(:t)
    when 'like' then :like
    when 'hate' then :hate
    else raise
    end
  end

  def _movie
    @_movie ||= Movie[params[:movie_id]]
  end
end
