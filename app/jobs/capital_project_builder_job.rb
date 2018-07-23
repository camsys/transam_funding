#------------------------------------------------------------------------------
#
# CapitalProjectBuilderJob
#
# Build SOGR projects
#
#------------------------------------------------------------------------------
class CapitalProjectBuilderJob < Job

  attr_accessor :organization
  attr_accessor :fta_asset_categories
  attr_accessor :start_fy
  attr_accessor :creator

  def run

    # Run the builder
    options = {}
    options[:fta_asset_category_ids] = fta_asset_categories
    options[:start_fy] = start_fy
    builder = CapitalProjectBuilder.new
    num_created = builder.build(organization, options)

    ## clear out funding requests
    # ---------------------------------------------

    # Find all the matching assets for this organization
    assets = Rails.application.config.asset_base_class_name.constantize.replacement_by_policy.very_specific
                 .where(options.except(:start_fy).merge({organization_id: organization.id, disposition_date: nil, scheduled_disposition_year: nil}))
                 .where('transam_assets.scheduled_replacement_year >= ?', start_fy)

    assets += Rails.application.config.asset_base_class_name.constantize.replacement_underway.where(organization_id: organization.id)

    FundingRequest.distinct.joins('INNER JOIN activity_line_items_assets ON funding_requests.activity_line_item_id = activity_line_items_assets.activity_line_item_id').where('activity_line_items_assets.asset_id IN (?)', assets.map{|x| x.id}).destroy_all

    # ---------------------------------------------

    # Let the user know the results
    if num_created > 0
      msg = "SOGR Capital Project Analyzer completed. #{num_created} SOGR capital projects were added to #{organization.short_name}'s capital needs list."
      # Add a row into the activity table
      ActivityLog.create({:organization_id => organization.id, :user_id => creator.id, :item_type => "CapitalProjectBuilder", :activity => msg, :activity_time => Time.now})
    else
      msg = "No capital projects were created. #{organization.short_name} has #{CapitalProject.where(organization_id: organization.id).count} existing projects."
    end

    event_url = Rails.application.routes.url_helpers.capital_projects_path
    builder_notification = Notification.create(text: msg, link: event_url, notifiable_type: 'Organization', notifiable_id: organization.id)
    UserNotification.create(user: creator, notification: builder_notification)

  end

  def prepare
    Rails.logger.debug "Executing CapitalProjectBuilderJob at #{Time.now.to_s} for SOGR projects"
  end

  def check
    raise ArgumentError, "organization can't be blank " if organization.nil?
    raise ArgumentError, "fta_asset_categories can't be blank " if fta_asset_categories.nil?
    raise ArgumentError, "start_fy can't be blank " if start_fy.nil?
    raise ArgumentError, "creator can't be blank " if creator.nil?
  end

  def initialize(organization, fta_asset_categories, start_fy, creator)
    super
    self.organization = organization
    self.fta_asset_categories = fta_asset_categories
    self.start_fy = start_fy
    self.creator = creator
  end

end
