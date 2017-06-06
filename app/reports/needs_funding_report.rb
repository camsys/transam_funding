class NeedsFundingReport < AbstractReport

  def initialize(attributes = {})
    super(attributes)
  end    
  
  def get_data(organization_id_list, params)
    # Assumption: data values have already been divided by 10^6 when returned.

    labels = ['Fiscal Year', 'Total Needs ($M)', 'Total Federal Funds ($M)', 'Total State Funds ($M)',
              'Total Local Funds ($M)', 'Balance/(Shortfall) ($M)']
    formats = [nil, :currency, :currency, :currency, :currency, :currency]

    data = [['FY 17-18', 987.654321, 456.0, 321.0, 123.0, -900.654321]]

    return {labels: labels, data: data, formats: formats}
  end
end