@istest
private class ContentVersion_test {

    static testMethod void contentVersionTest(){
        
        ContentVersion cv = new ContentVersion();
			cv.title='Test title';
			cv.VersionData=blob.valueof('New Bitmap Image.bmp');
			cv.PathOnClient ='/abc.txt';
			cv.origin  ='H';
			
			Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
            cv.VersionData=bodyBlob; 
			
        insert cv;
		
	}
}