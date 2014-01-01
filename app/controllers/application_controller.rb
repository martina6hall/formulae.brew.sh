# This code is free software; you can redistribute it and/or modify it under
# the terms of the new BSD License.
#
# Copyright (c) 2012-2014, Sebastian Staudt

class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from Mongoid::Errors::DocumentNotFound, with: :not_found

  def index
    @repository = Repository.main

    @added = @repository.formulae.with_size(revision_ids: 1).
                order_by(%i{date desc}).
                limit 5

    @updated = @repository.formulae.where(removed: false).
                not.with_size(revision_ids: 1).
                order_by(%i{date desc}).
                limit 5

    @removed = @repository.formulae.where(removed: true).
            order_by(%i{date desc}).
            limit 5

    all_repos = Repository.all.order_by [:name, :asc]
    @alt_repos = {}
    (all_repos - [ @repository ]).each do |repo|
      @alt_repos[repo] = ('a'..'z').find do |letter|
        repo.formulae.letter(letter).where(removed: false).exists?
      end
    end

    fresh_when etag: all_repos.max_by(&:updated_at).sha, public: true
  end

  def not_found
    flash.now[:error] = 'The page you requested does not exist.'
    index

    respond_to do |format|
      format.html { render 'application/index', status: :not_found }
    end

    headers.delete 'ETag'
    expires_in 5.minutes
  end

  def sitemap
    @repository = Repository.main

    respond_to do |format|
      format.xml
    end

    fresh_when etag: @repository.sha, public: true
  end

end
