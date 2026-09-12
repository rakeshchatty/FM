@isTest
private class RemoveSpacesAndSpecialCharactersTest {

    @isTest
    static void testRemoveSpacesAndSpecialCharacters() {
        List<String> inputStrings = new List<String>{'He?llo World!'};           
        List<String> Output = RemoveSpacesAndSpecialCharacters.removeSpacesAndSpecialCharacters(inputStrings);
        System.assertEquals('HelloWorld', Output[0]);
    }
}