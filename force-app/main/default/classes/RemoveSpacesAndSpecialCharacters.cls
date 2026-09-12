public without sharing class RemoveSpacesAndSpecialCharacters {

    @InvocableMethod(Label = 'Remove Spaces and Special characters')
    public static List<String> removeSpacesAndSpecialCharacters(List<String> inputs) {
        List<String> outputs = new List<String>();
        for (String text : inputs) {
            outputs.add(text.replaceAll('[^A-Za-z0-9]', ''));           
        }
        return outputs;
    }
}