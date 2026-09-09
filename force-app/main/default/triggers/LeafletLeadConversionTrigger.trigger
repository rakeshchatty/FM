trigger LeafletLeadConversionTrigger on Lead (after insert, after update) {
    for(Lead l : Trigger.new) {
        if(l.Auto_Convert__c) {
            User u = [Select Id From User Where Name =: 'Joe Allen'];
            
            Database.LeadConvert lc = new database.LeadConvert();
            Database.LeadConvertResult lcr;
            lc.setLeadId(l.id);
            lc.setOwnerId(u.Id);
            
            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
            RecordType rt = [Select Id From RecordType Where Name = 'Prospect' Limit 1];
            
            lc.setConvertedStatus(convertStatus.MasterLabel);
            
            String opName = (l.Company == null ? '' : l.Company + ' Giveaway Pack'); 
            lc.setOpportunityName(opName);
            
            try{
                lcr = Database.convertLead(lc);
            } catch (Exception e) {
                System.debug('Error converting a lead : ' + e);
                continue;
            }
            
            //Account
            Account a = new Account(
                Id = lcr.accountId,
                RecordTypeId = rt.Id,
                Name = l.Company,
                Source__c = l.LeadSource,
                Send_Me_Sacks_Form_Complete__c = l.Send_Me_Sacks_Form_Complete__c,
                Revolution_Form_Complete__c = l.Revolution_Form_Complete__c,
                Box_Givewaway_Form_Complete__c = l.Box_Givewaway_Form_Complete__c,
                InvoiceFrequency__c = ''
            );
            
            upsert a; 
            
            //Contact
            Contact c = new Contact(
                Id = lcr.contactId,
                FirstName = l.FirstName,
                LastName = l.LastName,
                Email = l.Email,
                Phone = l.Phone,
                AccountId = a.Id
            );
            
            update c;
            
            //Opportunity
            Opportunity o = new Opportunity(
                Id = lcr.opportunityId,
                Name = a.Name + ' Giveaway Pack',
                Amount = 0,
                Estimated_Annual_Sales__c = 300,
                StageName = '6 Handed Over',
                LeadSource = l.LeadSource
            );
            
            update o;
            
            Account acc_updated = [Select BillingStreet From Account Where Id = :lcr.accountId];
            
            //Send email
            if(l.Revolution_Form_Complete__c){
                Messaging.reserveSingleEmailCapacity(1);
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                // Strings to hold the email addresses to which you are sending the email.
                String[] toAddresses = new String[] {'customers@thefirstmile.co.uk', 'sarah.hayes@thefirstmile.co.uk'}; 
                  
                // Assign the addresses for the To and CC lists to the mail object.
                mail.setToAddresses(toAddresses);
                
                // Specify the address used when the recipients reply to the email. 
                mail.setReplyTo('no-reply@thefirstmile.co.uk');
                
                // Specify the name used as the display name.
                mail.setSenderDisplayName('First Mile');
                
                // Specify the subject line for your email address.
                mail.setSubject('Collection set up - Free trial giveaway');
                
                // Set to True if you want to BCC yourself on the email.
                mail.setBccSender(false);
                
                // Optionally append the salesforce.com email signature to the email.
                // The email address of the user executing the Apex Code will be used.
                mail.setUseSignature(false);
                
                // Specify the text content of the email.
                String text_body = 'Please set up the following collection for this new customer. They have already received a free giveaway box.\n';
                text_body += 'SALESFORCE ACCOUNT ID: ' + a.Id + '\n';
                text_body += 'First Name: ' + l.FirstName + '\n';
                text_body += 'Last Name: ' + l.LastName + '\n';
                text_body += 'Email: ' + l.Email + '\n';
                text_body += 'Phone: ' + l.Phone + '\n';
                text_body += 'Company Name: ' + l.Company + '\n';
                text_body += 'Address: ' + acc_updated.BillingStreet + '\n';
                text_body += 'Postcode: ' + l.PostalCode + '\n';
                text_body += 'Current waste supplier: ' + l.Current_Supplier__c + '\n';
                text_body += 'How many sacks do you put out a day?: ' + l.How_many_sacks_do_you_put_out__c + '\n';
                text_body += 'How often is your recycling and waste collected?: ' + l.How_often_is_your_recycling_and_waste_co__c + '\n';
                text_body += 'Collection start date: ' + l.Collection_start_date__c + '\n';
                text_body += 'On the following days: ' + l.On_the_following_days__c + '\n';
                text_body += 'I put my bags out at: ' + l.I_put_my_bags_out_at__c + '\n';
                text_body += 'Any other requirements: ' + l.Comments__c + '\n';
                
                mail.setPlainTextBody(text_body);
                
                String body = '<p>Please set up the following collection for this new customer. They have already received a free giveaway box.</p>';
				body += '<ul><li>SALESFORCE ACCOUNT ID: <a href="https://' +URL.getSalesforceBaseUrl().getHost() +'/' + a.Id + '">' + a.Id + '</a></li>';
                body += '<li>First Name: ' + l.FirstName + '</li>';
                body += '<li>Last Name: ' + l.LastName + '</li>';
                body += '<li>Email: ' + l.Email + '</li>';
                body += '<li>Phone: ' + l.Phone + '</li>';
                body += '<li>Company Name: ' + l.Company + '</li>';
                body += '<li>Address: ' + acc_updated.BillingStreet + '</li>';
                body += '<li>Postcode: ' + l.PostalCode + '</li>';
                body += '<li>Current waste supplier: ' + l.Current_Supplier__c + '</li>';
                body += '<li>How many sacks do you put out a day?: ' + l.How_many_sacks_do_you_put_out__c + '</li>';
                body += '<li>How often is your recycling and waste collected?: ' + l.How_often_is_your_recycling_and_waste_co__c + '</li>';
                body += '<li>Collection start date: ' + l.Collection_start_date__c + '</li>';
                body += '<li>On the following days: ' + l.On_the_following_days__c + '</li>';
                body += '<li>I put my bags out at: ' + l.I_put_my_bags_out_at__c + '</li>';
                body += '<li>Any other requirements: ' + l.Comments__c + '</li></ul>';
                    
                mail.setHtmlBody(body);
                
                // Send the email you have created.
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
            
            if(l.Box_Givewaway_Form_Complete__c){
                Messaging.reserveSingleEmailCapacity(1);
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                // Strings to hold the email addresses to which you are sending the email.
                String[] toAddresses = new String[] {'customers@thefirstmile.co.uk', 'sarah.hayes@thefirstmile.co.uk'}; 
                  
                // Assign the addresses for the To and CC lists to the mail object.
                mail.setToAddresses(toAddresses);
                
                // Specify the address used when the recipients reply to the email. 
                mail.setReplyTo('no-reply@thefirstmile.co.uk');
                
                // Specify the name used as the display name.
                mail.setSenderDisplayName('First Mile');
                
                // Specify the subject line for your email address.
                mail.setSubject('Collection set up - Box giveaway');
                
                // Set to True if you want to BCC yourself on the email.
                mail.setBccSender(false);
                
                // Optionally append the salesforce.com email signature to the email.
                // The email address of the user executing the Apex Code will be used.
                mail.setUseSignature(false);
                
                // Specify the text content of the email.
                String text_body = 'Please set up the following collection for this new customer. They have already received a free giveaway box./n';
                text_body += 'SALESFORCE ACCOUNT ID:' + a.Id + '\n';
                text_body += 'First Name: ' + l.FirstName + '/n';
                text_body += 'Last Name: ' + l.LastName + '/n';
                text_body += 'Email: ' + l.Email + '/n';
                text_body += 'Phone: ' + l.Phone + '/n';
                text_body += 'Company Name: ' + l.Company + '/n';
                text_body += 'Address: ' + acc_updated.BillingStreet + '/n';
                text_body += 'Postcode: ' + l.PostalCode + '/n';
                text_body += 'Collection start date: ' + l.Collection_start_date__c + '/n';
                text_body += 'On the following days: ' + l.On_the_following_days__c + '/n';
                text_body += 'I put my bags out at: ' + l.I_put_my_bags_out_at__c + '/n';
                text_body += 'Any other requirements: ' + l.Comments__c + '/n'; 
                
                mail.setPlainTextBody(text_body);
                
                String body = '<p>Please set up the following collection for this new customer. They have already received a free giveaway box.</p>';
                body += '<ul><li>SALESFORCE ACCOUNT ID: <a href="https://' +URL.getSalesforceBaseUrl().getHost() +'/' + a.Id + '">' + a.Id + '</a></li>';
                body += '<li>First Name: ' + l.FirstName + '</li>';
                body += '<li>Last Name: ' + l.LastName + '</li>';
                body += '<li>Email: ' + l.Email + '</li>';
                body += '<li>Phone: ' + l.Phone + '</li>';
                body += '<li>Company Name: ' + l.Company + '</li>';
                body += '<li>Address: ' + acc_updated.BillingStreet + '</li>';
                body += '<li>Postcode: ' + l.PostalCode + '</li>';
                body += '<li>Collection start date: ' + l.Collection_start_date__c + '</li>';
                body += '<li>On the following days: ' + l.On_the_following_days__c + '</li>';
                body += '<li>I put my bags out at: ' + l.I_put_my_bags_out_at__c + '</li>';
                body += '<li>Any other requirements: ' + l.Comments__c + '</li></ul>';
                    
                mail.setHtmlBody(body);
                
                // Send the email you have created.
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
            
            if(l.Send_Me_Sacks_Form_Complete__c){
                Messaging.reserveSingleEmailCapacity(1);
                
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                
                // Strings to hold the email addresses to which you are sending the email.
                String[] toAddresses = new String[] {'customers@thefirstmile.co.uk', 'sarah.hayes@thefirstmile.co.uk'}; 
                  
                // Assign the addresses for the To and CC lists to the mail object.
                mail.setToAddresses(toAddresses);
                
                // Specify the address used when the recipients reply to the email. 
                mail.setReplyTo('no-reply@thefirstmile.co.uk');
                
                // Specify the name used as the display name.
                mail.setSenderDisplayName('First Mile');
                
                // Specify the subject line for your email address.
                mail.setSubject('New free trial');
                
                // Set to True if you want to BCC yourself on the email.
                mail.setBccSender(false);
                
                // Optionally append the salesforce.com email signature to the email.
                // The email address of the user executing the Apex Code will be used.
                mail.setUseSignature(false);
                
                // Specify the text content of the email.
                String text_body = 'Please set up the following new customer with a free trial pack delivery next working day.\n';
                text_body += 'SALESFORCE ACCOUNT ID: '+ a.Id + '\n';
                text_body += 'Name of BID: ' + l.BID__c + '\n';
                text_body += 'First Name: ' + l.FirstName + '\n';
                text_body += 'Last Name: ' + l.LastName + '\n';
                text_body += 'Email: ' + l.Email + '\n';
                text_body += 'Phone: ' + l.Phone + '\n';
                text_body += 'Company Name: ' + l.Company + '\n';
                text_body += 'Address: ' + acc_updated.BillingStreet + '\n';
                text_body += 'Postcode: ' + l.PostalCode + '\n';
                text_body += 'Current waste supplier: ' + l.Current_Supplier__c + '\n';
                text_body += 'Notes: ' + l.Comments__c + '\n';
                mail.setPlainTextBody(text_body);
                
                String body = '<p>Please set up the following new customer with a free trial pack delivery next working day.</p>';
                body += '<ul><li>SALESFORCE ACCOUNT ID: <a href="https://' +URL.getSalesforceBaseUrl().getHost() +'/' + a.Id + '">' + a.Id + '</a></li>';
                body += '<li>Name of BID: ' + l.BID__c + '</li>';
                body += '<li>First Name: ' + l.FirstName + '</li>';
                body += '<li>Last Name: ' + l.LastName + '</li>';
                body += '<li>Email: ' + l.Email + '</li>';
                body += '<li>Phone: ' + l.Phone + '</li>';
                body += '<li>Company Name: ' + l.Company + '</li>';
                body += '<li>Address: ' + acc_updated.BillingStreet + '</li>';
                body += '<li>Postcode: ' + l.PostalCode + '</li>';
                body += '<li>Current waste supplier: ' + l.Current_Supplier__c + '</li>';
                body += '<li>Notes: ' + l.Comments__c + '</li></ul>';    
                mail.setHtmlBody(body);
                
                // Send the email you have created.
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            }
        }
    }
}