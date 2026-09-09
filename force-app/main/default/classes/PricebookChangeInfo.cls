public class PricebookChangeInfo {
    public Decimal PricebookCode {get; set;}
    public Id oldPricebookVersion {get; set;}
    public Id newPricebookVersion {get; set;}

    public PricebookChangeInfo(Decimal pbCode, Id oldPbId, Id newPbId)
    {
        this.PricebookCode = pbCode;
        this.newPricebookVersion = newPbId;
        this.oldPricebookVersion = oldPbId;
    }
}