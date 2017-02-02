import unittest
from bucketFw import *

class BucketCreationForm(unittest.TestCase):
    @classmethod
    def setUpClass(self):
        browser.get(base_url)
        print('Setting up...')
        user_login()

    def setUp(self):
        browser.get(base_url + 'funding_buckets/new')

    def tearDown(self):
        print('Test Ended')

    @classmethod
    def tearDownClass(self):
        browser.quit()

    # Test bucket form behavior
    def test_bucket_form_multi_agency(self):
        print('Starting Multi-agency Test...')
        try:
            # Create Bucket
            create_bucket('false','Bucket Testing','ALL ORGS multi-agency','BPT')

            # Validate FY behavior
            from_fy = get_from_fy('17')
            print('FROM FY: ' + from_fy)
            to_fy = get_to_fy()
            print('TO FY: ' + to_fy)
            self.assertEquals(to_fy, from_fy, 'MULTI-AGENCY TEMPALTE: Fiscal years should be automatching but are NOT.')

            # Validate Bucket Name
            expected = get_expected_bucket_name()
            print('EXPECTED BUCKET NAME: ' + expected)
            actual = get_actual_bucketname()
            print('ACTIUAL BUCKET NAME: ' + actual)
            self.assertEquals(expected, actual, 'Expected bucket name did not match actual bucket name.')

            # Validate bucket exists in bucket table
            save_bucket()
            created = check_saved_bucket_exists(actual)
            self.assertEquals(created, True, 'Bucket not created (or created but not listed in buckets table: ' + actual)

        finally:
            # Delete Bucket
            delete_bucket('Bucket Testing-ALL ORGS multi-agency-BPT-FY17/18')
    def test_bucket_form_multi_bucket(self):
        print('Starting Multi-bucket Test...')
        try:
            # Create Bucket
            create_bucket('false', 'Bucket Testing', 'ALL ORGS multi-buckets', 'AMTRAN')

            # Validate FY behavior
            from_fy = get_from_fy('17')
            print('FROM FY: ' + from_fy)
            to_fy = get_to_fy()
            print('TO FY: ' + to_fy)
            self.assertEqual(to_fy, from_fy, 'MULTI-BUCKET TEMPALTE: Fiscal years should be automatching but are not.')

            # Validate Bucket Name
            expected = get_expected_bucket_name('true')
            textarea = browser.find_element_by_id('custom_funding_bucket_name')
            self.assertEquals(True, textarea.is_displayed(), 'Custom name textarea not present [id="custom_funding_bucket_name"]. Check custom bucket name textarea.')
            print('EXPECTED BUCKET NAME: ' + expected)
            actual = get_actual_bucketname()
            print('ACTIUAL BUCKET NAME: ' + actual)
            self.assertEquals(expected, actual,'Expected bucket name did not match actual bucket name.')

            # Validate bucket exists in bucket table
            save_bucket()
            created = check_saved_bucket_exists()
            self.assertEquals(created, True, 'Bucket not created (or created but not listed in buckets table: ' + actual)

        finally:
            # Delete Bucket
            delete_bucket('Bucket Testing-ALL ORGS multi-buckets-AMTRAN-FY17/18-')
    def test_bucket_form_multi_year(self):
        print('Starting Multi-year Test...')
        try:

            # Create Bucket
            create_bucket('false', 'Bucket Testing', 'ALL ORGS multi-year', 'BPT')

            # Validate FY behavior
            from_fy = get_from_fy('17')
            print('FROM FY: ' + from_fy)
            to_fy = get_to_fy()
            print('TO FY: ' + to_fy)
            self.assertNotEquals(to_fy, from_fy, 'MULTI-YEAR TEMPALTE: Fiscal years should NOT be automatching but are.')

            # Validate Bucket Name
            expected = get_expected_bucket_name()
            print('EXPECTED BUCKET NAME: ' + expected)
            actual = get_actual_bucketname()
            print('ACTIUAL BUCKET NAME: ' + actual)
            self.assertEquals(expected, actual, 'Expected bucket name did not match actual bucket name.')

            # Validate buckets exist in bucket table
            save_bucket()
            bucket1 = 'Bucket Testing-ALL ORGS multi-year-BPT-FY17/18'
            bucket2 = 'Bucket Testing-ALL ORGS multi-year-BPT-FY18/19'
            created = check_saved_bucket_exists(bucket1)
            self.assertEquals(created, True, 'Bucket not created (or created but not listed in buckets table: ' + bucket1)
            created = check_saved_bucket_exists(bucket2)
            self.assertEquals(created, True, 'Bucket not created (or created but not listed in buckets table: ' + bucket1)

        finally:
            # Delete Buckets
            delete_bucket('Bucket Testing-ALL ORGS multi-year-BPT-FY17/18')
            time.sleep(1)
            delete_bucket('Bucket Testing-ALL ORGS multi-year-BPT-FY18/19')

    # Test unique name validations
    def test_custom_name(self):
        print('Starting custom name test...')
        try:
            # Create Buckets and Save bucket
            create_bucket('false', 'Bucket Testing', 'ALL ORGS multi-buckets', 'AMTRAN', 'unique_name')
            save_bucket('true')

            # Validate unique name enforcement
            create_bucket('false', 'Bucket Testing', 'ALL ORGS multi-buckets', 'BARTA', 'unique_name')
            save_bucket()
            self.assertEquals(is_element_present(By.ID, 'funding_bucket_proxy_name-error'), True,
                              'Unique name validation message NOT displaying.')

        finally:
            # Delete Bucket
            delete_bucket('unique_name')
    def test_alert_modal_replace(self):
        print('Starting alert modal test (replace)...')
        try:
            # Create and save bucket
            create_bucket('false', 'Bucket Testing', 'ALL ORGS multi-agency', 'AMTRAN')
            save_bucket()
            browser.get(base_url + 'funding_buckets/new')

            # Verify alert modal appears
            create_bucket('false', 'Bucket Testing', 'ALL ORGS multi-agency', 'AMTRAN', 'false', '17', '18', '15')
            actual_name = get_actual_bucketname()
            save_bucket()
            self.assertEquals(is_element_present(By.CSS_SELECTOR, '[class="modal-content"]'), True, 'Alert modal did not display.')

            # Validate conflict in bucket names
            table = browser.find_element_by_css_selector('[class="table table-hover"]')
            row = table.find_element_by_css_selector('[class="action-path"]')
            modal_bucket_name = row.find_element_by_xpath('//td[3]').text
            print('ACTUAL BUCKET NAME: ' + actual_name)
            print('MODAL BUCKET NAME: ' + modal_bucket_name)
            self.assertEquals(modal_bucket_name, actual_name,
                              'Name alert modal did not match parameters entered on the bucket form. Check conflict exists.')

            # Test Replace option
            select_option_submit('replace')
            time.sleep(1)
            exists = check_saved_bucket_exists('Bucket Testing-ALL ORGS multi-agency-AMTRAN-FY18/19')
            self.assertEquals(exists, True,
                              'Cannot find bucket on bucket table. Bucket was possibly removed instead of replaced.')
            table = browser.find_element_by_css_selector('table.table.table-hover tbody')
            funding = table.find_element_by_css_selector('tr:last-child td:nth-of-type(6)').text
            self.assertEquals(funding, '$15',
                              'Bucket not replaced. Funding of new bucket should be 10 but is: ' + funding)

        finally:
            delete_bucket('Bucket Testing-ALL ORGS multi-agency-AMTRAN-FY18/19')
    def test_alert_modal_ignore(self):
        print('Starting alert modal test (ignore)...')
        try:
            # Create and save bucket
            create_bucket('false', 'Bucket Testing', 'ALL ORGS multi-agency', 'AMTRAN')
            save_bucket()
            browser.get(base_url + 'funding_buckets/new')

            # Verify alert modal appears
            create_bucket('false', 'Bucket Testing', 'ALL ORGS multi-agency', 'AMTRAN', 'false', '17', '18', '10')
            actual_name = get_actual_bucketname()
            save_bucket()
            self.assertEquals(is_element_present(By.CSS_SELECTOR, '[class="modal-content"]'), True,
                              'Alert modal did not display.')

            # Validate conflict in bucket names
            table = browser.find_element_by_css_selector('[class="table table-hover"]')
            row = table.find_element_by_css_selector('[class="action-path"]')
            modal_bucket_name = row.find_element_by_xpath('//td[3]').text
            print('ACTUAL BUCKET NAME: ' + actual_name)
            print('MODAL BUCKET NAME: ' + modal_bucket_name)
            self.assertEquals(modal_bucket_name, actual_name,
                              'Name alert modal did not match parameters entered on the bucket form. Check conflict exists.')

            # Test Ignore option
            select_option_submit('ignore')
            time.sleep(1)
            exists = check_saved_bucket_exists('Bucket Testing-ALL ORGS multi-agency-AMTRAN-FY18/19')
            self.assertEquals(exists, True,
                              'Cannot find bucket on bucket table. Bucket was possibly removed instead of being ignored.')
            table = browser.find_element_by_css_selector('table.table.table-hover tbody')
            funding = table.find_element_by_css_selector('tr:last-child td:nth-of-type(6)').text
            self.assertEquals(funding, '$5',
                              'Bucket not ignored but replaced. Funding of ignored bucket should be 5 but is: ' + funding)

        finally:
            delete_bucket('Bucket Testing-ALL ORGS multi-agency-AMTRAN-FY18/19')
    def test_alert_modal_cancel(self):
        print('Starting alert modal test (cancel)...')
        try:
            # Create and save bucket
            create_bucket('false', 'Bucket Testing', 'ALL ORGS multi-agency', 'AMTRAN')
            save_bucket()
            browser.get(base_url + 'funding_buckets/new')

            # Verify alert modal appears
            create_bucket('false', 'Bucket Testing', 'ALL ORGS multi-agency', 'AMTRAN', 'false', '17', '18', '10')
            actual_name = get_actual_bucketname()
            save_bucket()
            self.assertEquals(is_element_present(By.CSS_SELECTOR, '[class="modal-content"]'), True,
                              'Alert modal did not display.')

            # Validate conflict in bucket names
            table = browser.find_element_by_css_selector('[class="table table-hover"]')
            row = table.find_element_by_css_selector('[class="action-path"]')
            modal_bucket_name = row.find_element_by_xpath('//td[3]').text
            print('ACTUAL BUCKET NAME: ' + actual_name)
            print('MODAL BUCKET NAME: ' + modal_bucket_name)
            self.assertEquals(modal_bucket_name, actual_name,
                              'Name alert modal did not match parameters entered on the bucket form. Check conflict exists.')

            # Test Cancel option
            select_option_submit('ignore')
            time.sleep(1)
            exists = check_saved_bucket_exists('Bucket Testing-ALL ORGS multi-agency-AMTRAN-FY18/19')
            self.assertEquals(exists, True,
                              'Cannot find bucket on bucket table. Bucket was possibly removed instead of the save operation cancelled.')
            table = browser.find_element_by_css_selector('table.table.table-hover tbody')
            funding = table.find_element_by_css_selector('tr:last-child td:nth-of-type(6)').text
            self.assertEquals(funding, '$5',
                              'Save bucket operation was not cancelled as expected. Funding of bucket should be 5 but is: ' + funding)


        finally:
            delete_bucket('Bucket Testing-ALL ORGS multi-agency-AMTRAN-FY18/19')

if __name__ == '__main__':
    unittest.main()