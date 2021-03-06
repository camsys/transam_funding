class BondRequestReport < AbstractReport

  include FiscalYear

  def initialize(attributes = {})
    super(attributes)
  end
  
  def get_actions
    @actions = [
      {
        type: :datepicker,
        where: :start_date,
        label: 'From'
      },
      {
        type: :datepicker,
        where: :end_date,
        label: 'To'
      }
    ]
  end
  
  def get_data(organization_id_list, params)
    labels = ['Agency', 'Title', 'Description', 'Justification', 'Total Costs', 'Federal Funding', 'Federal Share', 'Federal Source', 'State Amount Requested', 'State Share', 'Local Funding', 'Local Share']
    formats = [:string, :string, :string, :string, :currency, :currency, :percent, :string, :currency, :percent, :currency, :percent]
    
    # Order by org name, then by FY
    query = BondRequest.where(organization_id: organization_id_list, state: ['pending', 'submitted']).joins(:organization).order('organizations.name')

    # Add clauses based on params
    conditions = []
    values = []

    unless params[:start_date].blank?
      conditions << 'DATE(bond_requests.updated_at) >= ?'
      start_date = Chronic.parse(params[:start_date]).to_date
      values << start_date
    end

    unless params[:end_date].blank?
      conditions << 'DATE(bond_requests.updated_at) <= ?'
      end_date = Chronic.parse(params[:end_date]).to_date
      values << end_date
    end

    # Validation
    if start_date && end_date && end_date < start_date
      return "To Date cannot be before From Date."
    end
    
    query = query.where(conditions.join(' AND '), *values)
    data = []
    
    query.each do |cp|
      row = [
        cp.organization.name,
        cp.title,
        cp.description,
        cp.justification,
        cp.amount,
        cp.federal_amount,
        cp.federal_pcnt,
        cp.funding_template.to_s,
        cp.state_amount,
        cp.state_pcnt,
        cp.local_amount,
        cp.local_pcnt
      ]
      data << row
    end

    
    return {labels: labels, data: data, formats: formats}
  end

end