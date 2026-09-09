@isTest
public class LeafletLeadConversionTest {
    
    @isTest
    static void test_1() {
        Integer emailbefore = Limits.getEmailInvocations();
        
        Lead l = new Lead(
        	FirstName = 'Test',
            LastName = 'Account',
            Company = 'Test Company',
            Email = 'test@mail.com',
            Phone = '00000000000',
            LeadSource = 'Got a leaflet',
            Auto_Convert__c = true,
            Revolution_Form_Complete__c = true,
            Services_wanted__c = 'Reporting and Data'
        );
        
        insert l;
        
        //Find Contact, Account and Opportunity
        Opportunity o = [Select Name, Amount, StageName, AccountId From Opportunity Where Name = :l.Company + ' Giveaway Pack'];
        
        //System.assertEquals(0, o.Amount);
        System.assertEquals('6 Handed Over', o.StageName);
        
        Account a = [Select Name, Source__c From Account Where Id = :o.AccountId];
        
        System.assertEquals(l.Company, a.Name);
        System.assertEquals(l.LeadSource, a.Source__c);
        
        for(Contact c : [Select FirstName, LastName, Email, Phone From Contact Where AccountId = :o.AccountId]){   
            System.assertEquals(l.FirstName, c.FirstName);
            System.assertEquals(l.LastName, c.LastName);
            System.assertEquals(l.Email, c.Email);
            System.assertEquals(l.Phone, c.Phone);
        }
        
        system.assertNotEquals(emailbefore,Limits.getEmailInvocations());
    }
    
    @isTest
    static void test_2() {
        Lead l = new Lead(
        	FirstName = 'Test',
            LastName = 'Account',
            Company = 'Test Company',
            Email = 'test@mail.com',
            Phone = '00000000000',
            LeadSource = 'Got a leaflet',
            Services_wanted__c = 'Reporting and Data'
        );
        
        insert l;
        
        Lead l2 = new Lead(
        	Id = l.Id,
            Auto_Convert__c = true,
            Send_Me_Sacks_Form_Complete__c = true
        );
        
        update l2;
        
        //Find Contact, Account and Opportunity
        Opportunity o = [Select Name, Amount, StageName, AccountId From Opportunity Where Name = :l.Company + ' Giveaway Pack'];
        
        //System.assertEquals(0, o.Amount);
        System.assertEquals('6 Handed Over', o.StageName);
        
        Account a = [Select Name, Source__c From Account Where Id = :o.AccountId];
        
        System.assertEquals(l.Company, a.Name);
        System.assertEquals(l.LeadSource, a.Source__c);
        
        for(Contact c : [Select FirstName, LastName, Email, Phone From Contact Where AccountId = :o.AccountId]){   
            System.assertEquals(l.FirstName, c.FirstName);
            System.assertEquals(l.LastName, c.LastName);
            System.assertEquals(l.Email, c.Email);
            System.assertEquals(l.Phone, c.Phone);
        }
    }
    
    @isTest
    static void test_3() {
        Lead l = new Lead(
        	FirstName = 'Test',
            LastName = 'Account',
            Company = 'Test Company',
            Email = 'test@mail.com',
            Phone = '00000000000',
            LeadSource = 'Got a leaflet',
            Auto_Convert__c = true,
            Box_Givewaway_Form_Complete__c = true,
            Services_wanted__c = 'Reporting and Data'
        );
        
        insert l;
        
        //Find Contact, Account and Opportunity
        Opportunity o = [Select Name, Amount, StageName, AccountId From Opportunity Where Name = :l.Company + ' Giveaway Pack'];
        
        //System.assertEquals(0, o.Amount);
        System.assertEquals('6 Handed Over', o.StageName);
        
        Account a = [Select Name, Source__c From Account Where Id = :o.AccountId];
        
        System.assertEquals(l.Company, a.Name);
        System.assertEquals(l.LeadSource, a.Source__c);
        
        for(Contact c : [Select FirstName, LastName, Email, Phone From Contact Where AccountId = :o.AccountId]){   
            System.assertEquals(l.FirstName, c.FirstName);
            System.assertEquals(l.LastName, c.LastName);
            System.assertEquals(l.Email, c.Email);
            System.assertEquals(l.Phone, c.Phone);
        }
    }

}