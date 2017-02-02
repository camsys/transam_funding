from selenium import webdriver
from selenium.webdriver.firefox.firefox_binary import FirefoxBinary
from selenium.webdriver.support.select import Select
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
import time

# Driver
binary = FirefoxBinary()
browser = webdriver.Firefox(firefox_binary=binary)

# Variables
wait = WebDriverWait(browser, 10)
down_arrow = u'\ue015'
base_url = 'http://bpt-int.camsys-apps.com/'

# Login
def user_login(username='ebonini@pa.gov',password='Welcome1'):
   elem = browser.find_element_by_id('user_email')
   elem.clear()

   elem.send_keys(username)
   elem = browser.find_element_by_id('user_password')
   elem.clear()

   elem.send_keys(password)
   elem = browser.find_element_by_name('commit')
   elem.click()
   time.sleep(2)

# Create progream / template / bucket
def create_bucket(create='true', program='AUTO_TEST', template='AUTO_TEST_TEMPLATE', owner='All Agencies For This Template', custom_name='false',
                  from_fy='17', to_fy='18', funding='5', *agencies):
    ###################################################################
    ## PURPOSE: Create a bucket based on the arguments entered.
    ##
    ##
    ## create: whether you want to save the bucket or not. Useful when
    ##      needing to validate the form itself.
    ## program: name of the bucket's program.
    ## template: name of the bucket's template.
    ## owner: owner of the bucket. if single org, use acronymn (BPT, CAT,
    ##      etc).
    ## from_fy: from fiscal year. use first year (for 'FY 17-18, enter '17').
    ## to_fy: to fiscal year. use first year (for 'FY 17-18, enter '17').
    ## funding: funding for each org.
    ## custom_name: enter the custom name of the bucket. only for multi-
    ##      bucket templates. set to false for non multi-bucket buckets.
    ## *agencies: for when owner is 'All Agencies For Template"; list of
    ##      orgs. use acronymn (BPT, CAT, etc).
    ##

    # down_arrow = u'\ue015'
    wait = WebDriverWait(browser, 10)

    # Select Program
    wait.until(EC.presence_of_element_located((By.ID, 'funding_bucket_proxy_program_id')))
    time.sleep(1)
    select = Select(browser.find_element_by_id('funding_bucket_proxy_program_id'))
    select.select_by_visible_text(program)

    # Select template
    wait.until(EC.presence_of_element_located((By.ID, 'funding_bucket_proxy_template_id')))
    time.sleep(1)
    select = Select(browser.find_element_by_id('funding_bucket_proxy_template_id'))
    select.select_by_visible_text(template)

    # Select Owner
    dropdown = wait.until(EC.presence_of_element_located((By.ID, 'funding_bucket_proxy_owner_id')))
    time.sleep(1)
    for option in dropdown.find_elements_by_tag_name('option'):
        if option.text.partition("-")[0] == owner:
            option.click()

    # Select from and to fiscal years
    dropdown = wait.until(EC.presence_of_element_located((By.ID, 'funding_bucket_proxy_fiscal_year_range_start')))
    time.sleep(1)
    for option in dropdown.find_elements_by_tag_name('option'):
        if option.text[3:5] == from_fy:
            option.click()
        #     break
        # else:
        #     dropdown.send_keys(down_arrow)

    dropdown = browser.find_element_by_id('funding_bucket_proxy_fiscal_year_range_end')
    for option in dropdown.find_elements_by_tag_name('option'):
        if option.text[3:5] == to_fy:
            option.click()
        #     break
        # else:
        #     dropdown.send_keys(down_arrow)

    # Create Unique Name
    if custom_name != 'false':
        elem = browser.find_element_by_id('funding_bucket_proxy_name')
        elem.clear()
        elem.send_keys(custom_name)

    # Enter Funds
    if owner == 'All Agencies For This Template':
        agencytable = browser.find_element_by_id('all_agencies_covered_by_template_group_id')
        for option in agencytable.find_elements_by_tag_name('label'):
            for agency in agencies:
                elem = option.text
                if elem.partition("-")[0] == agency:
                    elem = option.find_element_by_xpath('..')
                    input = elem.find_element_by_tag_name('input')
                    input.send_keys(funding)
    else:
        elem = browser.find_element_by_css_selector('[class="form-group integer required funding_bucket_proxy_total_amount"]')
        budget = elem.find_element_by_id('funding_bucket_proxy_total_amount')
        budget.send_keys(funding)


    # Save bucket
    if create == 'true':
        time.sleep(2)
        elem = browser.find_element_by_id('new_funding_bucket_proxy')
        save = elem.find_element_by_css_selector('[class="btn btn-primary"]')
        save.click()
def create_template(program='funding program name', template_name='template name', description='used for automated testing',
                    contributor='State', owner='State', organization='Choose Organizations', type='year', *agencies):
   ###########################################################################
   ## PURPOSE: Create a bucket based on the entered arguments.
   ##
   ##
   ## program_name: template's funding program.
   ## template_name: desired template name.
   ## description: template description.
   ## contributor: template contributor; can be 'State' or 'Agency' only.
   ## owner: template owner; can be 'State' or 'Agency' only.
   ## organization: organization(s) that the template is for; calues can be:
   ##       'Choose Organizations', 'All Organizations', 'All Transit Agencues',
   ##       'Urban', 'Rural', 'Intercity Bus', 'Intercity Rail'
   ## type: select the type of template; values are:
   ##       * 'years' (Create Multiple Years)
   ##       * 'agencies' (Create Multiple Agencies)
   ##       * 'years, agencies' (multi-year and agency)
   ##       * 'buckets' (Create multiple buckets for agency year)
   ## *agencies: used only when owner is set to 'Choose Organizations; use
   ##       acronymn (BPT, CAT, etc).
   ##
   ##

   wait = WebDriverWait(browser, 10)
   down_arrow = u'\ue015'

   # Go to new template page
   browser.get('http://bpt-qa.camsys-apps.com/funding_templates/new')

   # Choose funding program
   dropdown = wait.until(EC.presence_of_element_located((By.ID, 'funding_template_funding_source_id')))
   time.sleep(2)
   for option in dropdown.find_elements_by_tag_name('option'):
       if option.text == program:
           option.click()

   # Enter Template Name
   elem = browser.find_element_by_id('funding_template_name')
   elem.send_keys(template_name)

   # Enter description
   elem = browser.find_element_by_id('funding_template_description')
   elem.send_keys(description)

   # Select contributor
   dropdown = browser.find_element_by_id('funding_template_contributor_id')
   for option in dropdown.find_elements_by_tag_name('option'):
       if option.text == contributor:
           option.click()

   # Select owner
   dropdown = browser.find_element_by_id('funding_template_owner_id')
   for option in dropdown.find_elements_by_tag_name('option'):
       if option.text == owner:
           option.click()

    # Select Orgs
   l = ['All Organizations', 'All Transit Agencies', 'Urban', 'Rural', 'Intercity Bus', 'Intercity Rail']
   if organization in l:
       dropdown = browser.find_element_by_id('query')
       for option in dropdown.find_elements_by_tag_name('option'):
           if option.text == organization:
               option.click()
   else:
       agencyselector = browser.find_element_by_xpath('//*[@id="shuttleboxes"]/div/div[1]/div/div[3]/select')
       for option in agencyselector.find_elements_by_tag_name('option'):
           for agency in agencies:
               if option.text.partition("-")[0] == agency:
                   option.click()
       elem = browser.find_element_by_css_selector('[class="selector-chooser"]')
       elem.find_element_by_css_selector('[class="btn btn-default selector selector-add"]').click()

   # Select Template Type
   if type == 'years':
       elem = browser.find_element_by_css_selector('[class="form-group boolean optional funding_template_recurring"]')
       checkbox = elem.find_element_by_css_selector('[class="checkbox"]')
       checkbox.click()
   if type == 'agencies':
       elem = browser.find_element_by_css_selector('[class="form-group boolean optional funding_template_create_multiple_agencies"]')
       checkbox = elem.find_element_by_css_selector('[class="checkbox"]')
       checkbox.click()
   if type == 'years, agencies' or 'agencies, years':
       elem = browser.find_element_by_css_selector('[class="form-group boolean optional funding_template_recurring"]')
       checkbox = elem.find_element_by_css_selector('[class="checkbox"]')
       checkbox.click()
       elem = browser.find_element_by_css_selector('[class="form-group boolean optional funding_template_create_multiple_agencies"]')
       checkbox = elem.find_element_by_css_selector('[class="checkbox"]')
       checkbox.click()
   if type == 'buckets':
       elem = browser.find_element_by_css_selector('[class="form-group boolean optional funding_template_create_multiple_buckets_for_agency_year"]')
       checkbox = elem.find_element_by_css_selector('[class="checkbox"]')
       checkbox.click()

   # Click Save (FIX)
   browser.find_element_by_name('commit').click()

   return
def create_fund(program_name='AUTO_TEST', description='used for automated testing', type='discretionary', source='state', pcnt_match=5):
   #####################################################################
   ## PURPOSE: Create funding program based on entered arguments.
   ##
   ##
   ## program_name: name of funding program.
   ## description: description of funding program.
   ## type: funding type; can be 'formula' or 'discretionary' only.
   ## source: funding source; can be 'federal', 'state', 'local',
   ##       'other' only.
   ## pcntMatch: percent match.
   ##
   ##

   # Go to new funding program page
   browser.get('http://bpt-qa.camsys-apps.com/funding_programs/new')

   # Enter funding program name
   elem = browser.find_element_by_id('funding_source_name')
   elem.clear()
   elem.send_keys(program_name)

   # Enter description
   elem = browser.find_element_by_id('funding_source_description')
   elem.clear()
   elem.send_keys(description)

   # Choose funding formula
   if type is 'formula':
       elem = browser.find_element_by_id('fund_formula')
       elem.click()
   if type is 'discretionary':
       elem = browser.find_element_by_id('fund_discretionary')
       elem.click()

   # Select Source
   if source is 'federal':
       browser.find_element_by_xpath('//select[@id="funding_source_funding_source_type_id"]/option[@value="1"]').click()
   if source is 'state':
       browser.find_element_by_xpath('//select[@id="funding_source_funding_source_type_id"]/option[@value="2"]').click()
   if source is 'local':
       browser.find_element_by_xpath('//select[@id="funding_source_funding_source_type_id"]/option[@value="3"]').click()
   if source is 'other':
       browser.find_element_by_xpath('//select[@id="funding_source_funding_source_type_id"]/option[@value="2"]').click()

   # Set Pcnt Match
   elem = browser.find_element_by_id('funding_source_match_required')
   elem.clear()
   elem.send_keys(pcnt_match)

   # Save Funding Program
   browser.find_element_by_css_selector('[class="btn btn-default btn btn-primary"]').click()

   return

# General test functions
def is_element_present(how, what):
    try:
        browser.find_element(by=how, value=what)
        return True
    except:
        return False
def check_table(how, what, name, driver=browser):
    table = driver.find_element(by=how, value=what)
    if name not in table.text:
        return False
    else:
        return True

# Test generated names
def get_actual_bucketname():
    elem = browser.find_element_by_id('funding_bucket_proxy_program_id')
    select = Select(elem)
    program = select.first_selected_option.text

    ## Get Template Name
    elem = browser.find_element_by_id('funding_bucket_proxy_template_id')
    select = Select(elem)
    template = select.first_selected_option.text

    ## Get Owner Name
    elem = browser.find_element_by_id('funding_bucket_proxy_owner_id')
    select = Select(elem)
    owner = select.first_selected_option.text

    ## Get Fiscal Years
    elem = browser.find_element_by_id('funding_bucket_proxy_fiscal_year_range_start')
    select = Select(elem)
    fy_start = select.first_selected_option.text
    elem = browser.find_element_by_id('funding_bucket_proxy_fiscal_year_range_end')
    select = Select(elem)
    fy_end = select.first_selected_option.text

    if fy_end == fy_start:
        fiscal_year = fy_start.replace('-', '/').replace(' ', '')
    else:
        fiscal_year = 'FYXX/ZZ'

    ## Create Bucket Name
    return program + '-' + template + '-' + owner.partition("-")[0] + '-' + fiscal_year
def get_expected_bucket_name(multi_bucket='false'):
    if multi_bucket == 'true':
        return browser.find_element_by_id('funding_bucket_proxy_name').text[:-1]
    else:
        return browser.find_element_by_id('default_funding_bucket_name').text

# Test automatching FYs
def get_from_fy(from_fy='18'):
    dropdown = browser.find_element_by_id('funding_bucket_proxy_fiscal_year_range_start')
    for option in dropdown.find_elements_by_tag_name('option'):
        if option.text[3:5] == from_fy:
            option.click()
            break
        else:
            dropdown.send_keys(down_arrow)
    elem = browser.find_element_by_id('funding_bucket_proxy_fiscal_year_range_start')
    select = Select(elem)
    return select.first_selected_option.text
def get_to_fy():
    elem = browser.find_element_by_id('funding_bucket_proxy_fiscal_year_range_end')
    select = Select(elem)
    return select.first_selected_option.text

# Test bucket was created successfully and exists in table
def save_bucket(another='false'):
    # if 'another' = true, click "submit and add another"
    wait.until(EC.presence_of_element_located((By.ID, 'new_funding_bucket_proxy')))
    elem = browser.find_element_by_id('new_funding_bucket_proxy')
    if another == 'true':
        btn_div = elem.find_element_by_id('do_not_return_to_buckets_index_after_create')
        save = btn_div.find_element_by_css_selector('[class="btn btn-primary"]')
        save.click()
    else:
        save = elem.find_element_by_css_selector('[class="btn btn-primary"]')
        save.click()
    time.sleep(2)
def check_saved_bucket_exists(name=''):
    wait.until(EC.presence_of_element_located((By.CSS_SELECTOR, '[class="fixed-table-body"]')))
    table = browser.find_element_by_css_selector('[class="fixed-table-body"]')
    if name not in table.text:
        return False
    else:
        return True
def delete_bucket(name=''):
    if browser.current_url != base_url + 'funding_buckets':
        browser.get(base_url + 'funding_buckets')
    time.sleep(1)
    table = browser.find_element_by_css_selector('[class="fixed-table-body"]')
    for row in table.find_elements_by_tag_name('tr'):
        if name in row.text:
            delete = row.find_element_by_css_selector('[class="fa fa-trash-o fa-1-5x text-danger"]')
            delete.click()
            modal = browser.find_element_by_id('confirm_dialog_modal')
            modal_btn = modal.find_element_by_css_selector('[class="btn btn-success"]')
            modal_btn.click()

# Alert Modal (select option and submit)
def select_option_submit(option='replace'):
    if option is 'replace':
        replace_btn = browser.find_element_by_id('funding_bucket_proxy_create_conflict_option_replace')
        replace_btn.click()
    if option is 'ignore':
        ignore_btn = browser.find_element_by_id('funding_bucket_proxy_create_conflict_option_ignore')
        ignore_btn.click()
    if option is 'cancel':
        cancel_btn = browser.find_element_by_id('funding_bucket_proxy_create_conflict_option_cancel')
        cancel_btn.click()
    wait.until(EC.presence_of_element_located((By.ID, 'new_funding_bucket_proxy')))
    time.sleep(2)
    submit = browser.find_element_by_css_selector('[class="btn btn-primary"]')
    submit.click()
